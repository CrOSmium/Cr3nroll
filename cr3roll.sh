#!/bin/bash

tput civis

selected_index=0
writeprotect=$(futility flash --wp-status | grep disabled)



# TODO:
# * Add factory backup stuff
# * Migrate to RW_VPD (done)

menu_reset() {
options=("Save Current Enrollment Keys" "Load saved Enrollment Keys" "Generate new Enrollment Keys" "Import Custom Enrollment Info" "Edit Enrollment list" "Backup Enrollment Info (Does not require WP OFF)" "Restore Enrollment Info" "Exit")
num_options=${#options[@]}
}
menu_reset

selector() {
clear
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
    echo -e "Keys written to VPD! (if WP was enabled)"
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
    echo -e "What do you want your serial number to be?"
    currentsn=$(vpd -i RO_VPD -g serial_number)
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
if [[ "${options[$selected_index]}" == "Load saved Enrollment Keys" ]]; then
    clear
    menu_logo
    echo -e "Getting keys..."
    sleep 2
    mapfile -t KEYNAMES < <(vpd -i RW_VPD -l | grep '^saved_' | awk -F'[ =]' '{print $1}' | awk -F_ '{print $2}' | sort -u)
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
    echo -e "\nCurrently selected serial number: '$(vpd -i RO_VPD -g "serial_number")'"
    echo ""
    
sleep 1
   #  if [[ ${#KEYNAMES[@]} -eq 0 ]]; then
   #     echo -e "No Keys found!"
   #     sleep 2
   #     menu_reset
   # else
        options=("-- RETURN TO MENU --" ${KEYNAMES[@]} "test")
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
                    echo -e "\nWarning: Setting your enrollment keys is highly destructive, I recommend saving your factory ones before you select any keys.\n"
                    read -r -n 1 -p "Press Y to continue, or press any key to exit..." confirmation
                    if [[ "$confirmation" != "y" ]]; then
                    menu_reset
                    full_menu
                    fi
                     overrideSet() {
        clear
    echo -e "Writing selected keys to RO_VPD in 3 seconds, press CTRL-C to cancel if you change your mind. THIS IS HIGHLY DESTRUCTIVE!!"
    sleep 1.5
    clear
           echo -e "Writing selected keys to RO_VPD in 3 seconds, press CTRL-C to cancel if you change your mind. THIS IS HIGHLY DESTRUCTIVE!!"
    echo -e "Writing in: 3"
    sleep 1.5
        clear
            echo -e "Writing selected keys to RO_VPD in 3 seconds, press CTRL-C to cancel if you change your mind. THIS IS HIGHLY DESTRUCTIVE!!"
    echo -e "Writing in: 2"
    sleep 1.5
        clear
           echo -e "Writing selected keys to RO_VPD in 3 seconds, press CTRL-C to cancel if you change your mind. THIS IS HIGHLY DESTRUCTIVE!!"
    echo -e "Writing in: 1"
    sleep 2
        clear
            echo -e "Writing selected keys to RO_VPD in 3 seconds, press CTRL-C to cancel if you change your mind. THIS IS HIGHLY DESTRUCTIVE!!"
    echo -e "Writing keys..."
    sleep 1.7
    vpd -i RO_VPD -s "serial_number"="$(vpd -i RW_VPD -g "saved_'$key'_serial_number")"
    vpd -i RO_VPD -s "stable_device_secret_DO_NOT_SHARE"="$(vpd -i RW_VPD -g "saved_'$key'_stable_device_secret")"
    echo -e "Keys written to VPD!"
    sleep 3.4
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
  echo -e "Write Protection Disabled, have fun! :D"
  else
  echo -e "This requires Firmware Write Protection to be disabled to work, please disable it!"
fi
echo ""
for i in "${!options[@]}"; do
        if [[ $i -eq $selected_index ]]; then
            echo -e "\e[7m > ${options[$i]} \e[0m"
        else
            echo "   ${options[$i]}      "
        fi
    done
}
clear
full_menu
tput cnorm
selector
