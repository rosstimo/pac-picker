#!/bin/sh

# this function determines what if any AUR helper  is installed then returns a list of AUR helpers found
# if no AUR helper is found it returns a list of AUR helpers that are available to install
get_aur_helper() {
    local aur_helpers=("yay" "paru" "trizen" "pikaur" "aurman" "aura" "pacaur" "bauerbill" "cower" "pacaur" "pamac-aur" "yay-bin" "paru-bin" "trizen-git" "pikaur-git" "aurman-git" "aura-git" "bauerbill-git" "cower-git" "pacaur-git" "pamac-aur-git")
    local aur_helpers_installed=()
    local aur_helpers_available=()
    for aur_helper in "${aur_helpers[@]}"; do
        if pacman -Qs "$aur_helper" &>/dev/null; then
            aur_helpers_installed+=("$aur_helper")
        else
            aur_helpers_available+=("$aur_helper")
        fi
    done
    #return the list of installed AUR helpers if any are found or exit 1 if no AUR helpers are found
    if [ ${#aur_helpers_installed[@]} -gt 0 ]; then
        echo "Installed AUR helpers: ${aur_helpers_installed[@]}"
    else
        echo "No AUR helpers found"
        echo "Available AUR helpers: ${aur_helpers_available[@]}"
        exit 1
    fi
}

#tests for above function
#run get_aur_helper function and print the return value from the function

# get_aur_helper

#a function to ceck if yay AUR helper is installed. yes exit 0, no exit 1
check_yay() {
    if pacman -Qs "yay" &>/dev/null; then
        echo "yay is installed"
        exit 0
    else
        echo "yay is not installed"
        exit 1
    fi
}
