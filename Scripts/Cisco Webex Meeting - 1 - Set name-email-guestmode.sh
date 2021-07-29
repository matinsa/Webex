#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# File Name: Cisco Webex Meeting - set name, email and guest mode.sh
#
# Description: set name, email and guest mode for current user's account when using webex.
# Written by: Matin Sasaluxanon
# Created on: Matin Sasaluxanon
last_updated="2021-07-28"
version=00.00.03
# Requirements:
#           - Jamf Pro
#           - macOS Clients running version 10.13 or later
#           - Cisco Webex Meeting
# Reference:
#           - http://hints.macworld.com/article.php?story=20111226075701552
#           - https://apple.stackexchange.com/questions/184764/how-do-i-disable-webex-assistant-on-startup-for-mac
#			- https://forums.macrumors.com/threads/terminal-variable-set-from-defaults-command.1354706/
#			- https://stackoverflow.com/questions/818255/in-the-shell-what-does-21-mean
#
# Version History:
#			2021-07-28 - 00.00.04
#           - added jamf parameter for email domain and conditiional to use local variable if jamf parameter is not set
#           - added last update variable and echo to screen/jamf log to easily see last update
#
#           2021-06-23 - 00.00.03
#           - fix check for currrent settings in webex plist
#           - add loop to check plist variables and set variables if missing
#
#           2021-04-29 - 00.00.02
#           - added condition checks to validate plist and value are not already set before apply setting to plist file
#
#           2021-04-29 - 00.00.01
#           - created script
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

#Jamf Parameter or use local variable if empty
emaildomain="${4}"
if [ -z "$emaildomain" ]; then
	emaildomain="" # example: pretendco.com
fi

#variable for storing the current users name
currentuser=$(ls -l /dev/console | awk '{ print $3 }')
realname="$(dscl . -read /Users/$currentuser RealName | cut -d: -f2 | sed -e 's/^[ \t]*//' | grep -v "^$")"

plistFile="/Users/$currentuser/Library/Preferences/com.cisco.webexmeetingsapp.plist"

echo ""
echo "--Start Program--"
echo "Last Update: $last_updated"
echo "Version: $version"
echo ""

if ! plutil -lint $plistFile; then
	echo "broken plist"
	exit 1
else
	plistVar_array=(
		"PTPlistIsGuestMode,true"
		"PTPlistDisplayName,$realname"
		"PTPlistUserName,$currentuser@$emaildomain"
	)

	for plistVar in "${plistVar_array[@]}"; do
		plistVarKey=$(echo "$plistVar" | cut -d ',' -f1)
		plistVarSetKey=$(echo "$plistVar" | cut -d ',' -f2)

		currentplistVar=$( defaults read $plistFile $plistVarKey )
		currentstatusplistVar=$( echo "$currentplistVar" 2>&1 | grep -E "( does not exist)$" )
		# Note: "2>&1" simply points everything sent to stderr, to stdout instead.

		if [[ -z $currentstatusplistVar ]]; then
			defaults write $plistFile $plistVarKey "$plistVarSetKey"
			echo "[STATUS] $plistVarKey set to $plistVarSetKey"
		else
			echo "[STATUS] $plistVarKey is already set to $currentplistVar"
		fi

	done
fi

# set file permissions
chown -R "$currentuser" "$plistFile"

echo ""
echo "--End Program--"
echo ""
