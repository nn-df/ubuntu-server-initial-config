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

display-ascii() {
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

update-repo() {
	apt update
}

upgrade-repo() {
	apt upgrade -y
}

autoremove-repo() {
	apt autoremove -y
}

install-service() {
	apt -yq install $1
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
	elif [ $VER = "20.04" ];then
		# ubuntu 20 disable
		sed -i -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' /etc/default/grub
                update-grub
	else
		echo "[-] Your ubuntu version is #{$VER} not supported"
		exit 1
	fi
}

get-confirmation() {
	if (whiptail --title "Ipv6" --yesno "This script will disable ipv6. Do you agree?" 8 78)
		then
			echo "[+] Disable ipv6..."
			dis-ipv6
		else
			:
	fi
}

enable-ufw() {
	install-service ufw
	echo "[+] Configure ufw..."
	ufw allow 22
	ufw --force enable
	echo "[++] To allow other port please used command : ufw allow [PORT] "
	echo "[++] Example allow port 80 : ufw allow 80"
	echo " "
	sleep 5
}

ufw-support() {
	if (whiptail --title "Firewall" --yesno "Enable firewall (ufw) on this server ?" 8 78)
		then
			echo "[+] Enable UFW..."
			enable-ufw
		else
			:
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

main() {
	# display main
	display-ascii

	# check run script
	check-root

	# get confirmation disable ipv6
	get-confirmation

	#configure ufw
	ufw-support

	# reconfigure date
	reconfig-date

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
