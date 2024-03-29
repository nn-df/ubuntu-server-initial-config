#!/bin/bash
set -euo pipefail

VER=$(lsb_release -rs)
DATE=$(date)

check_version() {
	if [ $VER = "16.04" ];then
		echo "[+] Ubuntu version #{$VER} detected"
	elif [ $VER = "18.04" ];then
		echo "[+] Ubuntu version #{$VER} detected"
	elif [ $VER = "20.04" ];then
		echo "[+] Ubuntu version #{$VER} detected"
	elif [ $VER = "22.04" ];then
		echo "[+] Ubuntu version #{$VER} detected"
	else
		echo "[!] Your ubuntu version is #{$VER} not supported"
		exit 1
	fi
}

update_repo() {
	apt update
}

upgrade_repo() {
	apt upgrade -y
}

autoremove_repo() {
	apt autoremove -y
}

install_service() {
	apt -yq install $1
}

check_dependency() {
	# check root
	if [[ $EUID -ne 0 ]]; then
	   echo "[!] This script must be run as root" 
	   exit 1
	fi

	# check network status (internet and dns)
	if ping -q -c 3 -W 1 www.google.com > /dev/null 2>&1;then
		echo "[+] Checking network OK"
	else 
		if ping -q -c 3 -W 1 8.8.8.8 > /dev/null 2>&1;then
			echo "[!] Check your DNS setting"
			exit $?
		else
			echo "[!] Check your NETWORK setting"
			exit $?
		fi
	fi

	# check whiptail
	if which whiptail > /dev/null 2>&1; then
		echo "[+] Checking whiptail OK"
		:
	else
		install_service whiptail
	fi
	
}



display_ascii() {
		echo -e '
		 m    m #                      m            mmmm                                    
		 #    # #mmm   m   m  m mm   mm#mm  m   m  #"   "  mmm    m mm  m   m   mmm    m mm 
		 #    # #" "#  #   #  #"  #    #    #   #  "#mmm  #"  #   #"  " "m m"  #"  #   #"  "
		 #    # #   #  #   #  #   #    #    #   #      "# #""""   #      #m#   #""""   #    
		 "mmmm" ##m#"  "mm"#  #   #    "mm  "mm"#  "mmm#" "#mm"   #       #    "#mm"   #    
		 
		 mmmmm           "      m      "           ""#      mmm                  m""    "          
		   #    m mm   mmm    mm#mm  mmm     mmm     #    m"   "  mmm   m mm   mm#mm  mmm     mmmm 
		   #    #"  #    #      #      #    "   #    #    #      #" "#  #"  #    #      #    #" "# 
		   #    #   #    #      #      #    m"""#    #    #      #   #  #   #    #      #    #   # 
		 mm#mm  #   #  mm#mm    "mm  mm#mm  "mm"#    "mm   "mmm" "#m#"  #   #    #    mm#mm  "#m"# 
		                                                                                      m  # 
		                                                                                       ""                                                 
		'
		sleep 3
}

dis_ipv6() {
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
	elif [ $VER = "20.04" ];then
		# ubuntu 20 disable
		sed -i -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' /etc/default/grub
        update-grub
	elif [ $VER = "22.04" ];then
		# ubuntu 22 disable
		sed -i -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' /etc/default/grub
        update-grub
		install_service net-tools
	else
		echo "[!] Your ubuntu version is #{$VER} not supported"
		exit 1
	fi
}

get_confirmation_ipv6_disable() {
	if (whiptail --title "Ipv6" --yesno "This script will disable ipv6. Do you agree?" 8 78)
		then
			echo "[+] Disable ipv6..."
			dis_ipv6
		else
			:
	fi
}

enable_ufw() {
	install_service ufw
	echo "[+] Configure ufw..."
	ufw allow 22
	ufw --force enable
	echo "[++] To allow other port please used command : ufw allow [PORT] "
	echo "[++] Example allow port 80 : ufw allow 80"
	echo " "
	sleep 5
}

ufw_support() {
	if (whiptail --title "Firewall" --yesno "Enable firewall (ufw) on this server ?" 8 78)
		then
			echo "[+] Enable UFW..."
			enable_ufw
		else
			:
	fi	
}

reconfig_date() {
	if (whiptail --title "Date" --yesno "The date now is #{$DATE} it is correct?" 8 78)
		then
			:
		else
			echo "[+] Reconfigure date..."
			dpkg-reconfigure tzdata
	fi
}

cmd_reboot() {
	whiptail --title "Reboting..." --msgbox "This server will reboot in 5 seconds" 8 78
	sleep 5
	reboot

}

main() {
	# display main
	display_ascii

	# check ubuntu version
	check_version

	# check run script
	check_dependency

	# get confirmation disable ipv6
	get_confirmation_ipv6_disable

	#configure ufw
	ufw_support

	# reconfigure date
	reconfig_date

	# update repo
	update_repo

	# upgrade repo
	upgrade_repo

	# clean_up repo
	autoremove_repo

	# reboot server
	cmd_reboot
}

main
