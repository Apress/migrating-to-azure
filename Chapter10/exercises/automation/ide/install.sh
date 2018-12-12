#!/bin/bash

# Set up repos based on ide selected
# as well as OS, since it does matter

if [ "$1" = "brew" ]; then
    $1 cask $2 $3
else
    $1 $2 $3
fi