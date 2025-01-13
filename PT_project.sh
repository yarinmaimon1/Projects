#!/bin/bash

# Made by Yarin Maimon
# This is my 3rd project at John Bryce. Its purpuse is to identify ports, services, and vulnerabilities. Uses tools like nmap and masscan for scanning the network and searchsploit and hydra to identify security gaps, such as weak passwords.

HOME=$(pwd)

#this is the final function. here you can search inside everything that was saved, all the results. then you can also zip the files.
function END()
{
	echo "All the found information in inside $newdir"
	read -p "Would you like to search inside the results? [Y/n] " res
	if [[ "$res" == "Y" || "$res" == "y" ]]
		then
			read -p "What would you like to search? " newsearch
			grep -iRn "$newsearch" || echo "No matches found for $newsearch.."
	fi
	echo " "
	read -p "Would you like to save all the results to a ZIP file? [Y/n] " zip
	if [[ "$zip" == "Y" || "$zip" == "y" ]]
		then
			cd "$HOME"
			zip -r "$newdir".zip $newdir >/dev/null 2>&1
			echo "Results saved to ZIP!"
		else
			echo "Finished!! Thank you!"
			exit
	fi
}

# here i display the nmap vulners results and use searchsploit (ONLY FULL SCAN)
function VULNERS()
{
	echo "Displaying Vulners (Nmap results)"
	sleep 1
	cat ./Nmap_Full.txt
	echo "  "
	sleep 1
	read -p "Would you like to use Searchsploit? [Y/n] " search
	
	if [[ "$search" == "Y" || "$search" == "y" ]]
	then
		read -p "Would you like to display the services in use? [Y/n] " services
			if [[ "$services" == "Y" || "$services" == "y" ]]
			then
				cat ./Services.txt
			fi
		read -p "Enter a term to search: " sploit
		searchsploit "$sploit"
	else
		echo "Moving on..."
	fi
	echo "  "
}

# now we look for weak passords, i chose to work with hydra and gave 3 options. 1st uses a list i made. 2nd is user import. 3rd uses crunch to create a new list
function PASSLST()
{
	mkdir "Hydra"
	echo -e "Choose an option to look for weak passwords: [ PICK A NUMBER ]\n [ 1 ] Use SecLists Top 15 Passwords\n [ 2 ] Load Your Own List\n [ 3 ] Create A List Now (Using Crunch)"
	read -p "Enter your choice: " list
	
	case $list in
	1)
		git clone https://github.com/yarinmaimon1/Lists.git >/dev/null 2>&1
		cp ./Lists/Top15Users.txt ./Top15Users.txt
		cp ./Lists/Top15Pass.txt ./Top15Pass.txt
		rm -rf Lists
		echo "Starting Hydra..."
		hydra -L ./Top15Users.txt -P ./Top15Pass.txt -t 8 $ip ssh >> Hydra/hydra_ssh.log 2>&1 &
		hydra -L ./Top15Users.txt -P ./Top15Pass.txt -t 8 $ip ftp >> Hydra/hydra_ftp.log 2>&1 &
		hydra -L ./Top15Users.txt -P ./Top15Pass.txt -t 8 $ip rdp >> Hydra/hydra_rdp.log 2>&1 &
		hydra -L ./Top15Users.txt -P ./Top15Pass.txt -t 8 $ip telnet >> Hydra/hydra_telnet.log 2>&1 &
		wait
		echo "[+] Hydra completed! Logs saved to $newdir/Hydra."
		echo " "
	;;
	2)
		echo "Please enter the full path to your usernames list:"
		read users_path
		echo "Please enter the full path to your password list:"
		read pass_path
		echo "Starting Hydra..."
		hydra -L $users_path -P $pass_path -t 8 $ip ssh >> Hydra/hydra_ssh.log 2>&1 &
		hydra -L $users_path -P $pass_path -t 8 $ip ftp >> Hydra/hydra_ftp.log 2>&1 &
		hydra -L $users_path -P $pass_path -t 8 $ip rdp >> Hydra/hydra_rdp.log 2>&1 &
		hydra -L $users_path -P $pass_path -t 8 $ip telnet >> Hydra/hydra_telnet.log 2>&1 &
		wait
		echo "[+] Hydra completed! Logs saved to $newdir/Hydra."
		echo " "
	;;
	3)
		echo "note: this option will use the same list of both users and passwords."
		if ! dpkg -s crunch >/dev/null 2>&1; then
			echo "[%] Crunch not found. Installing..."
			sudo apt-get install crunch -y >/dev/null 2>&1
			echo "[!] Crunch installed!"
		fi

		read -p "What is the Minimum length of the password? " MIN
		read -p "What is the Maximum length of the password? " MAX
		read -p "Please provide the characters to use: " CHR
		crunch $MIN $MAX $CHR > passlist.txt
		echo "Password list generated as passlist.txt."
		echo "Starting Hydra..."
		timeout 180 hydra -L passlist.txt -P passlist.txt -t 8 $ip ssh >> Hydra/hydra_ssh.log 2>&1 &
		timeout 180 hydra -L passlist.txt -P passlist.txt -t 8 $ip ftp >> Hydra/hydra_ftp.log 2>&1 &
		timeout 180 hydra -L passlist.txt -P passlist.txt -t 8 $ip rdp >> Hydra/hydra_rdp.log 2>&1 &
		timeout 180 hydra -L passlist.txt -P passlist.txt -t 8 $ip telnet >> Hydra/hydra_telnet.log 2>&1 &
		wait
		echo "[+] Hydra completed! Logs saved to $newdir/Hydra."
		echo " "
	;;
	*)
		echo "Wrong input! Try again."
			PASSLST
	;;
	esac
}

# here i make sure i have every tool i need rot the full scan, this include searchsploit(exploitdb)
function FULLTOOLS()
{
		All_Packages=( "nmap" "hydra" "masscan" "exploitdb" )
		for package in "${All_Packages[@]}"
		do
			dpkg -s "$package" >/dev/null 2>&1 || \
			sudo apt-get install "$package" -y >/dev/null 2>&1
		done
}

# the full scan gets the services like the basic scan but also uses the vuln.nse script to get vulnerabilities, also scan udp ports.
function FULLSCAN()
{
		FULLTOOLS
		LOGFILE="$HOME/$newdir/script.log"
		
		echo "Starting Nmap.. NOTE: Might take time!"
		echo "$ip" >> ./Services.txt
		nmap -p- -sV $ip | grep open | awk '{print $4,$5,$6,$7 ,$8,$9}' >> ./Services.txt &
		nmap -p- -sV -sC --script=vulners.nse $ip -oN ./Nmap_Full.txt >> "$LOGFILE" 2>&1 &
		wait
		echo "Nmap results saved to $HOME/$newdir/Nmap_Full.txt" && echo " "
		echo "Starting Masscan.. NOTE: Might take MORE time!"
		sudo masscan $ip -pU:1-1000 --rate=10000 -oG ./Masscan_Full.txt >> "$LOGFILE" 2>&1
		echo "Masscan results saved to $HOME/$newdir/Masscan_Full.txt"
		echo " "
		PASSLST
		VULNERS
		END

}

#here i make sure i have every tool i need for the basic scan
function BASICTOOLS()
{
		All_Packages=( "nmap" "hydra" "masscan" )
		for package in "${All_Packages[@]}"
		do
			dpkg -s "$package" >/dev/null 2>&1 || \
			sudo apt-get install "$package" -y >/dev/null 2>&1
		done
}

# here i get the basictools function to install whatever is needed, starts nmap to get the services that are running, and scanns for udp ports using masscan
function BASICSCAN()
{
		BASICTOOLS
		LOGFILE="$HOME/$newdir/script.log"
		
		echo "Starting Nmap.. NOTE: Might take time!"
		echo "$ip" >> ./Services.txt
		nmap -sV $ip | grep open | awk '{print $4,$5,$6,$7 ,$8,$9}' >> ./Services.txt &
		nmap -sV -sC --script=ftp-brute.nse $ip -oN ./Nmap_Basic.txt >> "$LOGFILE" 2>&1 &
		wait
		echo "Nmap results saved to $HOME/$newdir/Nmap_Basic.txt" && echo " "
		echo "Starting Masscan.. NOTE: Might take MORE time!"
		sudo masscan $ip -pU:1-1000 --rate=10000 -oG ./Masscan_Basic.txt >> "$LOGFILE" 2>&1
		echo "Masscan results saved to $HOME/$newdir/Masscan_Basic.txt"
		echo " "
		PASSLST
		END
}

# this function asks what scan the user would like to perform
function WHATSCAN()
{
	echo "NOTE: Nmap, Masscan and hydra required! The script will install them if needed!"
	echo -e "What scan would you like to perform? [ PICK A NUMBER ]\n [ 1 ] Basic scan \n [ 2 ] Full scan"
	read -p "Enter your choice: " scan
	
	case $scan in
	1)
		BASICSCAN
	;;
	2)
		FULLSCAN
	;;
	*)
		echo "Wrong input! Try again."
			WHATSCAN
	;;
	esac
}

# the start function gets an ip adress, validates it and creates a new directory.
function START()
{
	while true
		do
			echo "Please provide a network to scan:"
			read ip

			if [[ $ip =~ ^([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]
			then
				echo "Valid IP address: $ip"
				break
			else
				echo "Invalid IP address! Try again!"
			fi
		done


	echo "Please provide a name for the new directory:"
	read newdir
	mkdir $HOME/$newdir
	cd $HOME/$newdir
	WHATSCAN
}
START
