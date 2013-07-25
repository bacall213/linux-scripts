#!/bin/bash

#######################################################################
# UBUNTU UPDATER - Custom Ubuntu Updater Script
#######################################################################
#                                                                     #
#   Author:   Brian Call                                              #
#   License:  Free to use, distribute, and modify as necessary.       #
#                                                                     #
#######################################################################


#######################################################################
# UPDATER DOCUMENTATION
#######################################################################
# 
# Variables
#   Variable Name               Type    : SCOPE   : Description
#   -------------               ----      -----     -----------
#   OS_NICKNAME                 STRING  : GLOBAL  : Customize the OS name used
#   VERBOSE                     BOOL    : GLOBAL  : Enable verbosity
#   TEST                        BOOL    : GLOBAL  : Don't actually make any changes
#   FORCE                       BOOL    : GLOBAL  : Override self-preservation and 
#                                                   use --force-yes with apt-get
#   ASSUMEYES                   BOOL    : GLOBAL  : Assume "yes" for most prompts
#   APTOPTS                     STRING  : GLOBAL  : Store apt-get options
#   APTCMD                      STRING  : GLOBAL  : Store apt-get path
#   UPDATER_EXIT                INT     : GLOBAL  : Track exit code
#   STIME                       STRING  : LOCAL   : Start time for log
#   ETIME                       STRING  : LOCAL   : End time for log
#   FTIME                       STRING  : LOCAL   : Failure time for log
#   FAILMSG                     STRING  : LOCAL   : Failure message for log
#   DEBUG                       BOOL    : GLOBAL  : Debugging enabled/disabled
#   ALLARGS                     STRING  : GLOBAL  : Container for all arguments
#   KEEPLOGS                    BOOL    : GLOBAL  : Preserve this scripts' temp logs
#   LOGPATH                     STRING  : GLOBAL  : Log path in use
#   DLOGPATH                    STRING  : GLOBAL  : Default log path (/tmp)
#   BLOGPATH                    STRING  : GLOBAL  : Backup log path (~/)
#   UPDATELOG                   STRING  : GLOBAL  : apt-get update temp log
#   UPGRADELOG                  STRING  : GLOBAL  : apt-get upgrade temp log
#   
#
#
# APT flags
#   apt-get <CMD> -s                    :   Simulate; No action
#   apt-get <CMD> -q                    :   Quiet mode
#   apt-get <CMD> -y [--assume-yes]     :   Assume "yes"
#   apt-get <CMD> --force-yes           :   Force "yes"
#
#
# Updater flags
#   -v [--verbose]                      :   Verbose
#   -t [--test]                         :   Simulate/Test mode (no changes)
#   -update [--update]                  :   Update ONLY
#   -upgrade [--upgrade]                :   Upgrade ONLY
#   -f [--force-yes]                    :   Force "yes" (--force-yes)
# D -y [--yes|--assume-yes]             :   Assume "yes" (--assume-yes)*
#                                           * Not the same as --force-yes
#   -no-auto|--no-auto                  :   No automatic upgrades
#   -k [--keep-logs]                    :   Preserve logs**
#                                           ** Until next run of script
#   -h [--h|--help|?|/?]                :   Help!***
#                                           *** Any help flag will force 
#                                              script to show usage menu
#   -d [--d|--debug]                    :   Show additional debug comments
#
#   A note on the use of updater flags:
#     The only option that is generally desirable for apt-get update is 
#     whether or not you want it ot be quiet, so I only apply updater 
#     flags to apt-get [upgrade | dist-upgrade].
#
# Keeping log files
#   This script generates a few temporary log files when apt-get is executing. By 
#   default, these log files will be generated in /tmp and will be deleted after 
#   this script completes. Using -k or --keep-logs will not only prevent the deletion
#   of the log files, but it will also move the files to ~/. Additionally, the files 
#   will be set to:
#     owner=$USER
#     group=`cat /etc/group | grep $UID | cut -d ":" -f1`
#
#   
# Exit codes
#   0                                   :   Normal exit
#   1                                   :   Usage was called
#   2                                   :   apt-get update failed
#   3                                   :   apt-get dist-upgrade failed
#   4                                   :   `sudo` required
#   5                                   :   apt-get was not executable
#   6                                   :   User-opted exit from
#                                             --force-yes prompt
#   7                                   :   Default exit from
#                                             --force-yes prompt
#   8                                   :   Failure to write to log path
#   9                                   :   File ownership mod failed
#   10                                  :   Unexpected variable value
#   11                                  :   
#
#
# `sudo` requirement
#   Instead of coding every command in this script with `sudo`, this 
#   script must, instead, be executed with `sudo`. This means that 
#   the script location needs to be put in the path defined in the   
#   secure_path variable in /etc/sudoers, or the path you want it to   
#   be executed from must be added to secure_path variable in 
#   /etc/sudoers.
#
#   HINT: /etc/sudoers should be edited via `sudo visudo` - never 
#         directly.
#
#   HINT: View your current `sudo` settings with `sudo sudo -V`
#
# Functions
#   start_logging                  :  Start updater log
#   stop_logging                   :  Stop updater log
#   fail_logging                   :  Log failures to syslog and console
#   update_logging                 :  Log statuses to syslog and console
#   debug_logging                  :  Log debug info
#   check_logs_dir                 :  Ensure logs can be read/written
#   cleanup_logs                   :  Deletes/moves logs
#   usage                          :  Show script usage
#   check_force                    :  Check/confirm --force-yes
#   find_apt                       :  Find apt-get (for universal compat)
#   apt_update                     :  Run apt-get update
#   apt_upgrade                    :  Run apt-get dist-upgrade
#   
#
########################################################################


########################################################################
# VARIABLES
########################################################################
# OS_NICKNAME: Set this to customize the OS nickname used
OS_NICKNAME="Ubuntu";

# Uncomment the following to customize this script for Ubuntu running on a Chromebox/Chromebook (Croubuntu)
#OS_NICKNAME="Crobuntu";

# FLAG VARS
VERBOSE=false;
TEST=false;
FORCE=false;
ASSUMEYES=true;
DEBUG=false;
ALLARGS="";
KEEPLOGS=false;
UPDATEONLY=false;
UPGRADEONLY=false;

# APT-GET OPTIONS
APTOPTS="-q --assume-yes";

# APT-GET COMMANDLINE
# You can define the location for Apt here manually if you really want to. If everything works as intended, a function in this script will find it for you.
APTCMD="";

# LOGGING FLAGS
UPDATELOG="updater-update-log.txt";
UPGRADELOG="updater-upgrade-log.txt";
LOGPATH="";
DLOGPATH="/tmp";
BLOGPATH="~/";

# UPDATER EXIT CODE
UPDATER_EXIT=0;

########################################################################


########################################################################
# FUNCTION: START LOGGING
########################################################################
function start_logging()
{
  STIME=`date`;
  logger "[UPDATER STARTED] $OS_NICKNAME Updater has started at $STIME!";
  echo "[UPDATER STARTED] $OS_NICKNAME Updater has started at $STIME!";
  echo "";
}


########################################################################
# FUNCTION: STOP LOGGING
########################################################################
function stop_logging()
{
  ETIME=`date`;
  logger "[UPDATER FINISHED] $OS_NICKNAME Updater has completed at $ETIME with exit code $UPDATER_EXIT!";
  echo "";
  echo "[UPDATER FINISHED] $OS_NICKNAME Updater has completed at $ETIME with exit code $UPDATER_EXIT!";
}


########################################################################
# FUNCTION: FAIL LOGGING
########################################################################
function fail_logging()
{
  FTIME=`date`;
  FAILMSG=$1;
  UPDATER_EXIT=$2;

  logger "[UPDATER ERROR] $OS_NICKNAME Updater has failed at $FTIME due to \"$FAILMSG\" with exit code $UPDATER_EXIT!";
  echo "";
  echo -e "[UPDATER ERROR] $OS_NICKNAME Updater has \E[31mfailed\E[00m at $FTIME due to \"$FAILMSG\" with exit code $UPDATER_EXIT!";
}


########################################################################
# FUNCTION: UPDATE LOGGING
########################################################################
function update_logging()
{
  LTIME=`date`;
  LOGMSG=$1;

  logger "[UPDATER] $LOGMSG";
  echo "[UPDATER] $LOGMSG";
}


########################################################################
# FUNCTION: DEBUG LOGGING
########################################################################
function debug_logging()
{
  LOGMSG=$1;

  logger "[UPDATER DEBUG] $LOGMSG";
  echo "[UPDATER DEBUG] $LOGMSG";
}


########################################################################
# FUNCTION: CHECK LOG DIRECTORY
########################################################################
function check_logs_dir()
{
  # Log path = $LOGPATH (/tmp by default)
  # Default log = $DLOGPATH (/tmp)
  # Backup log path = $BLOGPATH (~/)

  if [[ -w $DLOGPATH ]]
  then
    # Logging to /tmp
    LOGPATH=$DLOGPATH;

    if [[ $KEEPLOGS == true ]]
    then
      update_logging "Logs will be in $LOGPATH."
    fi
  elif [[ -w $BLOGPATH ]]
  then
    # Logging to ~/
    LOGPATH=$BLOGPATH;
    
    if [[ $KEEPLOGS == true ]]
    then
      update_logging "Logs will be in $LOGPATH."
    fi
  else
    # /tmp and ~/ aren't writable?! ... bail out!
    UPDATER_EXIT=8;

    fail_logging "Logging is hard when you can't write. Go fish." $UPDATER_EXIT;
  fi
}


########################################################################
# FUNCTION: CLEANUP LOGS
########################################################################
function cleanup_logs()
{
  # Update log: updater-update-log.txt
  # Upgrade log: updater-upgrade-log.txt

  if [[ $KEEPLOGS == true ]]
  then
    if [[ $DEBUG == true ]]
    then
      # Display log status only if debugging
      debug_logging "Moving logs from $LOGPATH to ~/";
    else
      # Else, only update to the system log
      logger "[UPDATER] Moving logs from $LOGPATH to ~/";
    fi
    
    # Move logs from /tmp to ~/
    if [[ -e $LOGPATH/$UPDATELOG ]]
    then
      mv $LOGPATH/$UPDATELOG ~/;
    fi

    if [[ -e $LOGPATH/$UPGRADELOG ]]
    then
      mv $LOGPATH/$UPGRADELOG ~/;
    fi

    # Change ownership
    if [[ $DEBUG == true ]]
    then
      # Display log ownership status only if debugging
      debug_logging "Changing log file ownership.";
    else
      # Else, only output to system log
      logger "[UPDATER] Changing log file ownership.";
    fi
    UGROUP=`cat /etc/group | grep $SUDO_UID | cut -d ":" -f1`;

    if [[ -w ~/$UPDATELOG && -w ~/$UPGRADELOG ]]
    then
      chown $SUDO_USER:$UGROUP ~/$UPDATELOG;
      chown $SUDO_USER:$UGROUP ~/$UPGRADELOG;
    elif [[ -w ~/$UPDATELOG ]]
    then
      chown $SUDO_USER:$UGROUP ~/$UPDATELOG;
    elif [[ -w ~/$UPGRADELOG ]]
    then
      chown $SUDO_USER:$UGROUP ~/$UPGRADELOG;
    else
      UPDATER_EXIT=9;
      fail_logging "File ownership modification failed." $UPDATER_EXIT;
    fi

  else
    # Delete logs in /tmp
    if [[ $DEBUG == true ]]
    then
      # Display log status if debuggin
      debug_logging "Deleting logs";
    else
      # Else, only output to system log
      logger "[UPDATER] Deleting logs";
    fi

    if [[ -e $LOGPATH/$UPDATELOG ]]
    then
      rm $LOGPATH/$UPDATELOG;
    fi

    if [[ -e $LOGPATH/$UPGRADELOG ]]
    then
      rm $LOGPATH/$UPGRADELOG;
    fi

  fi
}


########################################################################
# FUNCTION: USAGE
########################################################################
function usage()
{
  # Set updater exit code
  UPDATER_EXIT=$1

  # Usage statement
  echo "USAGE: sudo $0 [OPTIONS]";
  echo "    -v|--v|--verbose        :   Verbose";
  echo "    -t|--t|--test           :   Simulate/Test mode (no changes)";
	echo "    -update|--update        :   Update ONLY";
	echo "    -upgrade|--upgrade      :   Upgrade ONLY";
  echo "    -no-auto|--no-auto      :   No automatic upgrades";
#  echo "    -y|--yes|--assume-yes   :   Assume \"yes\"";
  echo "    -f|--f|--force-yes      :   Force \"yes\" (USE WITH CAUTION!!)";
  echo "    -k|--keep-logs          :   Preserve logs";
  echo "    -h|--h|--help|?|/?      :   Display script help";
  echo "    -d|--d|--debug          :   Show additional debug comments";
  echo "";
  echo "    Detailed documentation can be found within the script.";
  echo "";

  # Logging never started - no need to stop it

  # Exit
  exit $UPDATER_EXIT;
}


########################################################################
# FUNCTION: FIND APT-GET ABSOLUTE PATH
########################################################################
function find_apt()
{
  # Find apt-get and verify it's executable
  if [[ -x `which apt-get` ]]
  then
    APTCMD=`which apt-get`;
    update_logging "Apt-get found at $APTCMD, continuing..."; 
  else
    # Set exit code
    UPDATER_EXIT=5;
    
    # Send update to syslog/console
    fail_logging "$APTCMD is not executable" $UPDATER_EXIT;

    # Exit with code 5
    exit 5;
  fi
}


########################################################################
# FUNCTION: CHECK FOR --FORCE-YES AND PROMPT IF FOUND 
########################################################################
function check_force()
{
  CHOICE="";

  if [[ `echo $APTOPTS | grep -o '\--force-yes'` == "--force-yes" ]]
  then
    update_logging "--force-yes was found in options. Check forced to ensure it was intended.";

    echo "";
    echo -ne "\E[31mYou've chosen to use \"--force-yes\" which can be destructive. Do you wish to continue [yes/NO]? \E[00m";
    read -t 30 CHOICE;
    
    # Line break for formatting
    echo "";
    
    # Process user choice
    case $CHOICE in
      n | N | no | NO)
        # Update logging
        update_logging "Always better to be safe than sorry, script will exit.";

        # User opted to exit, exit code 6
        UPDATER_EXIT=6;
        stop_logging;
        
        # stop_logging should handle the exit, but just in case
        exit $UPDATER_EXIT;
      ;;
      yes | YES)
        # Update logging
        update_logging "--force-yes confirmed. Continuing...";
      ;;
      *)
        update_logging "I didn't understand you. I'm assuming you meant to say \"NO\" and exiting.";

        # Choice was invalid, exit code 7
        UPDATER_EXIT=7;
        fail_logging "--force-yes prompt yielded invalid choice. Exiting." $UPDATER_EXIT;
        exit $UPDATER_EXIT;
      ;;
    esac
  fi
	# Returns to main if nothing is found
}


############################
# FUNCTION: APT-GET UPDATE #
############################
function apt_update()
{
	# Apt-get Update
	update_logging "Starting APT UPDATES!";

	# Clear current logs in /tmp
	if [[ -e $LOGPATH/$UPDATELOG ]]
	then
		rm $LOGPATH/$UPDATELOG;
	fi

	# Run `apt-get update`
	# Oputput to log and console if verbose, log only otherwise
	if [[ $VERBOSE == true ]]
	then
		$APTCMD update | while read line;
		  do
				# Send to syslog
		    logger "[UPDATER] $line";

				# Send to console and UPDATELOG
		    echo "[UPDATER] $line" | tee -a $LOGPATH/$UPDATELOG;
		  done

		# Apt-get update logging
		update_logging "APT UPDATE Complete";
	else
		$APTCMD update -q | while read line;
		  do
				# Send to syslog
		    logger "[UPDATER] $line";

				# Send to UPDATELOG only
		    echo "[UPDATER] $line" >> $LOGPATH/$UPDATELOG;
		  done

	fi

	# CATCH UPDATER SUCCESS/FAILURE
  if [[ $? -eq 0 ]]
	then
    if [[ $DEBUG == true ]]
    then
      debug_logging "APT UPDATE ($APTCMD) has completed.";
    else
		  update_logging "APT UPDATE has completed.";
    fi
		# Return to main (should hit apt_upgrade() next)
	else
		# Set update exit code to 2 (apt-get update failure)
		UPDATER_EXIT=2;

		# Call fail logging function (console and syslog)
		fail_logging "$APTCMD failure" $UPDATER_EXIT;
		
		# Exit with code 2 (apt-get update failure)
		exit $UPDATER_EXIT;
	fi
}



#############################
# FUNCTION: APT-GET UPGRADE #
#############################
function apt_upgrade()
{
  # Status message
  update_logging "Starting APT UPGRADES! This may take some time...";

	# Clear current logs in /tmp
	if [[ -e $LOGPATH/$UPGRADELOG ]]
	then
		rm $LOGPATH/$UPGRADELOG;
	fi

  # Blank line for console formatting
  echo "";

  # Run `apt-get dist-upgrade` with chosen flags
  # The output of `dist-upgrade` is important, don't bother trying to be quiet
  # -q flag not needed as it is not included in the APTOPTS variable
	$APTCMD dist-upgrade $APTOPTS | \
    tee -a $LOGPATH/$UPGRADELOG

  # CATCH UPDATER SUCCESS/FAILURE
  if [[ $? -eq 0 ]]
  then
    # Apt-get dist-upgrade has succeeded
    if [[ $DEBUG == true ]]
		then
      debug_logging "APT UPGRADE ($APTCMD) has completed.";
    else
      update_logging "APT UPGRADE has completed.";
    fi
		# Return to main (should cleanup logs next)
  else
    # Set update exit code to 3 (apt-get upgrade failure)
    UPDATER_EXIT=3;

    # Call fail logging function (console and syslog)
    fail_logging "$APTCMD failure" $UPDATER_EXIT;

    # Exit with code 3 (apt-get upgrade failure)
    exit $UPDATER_EXIT;
  fi


#############
# OLD CODE! #
#############
#  # Run `apt-get dist-upgrade` with chosen flags
#  # Handle verbose vs quiet
#  # -q flag not needed as it is or is not included in the APTOPTS variable
#  if [[ $VERBOSE == true ]]
#  then
#    $APTCMD dist-upgrade $APTOPTS | while read line;
#      do
#        # Catch prompt for upgrades
#        if [[ $line == "Do you want to continue [Y/n]" ]]
#        then
#          echo "upgrade ready, continue?";
#        else
#          echo "no upgrade, continue";
#        fi
#
#        # Log output to system log and updater log file
#        logger "[UPDATER] $line";
#        echo "[UPDATER] $line" | tee -a $LOGPATH/$UPGRADELOG;
#      done
#
#    # Apt-get status update
#    update_logging "APT UPGRADE Complete";
#  else
#    $APTCMD dist-upgrade $APTOPTS | while read line;
#      do
#        logger "[UPDATER] $line";
#        echo "[UPDATER] $line" >> $LOGPATH/$UPGRADELOG;
#      done
#
#    # Apt-get status update
#    update_logging "APT UPGRADE Complete";
#  fi

#    # This is problematic if there's an upgrade... apt-get waits in limbo 
#    #   for a user response that won't come since the user can't see 
#    #   the prompt.
#    #
#    #   cmd | tee $logfiles works, but we lose the [UPDATER] append
#    #
#    #   NEEDS FIXING!
#    #
#    # PAUSE UPGRADE FUNCTION...
#    #
#    echo "UPGRADE function is paused for debugging...";
#    #$APTCMD dist-upgrade $APTOPTS > $LOGPATH/$UPGRADELOG 2>&1;
#
#    # Check for logs before displaying in verbose mode
#    #   This handles errors caused by pausing log-creating functions
#    if [[ -e $LOGPATH/$UPGRADELOG ]]
#    then
#
#      while read line
#      do
#        LOGLINE=`echo -en "[UPDATER] "``echo -en $line "\n"`;
#        logger $LOGLINE;
#        echo $LOGLINE;
#
#      done < $LOGPATH/$UPGRADELOG
#    fi
#
#    # Status
#    update_logging "APT UPGRADE Complete";
#  else
#    echo "UPGRADE function is paused for debugging...";
#    #$APTCMD dist-upgrade $APTOPTS > $LOGPATH/$UPGRADELOG 2>&1;
#
#    if [[ -e $LOGPATH/$UPGRADELOG ]]
#    then
#   
#      while read line
#      do
#        LOGLINE=`echo -en "[UPDATER] "``echo -en $line "\n"`;
#        logger $LOGLINE;
#
#      done < $LOGPATH/$UPGRADELOG
#    fi
#
#    # Status
#    update_logging "APT UPGRADE Complete";
#  fi
}


########################################################################
# MAIN
########################################################################


####################
# MAIN: PARSE ARGS #
####################

# Parse arguments if > 0, otherwise exit
if [[ $# -ge 0 && "$(whoami)" == "root" ]]
then
  ALLARGS=$@;

  # Parse the arguments
  for OPT in $@
  do
  case $OPT in
    --debug | -d | --d)
      DEBUG=true;
      ;;
    --verbose | -v | --v)
      VERBOSE=true;

      # Use a particularly brutal approach to removing the "-q"
      APTOPTS=`echo $APTOPTS | sed -r s/-q//`;
      ;;
    --update | -update)
      UPDATEONLY=true;
      ;;
    --upgrade | -upgrade)
      UPGRADEONLY=true;
      ;;
    --test | -t | --t)
      TEST=true;
      APTOPTS="$APTOPTS -s";
      ;;
    --assume-yes | -y | --yes)
      ## DEPRECATED ##
      ASSUMEYES=true;
      APTOPTS="$APTOPTS --assume-yes";
      ;;
    --force-yes | -f | --f)
      FORCE=true;
      APTOPTS="$APTOPTS --force-yes";
      ;;
    --keep-logs | -k)
      KEEPLOGS=true;
      ;;
    --help | -h | --h | ? | /?)
      # Send update to syslog
      logger "[UPDATER] $OS_NICKNAME Updater called with HELP flag. Showing usage and exiting."

      # Help key, show usage and exit 1
      UPDATER_EXIT=1;
      usage $UPDATER_EXIT;
      ;;
    *)
      # Send update to syslog
      logger "[UPDATER] Invalid flag detected (flag = $OPT).";

      # Invalid option, show usage and exit 1
      echo "";
      echo -e "\E[31mAhoy there captain, you're flying the wrong flag (flag = $OPT). Try again. \E[00m";
      echo "";
      UPDATER_EXIT=1;
      usage $UPDATER_EXIT;
      ;;
  esac
  done
else
  # Not root
  echo "";
  echo -e "\E[31mMagic 8-ball says \"Root is required.\" Try running this with \`sudo\` \E[00m";
  echo "";

  # Send update to syslog
  logger "[UPDATER] $OS_NICKNAME Updater requires root privileges. Try running this with \`sudo\`";

  # Set exit code to 4 and call usage function. See documentation for more exit codes.
  UPDATER_EXIT=4;
  usage $UPDATER_EXIT;
fi


###################
# MAIN: DEBUGGING #
###################
if [[ $DEBUG == true ]]
then
  debug_logging "Arguments: $ALLARGS";
  debug_logging "Verbose? $VERBOSE";
  debug_logging "Test? $TEST";
  debug_logging "Assume yes? $ASSUMEYES";
  debug_logging "Force? $FORCE";
  debug_logging "Keep logs? $KEEPLOGS";
  debug_logging "Update only? $UPDATEONLY";
  debug_logging "Upgrade only? $UPGRADEONLY";
  debug_logging "Apt-Get Options? $APTOPTS";
fi


#######################
# MAIN: START LOGGING #
#######################
start_logging;


#######################################
# MAIN: CHECK FOR FORCE-YES -- PROMPT #
#######################################
check_force;


######################################
# MAIN: VERIFY APT-GET IS EXECUTABLE #
######################################
find_apt;


###################
# MAIN: DEBUGGING #
###################
if [[ $DEBUG == true ]]
then
  # Apt-get should be found by now, show the path
  debug_logging "Apt-Get command? $APTCMD";
fi


###############################
# MAIN: CHECK LOG DESTINATION #
###############################
check_logs_dir;


################
# MAIN: UPDATE #
################
# Only call the update function if $UPGRADEONLY is false
if [[ $UPGRADEONLY == false ]]
then
  apt_update;
elif [[ $UPGRADEONLY == true ]]
then
	update_logging "APT UPDATE skipped!";
else
	# Set exit code
	UPDATER_EXIT=10;

	# Log useful info
	fail_logging "Something was lost in translation. UPGRADEONLY value ($UPGRADEONLY) isn't what I expected it to be." $UPDATER_EXIT;

	# Exit
  exit $UPDATER_EXIT;
fi


#################
# MAIN: UPGRADE #
#################
# Only call the upgrade function if $UPDATEONLY is false
if [[ $UPDATEONLY == false ]]
then
  apt_upgrade;
elif [[ $UPDATEONLY == true ]]
then
	update_logging "APT UPGRADE skipped!"
else
	# Set exit code
	UPDATER_EXIT=10;

	# Log useful info
	fail_logging "Something was lost in translation. UPDATEONLY value ($UPDATEONLY) isn't what I expected it to be." $UPDATER_EXIT;

	# Exit
  exit $UPDATER_EXIT;
fi


#####################
# MAIN: LOG CLEANUP #
#####################
cleanup_logs;


##########################
# MAIN: SET UPDATER EXIT #
##########################
UPDATER_EXIT=0;


######################
# MAIN: STOP LOGGING #
######################
stop_logging;

##############################################
# MAIN: RESET TERMINAL COLORS (JUST IN CASE) #
##############################################
echo -e "\E[00m";


########################################################################
