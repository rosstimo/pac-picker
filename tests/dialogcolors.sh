#!/bin/bash

# Set background color to blue using ANSI escape codes
echo -e "\033[44m"

# Display a dialog box with custom text colors
dialog --colors --title "\Zb\Z1Custom Interface" --msgbox "This dialog box has a \Zb\Z1blue background\Zn\Z0.\n\n\
You can also customize \Zb\Z2text colors\Zn\Z0 within the dialog box." 10 50

# Reset background color
echo -e "\033[0m"

