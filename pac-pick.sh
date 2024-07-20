#!/bin/bash

# Safety measures to ensure the script exits on errors, uses unset variables, or pipeline failures.
set -o errexit  # Exit immediately if a command exits with a non-zero status.
set -o nounset  # Treat unset variables as an error and exit immediately.
set -o pipefail # Return the exit status of the last command in the pipeline that failed.

# Function: show_welcome_screen
# Purpose: Displays a welcome screen using dialog.
show_welcome_screen() {
    dialog --title "Welcome" --msgbox "Welcome to the pac-pick script! This script helps you manage optional dependencies for packages." 10 50
    clear
}

# Function: is_installed
# Purpose: Checks if a given package is installed using pacman.
# Arguments:
#   $1 - The name of the package to check.
# Returns:
#   0 if the package is installed, 1 otherwise.
is_installed() {
    local package=$1
    if pacman -Q "$package" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function: is_yay_installed
# Purpose: Checks if yay is installed.
# Returns:
#   0 if yay is installed, 1 otherwise.
is_yay_installed() {
    if command -v yay &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function: select_package_manager
# Purpose: Asks the user to select whether to continue with yay or use pacman.
# Returns:
#   The selected package manager (yay or pacman).
select_package_manager() {
    local choice=$(dialog --title "Select Package Manager" --menu "yay is installed. Select package manager to use:" 15 50 2 \
        1 "yay" \
        2 "pacman" 2>&1 >/dev/tty)
    clear
    if [ "$choice" -eq 1 ]; then
        echo "yay"
    else
        echo "pacman"
    fi
}

# Function: is_package_valid
# Purpose: Checks if a given package is valid and installable.
# Arguments:
#   $1 - The name of the package manager.
#   $2 - The name of the package to check.
# Returns:
#   0 if the package is valid, 1 otherwise.
is_package_valid() {
    local package_manager=$1
    local package=$2
    local output

    if [[ "$package_manager" == "yay" ]]; then
        output=$(yay -Si "$package" 2>&1)
        if [[ -z "$output" ]]; then
            return 1
        else
            return 0
        fi
    else
        output=$(pacman -Si "$package" 2>&1)
        if echo "$output" | grep -q '^error:'; then
            return 1
        else
            return 0
        fi
    fi
}
# Function: get_optional_deps
# Purpose: Retrieves optional dependencies of a given package and checks their installation status.
# Arguments:
#   $1 - The name of the package to check.
# Returns:
#   A list of optional dependencies with their descriptions and installation status.
get_optional_deps() {
    local package=$1
    # Extract optional dependencies from pacman information.
    local opt_deps=$(pacman -Si "$package" | sed -n '/^Optional Deps/,/^Conflicts With/p' | sed '$d')
    # Process each line to handle multiple colons and format the output.
    echo "$opt_deps" | while read -r line; do
        # Remove the "Optional Deps :" prefix from the first line.
        if echo "$line" | grep -q "^Optional Deps"; then
            line=$(echo "$line" | sed 's/^Optional Deps *: //')
        fi
        # Extract the package name and description.
        package_name=$(echo "$line" | cut -d':' -f1)
        description=$(echo "$line" | cut -d':' -f2-)
        # Check if the package is installed.
        if is_installed "$package_name"; then
            installed=1
        else
            installed=0
        fi
        # Print the package name, description, and installation status.
        echo "$package_name: $description: $installed"
    done
}

# Function: get_selections
# Purpose: Creates a menu of optional dependencies using dialog and captures user selections.
# Arguments:
#   $1 - A list of optional dependencies with their descriptions and installation status.
# Returns:
#   Lists of selected and not selected items.
get_selections() {
    local optional_deps="$1"
    local dialog_items=()
    IFS=$'\n'
    # Process each line of the optional dependencies.
    for line in $optional_deps; do
        package_name=$(echo "$line" | cut -d':' -f1)
        description=$(echo "$line" | cut -d':' -f2)
        installed=$(echo "$line" | cut -d':' -f3)
        # Add the package name, description, and selection status to the dialog list.
        if [ "$installed" -eq 1 ]; then
            dialog_items+=("$package_name" "$description" "on")
        else
            dialog_items+=("$package_name" "$description" "off")
        fi
    done
    # Create a dialog checklist of optional dependencies.
    choices=$(dialog --separate-output --checklist "Select optional dependencies to install:" 15 50 10 "${dialog_items[@]}" 2>&1 >/dev/tty)
    clear
    local selected_items=()
    local not_selected_items=()
    # Convert choices to an array.
    IFS=$'\n' read -d '' -r -a selected_items <<< "$choices"
    # Determine not selected items.
    for line in $optional_deps; do
        package_name=$(echo "$line" | cut -d':' -f1)
        if ! [[ " ${selected_items[@]} " =~ " ${package_name} " ]]; then
            not_selected_items+=("$package_name")
        fi
    done
    # Return the selected and not selected items.
    echo "Selected items: ${selected_items[@]}"
    echo "Not selected items: ${not_selected_items[@]}"
    IFS=$' \t\n'
}

# Function: show_summary
# Purpose: Shows a summary of the packages to be installed and removed using dialog.
# Arguments:
#   $1 - A list of packages to install.
#   $2 - A list of packages to remove.
show_summary() {
    local install_list="$1"
    local remove_list="$2"
    dialog --title "Summary" --msgbox "Packages to install:\n$install_list\n\nPackages to remove:\n$remove_list" 15 50
    clear
}

# Function: confirm_action
# Purpose: Asks the user to confirm the actions using dialog.
# Returns:
#   0 if the user confirms, 1 otherwise.
confirm_action() {
    dialog --title "Confirm" --yesno "Do you want to proceed with the installation and removal of packages?" 10 50
    clear
    return $?
}

# Function: main
# Purpose: Main script logic to handle user input and manage optional dependencies.
# Arguments:
#   $@ - The package name to check.
main() {
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <package_name>"
        return 1
    fi
    local package=${1:-}
    if [ -z "$package" ]; then
        echo "Error: Package name is required."
        return 1
    fi

    # Show the welcome screen
    show_welcome_screen

    # Check if yay is installed and prompt user to select package manager
    local package_manager="pacman"
    if is_yay_installed; then
        package_manager=$(select_package_manager)
    fi

    echo "Using package manager: $package_manager"

    # Check if the package is valid/installable
    if ! is_package_valid "$package_manager" "$package"; then
        dialog --title "Error" --msgbox "Package $package is not valid or installable." 10 50
        clear
        return 1
    fi

    echo "Checking optional dependencies for package: $package"
    optional_deps=$(get_optional_deps "$package")
    if [ $? -ne 0 ]; then
        dialog --title "Error" --msgbox "Could not get optional dependencies for $package" 10 50
        clear
        return 1
    fi
    echo "Retrieved optional dependencies for $package"

    # Inform the user about optional dependencies
    dialog --title "Optional Dependencies" --msgbox "Optional dependencies for $package have been retrieved." 10 50
    clear

    # Let the user choose all, none, or custom dependencies
    local choice=$(dialog --title "Choose Dependencies" --menu "Select an option:" 15 50 3 \
        1 "All" \
        2 "None" \
        3 "Custom" 2>&1 >/dev/tty)
    clear

    local install_list=""
    local remove_list=""

    case $choice in
        1)  # All
            install_list=$(echo "$optional_deps" | awk -F': ' '{print $1}')
            ;;
        2)  # None
            install_list=""
            ;;
        3)  # Custom
            selections=$(get_selections "$optional_deps")
            install_list=$(echo "$selections" | grep "Selected items:" | cut -d':' -f2)
            remove_list=$(echo "$selections" | grep "Not selected items:" | cut -d':' -f2)
            ;;
    esac

    # Show summary and confirm
    show_summary "$install_list" "$remove_list"
    if confirm_action; then
        # Perform installation and removal
        if [ -n "$remove_list" ]; then
            echo "Removing packages: $remove_list"
            sudo $package_manager -Rns $remove_list
        fi
        if [ -n "$install_list" ]; then
            echo "Installing packages: $install_list"
            sudo $package_manager -S --needed $install_list
        fi
    else
        echo "Action canceled."
    fi
}

# Test function for is_installed
# Purpose: Tests the is_installed function.
test_is_installed() {
    pacman -Q bash &> /dev/null
    if [ $? -eq 0 ]; then
        is_installed bash
        [ $? -eq 0 ] && echo "test_is_installed passed" || echo "test_is_installed failed"
    else
        is_installed non_existent_package
        [ $? -eq 1 ] && echo "test_is_installed passed" || echo "test_is_installed failed"
    fi
}

# Test function for get_optional_deps
# Purpose: Tests the get_optional_deps function.
# TODO use the test method from the dialogexample.sh if passes test with vlc package
# TODO: user will have to look at dialog and confirm if the output is correct
test_get_optional_deps() {
    local package="vlc"
    local output=$(get_optional_deps "$package")
    echo "Output of get_optional_deps for $package:"
    echo "$output"
    echo "Please confirm if the output is correct."
}

# Test function for get_selections
# Purpose: Tests the get_selections function.
test_get_selections() {
    local optional_deps="readline: GNU readline library: 1"
    output=$(echo "$optional_deps" | get_selections)
    if [[ "$output" == *"Selected items: readline"* ]]; then
        echo "test_get_selections passed"
    else
        echo "test_get_selections failed"
    fi
}

# Function: run_tests
# Purpose: Runs all test functions and logs results to a timestamped log file.
run_tests() {
    local log_file="test_results_$(date +%Y%m%d_%H%M%S).log"
    {
        echo "Running test_is_installed..."
        test_is_installed
        echo "Running test_get_optional_deps..."
        test_get_optional_deps
        echo "Running test_get_selections..."
        test_get_selections
        echo "All tests completed."
    } | tee "$log_file"
}

# Function: show_help
# Purpose: Displays help message for the script.
show_help() {
    echo "Usage: $0 [--debug] <package_name>"
    echo
    echo "Options:"
    echo "  --debug    Run tests instead of the main script."
    echo "  -h, --help Show this help message."
}

# Parse command-line arguments
if [[ $# -eq 0 ]]; then
    show_help
    exit 1
fi

case "$1" in
    --debug)
        run_tests
        ;;
    -h|--help)
        show_help
        ;;
    *)
        main "$@"
        ;;
esac

# Plan Outline
# 1. [x] Show welcome screen using dialog
# 2. [x] Check if yay is installed
#    - [x] Yes: Use dialog to ask user to select continue with yay or use pacman
#    - [x] No: Use pacman
# 3. [x] Use the selected pacman/yay to check if the $package is valid/installable. If not, show message and exit
# 4. [x] If found, run get_optional_deps. If none, continue
# 5. [x] If one or more, run get_selections
# 6. [x] Use dialog to inform the user that there are optional dependencies
# 7. [x] Use dialog to let the user choose all, none, or custom
#    - [x] If all, continue with a list of all optional dependencies to install
#    - [x] If none, continue and don't install or remove any optional dependencies
#    - [x] If custom, use selected items to create a list of packages to install (--needed)
#      - [x] Use not selected items to create a list of packages to remove (only if installed)
# 8. [ ] Use dialog to show a summary of the packages to be installed and removed
# 9. [ ] Ask user to confirm or cancel
# 10. [ ] If confirm, perform remove then perform install
# 11. [ ] Add tests for all functions
# 12. [ ] Run shell check and fix as needed
# 13. [ ] Update comments and documentation

