#!/bin/bash

# Made by Yarin Maimon
# This is the 1st project I did in John Bryce. The goal here is to connect with SSH to another machine and use NMAP from there.

# In this final function i wanted the user to be able to see how long the Remote server is up and then give it the ip that we wanted to scan. then scan with sshpass, and copy the results. i also use sshpass in the scp so that the user won't need to enter the password again.
function SSH_connect()
{
		UP=$(uptime | awk '{print $3,$4}' | sed 's/,//g')
		echo "Connecting to the remote server..."
		sshpass -p "$password" ssh -o StrictHostKeyChecking=no $username@$ip "echo 'Remote server is up for: $UP'"
		sleep 1
		read -p "Which IP would you like to scan? " IPSCAN
		cd ~/Desktop
		sshpass -p "$password" ssh -o StrictHostKeyChecking=no $username@$ip "nmap $IPSCAN -oG /home/$username/Desktop/nmap.txt"
		sshpass -p "$password" ssh -o StrictHostKeyChecking=no $username@$ip "whois $IPSCAN >>/home/$username/Desktop/whois.txt"
		sshpass -p "$password" scp $username@$ip:/home/$username/Desktop/nmap.txt .
		sshpass -p "$password" scp $username@$ip:/home/$username/Desktop/whois.txt .
		echo "Copied both scans successfully. Thank you!"
}

# this function uses nipe to check if we are anonymous. if it is then moving on to the next function. if not then exitnig from the script.
function Nipe()
{
		echo "Anonymous check...."
		cd ~/nipe && sudo perl nipe.pl restart
		Addr=$(cd ~/nipe | sudo perl nipe.pl status | grep Ip: | awk '{print $3}')
		Country=$(geoiplookup $Addr | awk '{print $5}')
		
		if [ "$Country" == "IL" ]
		then
			echo "You are not anonymous! exiting.."
			exit
		else
			echo "You are anonymous! Country: $Country"
		fi
		SSH_connect
}

# this function checks if Nipe is installed or not. if not then move to install it. or just move to use Nipe
function Nipecheck()
{
		if [ $(cd ~ | find -name nipe.pl)==* ]
	then 
		echo " [%] Nipe already installed. moving on.."
		Nipe
	else
		echo " [!] Nipe in not installed. Installing.."
		Install_Nipe
fi
}

# this function would only happened if Nipe is not installed already, and would install it.
function Install_Nipe()
{
		git clone https://github.com/htrgouvea/nipe
		cpanm --installdeps .
		cd nipe
		sudo cpan install Try::Tiny Config::Simple JSON
		sudo perl nipe.pl install
	Nipe
}

# this function checks and installs all the relevant applications/packages that the script needs.
function Install_packages()
{
		All_Packages=( "geoip-bin" "sshpass" "git" "nmap" "whois")
		for package in "${All_Packages[@]}"
		do
			dpkg -s "$package" >/dev/null 2>&1 ||
			(echo -e " [$] Installing $package" &&
			sudu apt-get install "$package" -y >/dev/null 2>&1)
			echo " [%] $package installed."
		done
		Nipecheck
}

# in this opening function i wanted to get all the information i needed for the rest of the script. so it would run automated.
function Open()
{
		echo "Provide the IP of the remote server:"
		read ip
		echo "Username for the remote server:"
		read username
		echo "Password for the SSH service on the remote server:"
		read -s password
		echo "Thank you! Installing..."
		Install_packages
}
Open
