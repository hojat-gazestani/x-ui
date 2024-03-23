#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error: ${plain} This script must be run as root!\n" && exit 1

# check OS
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

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [default $2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Do you want to restart the panel? Restarting the panel will also restart xray" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Press Enter to return to the main menu: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/hojat-gazestani/x-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    confirm "This function will forcefully reinstall the latest version without data loss. Do you want to continue?" "n"
    if [[ $? != 0 ]]; then
        echo -e "${red}Operation canceled.${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 0
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/hojat-gazestani/x-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        echo -e "${green}Update completed. The panel has been automatically restarted.${plain}"
        exit 0
    fi
}

uninstall() {
    confirm "Are you sure you want to uninstall the panel? Xray will also be uninstalled." "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop x-ui
    systemctl disable x-ui
    rm /etc/systemd/system/x-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/x-ui/ -rf
    rm /usr/local/x-ui/ -rf

    echo ""
    echo -e "Uninstallation successful. If you want to delete this script, run ${green}rm /usr/bin/x-ui -f${plain} after exiting the script."
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_user() {
    confirm "Are you sure you want to reset the username and password to 'admin'?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -username admin -password admin
    echo -e "Username and password have been reset to ${green}admin${plain}. Please restart the panel now."
    confirm_restart
}

reset_config() {
    confirm "Are you sure you want to reset all panel settings? Account data will not be lost, and the username and password will remain unchanged." "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "All panel settings have been reset to default values. Please restart the panel now and access it using the default ${green}54321${plain} port."
    confirm_restart
}

set_port() {
    echo && echo -n -e "Enter port number [1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        echo -e "${yellow}Operation canceled.${plain}"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "Port setting completed. Please restart the panel and access it using the new port ${green}${port}${plain}."
        confirm_restart
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}The panel is already running. No need to start again. To restart, please choose 'Restart'.${plain}"
    else
        systemctl start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}x-ui started successfully.${plain}"
        else
            echo -e "${red}Failed to start the panel. This may be because the startup time exceeded two seconds. Please check the log information later.${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        echo -e "${green}The panel is already stopped. No need to stop again.${plain}"
    else
        systemctl stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            echo -e "${green}x-ui and xray stopped successfully.${plain}"
        else
            echo -e "${red}Failed to stop the panel. This may be because the stop time exceeded two seconds. Please check the log information later.${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}x-ui and xray restarted successfully.${plain}"
    else
        echo -e "${red}Failed to restart the panel. This may be because the startup time exceeded two seconds. Please check the log information later.${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status x-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable x-ui
    if [[ $? == 0 ]]; then
        echo -e "${green}x-ui set to start on boot successfully.${plain}"
    else
        echo -e "${red}Failed to set x-ui to start on boot.${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable x-ui
    if [[ $? == 0 ]]; then
        echo -e "${green}x-ui disabled from starting on boot successfully.${plain}"
    else
        echo -e "${red}Failed to disable x-ui from starting on boot.${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u x-ui.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

migrate_v2_ui() {
    /usr/local/x-ui/x-ui v2-ui

    before_show_menu
}

install_bbr() {
    # temporary workaround for installing bbr
    bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
    echo ""
    before_show_menu
}

update_shell() {
    wget -O /usr/bin/x-ui -N --no-check-certificate https://github.com/hojat-gazestani/x-ui/raw/master/x-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Failed to download the script. Please check if your machine can connect to Github.${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/x-ui
        echo -e "${green}Script upgraded successfully. Please run the script again.${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
        return 2
    fi
    temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled x-ui)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}The panel is already installed. Please do not reinstall.${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}Please install the panel first.${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "Panel Status: ${green}Running${plain}"
            show_enable_status
            ;;
        1)
            echo -e "Panel Status: ${yellow}Not Running${plain}"
            show_enable_status
            ;;
        2)
            echo -e "Panel Status: ${red}Not Installed${plain}"
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Autostart: ${green}Yes${plain}"
    else
        echo -e "Autostart: ${red}No${plain}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    check_xray_status
    if [[ $? == 0 ]]; then
        echo -e "Xray Status: ${green}Running${plain}"
    else
        echo -e "Xray Status: ${red}Not Running${plain}"
    fi
}

show_usage() {
    echo "x-ui Management Script Usage: "
    echo "------------------------------------------"
    echo "x-ui              - Display management menu (more options)"
    echo "x-ui start        - Start x-ui panel"
    echo "x-ui stop         - Stop x-ui panel"
    echo "x-ui restart      - Restart x-ui panel"
    echo "x-ui status       - Check x-ui status"
    echo "x-ui enable       - Set x-ui to start on boot"
    echo "x-ui disable      - Disable x-ui from starting on boot"
    echo "x-ui log          - View x-ui logs"
    echo "x-ui v2-ui        - Migrate v2-ui account data to x-ui on this machine"
    echo "x-ui update       - Update x-ui panel"
    echo "x-ui install      - Install x-ui panel"
    echo "x-ui uninstall    - Uninstall x-ui panel"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}x-ui Panel Management Script${plain}
  ${green}0.${plain} Exit Script
————————————————
  ${green}1.${plain} Install x-ui
  ${green}2.${plain} Update x-ui
  ${green}3.${plain} Uninstall x-ui
————————————————
  ${green}4.${plain} Reset Username and Password
  ${green}5.${plain} Reset Panel Settings
  ${green}6.${plain} Set Panel Port
————————————————
  ${green}7.${plain} Start x-ui
  ${green}8.${plain} Stop x-ui
  ${green}9.${plain} Restart x-ui
 ${green}10.${plain} Check x-ui Status
 ${green}11.${plain} View x-ui Logs
————————————————
 ${green}12.${plain} Enable x-ui Autostart
 ${green}13.${plain} Disable x-ui Autostart
————————————————
 ${green}14.${plain} One-click Install bbr (Latest Kernel)
 "
    show_status
    echo && read -p "Enter your choice [0-14]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && reset_user
        ;;
        5) check_install && reset_config
        ;;
        6) check_install && set_port
        ;;
        7) check_install && start
        ;;
        8) check_install && stop
        ;;
        9) check_install && restart
        ;;
        10) check_install && status
        ;;
        11) check_install && show_log
        ;;
        12) check_install && enable
        ;;
        13) check_install && disable
        ;;
        14) install_bbr
        ;;
        *) echo -e "${red}Please enter a valid number [0-14]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "v2-ui") check_install 0 && migrate_v2_ui 0
        ;;
        "update") check_install 0 && update 0
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        *) show_usage
    esac
else
    show_menu
fi
