#!/bin/bash
#
#                                 _       _
#     /\                         (_)     | |
#    /  \   _ __ ___   ___  _ __  _  ___ | |_
#   / /\ \ | '_ ` _ \ / _ \| '_ \| |/ _ \| __|
#  / ____ \| | | | | | (_) | | | | | (_) | |_
# /_/    \_\_| |_| |_|\___/|_| |_| |\___/ \__|
#                               _/ |
#                              |__/
# 19/01/2024
#
BEFORE=$SECONDS
# Install dependencies
## test conda installation and install it if necessary
if [ $(which conda activate | grep "/activate" | wc -l) -eq 0 ]
then
    mkdir -p ~/miniconda3
    if [ $(uname -a | grep "Darwin" | grep "x86_64" | wc -l) -gt 0 ]
    then
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -O ~/miniconda3/miniconda.sh
    elif [ $(uname -a | grep "Darwin" | grep "ARM64" | wc -l) -gt 0 ]
    then
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh -O ~/miniconda3/miniconda.sh
    elif [ $(uname -a | grep "Linux" | grep "x86_64" | wc -l) -gt 0 ]
    then
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
    fi
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm -rf ~/miniconda3/miniconda.sh
fi
#
## Initialization file 
ELAPSED=$((($SECONDS-$BEFORE)/60))
echo "Installation of miniconda is completed and takes $ELAPSED minutes"
