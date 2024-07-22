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

    echo "${array1[@]}" >&3
    echo "${array2[@]}" >&4
}

# Check if process substitution is supported
if ! echo >(true) &>/dev/null; then
    echo "Process substitution is not supported in this environment" >&2
    exit 1
fi

# Create temporary files
tmpfile1=$(mktemp)
tmpfile2=$(mktemp)

# Open file descriptors for capturing the arrays using temporary files
exec 3> "$tmpfile1"
exec 4> "$tmpfile2"

# Call the function
return_arrays

# Close file descriptors
exec 3>&-
exec 4>&-

# Read arrays from temporary files
readarray -t array1 < "$tmpfile1"
readarray -t array2 < "$tmpfile2"

# Remove temporary files
rm "$tmpfile1" "$tmpfile2"

# Enable debugging for this section
set -x

# Access the arrays
echo "Array 1: ${array1[@]}"
echo "Array 2: ${array2[@]}"

# Disable debugging
set +x

