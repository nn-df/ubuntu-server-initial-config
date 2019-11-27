#!/bin/bash
set -euo pipefail

VER=$(lsb_release -rs)
DATE=$(date)

check-root() {
	if [[ $EUID -ne 0 ]]; then
	   echo "[-] This script must be run as root" 
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

get-confirmation() {
	if (whiptail --title "Warning" --yesno "This script will disable ipv6. Do you agree?" 8 78)
		then
			:
		else
			echo "[-] No. The installer will exit"
			exit 1
	fi
}

reconfig-date() {
	if (whiptail --title "Date" --yesno "The date now is #{$DATE} it is correct?" 8 78)
		then
			:
		else
			echo "[+] Reconfigure date..."
			dpkg-reconfigure tzdata
	fi
}

cmd-reboot() {
	whiptail --title "Reboting..." --msgbox "This server will reboot in 5 seconds" 8 78
	sleep 5
	reboot

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
		update-grub
	else
		echo "[-] Your ubuntu version is #{$VER} not supported"
		exit 1
	fi
}

main() {
	# check run script
	check-root

	# get confirmation disable ipv6
	get-confirmation

	#reconfigure date
	reconfig-date

	#disable ipv6
	dis-ipv6

	# update repo
	update-repo

	# upgrade repo
	upgrade-repo

	# clean-up repo
	autoremove-repo

	# reboot server
	cmd-reboot
}

main
