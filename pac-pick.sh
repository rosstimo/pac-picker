#!/bin/bash

# Safety measures to ensure the script exits on errors, uses unset variables, or pipeline failures.
set -o errexit  # Exit immediately if a command exits with a non-zero status.
set -o nounset  # Treat unset variables as an error and exit immediately.
set -o pipefail # Return the exit status of the last command in the pipeline that failed.

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

# Function: main
# Purpose: Main script logic to handle user input and manage optional dependencies.
# Arguments: 
#   $@ - The package name to check.
main() {
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <package>"
        return 1
    fi
    local package=$1
    # Capture the result of get_optional_deps.
    optional_deps=$(get_optional_deps "$package")
    if [ $? -ne 0 ]; then
        echo "Error: Could not get optional dependencies for $package"
        return 1
    fi
    # Create and echo a summary of the optional dependencies to be installed/removed.
    selections=$(get_selections "$optional_deps")
    echo "$selections"
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
test_get_optional_deps() {
    output=$(get_optional_deps bash)
    if [[ "$output" == *"readline"* ]]; then
        echo "test_get_optional_deps passed"
    else
        echo "test_get_optional_deps failed"
    fi
}

# Test function for get_selections
# Purpose: Tests the get_selections function.
test_get_selections() {
    optional_deps="readline: GNU readline library: 1"
    output=$(echo "$optional_deps" | get_selections)
    if [[ "$output" == *"Selected items: readline"* ]]; then
        echo "test_get_selections passed"
    else
        echo "test_get_selections failed"
    fi
}

# Test function for get_optional_deps with fake data
# Purpose: Tests the get_optional_deps function with fake data.
test_get_optional_deps_fake() {
    fake_data="Optional Deps : fakepkg1: Fake package 1 description
fakepkg2: Fake package 2 description"
    output=$(echo "$fake_data" | get_optional_deps)
    if [[ "$output" == *"fakepkg1"* ]] && [[ "$output" == *"fakepkg2"* ]]; then
        echo "test_get_optional_deps_fake passed"
    else
        echo "test_get_optional_deps_fake failed"
    fi
}

# Function: run_tests
# Purpose: Runs all test functions and logs results to a timestamped file.
run_tests() {
    local log_file="test_results_$(date +%Y%m%d_%H%M%S).log"
    {
        echo "Running test_is_installed..."
        test_is_installed
        echo "Running test_get_optional_deps..."
        test_get_optional_deps
        echo "Running test_get_selections..."
        test_get_selections
        echo "Running test_get_optional_deps_fake..."
        test_get_optional_deps_fake
        echo "All tests completed."
    } | tee "$log_file"
}

# Uncomment the following line to run tests
 run_tests

# Uncomment the following line to run the main function
# main "$@"

# Plan Outline
# [ ] 1. Show welcome screen using dialog
# [ ] 2. Check if yay is installed
# [ ]    - Yes: Use dialog to ask user to select continue with yay or use pacman
# [ ]    - No: Use pacman
# [ ] 3. Use the selected pacman/yay to check if the $package is valid/installable. If not, show message and exit
# [ ] 4. If found, run get_optional_deps. If none, continue
# [ ] 5. If one or more, run get_selections
# [ ] 6. Use dialog to inform the user that there are optional dependencies
# [x] 7. Use dialog to let the user choose all, none, or custom
# [ ]    - If all, continue with a list of all optional dependencies to install
# [ ]    - If none, continue and don't install or remove any optional dependencies
# [ ]    - If custom, use selected items to create a list of packages to install (--needed)
# [x]    - Use not selected items to create a list of packages to remove (only if installed)
# [ ] 8. Use dialog to show a summary of the packages to be installed and removed
# [ ] 9. Ask user to confirm or cancel
# [ ] 10. If confirm, perform remove then perform install
# [ ] 11. Add tests for all functions
# [ ] 12. run shell check and fix as needed
# [ ] 13. update comments and documentation
