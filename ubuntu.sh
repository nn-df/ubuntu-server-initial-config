#!/bin/bash
set -e

VER=$(lsb_release -rs)

check-root() {
	if [[ $EUID -ne 0 ]]; then
	   echo "This script must be run as root" 
	   exit 1
	fi
}

get-confirmation() {
	if (whiptail --title "Warning" --yesno "This script will disable ipv6. Do you agree?" 8 78); then
		:
		else
			echo "No. The installer will exit"
			exit 1
	fi
}

update-repo() {
	apt update
}

upgrade-repo() {
	apt upgrade -y
}

autoremove-repo() {
	apt autoremove -y
}

dis-ipv6() {
	if [ $VER = "16.04" ];then
		# ubuntu 16 disable
		echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
		echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
		echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
		sysctl -p
	elif [ $VER = "18.04" ];then
		# ubuntu 18 disable
		sed -i -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' /etc/default/grub
		sudo update-grub
	else
		echo "not found"
	fi
}

main() {
	check-root
	get-confirmation
	dis-ipv6
	update-repo
	upgrade-repo
	autoremove-repo
	reboot	
}

main
