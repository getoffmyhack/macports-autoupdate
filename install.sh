#!/bin/zsh

#------------------------------------------------------------------------------
#
# define vars
#
#------------------------------------------------------------------------------

# colors vars
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
cyan="\e[36m"
normal="\e[0m"

# text separation line
textline="-------------------------------------------------------------------------------"

# get width for display string field
((width=${COLUMNS}-5))

# launchdaemon vars
launchdaemon="org.macports.autoupdate"
launchdaemondir="/Library/LaunchDaemons"
launchdaemonfile="$launchdaemon.plist"
launchdaemonpath="$launchdaemondir/$launchdaemonfile"
launchdaemonbackup=FALSE

# autoupdate script vars
autoupdatedir="/usr/local/bin"
autoupdatefile="macports-autoupdate.zsh"
autoupdatepath="$autoupdatedir/$autoupdatefile"
autoupdatebackup=FALSE

# backup directory vars
backupdate=$(date +'%Y%m%d%H%M')
backupdirbase="/tmp"
backupdirtemplate="macports-autoupdate.$backupdate.XXXXX"

#------------------------------------------------------------------------------
#
# functions
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# notice <text> <color>
#
# prints <text> in <color>
#------------------------------------------------------------------------------
notice() {
  status_str="${2}$1${normal}"
  printf "%b" "$status_str"
}

#------------------------------------------------------------------------------
# check_file <filename> <message>
#
# displays messages w/o ending newline
# checks if <filename> exists -  a full path to the file
# returns 0 if found      - notice [Found]
# returns 1 if not found  - notice [Not Found]
#------------------------------------------------------------------------------
check_file() {
  
  # strip path from filename
  filename=$1:t
   
  #create display string + print
  string="$2 ${cyan}$filename${normal}"
  printf "%-${width}b" "$string"
  
  if [[ -f $1 ]]; then
    notice "[Found]\n" $green
    retval=0
  else
    notice "[Not Found]\n" $yellow
    retval=1
  fi

  return retval
}

#------------------------------------------------------------------------------
# check_valid_input <string> <regex>
#
# checks input <string> against <regex>
#------------------------------------------------------------------------------

check_valid_input() {
  [[ $1 =~ $2 ]]
}

#------------------------------------------------------------------------------
# install_file <destinationpath>
#
# extracts filename from destinationpath to copy 
# local file into dest directory
#------------------------------------------------------------------------------
install_file() {

  source=$1:t
  dest=$1

  printf "Installing: ${yellow}$source${normal} to ${yellow}$dest:h${normal}\n"
  cp $source $dest
}

#------------------------------------------------------------------------------
#
# Install
#
#------------------------------------------------------------------------------

###############################################################################
# 
# make sure install script is run as root
#

if [[ $EUID -ne 0 ]]; then
    notice "$0 needs to be run as the root user\n" $red
    exit 1
fi

###############################################################################
# 
# read email address and use regex to validate if proper format
# https://gist.github.com/guessi/82a73ee7eb2b1216eb9db17bb8d65dd1
#

emailregex="^(([A-Za-z0-9]+((\.|\-|\_|\+)?[A-Za-z0-9]?)*[A-Za-z0-9]+)|[A-Za-z0-9]+)@(([A-Za-z0-9]+)+((\.|\-|\_)?([A-Za-z0-9]+)+)*)+\.([A-Za-z]{2,})+$"
while [ "${EMAILVALID}" != "TRUE" ]
do 
  read  "?Enter your email address: " emailaddress
  printf "%-${width}b" "Checking address syntax: ${cyan}$emailaddress${normal}"
  if [ -z $emailaddress ]; then
    emailaddress=" "
  fi
  if check_valid_input $emailaddress $emailregex; then
    EMAILVALID="TRUE"
    notice "[Valid]\n" $green
  else
    notice "[Invalid]\n" $red
  fi
done

###############################################################################
# 
# read start hour and use regex to validate between 0 - 23
#

hourregex="^([0-9]|1[0-9]|2[0-3])$"
while [ "${HOURVALID}" != "TRUE" ]
do
  read "?Enter start hour (0-23)   - default 0: " starthour
  
  if [ -z $starthour ]; then
    starthour=0
  fi
  
  printf "%-${width}b" "Checking if valid hour entered: ${cyan}$starthour${normal}"
  
  if check_valid_input $starthour $hourregex; then
    HOURVALID="TRUE"
    notice "[Valid]\n" $green
  else
    notice "[Invalid]\n" $red
  fi

done

if [ $starthour -lt "10" ]; then
  displayhour="0$starthour"
else
  displayhour="$starthour"
fi

###############################################################################
# 
# read start minute and use regex to validate between 0 - 59
#

minregex="^([0-9]|[1-5][0-9])$"
while [ "$MINVALID" != "TRUE" ]
do

  read "?Enter start minute (0-59) - default 0: " startmin
  
  if [ -z $startmin ]; then
    startmin=0
  fi

  printf "%-${width}b" "Checking if valid minute entered: ${cyan}$startmin${normal}"

  if check_valid_input $startmin $minregex; then
    MINVALID="TRUE"
    notice "[Valid]\n" $green
  else
    notice "[Invalid]\n" $red
  fi
done

if [ $startmin -lt "10" ]; then
  displaymin="0$startmin"
else
  displaymin="$startmin"
fi

###############################################################################
# 
# check if macports is installed
#

portcommand=$(which port 2>/dev/null)
if [ $? -ne 0 ]; then
  notice "port command not found.  MacPorts reqired, exiting.\n" $red
  notice "Goto www.macports.org for more information.\n" $yellow
  exit 1
else 
  printf "%-${width}b" "Checking for macports: ${cyan}$portcommand${normal}"
  notice "[Found]\n" $green
fi

###############################################################################
# 
# check if files needed for install exist
#

check_file $autoupdatefile "Looking for install file: "
if [[ $? == 1 ]]; then
  notice "Install failed, exiting.\n" $red
  exit 1
fi

check_file $launchdaemonfile "Looking for install file: "
if [[ $? == 1 ]]; then
  notice "Install failed, exiting.\n" $red
  exit 1
fi

###############################################################################
# 
# check if launchdaemon plist already exist, if so, mark for backup
#

check_file $launchdaemonpath "Checking destination file:"
if [[ $? == 0 ]]; then
  launchdaemonbackup=TRUE
  createbackup=TRUE
fi

###############################################################################
# 
# check if autoupdate script already exits, if so, mark for backup
#

check_file $autoupdatepath "Checking destination file:"
if [[ $? == 0 ]]; then
  autoupdatebackup=TRUE
  createbackup=TRUE
fi

###############################################################################
# 
# create backup dir if needed
#

if [ "$createbackup" = "TRUE" ]; then
  printf "Creating backup directory: "
  backupdir=$(mktemp -d ${backupdirbase}/${backupdirtemplate})
  printf "${cyan}$backupdir${normal}\n"
else
  printf "Previous install not found: ${cyan}skipping backup${normal}\n"
fi

###############################################################################
# 
# Get final confirmation before installing
#

printf "\n"
printf "%b\n" $textline
printf "\n"
printf "Installion summary:\n\n"
printf "%-30b" "Notify email:  "
notice "[ $emailaddress ]\n" $yellow
printf "%-30b" "Update time:   "
notice "[ $displayhour:$displaymin ]\n" $yellow
printf "%-30b" "Create backup: "
notice "[ $createbackup ]\n" $yellow
if [ "$createbackup" = "TRUE" ]; then
  printf "%-30b" "Backup directory: "
  notice "$backupdir\n" $yellow
fi

printf "\n"
read "?Finalize Installation? [y/N]: " install

if [ -z $install ]; then
  install="n"
fi

if [[ ($install != "y" && $install != 'Y') ]]; then
  printf "\n${red}Exiting installation.${normal}\n"
  exit 1;
fi

printf "\n"
printf "%b\n" $textline
printf "\n"

###############################################################################
# 
# move launch daemon plist file to backup dir if needed
#

if [[ $launchdaemonbackup == TRUE ]]; then
  printf "Creating backup for file:  ${cyan}$launchdaemonpath:t${normal}\n"
  cp $launchdaemonpath $backupdir
fi

###############################################################################
# 
# move selfupdate script to backup dir if needed
#

if [[ $autoupdatebackup == TRUE ]]; then
  printf "Creating backup for file:  ${cyan}$autoupdatepath:t${normal}\n"
  cp $autoupdatepath $backupdir
fi

###############################################################################
# 
# if launchdaemon exists, unload from launchd
#

if [[ $launchdaemonbackup == TRUE ]]; then
  printf "Unloading previous launchdaemon: ${cyan}$launchdaemonfile${normal}\n"
  launchctl unload $launchdaemonpath
fi

###############################################################################
# 
# copy autoupdate script to dest
#

install_file $autoupdatepath
install_file $launchdaemonpath

###############################################################################
# 
# update email address in autoupdate script
#

printf "Configuring email address: ${cyan}$emailaddress${normal}\n"
sed -i '' "s/__EMAIL__/${emailaddress}/" $autoupdatepath

###############################################################################
# 
# update start hour and minute in org.macports.autoupdate.plist
#

printf "Configuring autoupdate start time: ${cyan}$displayhour:$displaymin${normal}\n"
sed -i '' "s/__HOUR__/${starthour}/;s/__MIN__/${startmin}/" $launchdaemonpath


###############################################################################
# 
# load launchdaemon
#
printf "Loading launchdaemon: ${cyan}$launchdaemonfile${normal}\n"
launchctl load $launchdaemonpath

printf "\n${green}Installation Complete.${normal}\n"
printf "%b\n" $textline
printf "\n"

