#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# File Name: Cisco Webex Meeting - Disable Open at Login-00.00.01.sh
#
# Description: Close Cisco Webex Meeting if open and remove login item from current user's account.
# Written by: Matin Sasaluxanon
# Created on: Matin Sasaluxanon
last_update="2021-07-29"
version=00.00.03
# Requirements:
#           - Jamf Pro
#           - macOS Clients running version 10.13 or later
#           - Cisco Webex Meeting
# Reference:
#           - http://hints.macworld.com/article.php?story=20111226075701552
#           - https://apple.stackexchange.com/questions/184764/how-do-i-disable-webex-assistant-on-startup-for-mac
#
# Version History:
#           2021-07-29 - 00.00.03
#           - added version_update variable to echo to screen/jamf log
#           - added status variable to determine if login item was removed successfully or an error occured
#
#           2021-06-23 - 00.00.02
#           - updated script to check if open at login is enable and if so exit
#           - added additional comments for formating in Jamf Log
#
#           2021-04-29 - 00.00.01
#           - created script
#           - added killall for cisco webex meeting with conditional
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

#variable for storing the current users name
currentuser=$(ls -l /dev/console | awk '{ print $3 }')
realname="$(dscl . -read /Users/$currentuser RealName | cut -d: -f2 | sed -e 's/^[ \t]*//' | grep -v "^$")"
plistFile="/Users/$currentuser/Library/Preferences/com.cisco.webexmeetingsapp.plist"

####Historical Note####
# The following command was tested and confirmed not work to remove open at login on macOS 10.15 or higher. 
#command=$( defaults write com.cisco.webexmeetingsapp PTLaunchAtLogin -bool false )
#######################

function closeRunningApp() {
  local appName=$1
  if [[ $(ps axo pid,command | grep "$appName.app") ]]; then
      # Close App
      # example: osascript -e 'quit app "APPLICATIONNAME"'
      osascript -e "quit app \"$appName\""
  fi
}

echo ""
echo "--Start Program--"
echo "Last Update: $last_update"
echo "Version: $version"
echo ""

statusPTLaunchAtLogin=$( defaults read $plistFile PTLaunchAtLogin )
echo "PTLaunchAtLogin=$statusPTLaunchAtLogin"

if [[ $statusPTLaunchAtLogin -eq 1 ]]; then
	echo "[STATUS] Webex Meeting - Open at Login is enabled.  Preparing to disable open at login."
    
    # Close Webex Meetings after upgrade or installation
    if (ps aux | grep "Cisco Webex Meeting" | grep -v grep > /dev/null)
    then
        echo "[STATUS] Cisco Webex Meetings is RUNNING. Closing."
        closeRunningApp "Cisco Webex Meetings"
        echo "[STATUS] Cisco Webex Meetings is closed."
    else
        echo "[STATUS] STOPPED"
    fi

    # Pause for 3 seconds
    sleep 3

    # remove login item from current users account
    command=$( osascript -e 'tell application "System Events" to delete login item "Cisco Webex Meetings"' )

    #run command as user
    echo "[STATUS] Running command to remove login item for Cisco Webex Meetings."
    status=$( su "$currentuser" -c "$command" )
    if [[ -z $status ]]; then
      echo "[STATUS] Login Item for Cisco Webex Meetings has been successfully removed."
    else
      echo "[ERROR] $status"
      exit 1
    fi
else
	echo "[STATUS] Webex Meeting - Open at Login is disabled.  Nothing to do here."
fi


echo ""
echo "--End Program--"
echo ""
