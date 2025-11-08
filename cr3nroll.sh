#!/bin/bash

tput civis

selected_index=0
writeprotect=$(flashrom --wp-status | grep disabled)
factoryserial=$(vpd -i RO_VPD -g "factory_serial_number")
if [[ "$factoryserial" == "" ]]; then
factorysaved="1"
fi
# TODO:
# * Add factory backup stuff (done)
# * Migrate to RW_VPD (done)
# * finish the empty options (5/7 done)



# colors that i totally didn't steal from a previous project
B='\033[1;36m' 
G='\033[1;32m' 
Y='\033[38;5;220m'
R='\033[38;5;203m'
N='\033[0m'    
D='\033[1;90m'

menu_reset() {
if [[ "$factorysaved" == "1" ]]; then
options=("Save Current Enrollment Keys" "${R}Load saved Enrollment Keys${N}" "Generate new Enrollment Keys" "${D}Import Custom Enrollment Info (WIP)${N}" "${D}Edit Enrollment list (WIP)${N}" "${B}Backup Enrollment Info${N}" "${D}Restore Enrollment Info (WIP)${N}" "${G}Backup Factory Enrollment Info (Recommended)${N}" "Disable Enrollment (Quicksilver)" "Exit")
else
options=("Save Current Enrollment Keys" "${R}Load saved Enrollment Keys${N}" "Generate new Enrollment Keys" "${D}Import Custom Enrollment Info (WIP)${N}" "${D}Edit Enrollment list (WIP)${N}" "${B}Backup Enrollment Info${N}" "${D}Restore Enrollment Info (WIP)${N}" "Disable Enrollment (Quicksilver)" "Exit")
fi
if [[ "$(vpd -i RW_VPD -g "re_enrollment_key")" != "" ]]; then
options=("Remove Quicksilver${N}")
fi
num_options=${#options[@]}

}

menu_reset

selector() {
clear
if [[ "${options[$selected_index]}" == "${D}Edit Enrollment list (WIP)${N}" ]]; then
menu_reset
full_menu
fi
if [[ "${options[$selected_index]}" == "${D}Import Custom Enrollment Info (WIP)${N}" ]]; then
menu_reset
full_menu
fi
if [[ "${options[$selected_index]}" == "${D}Restore Enrollment Info (WIP)${N}" ]]; then
menu_reset
full_menu
fi
if [[ "${options[$selected_index]}" == "Exit" ]]; then
    echo "Exiting."
    sleep 0.5
    clear
    tput cnorm
    exit 0
fi
if [[ "${options[$selected_index]}" == "Save Current Enrollment Keys" ]]; then
    menu_logo
    sleep 0.3
    echo -e "Enter name to save enrollment keys as"
    tput cnorm
    KEYNAMEC() {
    echo -ne "Key name: "
    read KEYNAME
    sleep 0.4
    if [[ "$KEYNAME" =~ [[:space:]_] ]]; then
    echo -e "(Invalid Keyname! Cannot be contain a space OR underscore!)"
    KEYNAMEC
    fi
    if [[ $KEYNAME = "" ]]; then
    echo -e "(Invalid Keyname! Cannot be empty!)"
    KEYNAMEC
    fi
    }
    KEYNAMEC
    echo -e "Setting enrollment keyname to '$KEYNAME'"
    sleep 0.4
    sleep 0.4
    echo -e "Reading VPD..."
    sleep 0.67
    STABLEDEV=$(vpd -i RO_VPD -g "stable_device_secret_DO_NOT_SHARE")
    echo -e "Read stable_device_secret!"
    sleep 0.4
    SERIAL=$(vpd -i RO_VPD -g "serial_number")
    echo -e "Read serial_number!"
    sleep 1.2
    echo ""
    echo -e "Are you sure you want to save the key under the name '$KEYNAME' for the serial number '$SERIAL'?"
    echo -ne "(Y/N): "
    read YESNT
    if [[ ${YESNT,,} = "y" ]]; then
    echo -e "Saving keys (to RW_VPD)..."
    vpd -i RW_VPD -s "saved_"$KEYNAME"_stable_device_secret"="$STABLEDEV"
    sleep 0.3
    vpd -i RW_VPD -s "saved_"$KEYNAME"_serial_number"="$SERIAL"
    sleep 0.3
    echo -e "Keys written to VPD!"
    sleep 0.8
    else
    echo -e "Declined!"
    fi
    sleep 1
    echo -e "Returning to menu..."
    sleep 0.4
    menu_reset
    full_menu
fi
if [[ "${options[$selected_index]}" == "Remove Quicksilver${N}" ]]; then
vpd -i RW_VPD -d "re_enrollment_key"
echo -e "Removed Quicksilver! Returning to menu..."
sleep 2.6
menu_reset
full_menu
fi
if [[ "${options[$selected_index]}" == "Disable Enrollment (Quicksilver)" ]]; then
menu_logo
echo -e "Disable Enrollment"
echo ""
echo -e "\n${R}Warning: This will prevent editing enrollment configs and enrolling until Quicksilver is removed.)\n${N}"
                    read -r -n 2 -s -p "Double click Y to continue, or hold any other key to exit..." confirmation
                    if [[ "$confirmation" != "yy" ]]; then
                    menu_reset
                    full_menu
                    fi
echo -e "\nDisabling Enrollment..."
sleep 1
vpd -i RW_VPD -s "re_enrollment_key"="$(openssl rand -hex 32)"
echo -e "Done! Returning to menu..."
sleep 2
menu_reset
full_menu
fi
if [[ "${options[$selected_index]}" == "${B}Backup Enrollment Info${N}" ]]; then
menu_logo
echo -e "Backup Enrollment Info"
echo ""
if [[ -d "/tmp/aurora" ]]; then
echo -e "It looks like you're booted in Sh1mmer (via Aurora), automatically backing up VPD to '/tmp/aurora/vpd/RO.vpd' and '/tmp/aurora/vpd/RW.vpd'"
mkdir -p /tmp/aurora/vpd
vpd -i RO_VPD -l > /tmp/aurora/vpd/RO.vpd
vpd -i RW_VPD -l > /tmp/aurora/vpd/RW.vpd
sleep 0.67
echo -e "Backup complete! Returning to menu..."
menu_reset
full_menu
else
echo -e "Where would you like to backup your VPD to? (makes a new directory '/vpd/' underneath the selected one)"
echo -ne "Directory: "
read sdirec
sleep 0.67
if [[ -d "$sdirec" ]]; then
vpd -i RO_VPD -l
sleep 0.67
vpd -i RW_VPD -l
sleep 0.67
mkdir $sdirec/vpd
vpd -i RO_VPD -l > $sdirec/vpd/RO.vpd
vpd -i RW_VPD -l > $sdirec/vpd/RW.vpd
echo -e "Backup Complete, Validating..."
if [[ -f "$sdirec/vpd/RO.vpd" ]]; then
echo -e "Validated!"
else
echo ""
echo -e "Validation failed, check if you're in the correct environment, or if the directory is writeable."
sleep 4
echo -e "Returning to menu..."
sleep 1.2
menu_reset
full_menu
fi
else
echo -e "Not a valid directory! Returning to menu..."
sleep 1.2
menu_reset
full_menu
fi
fi
fi
if [[ "${options[$selected_index]}" == "${G}Backup Factory Enrollment Info (Recommended)${N}" ]]; then
menu_logo
echo -e "Backup Factory Enrollment Info"
echo ""
echo -e "${R}This is irreversible!!${N}\n\n${G}This will save these two keys: 'factory_serial_number' as '$(vpd -i RO_VPD -g "serial_number")' and 'factory_stable_device_secret' as '$(vpd -i RO_VPD -g "stable_device_secret_DO_NOT_SHARE")'${N}"

read -r -n 1 -p "Press Y to continue, or press any key to exit..." yesnts

if [[ "$yesnts" == "y" ]]; then
echo -e "\n\nSaving factory enrollment info to RO_VPD..."
sleep 0.67
vpd -i RO_VPD -s "factory_serial_number"="$(vpd -i RO_VPD -g "serial_number")"
sleep 0.67
vpd -i RO_VPD -s "factory_stable_device_secret"="$(vpd -i RO_VPD -g "stable_device_secret_DO_NOT_SHARE")"
sleep 0.67
vpd -i RW_VPD -s "factory_backup"="2"
echo -e "Enrollment info backed up under 'factory_serial_number' and 'factory_stable_device_secret'!\nReturning to menu..."
sleep 4
menu_reset
full_menu
else
menu_reset
full_menu
fi
fi
if [[ "${options[$selected_index]}" == "Generate new Enrollment Keys" ]]; then
    menu_logo
    echo -e "Would you like to generate and save new Enrollment Keys? (Does not override currently selected keys)"
    tput cnorm
    echo -ne "(Y/N): "
    read YESNT2
    if [[ ${YESNT2,,} = "y" ]]; then
    sleep 0.67
    echo -e "Generating new Keys..."
    sleep 0.4
    
    gensdev=$(openssl rand -hex 32)
    echo -e "Generated stable_device_secret: '$gensdev'"
    sleep 0.4
    echo -e "Would you like to have your serial number auto-generated? (Y/N)"
    read -r -n 1 -p "(y/n):" snauto
    if [[ "${snauto}" == "y" ]]; then
    KEYNAME="$(tr -dc 'A-Z' </dev/urandom | head -c2; tr -dc '0-9' </dev/urandom | head -c1; tr -dc 'A-Z' </dev/urandom | head -c3; tr -dc 'A-Z0-9' </dev/urandom | head -c3; echo)"
    echo -e "Setting serial number to '$KEYNAME'"
    else
    echo -e "What do you want your serial number to be?"
    currentsn=$(vpd -i RO_VPD -g "serial_number")
    echo -e "Your currently set one is: '$currentsn'"
    echo -e "Warning: Setting your serial number or Keyname blank WILL corrupt your enrollment keys!!"
    KEYNAMESN() {
    echo -ne "Serial Number: "
    read KEYNAME
    sleep 0.4
    if [[ "$KEYNAME" =~ [[:space:]_] ]]; then
    echo -e "(Invalid Keyname! Cannot be contain a space OR underscore!)"
    KEYNAMESN
    fi
    if [[ $KEYNAME = "" ]]; then
    echo -e "(Invalid Keyname! Cannot be empty!)"
    KEYNAMESN
    fi
    }
    KEYNAMESN
    sleep 0.67
    echo ""
    echo -e "You want your new serial number to be '$KEYNAME'?"
    echo -ne "(Y/N): "
    read SCONFIRM
    fi
    if [[ ${SCONFIRM,,} = "y" ]]; then
    echo -e "What would you like to name these keys? (NO SPACES)"
    SKNAME() {
    echo -ne "Name: "
    read SKNAMES
    SKNAME=$SKNAMES
    sleep 0.4
    if [[ "$SKNAME" =~ [[:space:]_] ]]; then
    echo -e "(Invalid Keyname! Cannot be contain a space OR underscore!)"
    SKNAME
    fi
    if [[ $SKNAME = "" ]]; then
    echo -e "(Invalid Keyname! Cannot be empty!)"
    SKNAME
    fi
    }
    SKNAME
        sleep 0.4
        echo -e "Saving new stable_device_secret and serial_number('$KEYNAME') as '$SKNAME'..."
        sleep 0.67
        vpd -i RW_VPD -s "saved_"$SKNAME"_stable_device_secret"="$gensdev"
        sleep 0.4
        vpd -i RW_VPD -s "saved_"$SKNAME"_serial_number"="$KEYNAME"
        sleep 1
        echo -e "Finished!"
        sleep 3
        else
        echo -e "Cancelled!"
        fi
    
    else
    echo -e "Declined!"
    fi
    sleep 1
    echo -e "Returning to menu..."
    sleep 0.4
    menu_reset
    full_menu
fi
if [[ "${options[$selected_index]}" == "${R}Load saved Enrollment Keys${N}" ]]; then
    clear
    menu_logo
    echo -e "Getting keys..."
    sleep 2
    mapfile -t KEYNAMES < <(vpd -i RW_VPD -l | grep '"saved_' | awk -F'[ =]' '{print $1}' | awk -F_ '{print $2}' | sort -u)
# mapfile -t KEYNAMES < <(echo -e "saved_test" "saved_test_serial" | grep '^saved_' | awk -F'[ =]' '{print $1}' | awk -F_ '{print $2}' | sort -u)
    clear
    echo -e " █████                              █████                                               █████                                              
░░███                              ░░███                                               ░░███                                               
 ░███         ██████   ██████    ███████      █████   ██████   █████ █████  ██████   ███████                                               
 ░███        ███░░███ ░░░░░███  ███░░███     ███░░   ░░░░░███ ░░███ ░░███  ███░░███ ███░░███                                               
 ░███       ░███ ░███  ███████ ░███ ░███    ░░█████   ███████  ░███  ░███ ░███████ ░███ ░███                                               
 ░███      █░███ ░███ ███░░███ ░███ ░███     ░░░░███ ███░░███  ░░███ ███  ░███░░░  ░███ ░███                                               
 ███████████░░██████ ░░████████░░████████    ██████ ░░████████  ░░█████   ░░██████ ░░████████                                              
░░░░░░░░░░░  ░░░░░░   ░░░░░░░░  ░░░░░░░░    ░░░░░░   ░░░░░░░░    ░░░░░     ░░░░░░   ░░░░░░░░                                               
                                                                                                                                           
                                                                                                                                           
                                                                                                                                           
                                        ████  ████                                       █████       █████                                 
                                       ░░███ ░░███                                      ░░███       ░░███                                  
  ██████  ████████   ████████   ██████  ░███  ░███  █████████████    ██████  ████████   ███████      ░███ █████  ██████  █████ ████  █████ 
 ███░░███░░███░░███ ░░███░░███ ███░░███ ░███  ░███ ░░███░░███░░███  ███░░███░░███░░███ ░░░███░       ░███░░███  ███░░███░░███ ░███  ███░░  
░███████  ░███ ░███  ░███ ░░░ ░███ ░███ ░███  ░███  ░███ ░███ ░███ ░███████  ░███ ░███   ░███        ░██████░  ░███████  ░███ ░███ ░░█████ 
░███░░░   ░███ ░███  ░███     ░███ ░███ ░███  ░███  ░███ ░███ ░███ ░███░░░   ░███ ░███   ░███ ███    ░███░░███ ░███░░░   ░███ ░███  ░░░░███
░░██████  ████ █████ █████    ░░██████  █████ █████ █████░███ █████░░██████  ████ █████  ░░█████     ████ █████░░██████  ░░███████  ██████ 
 ░░░░░░  ░░░░ ░░░░░ ░░░░░      ░░░░░░  ░░░░░ ░░░░░ ░░░░░ ░░░ ░░░░░  ░░░░░░  ░░░░ ░░░░░    ░░░░░     ░░░░ ░░░░░  ░░░░░░    ░░░░░███ ░░░░░░  
                                                                                                                          ███ ░███         
                                                                                                                         ░░██████          
                                                                                                                          ░░░░░░           "
    echo -e "| Cr3nroll By OSmium (crosmium on Github) |"
    echo ""
    echo ""
    echo -e "\nCurrently active serial number: '$(vpd -i RO_VPD -g "serial_number")'"
    echo ""
    
sleep 1
   #  if [[ ${#KEYNAMES[@]} -eq 0 ]]; then
   #     echo -e "No Keys found!"
   #     sleep 2
   #     menu_reset
   # else
        options=("-- RETURN TO MENU --" ${KEYNAMES[@]})
        num_options=${#options[@]}

        PS3=$'\nSelection: '
        select key in "${options[@]}"; do
            case "$key" in
                "-- RETURN TO MENU --")
                    menu_reset
                    full_menu
                    ;;
                "")
                    echo "Invalid selection, try again."
                    ;;
                *)
                    echo -e "(Selected '$key')"
                    echo -e "\n${R}Warning: Setting your enrollment keys is highly destructive, I recommend saving your factory ones before you select any keys.${N}\n\n(This script will attempt to back them up automatically if you haven't, but I still highly recommend doing it manually)\n"
                    read -r -n 2 -s -p "Double click Y to continue, or hold any other key to exit..." confirmation
                    if [[ "$confirmation" != "yy" ]]; then
                    menu_reset
                    full_menu
                    fi
                    clear
                    menu_logo
                    
                    if [[ "$(vpd -i RO_VPD -g "factory_stable_device_secret")" == "" ]]; then
                    vpd -i RO_VPD -s "factory_stable_device_secret"="$(vpd -i RO_VPD -g "stable_device_secret_DO_NOT_SHARE")"
                    echo -e "if you see this that means that you don't have your factory SDS (stable_device_secret) backed up, It will be backed up in the next step."
                    else
                    echo -e "Found valid factory entry (SDS)!"
                    fi
                    if [[ "$(vpd -i RO_VPD -g "factory_serial_number")" == "" ]]; then
                    vpd -i RO_VPD -s "factory_serial_number"="$(vpd -i RO_VPD -g "serial_number")"
                    echo -e "if you see this that means that you don't have your factory SN backed up, It will be backed up in the next step."
                    else
                    echo -e "Found valid factory entry (SN)!"
                    fi
                    sleep 3.4
                     overrideSet() {
        clear
    echo -e "Writing selected keys to RO_VPD in 3 seconds, press CTRL-C to cancel if you change your mind. ${R}THIS IS HIGHLY DESTRUCTIVE!!${N}"
    sleep 1.5
    clear
           echo -e "Writing selected keys to RO_VPD in 3 seconds, press CTRL-C to cancel if you change your mind. ${R}THIS IS HIGHLY DESTRUCTIVE!!${N}"
    echo -e "Writing in: 3"
    sleep 1.5
        clear
            echo -e "Writing selected keys to RO_VPD in 3 seconds, press CTRL-C to cancel if you change your mind. ${R}THIS IS HIGHLY DESTRUCTIVE!!${N}"
    echo -e "Writing in: 2"
    sleep 1.5
        clear
           echo -e "Writing selected keys to RO_VPD in 3 seconds, press CTRL-C to cancel if you change your mind. ${R}THIS IS HIGHLY DESTRUCTIVE!!${N}"
    echo -e "Writing in: 1"
    sleep 2
        clear
        
            echo -e "Writing selected keys to RO_VPD in 3 seconds, press CTRL-C to cancel if you change your mind. ${R}THIS IS HIGHLY DESTRUCTIVE!!${N}"
    echo -e "${R}Writing keys...${N}"
    sleep 0.8
            clear
            menu_logo
    echo -e "Checking and backing up factory info..."
    sleep 1.7
    if [[ "$(vpd -i RW_VPD -g "factory_backup")" != "2" ]]; then
    if [[ "$(vpd -i RO_VPD -g "factory_stable_device_secret")" == "" ]]; then
                    vpd -i RO_VPD -s "factory_stable_device_secret"="$(vpd -i RO_VPD -g "stable_device_secret_DO_NOT_SHARE")"
                    vpd -i RW_VPD -s "factory_backup"="$(($(vpd -i RW_VPD -g "factory_backup") + 1 ))"
                    echo -e "Wrote factory info! (SDS)"
                    fi
                    if [[ "$(vpd -i RO_VPD -g "factory_serial_number")" == "" ]]; then
                    vpd -i RO_VPD -s "factory_serial_number"="$(vpd -i RO_VPD -g "serial_number")"
                    vpd -i RW_VPD -s "factory_backup"="$(($(vpd -i RW_VPD -g "factory_backup") + 1 ))"
                    echo -e "Wrote factory info! (SN)"
                    fi
                    fi
    sleep 2
    echo -e "Writing keys to RO_VPD..."
    vpd -i RO_VPD -s "serial_number"="$(vpd -i RW_VPD -g "saved_${key}_serial_number")"
    vpd -i RO_VPD -s "stable_device_secret_DO_NOT_SHARE"="$(vpd -i RW_VPD -g "saved_${key}_stable_device_secret")"
    echo -e "Keys written to VPD!"
    sleep 4
    menu_reset
    full_menu
}
                    overrideSet
                    menu_reset
                    full_menu
                    ;;
            esac
        done
    # fi   
fi
}
full_menu() {
clear
tput civis
while true; do
    display_menu
    
    read -rsn1 key

    if [[ "$key" == $'\x1b' ]]; then
        read -rsn2 -t 0.01 keyseq
        case "$keyseq" in
            '[A')
                selected_index=$(( (selected_index - 1 + num_options) % num_options ))
                ;;
            '[B')
                selected_index=$(( (selected_index + 1) % num_options ))
                ;;
        esac
    elif [[ "$key" == "" ]]; then
        break
    fi
    tput rc
done
selector
}
menu_logo() {
 echo -e "
 ██████╗██████╗ ██████╗ ███╗   ██╗██████╗  ██████╗ ██╗     ██╗     
██╔════╝██╔══██╗╚════██╗████╗  ██║██╔══██╗██╔═══██╗██║     ██║     
██║     ██████╔╝ █████╔╝██╔██╗ ██║██████╔╝██║   ██║██║     ██║     
██║     ██╔══██╗ ╚═══██╗██║╚██╗██║██╔══██╗██║   ██║██║     ██║     
╚██████╗██║  ██║██████╔╝██║ ╚████║██║  ██║╚██████╔╝███████╗███████╗
 ╚═════╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝
"
    echo -e "| By OSmium (crosmium on Github) |"
    echo ""
}
display_menu() {
tput sc
   menu_logo


if [[ "$writeprotect" == *"disabled"* ]]; then
  echo -e "You currently have Firware Write Protection set to ${R}(DISABLED)${N}, all features *should* work properly. Have fun :D"
  else
  echo -e "You currently have Firmware Write Protection set to ${G}(ENABLED)${N}, you will be ${R}unable${N} to change your current enrollment info until you disable it!\n\n(This appears if your Write Protection is set to ${G}(ENABLED)${N}, regardless of the WP range)"
fi
echo ""
for i in "${!options[@]}"; do
        if [[ $i -eq $selected_index ]]; then
            echo -e "\e[7m > ${options[$i]} \e[0m"
        else
            echo -e "   ${options[$i]}      "
        fi
    done
}
clear
full_menu
tput cnorm
selector
