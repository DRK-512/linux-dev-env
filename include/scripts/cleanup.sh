#!/bin/sh
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "This script was made just run all the apt update upgrade cleanup command to ensure my system is running the latest apt packages"
    echo ""
    echo "Usage: $0"
    echo "-h, --help    Display this help message"
    exit 0
fi


sudo apt update -y
sudo apt upgrade -y 
sudo apt dist-upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y 
