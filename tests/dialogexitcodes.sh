#!/bin/bash

# Display an input box with custom buttons and handle various exit codes
dialog --ok-label "Submit" --cancel-label "Abort" --extra-button --extra-label "More Info" --help-button --help-label "Help" --inputbox "Please enter your name:" 40 40 2>name.txt
response=$?

case $response in
    0)
        name=$(<name.txt)
        echo "User entered: $name"
        ;;
    1)
        echo "User canceled."
        ;;
    2)
        echo "User aborted."
        ;;
    3)
        echo "User requested help."
        ;;
    4)
        echo "User selected 'More Info'."
        ;;
    255)
        echo "User pressed ESC."
        ;;
    *)
        echo "Unexpected exit code: $response"
        ;;
esac

