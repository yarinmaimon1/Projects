#!/bin/bash

# Made by Yarin Maimon

HOME=$(pwd)

#the last function, makes a report file, shows how many files where found and the time of analysis, then zip all the files.
function END()
{
	REPORT=$(ls -lR | awk '{print $9}' | grep -v "^$" | find -type f )
	cd $HOME
	NUFILES=$(find "${filename} Carved" | wc -l)
	echo "Finishing..."
	echo "Total files found: $NUFILES"
	echo "$REPORT" > $HOME/Report.txt
	echo "Report file saved to 'Report.txt'"
	zip "${filename} Carved".zip Report.txt "${filename} Carved" >/dev/null 2>&1
	
	echo "Start time: $START"
	echo "End time : $(date)"
}

#if volatility can run then the script makes a new dir and uses the profile to command pslist, connscan, hivelist and dumpregistry
function Volatility()
{
	echo "Creating a new directory: 'Volatility_Output'"
	mkdir "Volatility_Output" >/dev/null 2>&1
	cd Volatility_Output
	echo ""
	
	PROFILE=$($HOME/vol2.5/volatility_2.5_linux_x64 -f $filepath imageinfo | grep Suggested | awk '{print $4}' | awk -F ',' '{print $1}')
	echo "Displaying the process list from the file:"
	$HOME/vol2.5/volatility_2.5_linux_x64 -f $filepath --profile=$PROFILE pslist | tee $HOME/"${filename} Carved"/Volatility_Output/processes.txt
	echo ""
	
	echo "Displaying the network connections:"
	$HOME/vol2.5/volatility_2.5_linux_x64 -f $filepath --profile=$PROFILE connscan | tee $HOME/"${filename} Carved"/Volatility_Output/connections.txt
	echo ""
	
	echo "Saved hive list (if possible) to: 'hives.txt'"
	$HOME/vol2.5/volatility_2.5_linux_x64 -f $filepath --profile=$PROFILE hivelist | tee $HOME/"${filename} Carved"/Volatility_Output/hives.txt >/dev/null 2>&1
	
	mkdir Dump_files
	echo "Dump registry saved to: 'Dump_files'"
	$HOME/vol2.5/volatility_2.5_linux_x64 -f $filepath --profile=$PROFILE dumpregistry --dump-dir $HOME/"${filename} Carved"/Volatility_Output/Dump_files >/dev/null 2>&1
	echo ""
	
	END
}

#this one checks if volatility can run on the file. if it can then use vol, if not move to the end function.
function VOLCHECK()
{
	extension="${filename##*.}"
	supported=("raw" "bin" "mem" "dmp" "vmem" "vmsn" "vmss" "sav")
	
	for ext in "${supported[@]}"
do
	if [[ "$extension" == "$ext" ]]
		then
			echo "Running Volatility..."
			Volatility
			return 0
	fi
done
echo "Volatility doesn't support this file type."
END
}

#this function uses all the carvers, then looks for network files(pcap).
function CARVING()
{
	mkdir ./"${filename} Carved" >/dev/null 2>&1
	cd "${filename} Carved"
	foremost -i "$filepath"
	echo "Foremost results saved to 'Output'"
	binwalk --run-as=root -e "$filepath" >/dev/null 2>&1
	echo "Binwalk results saved to '_$filename.extracted'"
	bulk_extractor "$filepath" -o Bulk_results>/dev/null 2>&1
	echo "Bulk results saved to 'Bulk_results'"
	
	strings "$filepath" | grep -i "password" >> strings_output.txt
	strings "$filepath" | grep -i "username" >> strings_output.txt
	strings "$filepath" | grep -i "exe" >> strings_output.txt
	exefiles=$(find -type f -name "*.exe")
	for exe in $exefiles
	do
		strings "$exe" | grep -i "password" >> strings_output.txt
		strings "$exe" | grep -i "username" >> strings_output.txt
	done
	echo "Human-readable strings saved to 'strings_output.txt'"
	
	echo ""
	echo "Looking for pcap files..."
	sleep 1
	pcapfiles=$(find -type f -name "*.pcap")
	if [ -n "$pcapfiles" ]
		then
			echo "Found! pcap files at:"
			echo "$pcapfiles"
			pcapsize=$(ls -l $pcapfiles | awk '{print $5}')
			echo "File size: $pcapsize"
			echo ""
		else
			echo "No pcap files found."
			echo ""
	fi
	VOLCHECK
}

#this function makes a new directory, based on the file that the user gives(only if the file exists).
function FILENAMEEX()
{
	echo "Please provide the full path to the file you want to check."
	read filepath
	if [ -e "$filepath" ]
		then
			filename=$(basename "$filepath")
			echo "Creating a new directory: $filename Carved."
			CARVING
		else
			echo "No file Found. Please provide a valid file."
			FILENAMEEX
	fi
}

#i uploaded the correct version of volatility to github, and made  sure that the user have to correct one
function Install_Volatility()
{
	if [ -d vol2.5 ]
		then
			echo " [!] Volatilty installed."
			FILENAMEEX
		else
			echo " [%] Installing Volatility"
			git clone https://github.com/yarinmaimon1/vol2.5.git >/dev/null 2>&1
			cd vol2.5
			chmod +x volatility_2.5_linux_x64
			echo " [!] Volatily installed."
			cd ..
			FILENAMEEX
	fi
}

#here i made sure that everything that i use in the rest of the script is installed.
function Install_packages()
{
		All_Packages=( "binwalk" "foremost" "bulk-extractor" "binutils")
		for package in "${All_Packages[@]}"
		do
			dpkg -s "$package" >/dev/null 2>&1 ||
			(echo -e " [%] Installing $package" &&
			sudu apt-get install "$package" -y >/dev/null 2>&1)
			echo " [!] $package installed."
		done
		Install_Volatility
}

#in this first function i wanted to make sure only root can run this script, also i captured the start time.
function WHOAMI()
{
	START=$(date)
	if [ $(whoami) == "root" ]
		then
			echo "You are Root! Proceeding to installations..."
			Install_packages
		else
			echo "Must be root to use this script!"
			exit
	fi
}
echo "Checking user..."
sleep 1
WHOAMI
