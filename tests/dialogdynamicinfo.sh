#!/bin/bash

# Enable item help
DIALOGRC="$(mktemp)"
echo 'use_shadow = no
use_colors = yes
screen_color = (CYAN,BLUE,ON)
title_color = (YELLOW,RED,OFF)
dialog_color = (BLACK,WHITE,OFF)
border_color = (YELLOW,RED,OFF)
button_active_color = (WHITE,RED,ON)
button_inactive_color = (WHITE,BLUE,ON)
item_help = ON' > "$DIALOGRC"
export DIALOGRC

# Define the checklist items with help text
ITEMS=(
    1 "Option 1" off "This is the description for Option 1."
    2 "Option 2" on "This is the description for Option 2."
    3 "Option 3" off "This is the description for Option 3."
    4 "Option 4" off "This is the description for Option 4."
)

# Create the checklist with item help
dialog --title "Checklist with Descriptions" --checklist "Select options (highlight to see descriptions):" 20 60 10 \
"${ITEMS[@]}" 2>selections.txt

# response=$?
# if [ $response -eq 0 ]; then
#     selections=$(<selections.txt)
#     echo "You selected: $selections"
# else
#     echo "User canceled."
# fi
#
# # Clean up
# rm "$DIALOGRC"
#
