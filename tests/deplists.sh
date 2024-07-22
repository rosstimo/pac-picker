#!/bin/bash

# function to show command output in a programbox
show_output() {
  local command=$1
  local message=$2
  local timeout=$3
  if [[ -z "$timeout" ]]; then
    timeout=0
  fi
  dialog --timeout $timeout --programbox "$message"  32 64 < <(
    $command
  )
}

# display a message in a dialog box for n seconds
show_message() {
  local message=$1
  local timeout=$2
  local title=$3
  local backtitle=$4
  if [[ -z "$timeout" ]]; then
    timeout=0
  fi
  dialog  --timeout $timeout --title "$title" --backtitle "$backtitle" --msgbox "$message"  32 64
}

# attempt to get package information using the package package manager
get_package_info() {
  local package=$1
  local package_manager=$2
  local info=$($package_manager -Si $package 2>&1)
  if [[ -z "$info" ]] || echo "$info" | grep -q '^error:'; then
    return 1
  else
    echo $info
    return 0
  fi
}

# extract the optional dependencies
# return the optional dependencies in array format
get_optdeps() {
  local package=$1
  local package_manager=$2
  local optdeps=$($package_manager -Si "$package" | sed -n '/^Optional Deps/,/^Conflicts With/p' | sed '$d')
        optdeps=$(echo "$optdeps" | sed 's/^Optional Deps *: //')
  echo $optdeps
}

extract_optdeps() {
  local package_info=$1
  local optdeps=$(echo $package_info | sed -n '/^Optional Deps/,/^Conflicts With/p' | sed '$d')
        optdeps=$(echo "$optdeps" | sed 's/^Optional Deps *: //')
        # store the optional dependencies in optdeps_array
        echo "$optdeps" | while read -r line; do
          # Extract the package name and description.
          local package_name=$(echo "$line" | cut -d':' -f1)
          local description=$(echo "$line" | cut -d':' -f2-)
          # add the package_name to the optdeps_array and description to descriptions_array
          echo $package_name
          # $optdep_names+=($package_name)
          echo $description
          # $optdep_descriptions+=($description)
        done
  # echo $optdeps_array, $descriptions_arrayd
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

# Function: get_optional_deps
# Purpose: Retrieves optional dependencies of a given package and checks their installation status.
# Arguments:
#   $1 - The name of the package to check.
# Returns:
#   A list of optional dependencies with their descriptions and installation status.
get_optional_deps() {
    local package=$1
    local package_manager=$2
    local opt_deps=$($package_manager -Si "$package" | sed -n '/^Optional Deps/,/^Conflicts With/p' | sed '$d')
    # local package_info=$1
    # local opt_deps=$(echo $package_info | sed -n '/^Optional Deps/,/^Conflicts With/p' | sed '$d')
    # local package=$1
    # Extract optional dependencies from pacman information.
    # local opt_deps=$(pacman -Si "$package" | sed -n '/^Optional Deps/,/^Conflicts With/p' | sed '$d')
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
    choices=$(dialog --separate-output --checklist "Select optional dependencies to install:" 32 64 10 "${dialog_items[@]}" 2>&1 >/dev/tty)
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

main() {
#   echo "call get_optdeps"
#   optional_deps=$(get_optional_deps "$package")
#
#
# # call get_optdeps with package vlc and suppress direct output and capture the result in a variable
#   local optdeps=$(get_optdeps vlc)
#   # echo $optdeps
#   # convert the string to an array
#   local optdeps_array=($optdeps)
#   echo "iterate over the array and print each element"
#   # iterate over the array and print each element
#   for optdep in "${optdeps_array[@]}"; do
#     echo $optdep
#   done
#   echo "done"

  # show_output "$package_manager -Si $package" "Retrieving Package Information" 1
  # get_package_info "$package"
  # local package_info=$(get_package_info "$package")
  # local package_info=$(get_optdeps "$package") 
  # echo $package_info

  # Call the get_optional_deps function with the package name as an argument.
  local package="vlc"
  local package_manager="pacman"
  local timeout=2

  # run get_package_info. if returnvalue is 1, show_message "not found" then exit
  # if returnvalue is 0, show_output, show_message "package found" and store package_info in a variable
  if ! get_package_info "$package" "$package_manager"; then
    show_message "Package not found" 1
    exit 1
  fi
  
  show_message "Package found" $timeout

  local package_info=$(get_package_info "$package" "$package_manager")
  show_message "$package_info" $timeout 

  local optional_deps=$(get_optional_deps "$package" "$package_manager")
  show_message "$optional_deps" $timeout

  local selections=$(get_selections "$optional_deps")
  show_message "$selections" 0 "Selections"

  local selected_items=$(echo "$selections" | grep "Selected items:" | cut -d':' -f2)
  show_message "$selected_items" $timeout "Selected items"

  local not_selected_items=$(echo "$selections" | grep "Not selected items:" | cut -d':' -f2)
  show_message "$not_selected_items" $timeout "Not selected items"

  # Filter packages to install and remove
  for item in $selected_items; do
    if ! is_installed "$item"; then
      install_list+="$item "
    fi
  done
  show_message "$install_list" $timeout "Install List"

  for item in $not_selected_items; do
    if is_installed "$item"; then
      remove_list+="$item "
    fi
  done 
  show_message "$remove_list" $timeout "Remove List"

}

main "$@"
