#!/bin/bash

function show_menu() {
    local items_string="$1"
    IFS=';' read -r -a items <<< "$items_string"
    
    local dialog_items=()
    for item in "${items[@]}"; do
        IFS=': ' read -r name description status <<< "$item"
        if [[ "$status" -eq 1 ]]; then
            dialog_items+=("$name" "$description" "on")
        else
            dialog_items+=("$name" "$description" "off")
        fi
    done

    local choices
    choices=$(dialog --checklist "Select items:" 15 50 10 "${dialog_items[@]}" 2>&1 >/dev/tty)

    local exit_status=$?
    clear

    if [[ $exit_status -eq 0 ]]; then
        echo "Selected items:"
        for choice in $choices; do
            echo "- $choice"
        done
    else
        echo "Cancelled"
        exit 1
    fi
}

# Test cases with random data
item_5="item0: Description 0: 1; item1: Description 1: 1; item2: Description 2: 0; item3: Description 3: 1; item4: Description 4: 1"
item_10="item0: Description 0: 0; item1: Description 1: 1; item2: Description 2: 0; item3: Description 3: 1; item4: Description 4: 0; item5: Description 5: 0; item6: Description 6: 1; item7: Description 7: 0; item8: Description 8: 0; item9: Description 9: 1"
item_17="item0: Description 0: 1; item1: Description 1: 1; item2: Description 2: 0; item3: Description 3: 1; item4: Description 4: 0; item5: Description 5: 0; item6: Description 6: 0; item7: Description 7: 1; item8: Description 8: 1; item9: Description 9: 1; item10: Description 10: 0; item11: Description 11: 0; item12: Description 12: 1; item13: Description 13: 0; item14: Description 14: 0; item15: Description 15: 1; item16: Description 16: 1"

# Run tests
echo "Running test with 5 items:"
show_menu "$item_5"

echo "Running test with 10 items:"
show_menu "$item_10"

echo "Running test with 17 items:"
show_menu "$item_17"
