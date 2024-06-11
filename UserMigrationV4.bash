#!/bin/bash

####################################################################################################
#
# Display Message via swiftDialog
#
# Purpose: Displays an end-user message via swiftDialog
# See: https://snelson.us/2023/03/display-message-0-0-7-via-swiftdialog/
#                                                                                                                                                  
####################################################################################################

####################################################################################################
#
# Variables
#
####################################################################################################

scriptVersion="0.0.10"
scriptLog="/var/tmp/org.churchofjesuschrist.log"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
osVersion=$( sw_vers -productVersion )
osMajorVersion=$( echo "${osVersion}" | awk -F '.' '{print $1}' )
dialogBinary="/usr/local/bin/dialog"
dialogMessageLog=$( mktemp /var/tmp/dialogWelcomeLog.XXX )
if [[ -n ${4} ]]; then titleoption="--title"; title="${4}"; fi
if [[ -n ${5} ]]; then messageoption="--message"; message="${5}"; fi
if [[ -n ${6} ]]; then iconoption="--icon"; icon="${6}"; fi
if [[ -n ${7} ]]; then button1option="--button1text"; button1text="${7}"; fi
if [[ -n ${8} ]]; then button2option="--button2text"; button2text="${8}"; fi
extraflags="${10}"
action="${11}"

power=0
completion=1

# Create `overlayicon` from Self Service's custom icon (thanks, @meschwartz!)
xxd -p -s 260 "$(defaults read /Library/Preferences/com.jamfsoftware.jamf self_service_app_path)"/Icon$'\r'/..namedfork/rsrc | xxd -r -p > /var/tmp/overlayicon.icns
overlayicon="/var/tmp/overlayicon.icns"

# Default icon to Jamf Pro Self Service if not specified
if [[ -z ${icon} ]]; then
    iconoption="--icon"
    icon="/var/tmp/overlayicon.icns"
fi

####################################################################################################
#
# Pre-flight Checks
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Script Logging Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# Display Message via swiftDialog (${scriptVersion})\n###\n"
updateScriptLog "PRE-FLIGHT CHECK: Initiating …"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Operating System
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${osMajorVersion}" -ge 11 ]] ; then
    updateScriptLog "PRE-FLIGHT CHECK: macOS ${osMajorVersion} installed; proceeding ..."
else
    updateScriptLog "PRE-FLIGHT CHECK: macOS ${osVersion} installed; exiting."
    osascript -e 'display dialog "Display Message via swiftDialog ('"${scriptVersion}"')\rby Dan K. Snelson (https://snelson.us)\r\rmacOS '"${osVersion}"' installed; macOS Big Sur 11\r(or later) required" buttons {"OK"} with icon caution with title "Display Message via swiftDialog: Error"'
    exit 1
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate / install swiftDialog (Thanks big bunches, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogCheck() {

    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl -L --silent --fail "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"

    # Check for Dialog and install if not found
    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then

        updateScriptLog "PRE-FLIGHT CHECK: Dialog not found. Installing..."

        # Create temporary working directory
        workDirectory=$( /usr/bin/basename "$0" )
        tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

        # Download the installer package
        /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"

        # Verify the download
        teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

        # Install the package if Team ID validates
        if [[ "$expectedDialogTeamID" == "$teamID" ]]; then

            /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
            sleep 2
            dialogVersion=$( /usr/local/bin/dialog --version )
            updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version ${dialogVersion} installed; proceeding..."

        else

            # Display a so-called "simple" dialog if Team ID fails to validate
            osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "Display Message via Dialog: Error" buttons {"Close"} with icon caution'
            quitScript "1"

        fi

        # Remove the temporary working directory when done
        /bin/rm -Rf "$tempDirectory"

    else

        updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version $(${dialogBinary} --version) found; proceeding..."

    fi

}

if [[ ! -e "/Library/Application Support/Dialog/Dialog.app" ]]; then
    dialogCheck
else
    updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version $(${dialogBinary} --version) found; proceeding..."
fi

####################################################################################################
#
# Functions
#
####################################################################################################

# Quit Script (thanks, @bartreadon!)
function quitScript() {
    updateScriptLog "Quitting …"
    echo "quit:" >> "${dialogMessageLog}"

    sleep 1
    updateScriptLog "Exiting …"

    # Remove dialogMessageLog
    if [[ -f ${dialogMessageLog} ]]; then
        updateScriptLog "Removing ${dialogMessageLog} …"
        rm "${dialogMessageLog}"
    fi

    # Remove overlayicon
    if [[ -f ${overlayicon} ]]; then
        updateScriptLog "Removing ${overlayicon} …"
        rm "${overlayicon}"
    fi

    updateScriptLog "Goodbye!"
    exit "${1}"
}

# Draws initial dialog (Created by JAJ)
function drawDialog() {
    UI=$(
    ${dialogBinary} \
        ${titleoption} "${title}" \
        ${messageoption} "${message}" --alignment center\
        ${iconoption} "${icon}" \
        --centericon \
        ${button1option} "${button1text}" \
        ${button2option} "${button2text}" \
        --buttonstyle center \
        --messagefont "size=14" \
        --commandfile "${dialogMessageLog}" \
        ${extraflags}
    )

    returncode=$?

    if [[ $returncode == 10 ]]; then
        quitScript "0"
    fi
}

# Checks machine is connected to AC power (Created by JAJ)
function checkPower() {
    [[ $(pmset -g ps|grep "AC Power") ]] && state="AC" || state="BATT"
    
    if [[ $state == "AC" ]]; then
        power=1
    elif [[ $state == "BATT" ]]; then
        power=0
        ${dialogBinary} \
            --style "alert" \
            --title "ERROR!" \
            --centreicon \
            --messagealignment center \
            --buttonstyle center \
            ${button1option} "Back" \
            ${button2option} "Cancel" \
            ${iconoption} caution \
            --message "Please connect device to a power source!"

        returncode=$?
        updateScriptLog "checkPower - Return Code: ${returncode}"

        if [[ $returncode == 2 || $returncode == 10 ]]; then
            quitScript "0"
        fi
    fi 
}

# Compares sizes of both directorys and ensures destination has enough space (Created by JAJ)
function compareSizes() {
    local srcDir=$1
    local destDir=$2

    srcDirSize=$(du -sk "$1" | awk '{print $1}') 
    destDirSize=$(df -k "$2" | awk 'NR==2 {print $4}')

    updateScriptLog "Src size: ${srcDirSize}k | $((srcDirSize/1048576))gb"
    updateScriptLog "Dest size: ${destDirSize}k | $((destDirSize/1048576))gb"

    if [[ $srcDirSize -gt $destDirSize ]]; then
        ${dialogBinary} \
            --style "alert" \
            --title "ERROR!" \
            --centreicon \
            --messagealignment center \
            --buttonstyle center \
            ${button1option} "Cancel" \
            ${iconoption} warning \
            --message "Source directory is bigger than free space on the destination!"

        returncode=$?
        updateScriptLog "compareSizes - Return Code: ${returncode}"

        if [[ $returncode == 0 || $returncode == 10 ]]; then
            quitScript "0"
        fi
    fi
}

# "Before" part of transfer, used for saving data to external drive (Created by JAJ)
function beforeTransfer() {
    updateScriptLog "beforeTransfer - ${loggedInUser} clicked ${button2text};"
    completion=0
    UI=$(
    ${dialogBinary} \
        ${titleoption} "${title}" \
        ${messageoption} "This will backup the user's data \n- Source Directory: Client's user folder \n- Destination Directory: Folder on external drive" \
        ${iconoption} "${icon}" \
        ${button1option} "Continue" \
        ${button2option} "Cancel" \
        --textfield "Source Directory, fileselect, filetype=folder, required" \
        --textfield "Destination Directory, fileselect, filetype=folder, required" \
        --buttonstyle center \
        --messagefont "size=14" \
        --commandfile "${dialogMessageLog}" \
        ${extraflags}
    )
    
    returncode=$?
    updateScriptLog "beforeTransfer - Return Code: ${returncode}"

    case ${returncode} in 
    0)
        srcDir=$(echo "$UI" | awk -F 'Source Directory : ' '{print $2}')
        destDir=$(echo "$UI" | awk -F 'Destination Directory : ' '{print $2}' | tr -d '\n')          
        count=0           

        #Check to make sure both directories exist
        if [ -d "${srcDir}" ] && [ -d "${destDir}" ]; then
            ${dialogBinary} \
                --small \
                --centreicon \
                --messagealignment center \
                --title "Working..." \
                --button1disabled \
                ${iconoption} "${icon}" \
                --commandfile "${dialogMessageLog}" \
                --message "Your transfer is starting..  \nPlease wait!" & sleep 0.1

            updateScriptLog "beforeTransfer - ${loggedInUser} entered ${srcDir} and ${destDir};"

            compareSizes "$srcDir" "$destDir"

            output=$(rsync -avr --dry-run --stats --exclude='Library/CloudStorage' "$srcDir" "$destDir")
            total_files=$(echo "$output" | wc -l)

            /bin/echo "quit:" >> "${dialogMessageLog}"

            ${dialogBinary} \
                --title "Transfer in progress..." \
                --message "Please wait while the transfer completes  \n\n Files to be transferred: ${total_files}" \
                ${iconoption} "${icon}" \
                ${button1option} "Cancel" \
                --blurscreen \
                --button1disabled \
                --centreicon \
                --messagealignment center \
                --progress ${total_files} \
                --commandfile "${dialogMessageLog}" & sleep 0.1

            while IFS= read -r line; do
                ((count++))
                percentage=$(expr $count \* 100 / $total_files)
                /bin/echo "progress: ${count}" >> "${dialogMessageLog}"
                /bin/echo "progresstext: ${percentage}% / 100%" >> "${dialogMessageLog}"
            done < <(rsync -avr --stats --no-perms --exclude='Library/CloudStorage' "$srcDir/" "$destDir")

            /bin/echo "quit:" >> "${dialogMessageLog}"
            ${dialogBinary} \
                --style "alert" \
                --title "Finished!" \
                ${iconoption} "${icon}" \
                --message "Your transfer has completed!"
            killall caffeinate

        else    
            updateScriptLog "beforeTransfer - User did not enter a directory!"
            completion=1
            ${dialogBinary} \
                --style "alert" \
                --title "ERROR!" \
                --centreicon \
                --messagealignment center \
                ${button1option} "Back" \
                ${iconoption} "${icon}" \
                --message "Please enter a valid directory!"
        fi
        ;;
        
    2)
        updateScriptLog "beforeTransfer - ${loggedInUser} clicked Cancel;"
        quitScript "0"
    ;;
    esac
}

# "After" part of transfer, used for restoring a user's data (Created by JAJ)
function afterTranfer() {
    updateScriptLog "afterTranfer - ${loggedInUser} clicked ${button1text};"     

    UI=$(
    ${dialogBinary} \
        ${titleoption} "${title}" \
        ${messageoption} "This will restore the user's data \n- Standard Library Files includes (if found): Safari, Chrome, Mozilla, Thunderbird, and the MacOS Dock" \
        ${iconoption} "${icon}" \
        --height "325" \
        --textfield "Source Directory, fileselect, filetype=folder, required" \
        --textfield "Client NetID, required" \
        --checkbox "Include Standard Library Files" \
        ${button1option} "Continue" \
        ${button2option} "Cancel" \
        --messagefont "size=14" \
        --commandfile "${dialogMessageLog}" \
        ${extraflags}
    )

    returncode=$?
    updateScriptLog "afterTransfer - Return Code: ${returncode}"

    case ${returncode} in 
    0)
        srcDir=$(echo "$UI" | awk -F 'Source Directory : ' '{print $2}')
        username=$(echo "$UI" | awk -F 'Client NetID : ' '{print $2}' | tr -d '\n')

        destDir="/Users/${username}"

        checkboxValue=$(echo "$UI" | awk -F'\"' '/Include Standard Library Files/ {print $4}')

        #Check to make sure both directories exist
        if [ -d "${srcDir}" ] && [ -d "${destDir}" ]; then
            ${dialogBinary} \
                --small \
                --centreicon \
                --messagealignment center \
                --title "Working..." \
                --button1disabled \
                ${iconoption} "${icon}" \
                --commandfile "${dialogMessageLog}" \
                --message "Your transfer is starting..  \nPlease wait!" & sleep 0.1

            updateScriptLog "afterTranfer - ${loggedInUser} entered ${srcDir} and ${destDir};"

            compareSizes "$srcDir" "$destDir"

            completion=0
            count=0
            output=$(rsync -avr --exclude='Library' --dry-run --stats "$srcDir/" "$destDir")
            /bin/echo "quit:" >> "${dialogMessageLog}"
            number_of_files=$(echo "$output" | wc -l)
            real_number_of_files=$(echo "$output" | grep -o "Number of files transferred: [0-9]*" | awk '{print $5}')
            ${dialogBinary} \
                --title "Transfer in progress..." \
                --message "Please wait while the transfer completes  \n\n Files to be transferred: ${real_number_of_files}" \
                ${iconoption} "${icon}" \
                ${button1option} "Cancel" \
                --blurscreen \
                --button1disabled \
                --centreicon \
                --messagealignment center \
                --progress ${number_of_files} \
                --commandfile "${dialogMessageLog}" & sleep 0.1

            #While loop to run rsync and calculate percentage complete
            caffeinate -dis &
            while IFS= read -r line; do
                ((count++))
                percentage=$(expr $count \* 100 / $number_of_files)
                /bin/echo "progress: ${count}" >> "${dialogMessageLog}"
                /bin/echo "progresstext: ${percentage}% / 100%" >> "${dialogMessageLog}"
            done < <(rsync -avr --exclude='Library' --stats --no-perms "$srcDir/" "$destDir") 

            #Adding all standard Library files if checkbox is selected
            if [[ $checkboxValue == "true" ]]; then 
            /bin/echo "progresstext: Adding final library files..." >> "${dialogMessageLog}"
                if [[ -d  "$srcDir/Library/Safari" ]]; then
                    rsync -avr "$srcDir/Library/Safari" "$destDir/Library/"
                    updateScriptLog "Found Safari, adding library files..."
                fi
                if [[ -d  "$srcDir/Library/Thunderbird" ]]; then
                    rsync -avr "$srcDir/Library/Thunderbird" "$destDir/Library/"
                    updateScriptLog "Found Thunderbird, adding library files..."
                fi
                if [[ -d  "$srcDir/Library/Application Support/Firefox" ]]; then
                    rsync -avr "$srcDir/Library/Application Support/Firefox" "$destDir/Library/Application Support/"
                    updateScriptLog "Found Firefox, adding library files..."
                fi
                if [[ -d  "$srcDir/Library/Application Support/Google" ]]; then
                    rsync -avr "$srcDir/Library/Application Support/Google" "$destDir/Library/Application Support/"
                    updateScriptLog "Found Google, adding library files..."
                fi
                if [[ -f  "$srcDir/Library/Preferences/com.apple.dock.plist" ]]; then
                    rsync -avr "$srcDir/Library/Preferences/com.apple.dock.plist" "$destDir/Library/Preferences/"
                    updateScriptLog "Found Dock, adding library files..."
                    sudo -u $loggedInUser killall Dock
                fi                                                           
            fi

            #Setting permissions of all sub-folders under the User's directory
            /bin/echo "progresstext: Fixing permissions..." >> "${dialogMessageLog}"
            /bin/chmod -R -N /Users/$username
            /usr/bin/chflags -R nouchg /Users/$username
            /usr/sbin/chown -R "$username":"staff" $destDir
            updateScriptLog "Setting rwxr--r-- permission for Owner, Read for Everyone for everything under /Users/$username..."
			sudo chmod -R 755 /Users/$username/

			if [ -d /Users/$username/Desktop/ ]; then
				updateScriptLog "Setting rwx permission for Owner, None for Everyone for /Users/$username/Desktop..."
				sudo chmod 700 /Users/$username/Desktop/
			fi

			if [ -d /Users/$username/Documents/ ]; then
				updateScriptLog "Setting rwx permission for Owner, None for Everyone for /Users/$username/Documents..."
				sudo chmod 700 /Users/$username/Documents/
			fi

			if [ -d /Users/$username/Downloads/ ]; then
				updateScriptLog "Setting rwx permission for Owner, None for Everyone for /Users/$username/Downloads..."
				sudo chmod 700 /Users/$username/Downloads/
			fi

			if [ -d /Users/$username/Library/ ]; then
				updateScriptLog "Setting rwx permission for Owner, None for Everyone for /Users/$username/Library..."
				sudo chmod 700 /Users/$username/Library/
			fi

			if [ -d /Users/$username/Movies/ ]; then
				updateScriptLog "Setting rwx permission for Owner, None for Everyone for /Users/$username/Movies..."
				sudo chmod 700 /Users/$username/Movies/
			fi

			if [ -d /Users/$username/Music/ ]; then
				updateScriptLog "Setting rwx permission for Owner, None for Everyone for /Users/$username/Music..."
				sudo chmod 700 /Users/$username/Music/
			fi

			if [ -d /Users/$username/Pictures/ ]; then
				updateScriptLog "Setting rwx permission for Owner, None for Everyone for /Users/$username/Pictures..."
				sudo chmod 700 /Users/$username/Pictures/
			fi

            # If the Public folder exists in /Users/$username/, give it it's special permissions
            if [ -d /Users/$username/Public/ ]; then
                updateScriptLog "Setting Read only access for Everyone to /Users/$username/Public/..."
                sudo chmod -R 755 /Users/$username/Public
                # If the Drop Box folder exists in /Users/$username/, give it it's special permissions
                if [ -d /Users/$username/Public/Drop\ Box/ ]; then
                    updateScriptLog "Drop Box folder found, setting Write only access for Everyone to /Users/$username/Public/Drop Box/..."
                    sudo chmod -R 733 /Users/$username/Public/Drop\ Box/
                fi
            fi

            /bin/echo "quit:" >> "${dialogMessageLog}"
            ${dialogBinary} \
                --style "alert" \
                --title "Finished!" \
                ${iconoption} "${icon}" \
                --message "Your transfer has completed!"
            killall caffeinate

        else 
            updateScriptLog "afterTranfer - User did not enter a directory!"
            completion=1
            ${dialogBinary} \
                --style "alert" \
                --title "ERROR!" \
                --centreicon \
                --messagealignment center \
                ${button1option} "Back" \
                ${iconoption} "${icon}" \
                --message "Please enter a valid directory!"
        fi
    ;;

    2)
        updateScriptLog "afterTranfer - ${loggedInUser} clicked Cancel;"
        quitScript "0"
    ;;
    esac
}

####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Script Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

width=20

if [[ -z "${title}" ]] || [[ -z "${message}" ]]; then

    extraflags="--width 600 --height 300 --moveable --position middle --titlefont size=26 --messagefont size=13 --iconsize 125 /var/tmp/overlayicon.icns"
    #--width 825 --height 400 --moveable --timer 75 --position topright --blurscreen --titlefont size=26 --messagefont size=13 --iconsize 125 --overlayicon /var/tmp/overlayicon.icns --quitoninfo

    titleoption="--title"
    title="User Migration V4"

    messageoption="--message"
    message="Please choose from the following: \n- Before Imaging: Is to **copy** the **user's folder** to an **external drive** \n- After Imaging: Is to **restore** the **user's data** after imaging"

    button1option="--button1text"
    button1text="After"

    button2option="--button2text"
    button2text="Before"

else

    updateScriptLog "Both \"title\" and \"message\" Parameters are populated; proceeding ..."

fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Message: Dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Main program
while [ $completion == 1 ]; do
    completion=0

    drawDialog

    #Checking machine is connected to power source
    while [ $power == 0 ]; do
        checkPower
        if [[ $power == 0 ]]; then
            drawDialog
        fi
    done

    case ${returncode} in
    0)  # Process exit code 0 scenario here (After)
        afterTranfer
    ;;

    2)  # Process exit code 2 scenario here (Before)
        beforeTransfer
    ;;

    20) # Process exit code 20 scenario here (DND)
        updateScriptLog "${loggedInUser} had Do Not Disturb enabled"
        quitScript "0"
    ;;

    *)  # Catch all processing (Other occurances)
        updateScriptLog "Something else happened; Exit code: ${returncode};"
        quitScript "${returncode}"
    ;;
    esac
done

updateScriptLog "End-of-line."
quitScript "0"