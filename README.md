# nordvpn-linux-manager
A bash script for Linux to manage your NordVPN service

## How to
Just run the script with `bash ./nordvpn_script_menus.sh` and then use the on-screen menu.
You can add a file called credentials.txt with your NordVPN username in the first row and your password on the second row in the same folder as this script, otherwise you'll be asked for them upon connection.
A folder named nordvpn will be created to keep all the needed files.
If you run into problems try to run the script with sudo `sudo bash ./nordvpn_script_menus.sh` . You will be asked for su anyway since OpenVpn needs it.
