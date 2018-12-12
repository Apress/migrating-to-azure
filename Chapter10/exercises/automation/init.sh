#!/bin/bash

install_brew {
    echo 'Homebrew not found! Installing.'
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

update_brew {
    echo "Homebrew installed. Updating."
    brew update && brew upgrade
    brew cleanup
}

set_packagemanager {
    # Figure out what OS is being used and either update or install
OSVer=$(uname)
if [ "$OSVer" = "Darwin" ]; then 
    BREW=true
    brew -v >/dev/null 2>&1 || BREW=false
    if [ "$BREW" = "true" ];then
        update_brew
    else
        install_brew
        update_brew
    fi
    PKGMGR=brew
    PKGINSTALL=install
fi

if [ "$OSVer" = "Linux" ]; then
    YUM=true;APTGET=true;RPM=true;APK=true
    PKGINSTALL="install -y"
    which yum >/dev/null 2>&1 || YUM=false
    which apt-get >/dev/null 2>&1 || APTGET=false
    which rpm >/dev/null 2>&1 || RPM=false
    which apk >/dev/null 2>&1 || APK=false
    if [ "$YUM" = "true" ]; then
    PKGMGR="yum"
    sudo rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
    elif [ "$APTGET" = "true" ]; then
    PKGMGR="apt-get"
    wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    elif [ "$RPM" = "true" ]; then
    PKGMGR="rpm"
    elif [ "$APK" = "true" ];then
    PKGMGR="apk"
    PKGINSTALL="add -y --no-cache"
    fi

    $PKGMGR update
    EXPORT PKGMGR="$PKGMGR"
    EXPORT PKGINSTALL="$PKGINSTALL"
fi
}

IDE=vscode    # Values: vs, vscode, sublime
SCRIPTING=sh  # Values: sh, ps
test -z $1 || IDE=$1
test -z $2 || SCRIPTING=$2
echo "IDE selected: $IDE"
echo "Scripting language selected: $SCRIPTING"
set_packagemanager

echo "Installing packages..."
./util/packages.sh
echo "Installing IDE: $1"
./ide/install.sh $PKGMGR $PKGINSTALL $IDE
echo "Installing custom utilities..."
./custom/custom.sh
echo "Done."