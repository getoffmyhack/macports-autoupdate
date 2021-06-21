# Macports Autoupdate

## Description

This script and accompanying launch daemon plist will setup [Macports](https://www.macports.org/) to auto update (port selfupdate) daily at a specific time of your choosing.


## Installation

🚨🚨🚨  WARNING!  THE INSTALL MUST BE RUN AS ROOT! 🚨🚨🚨

Please see the detailed description below to understand what is happening, but the TLDR version, it requires root for the following commands:
```
cp macports-autoupdate.zsh /usr/local/bin/
cp org.macports.autoupdate.plist /Library/LaunchDaemons/
launchctl load /Library/LaunchDaemons/org.macports.autoupdate.plist
```

To Install:

```
% git clone https://github.com/getoffmyhack/macports-autoupdate
% cd macports-autoupdate
% sudo ./install.sh
```

## Detailed Description

The script will perform the following tasks:

- Ask for an email address that will be used to send success / failure notifications upon completion.
    - **_In order to properly function, a working MTA must be configured on your Mac._**  
    - **_Please note: the email address is not collected in any manner and is only used in the autoupdate script!_**
- Ask for the hour and minute on which to run the script.
    - _The hour must be in 24 hour format ranging from 0 to 23._
    - _The minute must be in the range 0 to 59._
- Check that Macports is installed.
- Check that the install files exists in the current directory.
- Check to determine if the autoupdate script and plist file are already installed.
    - _If the script and/or plist files are already installed, a temp backup directory is created._
- Ask for final confirmation before completing the installation.

Once the final confirmation as been made, script will perform the installation tasks:

- Copy the previous script and plist to the backup directory if needed.
- Unload the current plist from launchd if needed.
- Copy the script file to `/usr/local/bin`
- Copy the plist file to `/Library/LaunchDaemons`
- Updates the autoupdate script with the email as entered.
- Updates the plist file with the start hour & minute
- Loads the launch daemon.

The autoupdate script will then run daily at the specified time and, upon completion, will email the results of the `port selfupdate` command.

If the command completes successfully, it will also run the `port outdated` command and include the results in the email.

Log files are also used via the launchd system, with STDERR output to `/var/log/org.macports.autoupdate.err` and STDOUT to `/var/log/org.macports.autoupdate.log`.

## Install Example

```
% sudo ./install.sh
Password:
Enter your email address: email@domain.com
Checking address syntax: email@domain.com                         [Valid]
Enter start hour (0-23)   - default 0: 1
Checking if valid hour entered: 1                                 [Valid]
Enter start minute (0-59) - default 0: 15
Checking if valid minute entered: 15                              [Valid]
Checking for macports: /opt/local/bin/port                        [Found]
Looking for install file:  macports-autoupdate.zsh                [Found]
Looking for install file:  org.macports.autoupdate.plist          [Found]
Checking destination file: org.macports.autoupdate.plist          [Found]
Checking destination file: macports-autoupdate.zsh                [Found]
Creating backup directory: /tmp/macports-autoupdate.202106211309.G2Nix

-------------------------------------------------------------------------------

Installion summary:

Notify email:                 [ email@domain.com ]
Update time:                  [ 01:15 ]
Create backup:                [ TRUE ]
Backup directory:             /tmp/macports-autoupdate.202106211309.G2Nix

Finalize Installation? [y/N]: y

-------------------------------------------------------------------------------

Creating backup for file:  org.macports.autoupdate.plist
Creating backup for file:  macports-autoupdate.zsh
Unloading previous launchdaemon: org.macports.autoupdate.plist
Installing: macports-autoupdate.zsh to /usr/local/bin
Installing: org.macports.autoupdate.plist to /Library/LaunchDaemons
Configuring email address: email@domain.com
Configuring autoupdate start time: 01:15
Loading launchdaemon: org.macports.autoupdate.plist

Installation Complete.
-------------------------------------------------------------------------------
```