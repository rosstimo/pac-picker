#!/bin/bash

# Define the checklist items with help text
ITEMS=(
    1 "Option 1" off "This is the description for Option 1."
    2 "Option 2" on "This is the description for Option 2."
    3 "Option 3" off "This is the description for Option 3."
    4 "Option 4" off "This is the description for Option 4."
)

# Function to show the checklist
show_checklist() {
    dialog --title "Checklist with Descriptions" --checklist "Select options:" 20 60 10 \
        "${ITEMS[@]}" 2>selections.txt

    response=$?
    if [ $response -eq 0 ]; then
        selections=$(<selections.txt)
        echo "You selected: $selections"
    else
        echo "User canceled."
    fi
}

# Function to show descriptions
show_description() {
    local choice=$1
    for ((i=0; i<${#ITEMS[@]}; i+=4)); do
        if [ "${ITEMS[i]}" == "$choice" ]; then
            dialog --msgbox "${ITEMS[i+3]}" 10 60
            break
        fi
    done
}

# Main loop
while true; do
    show_checklist
    selections=$(<selections.txt)

    if [ -z "$selections" ]; then
        echo "User canceled."
        break
    fi

    # Iterate through selections and show descriptions
    for selection in $selections; do
        show_description "$selection"
    done

    dialog --yesno "Do you want to continue?" 10 30
    response=$?
    if [ $response -ne 0 ]; then
        break
    fi
done

# Clean up
rm -f selections.txt

