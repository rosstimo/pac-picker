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

# Main function
main() {
    # Verify there is at least one argument or show Usage
    if [ $# -lt 1 ]; then
        echo "Usage: $0 <package_name>"
        return 1
    fi

    local package=$1

    # Capture the result of get_optional_deps
    optional_deps=$(get_optional_deps "$package")
    if [ $? -ne 0 ]; then
        echo "Error: Could not get optional dependencies for $package"
        return 1
    fi

    # Print the optional dependencies
    echo "$optional_deps"
}

# Call the main function with all script arguments
main "$@"

