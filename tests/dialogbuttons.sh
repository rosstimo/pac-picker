#!/bin/bash

dialog --ok-label "Next" --msgbox "Welcome to the setup wizard" 10 30
echo $?
dialog --ok-label "Submit" --cancel-label "Abort" --inputbox "Please enter your username:" 10 30 2>username.txt
echo $?
response=$?
if [ $response -ne 0 ]; then
    echo "Setup aborted."
    exit 1
fi

username=$(<username.txt)
echo "Username: $username"

dialog --ok-label "Proceed" --cancel-label "Exit" --yesno "Do you want to continue?" 10 30
echo $?
response=$?
if [ $response -eq 0 ]; then
    echo "User chose to continue."
else
    echo "User exited."
    exit 1
fi

dialog --ok-label "Finish" --msgbox "Setup completed successfully!" 10 30
echo $?
