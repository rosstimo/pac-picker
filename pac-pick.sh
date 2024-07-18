#!/bin/sh

# Function to check if a package is installed
is_installed() {
    local package=$1

    if pacman -Q "$package" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to get optional dependencies of a package
get_optional_deps() {
    local package=$1

    # Extract optional dependencies
    local opt_deps=$(pacman -Si "$package" | sed -n '/^Optional Deps/,/^Conflicts With/p' | sed '$d')

    # Process each line to handle multiple colons
    echo "$opt_deps" | while read -r line; do
        # Remove the "Optional Deps :" prefix from the first line
        if echo "$line" | grep -q "^Optional Deps"; then
            line=$(echo "$line" | sed 's/^Optional Deps *: //')
        fi

        # Extract the package name (first field) and description (rest of the line)
        package_name=$(echo "$line" | cut -d':' -f1)
        description=$(echo "$line" | cut -d':' -f2-)

        # Check if the package is installed
        if is_installed "$package_name"; then
            installed=1
        else
            installed=0
        fi

        # Print the package name, description, and installation status
        echo "$package_name: $description: $installed"
    done
}

# Function to create a menu of optional dependencies using dialog
get_selections() {
    local optional_deps="$1"

    # Create an array to store the dialog items
    local dialog_items=()

    # Process each line of the optional dependencies
    IFS=$'\n'
    for line in $optional_deps; do
        # Extract the package name, description, and installation status
        package_name=$(echo "$line" | cut -d':' -f1)
        description=$(echo "$line" | cut -d':' -f2)
        installed=$(echo "$line" | cut -d':' -f3)

        # Add the package name, description, and selection status to the dialog list
        if [ "$installed" -eq 1 ]; then
            dialog_items+=("$package_name" "$description" "on")
        else
            dialog_items+=("$package_name" "$description" "off")
        fi
    done

    # Create a dialog checklist of optional dependencies
    choices=$(dialog --separate-output --checklist "Select optional dependencies to install:" 15 50 10 "${dialog_items[@]}" 2>&1 >/dev/tty)

    # Clear the screen after dialog exits
    clear

    # Process the selected and not selected items
    local selected_items=()
    local not_selected_items=()

    # Convert choices to an array
    IFS=$'\n' read -d '' -r -a selected_items <<< "$choices"

    # Determine not selected items
    for line in $optional_deps; do
        package_name=$(echo "$line" | cut -d':' -f1)
        if ! [[ " ${selected_items[@]} " =~ " ${package_name} " ]]; then
            not_selected_items+=("$package_name")
        fi
    done

    # Return the selected and not selected items
    echo "Selected items: ${selected_items[@]}"
    echo "Not selected items: ${not_selected_items[@]}"
}

# Main function
main() {
    # Verify there is at least one argument or show Usage
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <package_name>"
        return 1
    fi

    local package=$1

    # Check if the package is already installed
    if is_installed "$package"; then
        echo "Package '$package' is already installed."
        return 0
    fi

    # Capture the result of get_optional_deps
    optional_deps=$(get_optional_deps "$package")
    if [ $? -ne 0 ]; then
        echo "Error: Could not get optional dependencies for $package"
        return 1
    fi

    # Use the function get_selections to create and echo a summary of the optional dependencies to be installed/removed
    selections=$(get_selections "$optional_deps")

    # Print the selections
    echo "$selections"
}

# Call the main function with all script arguments
main "$@"

