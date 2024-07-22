#!/bin/bash
# Safety measures to ensure the script exits on errors, uses unset variables, or pipeline failures.
# set -o errexit  # Exit immediately if a command exits with a non-zero status.
# set -o nounset  # Treat unset variables as an error and exit immediately.
# set -o pipefail # Return the exit status of the last command in the pipeline that failed.


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

# Check if a given package is installed using pacman.
is_installed() {
    local package=$1
    if pacman -Q "$package" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# check if yay is installed
is_yay_installed() {
    if command -v yay &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# user selected package manager (yay or pacman).
select_package_manager() {
    local choice=$(dialog --title "Select Package Manager" --no-cancel --menu "yay is installed. Select package manager to use:" 32 64 2 \
        1 "pacman" \
        2 "yay" 2>&1 >/dev/tty)
    if [ "$choice" -eq 2 ]; then
        echo "yay"
    else
        echo "pacman"
    fi
    #if cancel exit
    # if [ $? -eq 1 ]; then
    #   clear
    #   exit 1
    # fi
}

# Checks if a given package is valid and installable with the selected package manager.
is_package_valid() {
    local package_manager=$1
    local package=$2
    local output
    output=$("$package_manager" -Si "$package" 2>&1)
    if [[ -z "$output" ]] || echo "$output" | grep -q '^error:'; then
        return 1
    else
        return 0
    fi
}

# choose between all, no change, custom
get_selection_choice() {
  local choice=$(dialog --title "Select Optional Dependency Installation" --no-cancel --menu "Select how to install optional  dependencies:" 32 64 3 \
        1 "Install All" \
        2 "No Change" \
        3 "Custom" 2>&1 >/dev/tty)
    echo $choice
}

# Returns a list of all optional dependencies of a package.
select_all_optional_deps() {
    local optional_deps="$1"
    local selected_items=()
    local not_selected_items=()
    IFS=$'\n'
    for line in $optional_deps; do
        package_name=$(echo "$line" | cut -d':' -f1)
        selected_items+=("$package_name")
    done
    echo "Selected items: ${selected_items[@]}"
    echo "Not selected items: ${not_selected_items[@]}"  # Always empty
    IFS=$' \t\n'
}
# Returns a list of optional dependencies with their descriptions and installation status.
# TODO: might be fun to run this recursivly to get all optional dependencies of all optional dependencies
# TODO: may want to include a max depth argument to limit recursion
# TODO: may want to somehow determine any either/or dependencies and prompt user to select one for each case
get_optional_deps() {
    local package=$1
    local package_manager=$2
    local opt_deps=$($package_manager -Si "$package" | sed -n '/^Optional Deps/,/^Conflicts With/p' | sed '$d')

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

get_selections() {
    local optional_deps="$1"
    local dialog_items=()
    IFS=$'\n'
    for line in $optional_deps; do
        package_name=$(echo "$line" | cut -d':' -f1)
        description=$(echo "$line" | cut -d':' -f2)
        installed=$(echo "$line" | cut -d':' -f3)
        if [ "$installed" -eq 1 ]; then
            dialog_items+=("$package_name" "$description" "on")
        else
            dialog_items+=("$package_name" "$description" "off")
        fi
    done
    choices=$(dialog --separate-output --no-cancel --checklist "Select optional dependencies to install:" 32 64 10 "${dialog_items[@]}" 2>&1 >/dev/tty)
    local selected_items=()
    local not_selected_items=()
    IFS=$'\n' read -d '' -r -a selected_items <<< "$choices"
    for line in $optional_deps; do
        package_name=$(echo "$line" | cut -d':' -f1)
        if ! [[ " ${selected_items[@]} " =~ " ${package_name} " ]]; then
            not_selected_items+=("$package_name")
        fi
    done
    echo "Selected items: ${selected_items[@]}"
    echo "Not selected items: ${not_selected_items[@]}"
    IFS=$' \t\n'
}

# Returns a list of packages selected to install.
get_install_list () {
  local selections="$1"
  local selected_items=$(echo "$selections" | grep "Selected items:" | cut -d':' -f2)
    for item in $selected_items; do
    if ! is_installed "$item"; then
      install_list+="$item "
    fi
  done
  echo $install_list
}

# Returns a list of packages selected to remove.
get_uninstall_list() {
  local selections="$1"
  local not_selected_items=$(echo "$selections" | grep "Not selected items:" | cut -d':' -f2)
  for item in $not_selected_items; do
    if is_installed "$item"; then
      remove_list+="$item "
    fi
  done 
  echo $remove_list
}

# Shows a summary of the packages to install and remove.
show_summary() {
    local install_list="$1"
    local remove_list="$2"
    dialog --title "Summary" --msgbox "Packages to install:\n$install_list\n\nPackages to remove:\n$remove_list" 32 64
}

# Prompts the user to confirm the action.
confirm_action() {
    dialog --title "Confirm" --yesno "Do you want to proceed with the installation and removal of packages?" 32 64
    return $?
}
# Removes a list of packages.
# this won't remove anything needed by other packages
# TODO: may want to add choice for --noconfirm flag
remove_packages() {
  local remove_list="$1"
    sudo pacman -Rns $remove_list 
}

# --needed flag probably redundant now that we have the get_install_list function 
# but could be mor performent than bothering with get_install_list
# TODO: may want to add choice for --noconfirm flag
install_packages() {
  local install_list="$1"
  sudo pacman -S --needed $install_list
}

main() {

  # Call the get_optional_deps function with the package name as an argument.
  # local package="vlc" #to be replaced with user input 
  if [ $# -lt 1 ]; then
    echo "Usage: $0 <package_name>"
    return 1
  fi
  local package=${1:-}
  if [ -z "$package" ]; then
    echo "Error: Package name is required."
    return 1
  fi
  local timeout=2

  #check for yay. if installed prompt user to choose between yay and pacman
  #otherwise no prompt and use pacman
  local package_manager="pacman" #to be replaced with user choice
  if is_yay_installed; then
    package_manager=$(select_package_manager)
  fi

  #check if package is valid
  if ! is_package_valid $package_manager "$package"; then
    show_message "Package $package is not installable using $package_manager" 1
    exit 1
  # else
  #   show_message "Package $package is installable using $package_manager" 1
  fi

  #check if package exists
  # if ! get_package_info "$package" "$package_manager"; then
  #   show_message "Package $package not found useing $package_manager" 1
  #   exit 1
  # fi
  
  # show_message "Package found" $timeout
  #get package info
  local package_info=$(get_package_info "$package" "$package_manager")
  # show_message "$package_info" $timeout 
  
  #get optional dependencies
  local optional_deps=$(get_optional_deps "$package" "$package_manager")
  # show_message "$optional_deps" $timeout

  #prompt all, no change, custom
  #if all install all
  #if no change install primary package only
  #if custom, show optional dependencies and prompt user to select which to install
  #and deselect which to remove
  # local install_list=""
  # local uninstall_list=""
  
  local selections=$(select_all_optional_deps "$optional_deps")
  local selection_choice=$(get_selection_choice)
  # show_message "$selection_choice" 0 "Selection Choice"

  case $selection_choice in
    1)
      selections=$(select_all_optional_deps "$optional_deps")
      ;;
    2)
      selections="" #$(select_no_optional_deps "$optional_deps")
      ;;
    3)
      selections=$(get_selections "$optional_deps")
      ;;
  esac

  # show_message "$selections" 0 "Selections"
  # Filter packages to install and remove
  local install_list=$(get_install_list "$selections")
  local uninstall_list=$(get_uninstall_list "$selections") 
  # show_message "$install_list" 0 "Install List"
  # show_message "$uninstall_list" 0 "Remove List"
  

  #finalize install and remove lists
  #prompt user to review and confirm
clear
    # Show summary and confirm
    show_summary "$install_list" "$uninstall_list"
    if confirm_action; then
        # Perform installation and removal
        if [ -n "$uninstall_list" ]; then
          clear
          remove_packages "$uninstall_list"
        fi
        if [ -n "$install_list" ]; then
          clear
          install_packages "$package $install_list"
        fi
    else
        echo "Action canceled."
    fi
  # clear 
}

main "$@"

echo "Have a nice day!"
