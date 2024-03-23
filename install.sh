#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# Check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error:${plain} This script must be run as root!\n" && exit 1

# Check OS
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}Unable to detect the OS version, please contact the script author!${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="amd64"
    echo -e "${red}Failed to detect architecture, using default architecture: ${arch}${plain}"
fi

echo "Architecture: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ]; then
    echo "This software does not support 32-bit systems (x86), please use 64-bit systems (x86_64), if detected incorrectly, please contact the author"
    exit -1
fi

os_version=""

# OS version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Please use CentOS 7 or higher!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Please use Ubuntu 16 or higher!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Please use Debian 8 or higher!${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

# This function will be called when the user installed x-ui out of security
config_after_install() {
    echo -e "${yellow}For security reasons, after installation/update, it is necessary to forcibly modify the port and account password${plain}"
    read -p "Confirm to continue? [y/n]: " config_confirm
    if [[ x"${config_confirm}" == x"y" || x"${config_confirm}" == x"Y" ]]; then
        read -p "Please set your username:" config_account
        echo -e "${yellow}Your username will be set to: ${config_account}${plain}"
        read -p "Please set your account password:" config_password
        echo -e "${yellow}Your account password will be set to: ${config_password}${plain}"
        read -p "Please set the panel access port:" config_port
        echo -e "${yellow}Your panel access port will be set to: ${config_port}${plain}"
        echo -e "${yellow}Confirm settings, setting up${plain}"
        /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password}
        echo -e "${yellow}Account password set completed${plain}"
        /usr/local/x-ui/x-ui setting -port ${config_port}
        echo -e "${yellow}Panel port set completed${plain}"
    else
        echo -e "${red}Cancelled, all settings are default settings, please modify them in time${plain}"
    fi
}

install_x-ui() {
    systemctl stop x-ui
    cd /usr/local/

    if [ $# == 0 ]; then
        last_version=$(curl -Ls "https://api.github.com/repos/hojat-gazestani/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}Failed to detect x-ui version, may exceed Github API limit, please try again later or manually specify x-ui version to install${plain}"
            exit 1
        fi
        echo -e "Detected x-ui latest version: ${last_version}, start installation"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/hojat-gazestani/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Download x-ui failed, please make sure your server can download files from Github${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/hojat-gazestani/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
        echo -e "Start installing x-ui v$1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Download x-ui v$1 failed, please make sure this version exists${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/hojat-gazestani/x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install
    #echo -e "If it is a fresh installation, the default web port is ${green}54321${plain}, and the username and password are both ${green}admin${plain}"
    #echo -e "Please ensure that this port is not occupied by other programs, ${yellow}and ensure that port 54321 is open${plain}"
    #    echo -e "If you want to change 54321 to another port, enter the x-ui command to modify it, and make sure that the port you modify is also open"
    #echo -e ""
    #echo -e "If it is an update panel, access the panel in the same way as before"
    #echo -e ""
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui v${last_version}${plain} installation completed, panel started,"
    echo -e ""
    echo -e "x-ui management script usage: "
    echo -e "----------------------------------------------"
    echo -e "x-ui              - Display management menu (more functions)"
    echo -e "x-ui start        - Start x-ui panel"
    echo -e "x-ui stop         - Stop x-ui panel"
    echo -e "x-ui restart      - Restart x-ui panel"
    echo -e "x-ui status       - Check x-ui status"
    echo -e "x-ui enable       - Set x-ui to start automatically"
    echo -e "x-ui disable      - Disable x-ui from starting automatically"
    echo -e "x-ui log          - View x-ui log"
    echo -e "x-ui v2-ui        - Migrate v2-ui account data on this machine to x-ui"
    echo -e "x-ui update       - Update x-ui panel"
    echo -e "x-ui install      - Install x-ui panel"
    echo -e "x-ui uninstall    - Uninstall x-ui panel"
    echo -e "----------------------------------------------"
}

echo -e "${green}Start installation${plain}"
install_base
install_x-ui $1
