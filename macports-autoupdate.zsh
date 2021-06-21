#!/bin/zsh

# notification email address
emailaddress=__EMAIL__

# if DEVEL_EMAIL is set, use this email during development
if [[ -v DEVEL_EMAIL ]]; then
  printf "\n\e[36mUsing dev email: \e[33m${DEVEL_EMAIL}\e[0m\n\n"
  emailaddress=$DEVEL_EMAIL
fi

# load functions from rc.common to use CheckForNetwork
. /etc/rc.common

# text separation line
textline="#-------------------------------------------------------------------------"

# get current date + time
datetime=$(date "+Start: %Y-%m-%d %H:%M:%S")

# get local hostname
hostname=$(hostname -s)

# get the name of this script
scriptname=$(basename $0)

# use the script name to create a temp log file
logfilename=$(mktemp /tmp/${scriptname}.XXXXXX)

# create log file
printf "%s\n" $textline >> $logfilename
printf "\n%s\n\n" $datetime >> $logfilename

# wait for the network before running selfupdate
CheckForNetwork
while [ "${NETWORKUP}" != "-YES-" ]
do
      echo "Waiting for network." >> $logfilename
      sleep 5
      NETWORKUP=
      CheckForNetwork
done

# exec port selfupdate; redirect stderr & stdour to log file
/opt/local/bin/port selfupdate &>> $logfilename

# get exit status of port command
exitstatus=$?

# if exitstatus = 0; port selfupdate finished successfuly
if [ $exitstatus -eq 0 ]; then

  # create email subject
  subject="✅ Macports Update Successful: ${hostname}"

  # get list of outdated ports and append to logfile
  updates=$(/opt/local/bin/port outdated)
  printf "\n%s\n" $updates >> $logfilename

  # append stop time to logfile and finish with textline
  datetime=$(date "+Finish: %Y-%m-%d %H:%M:%S")
  printf "\n%s\n" $datetime >> $logfilename
  printf "\n%s\n" $textline >> $logfilename

  # output logfile to stdout for launchd to log
  cat $logfilename

 # exitstatus != 0; port selfupdate failed 
else

  # create email subject
  subject="❗️ Macports Update Failed: ${hostname}"

  # append stop time to logfile and finish with textline
  datetime=$(date "+Finish: %Y-%m-%d %H:%M:%S")
  printf "\n%s\n" $datetime >> $logfilename
  printf "\n%s\n" $textline >> $logfilename

  # output logfile to stderr for launchd to log
  cat $logfilename 1>&2
fi

# base64 encode subject for MTAs to handle emojis
b64subject="=?utf-8?B?$(echo -n ${subject} | /usr/bin/base64)?="

# send port command output to mail with success or fail subject
cat $logfilename | /usr/bin/mail -s $b64subject $emailaddress

# remove log file
rm $logfilename

# exit with status of port command
exit $exitstatus
