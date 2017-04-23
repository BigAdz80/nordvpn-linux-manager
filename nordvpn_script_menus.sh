#!/bin/bash

scriptversion="0.01"

zip_conf_files="./nordvpn/config.zip"
zip_conf_folder="./nordvpn/config"
servers_info="./nordvpn/servers_info.txt"
geo="./country_codes.txt"
avaiable_countries_codes="./nordvpn/avaiable_countries_codes.txt"
paired_servers="./nordvpn/paired_servers.txt"
login="./credentials.txt"

foundservers=""
chosen=""

country=""
protocol="TCP"
servernumber=""

# ----------------------------------------------
# Functions!
# ----------------------------------------------
updateServers()
{
  printf "%s\n" "Downloading configuration files..."
  # Download the servers list -# progressbar only -L use redirect (necessary)
  curl -\# -L https://nordvpn.com/api/files/zip > $zip_conf_files
  # Extract the files -d output folder -q silent
  unzip -qu $zip_conf_files -d $zip_conf_folder
}

setCountry()
{
  clear
  # save the download opvn files name as a list
  find $zip_conf_folder -type f -printf "%f\n">$servers_info
  echo "Countries Found: "
  # save the coutries codes in a file
  printf '%s \n' $(grep -oE '^[a-zA-Z][a-zA-Z]([a-zA-Z])?' $servers_info | sort -u)>$avaiable_countries_codes
  # join them with the full countries name
  join -i <(sort $avaiable_countries_codes) <(sort $geo)>$paired_servers
  # print them in a formatted way
  printf "| %-2s | %-20s | %-2s | %-20s | %-2s | %-20s\n" $(awk '{printf "%s ",$0}' $paired_servers)
  printf "%s" "Insert the code for the desired country: "
  read -r country
}

setProtocol()
{
  clear
	echo "~~~~~~~~~~~~~~~~~~~~~"
	echo " PROTOCOL CHOICE"
	echo "~~~~~~~~~~~~~~~~~~~~~"
	echo "1. Use TCP Protocol"
	echo "2. Use UDP Protocol"
  read -rp "Enter choice [ 1 - 2 ] or press any other key to go back " protchoice;

  case $protchoice in
		1) protocol="TCP" ;;
    2) protocol="UDP" ;;
		*) ;;
	esac
}

setServerNumber()
{
  clear
  # filter servers by country and protocol
  foundservers=$(grep "^$country[0-9]" $servers_info | grep -i $protocol | sort -V)
  printf "%s\n" "Choose a server's number between these: "
  # avaiable servers number
  avaiable_numbers=$(grep -oE "[0-9]+.nord" <<< "$foundservers" | grep -oE "[0-9]+" )
  # check if at least one has been found
  if [ ${#avaiable_numbers} -gt 1 ]; then
  {
    printf " %s " $avaiable_numbers
    printf "%s\n" ""
    loop=true
    # loop until a correct server number is chosen
    while [ "$loop" = true ]; do
        read -r servernumber
        for item in $avaiable_numbers
        do
            if [ "$servernumber" == "$item" ]; then loop=false; fi;
        done
        if [ "$loop" = true ]; then printf "%s" "Please choose a valid server number: "; fi;
    done

    chosen=$(grep -F "$country$servernumber." $servers_info | grep -m1 -i $protocol)
  }
  else printf "%s" "No avaiable servers for these settings"; fi;

}

configurationWizard()
{
  setCountry
  setServerNumber
}

connectToServer()
{
  # check if a opvn file has been chosen
  if [ -n "$chosen" ]; then
    # there's no credentials file, you'll be asked to insert them
    if [ ! -f $login ]; then
      su -c "openvpn --config \"$zip_conf_folder/$chosen\""
    # using a credentials file
    else
      su -c "openvpn --config \"$zip_conf_folder/$chosen\" --auth-user-pass $login"
    fi
  fi;
}

# function to display menus
show_menus() {
	clear
	echo "~~~~~~~~~~~~~~~~~~~~~"
	echo " M A I N - M E N U"
	echo "~~~~~~~~~~~~~~~~~~~~~"
	echo "1. Connection Wizard"
	echo "2. Update Servers List"
	echo "3. Choose protocol TCP/UDP ( Currently " $protocol ")"
  if [ -n "$chosen" ]; then echo "4. Connect to the server" $chosen; fi;
	echo "0. Exit"
}

read_options(){
	local choice
  if [ -n "$chosen" ]; then
    read -rp "Enter choice [ 1 - 4 ] or Exit [0] " choice;
  else
    read -rp "Enter choice [ 1 - 3 ] or Exit [0] " choice; fi;

	case $choice in
		1) configurationWizard ;;
		2) updateServers ;;
		3) setProtocol ;;
		4) connectToServer ;;
		0) exit 0;;
		*) echo -e "${RED}Please choose between the avaiable options${STD}" && sleep 1
	esac
}

# ----------------------------------------------
# Trap CTRL+C, CTRL+Z and quit singles
# ----------------------------------------------
trap '' SIGINT SIGQUIT SIGTSTP

# ----------------------------------------------
# Check file and folders
# ----------------------------------------------
if [ ! -d "$zip_conf_folder" ]; then mkdir -p $zip_conf_folder; fi;
#conta i server scaricati $(find $zip_conf_folder -type f | wc -l)
serversfilesnumber=$(find $zip_conf_folder -type f | wc -l)
if [[ $serversfilesnumber -lt 1 ]]; then updateServers; fi;

# -----------------------------------
# Main logic - infinite loop
# ------------------------------------
while true
do
	show_menus
	read_options
done
