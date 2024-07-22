#!/bin/bash

# Ensure the script runs in bash
if [ -z "$BASH_VERSION" ]; then
    echo "This script requires bash." >&2
    exit 1
fi

# Function to return two arrays using process substitution
return_arrays() {
    local array1=("apple" "banana with space" "cherry")
    local array2=("dog" "elephant" "frog")

    if ! echo "${array1[@]}" >&3; then
        echo "Error writing to file descriptor 3" >&2
        return 1
    fi

    if ! echo "${array2[@]}" >&4; then
        echo "Error writing to file descriptor 4" >&2
        return 1
    fi
}

# Check if process substitution is supported
if ! echo >(true) &>/dev/null; then
    echo "Process substitution is not supported in this environment" >&2
    exit 1
fi

# Open file descriptors for capturing the arrays
exec 3> >(readarray -t array1)
exec 4> >(readarray -t array2)

# Call the function
return_arrays

# Close file descriptors
exec 3>&-
exec 4>&-

# Enable debugging for this section
set -x

# Access the arrays
echo "Array 1: ${array1[@]}"
echo "Array 2: ${array2[@]}"

# Disable debugging
set +x

