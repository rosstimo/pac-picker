#!/bin/bash

# Welcome Message with ASCII Art and Colors
dialog --colors --backtitle "My Application" --title "\Zb\Z1Welcome" --msgbox "Welcome to \Zb\Z2My Application\Zn\Z0!\n\n\
  \Zb\Z3.-.\Zn\n\
 / \Zb\Z4_.-' \Zn\n\
 \\ \Zb\Z5'-.\Zn\n\
  \Zb\Z6'--\Zn" 15 50

# User Input
dialog --colors --title "\Zb\Z2User Input" --inputbox "Please enter your name:" 10 50 2>name.txt
response=$?
if [ $response -eq 0 ]; then
    name=$(<name.txt)
    # Displaying User Input with a Colorful Message
    dialog --colors --title "\Zb\Z1Welcome" --msgbox "\Zb\Z2Hello, $name!\Zn\Z0\n\nWelcome to the application." 10 50
else
    dialog --colors --title "\Zb\Z1Abort" --msgbox "\Zb\Z3User canceled.\Zn\Z0" 10 30
    exit 1
fi

# User Opinion on ASCII Art
dialog --colors --title "\Zb\Z2Your Opinion" --inputbox "What do you think about the ASCII art?" 10 50 2>opinion.txt
response=$?
if [ $response -eq 0 ]; then
    opinion=$(<opinion.txt)
    # Thanking User for their Opinion
    dialog --colors --title "\Zb\Z1Thank You" --msgbox "Thank you for your opinion: \Zb\Z4$opinion\Zn\Z0" 10 50
else
    dialog --colors --title "\Zb\Z1Abort" --msgbox "\Zb\Z3User canceled.\Zn\Z0" 10 30
    exit 1
fi

# Final Message with Colors and ASCII Art
dialog --colors --title "\Zb\Z1Goodbye" --msgbox "Thank you for using \Zb\Z2My Application\Zn\Z0!\n\n\
  \Zb\Z3.-.\Zn\n\
 / \Zb\Z4_.-' \Zn\n\
 \\ \Zb\Z5'-.\Zn\n\
  \Zb\Z6'--\Zn\n\n\
Have a great day!" 15 50

