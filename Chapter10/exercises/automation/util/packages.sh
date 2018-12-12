#!/bin/bash
if [ "$1" = "brew" ]; then
    $1 cask $2 dotnet dotnet-sdk powershell
    $1 $2 git
else
    $1 $2 git dotnet-sdk-2.1 powershell
fi