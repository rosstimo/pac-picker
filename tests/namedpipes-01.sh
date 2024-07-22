#!/bin/bash

# Ensure the script runs in bash
if [ -z "$BASH_VERSION" ]; then
    echo "This script requires bash." >&2
    exit 1
fi

# Function to return two arrays using named pipes
return_arrays() {
    local array1=("apple" "banana" "cherry")
    local array2=("dog" "elephant" "frog")
    echo "Inside return_arrays function."
    echo "Writing to file descriptor 3..."
    echo "${array1[@]}" >&3
    echo "Writing to file descriptor 4..."
    echo "${array2[@]}" >&4
    echo "Finished writing to file descriptors in return_arrays."
}

# Create named pipes (FIFOs)
fifo1=$(mktemp -u)
fifo2=$(mktemp -u)
mkfifo "$fifo1"
mkfifo "$fifo2"
echo "Named pipes created: $fifo1, $fifo2"

# Open file descriptors for capturing the arrays using named pipes
exec 3> "$fifo1"
exec 4> "$fifo2"
echo "File descriptors opened."

# Read the arrays in the background using subshells
(
    echo "Reading from fifo1..."
    readarray -t array1 < "$fifo1"
    echo "Finished reading from fifo1: ${array1[@]}"
) &
pid1=$!

(
    echo "Reading from fifo2..."
    readarray -t array2 < "$fifo2"
    echo "Finished reading from fifo2: ${array2[@]}"
) &
pid2=$!

# Call the function in a subshell to ensure it doesn't block the main shell
(
    echo "Calling return_arrays function..."
    return_arrays
    echo "return_arrays function completed."
) &
pid3=$!

# Wait for all background processes to complete
echo "Waiting for background processes to complete..."
wait $pid1
wait $pid2
wait $pid3
echo "All background processes completed."

# Close file descriptors
exec 3>&-
exec 4>&-
echo "File descriptors closed."

# Remove named pipes
rm "$fifo1" "$fifo2"
echo "Named pipes removed."

# Access the arrays
echo "Array 1: ${array1[@]}"
echo "Array 2: ${array2[@]}"


