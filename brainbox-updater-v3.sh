#!/bin/bash

##############################################################################
# BRAINBOX UPDATER - Powerful Ubuntu Updater for the Masses
##############################################################################
#
# AUTHOR: Brian Call
# SOURCE: https://github.com/bacall213
# LICENSE: MIT
#
# GOALS:
#   - Automate the Ubuntu updater process
#   - Provide powerful features for systems administrators
#   - Default functionality should be simple enough for home users
#
# TESTED PLATFORMS:                                                
#   - Ubuntu 12.04 LTS (64-bit)
#   - Ubuntu 14.04 LTS (64-bit)
#                                                                   
# REQUIRED PACAKGES:
#   - notify-osd
#     - Provides
#         - /usr/bin/notify-send
#         - /usr/lib/notify-osd/* 
#
# FILES:
#   - brainbox-updater-v3.sh (this script)
#
# KNOWN ISSUES (KI):
#   - Nothing to report at this time
#
# CONVENTIONS USED:
#   - APT acquire: Update package repositories (apt-get update)
#   - APT install: Install updates (apt-get dist-upgrade)
#   - Versioning standard: 
#     - v[major_version].[month].[year]-b[build_num]
#     - e.g. v1.1.2014-b20 = Major version 1, January 2014, build 20
#
# REVISION HISTORY:
#   - v1.2.2015-b1
#     - 80 char/line cleanup
#     - Removed appended text on the front of apt-get output (inefficient)
#     - Replaced all 'echo' statements with 'printf'
#     - Added ability for logger to accept messages longer than 1 line
#
#   - v1.8.2014-b2:
#     - Moved to single log file 
#       - Filename: brainbox_updater_<date>.txt
#       - Added seconds into log file name
#       - Removed deletion of existing logs from apt-get functions
#         - No longer necessary as it's unlikely the script will be executed
#           more than once within a 1-second period.
#     - Moved more logging to conform to "debug<1-4>" standard
#     - Moved time variables to global for simplicity
#     - General cleanup
#
#   - v1.8.2014-b1: 
#     - Initial public release
#
# TODO:
#   1) [DONE] Create single "logging" function that will handle:
#       - update logging (replaces 'update_logging')
#       - debug logging (replaces 'debug_logging')
#       - startup logging (replaces 'start_logging')
#       - failure logging (replaces 'fail_logging')
#       - shutdown (stop) logging (replaces 'stop_logging')
#       
#     Requirements:
#       - Management of start/stop timestamps
#       - Check for $gui flag
#       - Check for $DEBUG flag
#       - Handle error codes passed into it
#       - Handle log type (update, debug, start, stop, fail) 
#       - Handle logging if-else logic (accept >= 1 logging message)
#         - e.g. if debug logging, output this, else, output that
#   2) [DONE] Build a better argument parsing system
#       - To resolve KI #1 and KI #2
#   3) [DONE] Fix versioning prior to release
#   4) Re-write variables/functions to conform to Google code
#         standards.
#   5) Update internal documentation
#   6) Fix GUI "long-line" continuation issue
#   7) [DONE] Remove old logging functions
#   8) [DONE] Re-write debug/verbose flag
#   9) [DONE] Merge verbose/debug flags
#   10) [DONE] Replace -t|--t|--test with "testonly"
#   11) [DONE]Replace -upgrade with "upgradeonly"
#   12) [DONE]Replace -update with "updateonly"
#   13) [DONE] Create quickhelp and fullhelp functions to contain all 
#       documentation
#   14) Update logger function to use new DEBUG levels
#   15) Consider adding a "full" vs "short" flag to the usage function 
#       instead of having two separate functions.
#   16) [DONE] Install check in usage functions so that it can be run without
#       exiting afterward.
#   17) Re-write log check function to handle "check" and "cleanup"
#       arguments. Consolidate to "check" and "cleanup" functions into
#       one function. Correct logic for placing logs in ~/ by default.
#   18) Update logger to handle colorized output conventions.
#   19) Top-down logging fix
#       - Convert everything to log based on CONSOLE or DEBUG 1-4 levels
#       - See TODO #18
#       - Standardize logging "tags", especially those for normal output
#         - Remove precursor tag?
#         - Need better tag for syslog message (better than just [DEBUG])
#       - Syslog logging for internal logger functions should only occur
#           if debug4 is enabled, otherwise syslog will get overly spammed.
#   20) [DONE] Speed up reference functions output (output is laggy).
#         - Fixed by significantly reducing the number of 
#           sub-processes required.
#   21) Replace all function headers with Google code style headers
#       https://google-styleguide.googlecode.com/svn/trunk/shell.xml?
#               showone=Function_Comments#Function_Comments
        #######################################
        # Cleanup files from the backup dir
        # Globals:
        #   BACKUP_DIR
        #   ORACLE_SID
        # Arguments:
        #   None
        # Returns:
        #   None
        #######################################
#
#   22) Limit line length to 80 chars
#       https://google-styleguide.googlecode.com/svn/trunk/shell.xml?
#               showone=Line_Length_and_Long_Strings#
#               Line_Length_and_Long_Strings     
#       # DO use 'here document's
#       cat <<END;
#       I am an exceptionally long
#       string.
#       END
#
#   23) Put ; do and ; then on the same lines as while, if...
#   24) Replace instances of external calls with builtins, where possible
#       1) aptopts removal of "-q" with sed replaced by ${aptopts//-q/}
#   25) Cleanup logs function
#   26) Redo loops with built-ins
#   27) Remove syslog output from "debug<1-4>" statements and add logger 
#       calls elsewhere when syslog logging should be done.
#   28) Fix error code line spacing in exit_codes function (and many others)
#   29) Many logger calls don't announce an exit code, causing the logger to
#       fail.
#   30) Fix tab spacing for entire script
#
##############################################################################


##############################################################################
##############################################################################
# VARIABLES
##############################################################################
# Formatting Constants
declare -r BOLD=$(tput bold);                     # Bold
declare -r UL=$(tput smul);                       # Underline
declare -r NO_UL=$(tput rmul);                    # No underline
declare -r NORM=$(tput sgr0);                     # Normal (not bolded)
declare -r BOLD_BG_RED=${BOLD}$(tput setab 1);    # Bold w/red background
declare -r BOLD_RED=${BOLD}$(tput setaf 1);       # Bold red
declare -r BOLD_BG_YELLOW=${BOLD}$(tput setab 3); # Bold w/yellow background
declare -r BOLD_YELLOW=${BOLD}$(tput setaf 3);    # Bold yellow
declare -r BOLD_GREEN=${BOLD}$(tput setaf 2);     # Bold green
declare -r BOLD_BG_GREEN=${BOLD}$(tput setab 2);  # Bold w/green background

# Script name
## /full/cannonical/name.sh
declare -r SCRIPT_NAME_FULL_LONG=$(readlink -e "$0");

## name.sh
declare -r SCRIPT_NAME_FULL_SHORT=$(basename "$SCRIPT_NAME_FULL_LONG");

## /full/cannonical/name
declare -r SCRIPT_NAME_BASE_LONG=${SCRIPT_NAME_FULL_LONG%%.sh};

## name
declare -r SCRIPT_NAME_BASE_SHORT=$(basename "$SCRIPT_NAME_BASE_LONG");

# Exit Codes Array
declare -r EXITCODES=(
  "0" "Normal exit"
  "1" "Updater usage was called"
  "2" "apt-get update failed"
  "3" "apt-get dist-upgrade failed"
  "4" "sudo required"
  "5" "apt-get was not executable"
  "6" "User-opted exit from --force-yes prompt"
  "7" "Default exit from --force-yes prompt"
  "8" "Failed to write to log path"
  "9" "File ownership modification failed"
  "10" "Unexpected variable value"
  "11" "Forced failure"
  "12" "notify-send was not found"
  "13" "Exit codes function was called by flag"
  "14" "Functions reference function was called by flag"
  "15" "Docs function was called by flag"
  "16" "Unexpected value in array parsing loop"
  "17" "Apt-get reference function was called by flag"
  "96" "Logger function: Exit code is not a number"
  "97" "Logger function: Invalid log type"
  "98" "Logger function: Invalid number of arguments"
  "99" "Interrupt detected");

# Functions Array
declare -r FUNCTIONS=(
  "apt_get_reference" "Display customized apt-get reference"
  "apt_update" "Run apt-get update"
  "apt_upgrade" "Run apt-get dist-upgrade"
  "brainbox_logger" "One logging function to handle it all"
  "calc_runtime" "Caclulate final script run time"
  "check_force" "Confirm the use of '--force-yes'"
  "check_logs_dir" "Check logs directory to make sure it's writable"
  "check_notify" "Check for notify-send for GUI flag"
  "cleanup_logs" "Cleanup logs before script exit"
  "docs" "Output all built-in documentation for updater script"
  "exit_codes" "Display exit codes for reference"
  "find_apt" "Find apt-get executable"
  "force_fail" "Output fail-whale when forced or when all else fails"
  "functions_reference" "Display functions list and short summary"
  "interrupts" "Detect and handle user interrupts"
  "usage_full" "Display [full] script help"
  "usage_short" "Display [short] script help");

# Notify-OSD Constants
declare -r GUI_ICON_WORKING=(
            "/usr/share/icons/hicolor/48x48/status/aptdaemon-working.png");
declare -r GUI_ICON_FAIL=(
            "/usr/share/icons/hicolor/scalable/mimetypes/text-x-apport.svg");

# Other functional constants
declare -r NUM_REGEX="^[0-9]+$";

# updater_nickname: Set variable to customize the updater/OS nickname
#   e.g. You might use "Crobuntu" if you're running Ubuntu on 
#         a [natively] ChromeOS device
updater_nickname="Brainbox";

# Flag-specific variables
testonly=false;
force=false;
assumeyes=true;
allargs="";
keeplogs=false;
updateonly=false;
upgradeonly=false;
forcefail=false;
gui=false;
trygui=false;

# Debug levels (set by command line flags)
debug1=false;
debug2=false;
debug3=false;
debug4=false;

# Notify-OSD Paths
notify_send_cmd="";
gui_title="$updater_nickname Updater";
gui_msg="";

# Apt-get Options
aptopts="--assume-yes";

# Apt-get Command line
# You can define the location for Apt here manually if you really want to.
#   If everything works as intended, a function in this script will find it
#   for you.
aptcmd="";

# Logging
updater_log="brainbox_updater_$(date +'%Y%m%d_%H%M%S%Z').txt";
log_path="";
default_log_path="/tmp";
backup_log_path="~/";

# Global timestamps
start_time_epoch="";
start_time_pretty="";
end_time_epoch="";
end_time_pretty="";
run_time_epoch="";
run_time_pretty="";
fail_time_epoch="";
fail_time_pretty="";


# Track updater exit code
updater_exit=0;


##############################################################################
# Detect and handle user interrupts
# Globals:
#   debug4
#   updater_exit
# Arguments:
#   System interrupts (SIGINT, SIGTSTP)
# Returns:
#   None
##############################################################################
function interrupts()
{
  # [debug] Function start
  if [[ $debug4 == true ]];
  then
    printf "%s%s%s %s\n"\
            "[DEBUG]"\
            "[INTERRUPTS]"\
            "[${BOLD_GREEN}INFO${NORM}]"\
            "Entering 'interrupts' function";
  fi

  # Cleanup
  cleanup_logs;

  # Exit with code 99 - Keyboard interrupt detected
  updater_exit=99;

  brainbox_logger "fail" "Interrupt detected. Exiting..." "$updater_exit";

  # [debug] Function end
  if [[ $debug4 == true ]];
  then
    printf "%s%s%s %s\n"\
            "[DEBUG]"\
            "[INTERRUPTS]"\
            "[${BOLD_GREEN}INFO${NORM}]"\
            "Leaving 'interrupts' function";
  fi

  exit 99;
}

trap interrupts SIGINT;
trap interrupts SIGTSTP;


##############################################################################
# Display custom apt-get command reference
# Globals:
#   debug4
#   updater_exit
# Arguments:
#   $1: "EXIT" on completion; otherwise continue
# Returns:
#   None
##############################################################################
function apt_get_reference()
{
  # [debug] Function start
  if [[ $debug4 == true ]]; then
    printf "%s%s%s %s\n"\
            "[DEBUG]"\
            "[APT_GET_REFERENCE]"\
            "[${BOLD_GREEN}INFO${NORM}]"\
            "Entering 'apt_get_reference' function";
  fi

  # Section title
  printf "%s\n%s\n%s\n\n"\
          " =================== "\
          "|${BOLD} APT-GET REFERENCE ${NORM}|"\
          " =================== ";

  # Apt-get reference
  printf "%s\n  %s\n  %s\n  %s\n  %s\n\n%s\n\n" \
          "APT flags" \
          "apt-get <CMD> -s                   :   Simulate; No action" \
          "apt-get <CMD> -q                   :   Quiet mode" \
          "apt-get <CMD> -y [--assume-yes]    :   Assume \"yes\""\
          "apt-get <CMD> --force-yes          :   Force \"yes\""\
          "For more on apt-get, see the apt-get man page.";

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    printf "%s%s%s %s\n"\
            "[DEBUG]"\
            "[APT_GET_REFERENCE]"\
            "[${BOLD_GREEN}INFO${NORM}]"\
            "Leaving 'apt_get_reference' function";
  fi

  # Check for flag to exit immediately after execution
  if [[ "$1" == "EXIT" ]]; then
    # Set exit code
    updater_exit=17;

    # Exit code 13
    exit 17;
  fi
}


##############################################################################
# Display exit codes reference
# Globals:
#   debug4
#   updater_exit
#   EXIT_CODES[]
# Arguments:
#   $1: "EXIT" on completion; otherwise continue
# Returns:
#   None
##############################################################################
function exit_codes()
{
  # [debug] Function start
  if [[ $debug4 == true ]]; then
    printf "%s%s%s %s\n"\
            "[DEBUG]"\
            "[EXIT_CODES]"\
            "[${BOLD_GREEN}INFO${NORM}]"\
            "Entering 'exit_codes' function";
  fi

  # Section title
  printf "%s\n%s\n%s\n\n"\
          " ====================== "\
          "|${BOLD} EXIT CODES REFERENCE ${NORM}|" \
          " ====================== ";

  # Table formatting
  printf "%-10s%-60s\n%-10s%-60s\n"\
          "Code" "Description"\
          "====" "===========";

  # Reset counter for loop
  i=0;

  while [[ $i -lt ${#EXITCODES[@]} ]]; do
    if ! (( $i % 2 )); then
      printf '%-10s' "${EXITCODES[$i]}";
    elif (( $i % 2 )); then
      printf '%-60s\n' "${EXITCODES[$i]}";
    else
      updater_exit=16;
      brainbox_logger "debug4"\
                      "${BOLD_BG_RED}FATAL${NORM}"\
                      "Unexpected value in array parsing loop"\
                      "$updater_exit";
      brainbox_logger "syslog"\
                      "[DEBUG][EXIT_CODES][BUG][FATAL]"\
                      "Unexpected value in array parsing loop"\
                      "$updater_exit";
    fi
    
    # Increment counter
    let i=i+1;
  done

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    printf "%s%s%s %s\n"\
            "[DEBUG]"\
            "[EXIT_CODES]"\
            "[${BOLD_GREEN}INFO${NORM}]"\
            "Leaving 'exit_codes' function";
  fi

  # Check for flag to exit immediately after execution
  if [[ "$1" == "EXIT" ]]; then
    # Set exit code
    updater_exit=13;

    # Exit code 13
    exit 13;
  fi
}


##############################################################################
# Display functions reference
# Globals:
#   debug4
#   updater_exit
#   FUNCTIONS_REFERENCE[]
# Arguments: 
#   $1: "EXIT" on completion; otherwise continue
# Returns:
#   None
##############################################################################
function functions_reference()
{
  # [debug] Function start
  if [[ $debug4 == true ]]; then
    printf "%s%s%s %s\n"\
            "[DEBUG]"\
            "[FUNCTIONS_REFERENCE]"\
            "[${BOLD_GREEN}INFO${NORM}]"\
            "Entering 'functions_reference' function";
  fi

  # Section title
  printf "%s\n%s\n%s\n\n"\
          " ===================== "\
          "|${BOLD} FUNCTIONS REFERENCE ${NORM}|"\
          " ===================== ";

  # Table formatting
  # Max-width is a self-imposed 70 chars
  printf "%-25s%-45s\n%-25s%-45s\n"\
          "Function" "Description"\
          "--------" "-----------";

  # Reset counter
  i=0;

  while [[ $i -lt ${#FUNCTIONS[@]} ]]; do
    if ! (( $i % 2 )); then
      printf '%-25s' "${FUNCTIONS[$i]}";
    elif (( $i % 2 )); then
      printf '%-45s\n' "${FUNCTIONS[$i]}";
    else
      updater_exit=16;
      if [[ $debug4 == true ]]; then
        printf "%s%s%s %s\n"\
                "[DEBUG]"\
                "[FUNCTIONS_REFERENCE]"\
                "[${BOLD_BG_RED}FATAL${NORM}]"\
                "Unexpected value in array parsing loop";

        brainbox_logger "debug"\
                        "[DEBUG][FUNCTIONS_REFERENCE][BUG][FATAL]"\
                        "Unexpected value in array parsing loop"\
                        "$updater_exit";
      else
        brainbox_logger "debug"\
                        "[DEBUG][FUNCTIONS_REFERENCE][BUG][FATAL]"\
                        "Unexpected value in array parsing loop"\
                        "$updater_exit";
      fi
    fi

    # Increment counter
    let i=i+1;
  done

  # Check for flag to exit immediately after execution
  if [[ "$1" == "EXIT" ]]; then
    # [debug] Function end
    if [[ $debug4 == true ]]; then
      printf "%s%s%s %s\n"\
              "[DEBUG]"\
              "[FUNCTIONS_REFERENCE]"\
              "[${BOLD_GREEN}INFO${NORM}]"\
              "Leaving 'functions_reference' function";
    fi

    # Set exit code
    updater_exit=14;

    # Exit code 14
    exit 14;
  else
    # continue
    # [debug] Function end
    if [[ $debug4 == true ]]; then
      printf "%s%s%s %s\n"\
              "[DEBUG]"\
              "[FUNCTIONS_REFERENCE]"\
              "[${BOLD_GREEN}INFO${NORM}]"\
              "Leaving 'functions_reference' function";
    fi
  fi
}


##############################################################################
# Display script built-in documentation
# Globals:
#   debug4
#   updater_exit
# Arguments: 
#   None
# Returns:
#   None
##############################################################################
function docs()
{
  # [debug] Function start
  if [[ $debug4 == true ]]; then
    printf "%s%s%s %s\n"\
            "[DEBUG]"\
            "[DOCS]"\
            "[${BOLD_GREEN}INFO${NORM}]"\
            "Entering 'docs' function";
  fi

  printf "%s\n%s\n%s\n%s\n%s\n"\
          " ======================= "\
          "|                       |"\
          "| ${BOLD}UPDATER DOCUMENTATION${NORM} |"\
          "|                       |"\
          " ======================= ";

  # Usage
  usage_full "NOEXIT";

  echo "";
  read -p "(Press ${BOLD}<Enter>${NORM} for next page)";
  echo "";

  # Functions reference
  functions_reference;

  echo "";
  read -p "(Press ${BOLD}<Enter>${NORM} for next page)";
  echo "";

  # Exit codes
  exit_codes;

  echo "";
  read -p "(Press ${BOLD}<Enter>${NORM} for next page)";
  echo "";

  # Apt-get reference
  apt_get_reference;

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    printf "%s%s%s %s\n"\
            "[DEBUG]"\
            "[DOCS]"\
            "[${BOLD_GREEN}INFO${NORM}]"\
            "Leaving 'docs' function";
  fi

  # Set exit code
  updater_exit=15;

  # Exit code 15
  exit 15;
}


##############################################################################
# Calculate script runtime
# Globals:
#   debug4
#   updater_exit
#   end_time_epoch
#   start_time_epoch
# Arguments: 
#   None
# Returns:
#   run_time_pretty: Formatted script runtime
##############################################################################
function calc_runtime()
{
  # Global variables
  # Uses 
  #   start_time_epoch
  #   end_time_epoch
  #   run_time_epoch
  #   run_time_pretty

  # [debug] Function start
  if [[ $debug4 == true ]]; then
    printf "%s%s%s %s\n"\
            "[DEBUG]"\
            "[CALC_RUNTIME]"\
            "[${BOLD_GREEN}INFO${NORM}]"\
            "Entering 'calc_runtime' function";
  fi

  # Calculate and print run-time of script
  run_time_epoch=$(expr $end_time_epoch - $start_time_epoch);
  run_time_pretty=$(date --date="@$run_time_epoch" +"%_M minute(s), and%_S seconds");
 
  echo "$run_time_pretty";

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    printf "%s%s%s %s\n"\
            "[DEBUG]"\
            "[CALC_RUNTIME]"\
            "[${BOLD_GREEN}INFO${NORM}]"\
            "Leaving 'calc_runtime' function";
  fi
}


##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: brainbox_logger
# PURPOSE: Single logging function to handle all logging needs
# ARGUMENTS:
# - Log type
# - Log message
# - Exit code
# OUTPUT:
# - Update, debug{1-4}, stop, start, or fail logging messages
# NOTES:
# - Should exit with code 98 for invalid number of arguments
# - Should exit with code 97 for bad log type
# TODO:
# - Check for #ARGS  == $NUM_ARGS 
# - Check for $l_type == value in $L_TYPE_ARRAY
##############################################################################
function brainbox_logger()
{
  # No logger start/stop messages (too spammy)
  #
  # Format
  # brainbox_logger {log type} {message} {exit code} 

  # Variables
  # MIN_ARGS: Controls minimum number of arguments to the logger
  local -r MIN_ARGS=3;
  # L_TYPE_ARRAY: Controls log types. Updates to array must be reflected 
  #   in logger case statement
  local -r L_TYPE_ARRAY=("update" 
                          "debug1" 
                          "debug2" 
                          "debug3" 
                          "debug4" 
                          "fail" 
                          "start" 
                          "stop" 
                          "syslog");
  local -r LOG_TAG="[DEBUG][BRAINBOX_LOGGER]";

  # l_type, l_msg, l_xcode: Define order of logger options
  local l_type;
  local l_msg;
  local l_xcode;
  local logger_found_match;

  l_type="$1" || return;
  l_msg="$2" || return;
  l_xcode="$3" || return;
  logger_found_match=false;

  # This debug output will only be accurate if the logger receives 3 args
  if [[ $debug4 == true ]]; then
    logger "$LOG_TAG[INFO][PRE-VALIDATION] Logger received:" \
            "Messsage type=$l_type," \
            "Message=$l_msg," \
            "Exit code=$l_xcode";
    printf "%s %s %s %s\n"\
            "$LOG_TAG]${BOLD_GREEN}INFO${NORM}][PRE-VALIDATION] received:"\
            "Message type=$l_type,"\
            "Message=$l_msg,"\
            "Exit code=$l_xcode";
  fi

  if [[ "${#@}" -lt "$MIN_ARGS" ]]; then
    # Argument count is an unexpected value
    logger "$LOG_TAG[BUG][FATAL] $updater_nickname" \
            "Updater FAILED due to an internal error:" \
            "\"Invalid number of arguments for the logger\" (98)";
    printf "\n%s %s %s\n%s\n"\
            "$LOG_TAG[BUG][${BOLD_BG_RED}FATAL${NORM}]"\
            "$updater_nickname Updater ${BOLD_BG_RED}FAILED${NORM}"\
            "due to an internal error:"\
            "\"Invalid number of arguments for the logger\" (98)";

    if [[ $gui == true ]]; then
      gui_msg="Updater failed (error code 98)";
      notify-send --urgency=critical --expire-time=10000 \
                  --icon="$GUI_ICON_FAIL" "$gui_title" "$gui_msg" &

      if [[ $debug4 == true ]]; then
        logger "$LOG_TAG[GUI][INFO]" \
                "Notify-send called for updater failure (98)";
      fi
    fi

    # Exit with code 98
    exit 98;
  else
    # Check log type against array
    for logtype in "${L_TYPE_ARRAY[@]}"; do
      # Compare specified value against current array entry
      if [[ "$l_type" == "$logtype" ]]; then
        # Found a match, continue
        # Only one log type is allowed, and no log types should
        #   be the same, so it doesn't matter if the entire array
        #   isn't checked.
        if [[ $debug4 == true ]]; then
          logger "$LOG_TAG[INFO] Log type is valid, continuing...";
          printf "%s %s\n"\
                  "$LOG_TAG[${BOLD_GREEN}INFO${NORM}]"\
                  "Log type is valid, continuing...";
        else
          logger "$LOG_TAG[INFO] Log type is valid, continuing...";
        fi
        logger_found_match=true;

        # Allow for log messages that span >1 line without awkward spaces
        # l_msg is $2
        # >> defined in init vars
        # for each arg, starting at position 3 ($3)
        # if 'each' is NOT number, concat to l_msg
        # else $3 is exit code, continue
        for logger_msg in "${@:3}"; do
          if [[ "$logger_msg" =~ $NUM_REGEX ]]; then
            l_xcode=$logger_msg;
          else
            l_msg="$l_msg $logger_msg";
          fi
        done;

        # Validate exit code
        if [[ "$l_xcode" =~ $NUM_REGEX ]]; then
          if [[ $debug4 == true ]]; then
            # Output to syslog and console
            logger "$LOG_TAG[INFO] Exit code, args, and log type" \
                    "are all valid, continuing...";
            printf "%s %s %s\n"\
                    "$LOG_TAG[${BOLD_GREEN}INFO${NORM}]"\
                    "Exit code, args, and log type"\
                    "are all valid, continuing...";
          else
            # Only output to syslog
            logger "$LOG_TAG[INFO] Exit code, args, and log type" \
                    "are all valid, continuing...";
          fi

          # Logger post-validation debug
          if [[ $debug4 == true ]]; then
            logger "$LOG_TAG[INFO][POST-VALIDATION] Logger received:" \
                    "Messsage type=$l_type," \
                    "Message=$l_msg," \
                    "Exit code=$l_xcode";
            printf "%s%s %s %s %s\n"\
                    "$LOG_TAG]${BOLD_GREEN}INFO${NORM}]"\
                    "[POST-VALIDATION] received:"\
                    "Message type=$l_type,"\
                    "Message=$l_msg,"\
                    "Exit code=$l_xcode";
          fi

          case "$l_type" in
            "update")
              ################################################################
              # NAME: update
              # PURPOSE:  Send message from the script to the logger and to 
              #           console
              # OUTPUT: 
              # - Log message to CONSOLE
              # - Log message to log
              ################################################################
              # Special line start due to being mostly end-user facing
              logger "UPDATER :: $l_msg";
              printf "%s\n" "UPDATER :: $l_msg";
            ;;
            "debug1")
              ################################################################
              # NAME: debug1
              # PURPOSE:  Send message from the script to the logger and to
              #           the console if debugging is turned on.
              # OUTPUT: 
              # - Log message to console if $debug1 is enabled
              # - Log message to log
              ################################################################
              if [[ $debug1 == true ]]; then
                logger "$LOG_TAG[INFO] $l_msg";
                printf "%s\n" "$LOG_TAG[${BOLD_GREEN}INFO${NORM}] $l_msg";
              else
                logger "$LOG_TAG[INFO] $l_msg";
              fi
            ;;
            "debug2")
              ################################################################
              # NAME: debug2
              # PURPOSE:  Send message from the script to the logger and to
              #           the console if debugging is turned on.
              # OUTPUT: 
              # - Log message to console if $debug2 is enabled
              # - Log message to log
              ################################################################
              if [[ $debug2 == true ]]; then
                logger "$LOG_TAG[INFO] $l_msg";
                printf "%s\n" "$LOG_TAG[${BOLD_GREEN}INFO${NORM}] $l_msg";
              else
                logger "$LOG_TAG[INFO] $l_msg";
              fi
            ;;
            "debug3")
              ################################################################
              # NAME: debug3
              # PURPOSE:  Send message from the script to the logger and to
              #           the console if debugging is turned on.
              # OUTPUT: 
              # - Log message to console if $debug3 is enabled
              # - Log message to log
              ################################################################
              if [[ $debug3 == true ]]; then
                logger "$LOG_TAG[INFO] $l_msg";
                printf "%s\n" "$LOG_TAG[${BOLD_GREEN}INFO${NORM}] $l_msg";
              else
                logger "$LOG_TAG[INFO] $l_msg";
              fi
            ;;
            "debug4")
              ################################################################
              # NAME: debug4
              # PURPOSE:  Send message from the script to the logger and to
              #           the console if debugging is turned on.
              # OUTPUT: 
              # - Log message to console if $debug4 is enabled
              # - Log message to log
              ################################################################
              if [[ $debug4 == true ]]; then
                logger "$LOG_TAG[INFO] $l_msg";
                printf "%s\n" "$LOG_TAG[${BOLD_GREEN}INFO${NORM}] $l_msg";
              else
                logger "$LOG_TAG[INFO] $l_msg";
              fi
            ;;
            "fail")
              ################################################################
              # NAME: fail
              # PURPOSE:  Log failure time and exit with failure message
              # OUTPUT: 
              # - Failure message and error code to console
              # - Failure message and error code to log
              ################################################################
              fail_time_epoch=`date +%s`;
              fail_time_pretty=`date --date="@$fail_time_epoch" +"%D %T %Z"`;

              logger "[FATAL] $updater_nickname" \
                      "Updater FAILED at $fail_time_pretty" \
                      "due to \"$l_msg\" with exit code $l_xcode!";
              printf "\n%s %s %s %s\n"\
                      "${BOLD_BG_RED}FATAL${NORM} $updater_nickname"\
                      "Updater ${BOLD_BG_RED}FAILED${NORM} at"\
                      "$fail_time_pretty due to \"$l_msg\""\
                      "with exit code $l_xcode!";

              if [[ $gui == true ]]; then
                gui_msg="Updater failed!";
                notify-send --urgency=critical --expire-time=10000 \
                            --icon="$GUI_ICON_FAIL" "$gui_title" "$gui_msg" &

                if [[ $debug4 == true ]]; then
                  printf "%s %s\n"\
                          "$LOG_TAG[GUI][${BOLD_GREEN}INFO${NORM}]"\
                          "Notify-send called for updater failure (generic)";
                else
                  logger "$LOG_TAG[GUI][INFO]" \
                          "Notify-send called for updater failure (generic)";
                fi
              fi
            ;;
            "start")
              ################################################################
              # NAME: start
              # PURPOSE:  Set script start time and display appropriate
              #           logging messages.
              # OUTPUT: 
              # - Updater started message to logger
              # - Updater started message console
              ################################################################
              start_time_epoch=`date +%s`;
              start_time_pretty=`date --date="@$start_time_epoch" +"%D %T %Z"`;

              logger "UPDATER STARTED :: $updater_nickname"\
                     "Updater started at $start_time_pretty.";

              printf "%s %s %s\n\n"\
                      "${BOLD_GREEN}UPDATER STARTED${NORM} ::"\
                      "$updater_nickname Updater started at"\
                      "$start_time_pretty.";

              if [[ $gui == true ]]; then
                gui_msg="Update started";
                notify-send --urgency=low --expire-time=5000 \
                            --icon="$GUI_ICON_WORKING" \
                            "$gui_title" "$gui_msg" &

                if [[ $debug4 == true ]]; then
                  printf "%s %s\n"\
                          "$LOG_TAG[GUI][${BOLD_GREEN}INFO${NORM}]"\
                          "Notify-send called for updater start";
                else
                  logger "$LOG_TAG[GUI][INFO] Notify-send called"\
                          "for updater start";
                fi
              fi
            ;;
            "stop")
              ################################################################
              # NAME: stop
              # PURPOSE:  Stop script run time counter and output message
              # OUTPUT: 
              # - Updater completion message to log
              # - Updater completion message to console
              ################################################################
              end_time_epoch=`date +%s`;
              end_time_pretty=`date --date="@$end_time_epoch" +"%D %T %Z"`;

              logger "UPDATER COMPLETED $updater_nickname Updater"\
                      "completed at $end_time_pretty, after running"\
                      "for $(calc_runtime), with exit code $l_xcode.";
              printf "\n%s %s%s\n%s%s%s"\
                      "${BOLD_GREEN}UPDATER COMPLETED${NORM} ::"\
                      "$updater_nickname Updater completed at "\
                      "$end_time_pretty."\
                      "                     "\
                      "Exit code $l_xcode. Run time was"\
                      "$(calc_runtime).";

              if [[ $gui == true ]]; then 
                gui_msg="Update complete";
                notify-send --urgency=normal --expire-time=5000 \
                            --icon="$GUI_ICON_WORKING" \
                            "$gui_title" "$gui_msg" &

                if [[ $debug4 == true ]]; then
                  printf "\n%s %s\n"\
                          "$LOG_TAG[GUI][${BOLD_GREEN}INFO${NORM}]"\
                          "Notify-send called for updater stop";
                else
                  logger "$LOG_TAG[GUI][INFO]"\
                          "Notify-send called for updater stop";
                fi
              fi
            ;;
            "syslog")
              ################################################################
              # NAME: syslog
              # PURPOSE:  Send message from the script to syslog ONLY
              # OUTPUT: 
              # - Log message to syslog
              ################################################################
              logger "$LOG_TAG[SYSLOG][INFO] $l_msg";
            ;;
            *)
              # Call the failwhale: This should never be reached
              force_fail;
            ;;
          esac
        else
          logger "[UPDATER BUG][FATAL] $updater_nickname Updater"\
                  "failed due to an internal error:"\
                  "\"Exit code is not a number\" (96)";
          printf "\n%s %s %s\n"\
                  "[UPDATER BUG][${BOLD_BG_RED}FATAL${NORM}]"\
                  "Updater ${BOLD_RED}failed${NORM} due to an internal"\
                  "error: \"Exit code is not a number\" (96)";

          if [[ $gui == true ]]; then
            gui_msg="Updater failed (error code 96)!";
            notify-send --urgency=critical --expire-time=10000 \
                        --icon="$GUI_ICON_FAIL" "$gui_title" "$gui_msg" &

            if [[ $debug4 == true ]]; then
              printf "%s %s\n"\
                      "$LOG_TAG[GUI][${BOLD_GREEN}INFO${NORM}]"\
                      "Notify-send called for updater failure (96)";
            else
              logger "$LOG_TAG[GUI][INFO]"\
                      "Notify-send called for updater failure (96)";
            fi
          fi

          # Exit with code 96
          exit 96;
        fi
      fi
    done

    # Valid log type was NOT found
    # Function will fail if this point is reached
    # Calls to this function are internal, so this is mostly a 
    #   debugging tool.
    if [[ $logger_found_match != true ]]; then
      logger "[UPDATER BUG][FATAL] $updater_nickname Updater"\
              "failed due to an internal error: \"Invalid log type\" (97)";
      printf "\n%s %s%s\n"\
              "[UPDATER BUG][${BOLD_BG_RED}FATAL${NORM}] $updater_nickname"\
              "Updater ${BOLD}failed${NORM} due to an internal error:"\
              "\"Invalid log type\" (97)";

      if [[ $gui == true ]]; then
        gui_msg="Updater failed (error code 97)!";
        notify-send --urgency=critical --expire-time=1000 \
                    --icon="$GUI_ICON_FAIL" "$gui_title" "$gui_msg" &

        if [[ $debug4 == true ]]; then
          logger "[UPDATER DEBUG][LOGGER][GUI]"\
                  "Notify-send called for updater failure (97)";
        fi
      fi

      # Exit with code 97
      exit 97;
    fi
  fi
}


##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: check_logs_dir
# PURPOSE: Check logs directory to make sure it's writable
# ARGUMENTS:
# - None (uses global vars)
# OUTPUT: 
# - Output logs dir to console if debugging is enabled
# - Output logs dir to log
# - Output failure message and exit if logs dir is not writable
##############################################################################
function check_logs_dir()
{
  # Log path = $log_path (/tmp by default)
  # Default log = $default_log_path (/tmp)
  # Backup log path = $backup_log_path (~/)

  if [[ -w $default_log_path ]]; then
    # Logging to /tmp
    log_path=$default_log_path;

    if [[ $keeplogs == true ]]; then
      brainbox_logger "debug4"\
                      "Logs currently stored in $log_path."\
                      "0";
    fi
  elif [[ -w $backup_log_path ]]; then
    # Logging to ~/
    log_path=$backup_log_path;

    if [[ $keeplogs == true ]]; then
      brainbox_logger "debug2"\
                      "Logs currently stored in $log_path."\
                      "0";
    fi
  else
    # /tmp and ~/ aren't writable?! ... bail out!
    updater_exit=8;

    brainbox_logger "fail"\
                    "Logging is hard when you can't write. Go fish."\
                    "$updater_exit";
  fi
}


##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: cleanup_logs
# PURPOSE: Cleanup logs before script exit
# ARGUMENTS:
# - None (uses global vars)
# OUTPUT: 
# - Debug messages, if enabled
##############################################################################
function cleanup_logs()
{
  if [[ $keeplogs == true ]]; then
    # Display log status... console if $debug3
    brainbox_logger "debug4"\
                    "Moving logs from $log_path to ~/"\
                    "0";
    # ... syslog everytime
    brainbox_logger "syslog"\
                    "Moving logs from $log_path to ~/"\
                    "0";
    
    # Move logs from /tmp to ~/
    if [[ -e $log_path/$updater_log ]]; then
      mv $log_path/$updater_log ~/;
    fi

    # Change ownership
    # Display log ownership status... console if $debug4
    brainbox_logger "debug4"\
                    "Changing log file ownership."\
                    "0";
    # ... syslog everytime
    brainbox_logger "syslog"\
                    "Changing log file ownership."\
                    "0";
    UGROUP=`cat /etc/group | grep $SUDO_UID | cut -d ":" -f1`;

    if [[ -w ~/$updater_log ]]; then
      chown $SUDO_USER:$UGROUP ~/$updater_log;
    else
      updater_exit=9;
      brainbox_logger "fail"\
                      "File ownership modification failed."\
                      "$updater_exit";
    fi
  else
    # Delete logs in /tmp
    # Display log deletion messages... console if $debug3
    brainbox_logger "debug3"\
                    "Deleting logs"\
                    "0";
    # ... syslog everytime
    brainbox_logger "syslog"\
                    "Deleting logs"\
                    "0";

    if [[ -e $log_path/$updater_log ]]; then
      rm $log_path/$updater_log;
    fi
  fi
}


##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: usage_short
# PURPOSE: Script [short] usage menu
# ARGUMENTS:
# - $1  : $updater_exit : Exit code
# OUTPUT:·
# - [Short] script usage menu
##############################################################################
function usage_short()
{
  # Set updater exit code
  updater_exit=$1

  # Usage statement
  printf "\n%s%s\n\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s\n\n%s\n%s\
          \n\n%s\n%s%s\n%s%s\n\n"\
          "${BOLD}USAGE :: sudo $SCRIPT_NAME_FULL_SHORT${NORM} "\
          "[-v|vv|vvv|vvvv] [options]"\
          "  -updateonly            :"\
          "  Update ONLY"\
          "  -upgradeonly           :"\
          "  Upgrade ONLY"\
          "  -t [testonly]          :"\
          "  Test mode (no changes)(apt-get -s)"\
          "  -f [force-yes]         :"\
          "  Force \"yes\" (USE WITH CAUTION!)"\
          "  -k [keep-logs]         :"\
          "  Preserve logs"\
          "  -g [gui]               :"\
          "  Use notify-osd for notices"\
          "  -updatername=${UL}nickname${NO_UL}  :"\
          "  Set updater name to ${UL}nickname${NO_UL}"\
          "                            (default: Brainbox)"\
          "  ${BOLD}Most command line arguments can be called with a"\
          "  single(-) or double(--) dash.${NORM}"\
          "  Script Help"\
          "    -h [help | ?]        :"\
          "  Display [short] script help (this menu)"\
          "    -helpfull            :"\
          "  Display [full] script help";

  read -p "(Press ${BOLD}<Enter>${NORM} for the next page)";

  printf "\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\
          \n\n%s\n%s\n"\
          "  Debug/Verbose Mode (${BOLD}Must be first argument${NORM})"\
          "    -v    : Minimal verbosity/debug information"\
          "    -vv   : More verbose/some internal debug information"\
          "    -vvv  : Most debug information"\
          "    -vvvv : All debug information"\
          "  Advanced debug flags"\
          "    -debug-apt-get-ref   :"\
          "  Show apt-get reference"\
          "    -debug-exitcodes     :"\
          "  Show exit code table"\
          "    -debug-functions     :"\
          "  Show functions reference"\
          "    -debug-forcefail     :"\
          "  Force failure for debugging"\
          "    -docs                :"\
          "  Show all available documentation"\
          "  Further documentation can be found within the script or by"\
          "  executing this script with the '-helpfull' flag.";

  # Logging never started - no need to stop it

  # Exit
  exit $updater_exit;
}


##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: usage_full
# PURPOSE: Script [full] usage menu
# ARGUMENTS:
# - $1  : $updater_exit : Exit code
# OUTPUT: 
# - [Full] script usage menu
##############################################################################
function usage_full()
{
  # Set updater exit code
  updater_exit=$1

  # Usage statement
  printf "\n%s%s\n\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s\n\n%s\n%s\
          \n\n%s\n%s%s\n%s%s\n\n"\
          "${BOLD}USAGE :: sudo $SCRIPT_NAME_FULL_SHORT${NORM} "\
          "[-v|vv|vvv|vvvv] [options]"\
          "  -updateonly            :"\
          "  Update ONLY"\
          "  -upgradeonly           :"\
          "  Upgrade ONLY"\
          "  -t [testonly]          :"\
          "  Test mode (no changes)(apt-get -s)"\
          "  -f [force-yes]         :"\
          "  Force \"yes\" (USE WITH CAUTION!)"\
          "  -k [keep-logs]         :"\
          "  Preserve logs"\
          "  -g [gui]               :"\
          "  Use notify-osd for notices"\
          "  -updatername=${UL}nickname${NO_UL}  :"\
          "  Set updater name to ${UL}nickname${NO_UL}"\
          "                            (default: Brainbox)"\
          "  ${BOLD}Most command line arguments can be called with a"\
          "  single(-) or double(--) dash.${NORM}"\
          "  Script Help"\
          "    -h [help | ?]        :"\
          "  Display [short] script help"\
          "    -helpfull            :"\
          "  Display [full] script help (this menu)";

  read -p "(Press ${BOLD}<Enter>${NORM} for the next page)";

  printf "\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\
          \n\n%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\
          \n%s%s\n\n"\
          "  Debug/Verbose Mode (${BOLD}Must be first argument${NORM})"\
          "    -v    : Minimal verbosity/debug information"\
          "    -vv   : More verbose/some internal debug information"\
          "    -vvv  : Most debug information"\
          "    -vvvv : All debug information"\
          "  Advanced debug flags"\
          "    -debug-apt-get-ref   :"\
          "  Show apt-get reference"\
          "    -debug-exitcodes     :"\
          "  Show exit code table"\
          "    -debug-functions     :"\
          "  Show functions reference"\
          "    -debug-forcefail     :"\
          "  Force failure for debugging"\
          "    -docs                :"\
          "  Show all available documentation"\
          "  Log Types"\
          "    update               :"\
          "  Normal updates; console and syslog"\
          "    debug1               :"\
          "  Minimal verbosity/debug information (-v)"\
          "    debug2               :"\
          "  More verbose/some debug information (-vv)"\
          "    debug3               :"\
          "  Most debug information (-vvv)"\
          "    debug4               :"\
          "  All debug information (-vvvv)"\
          "    fail                 :"\
          "  Log failures; console and syslog"\
          "    start                :"\
          "  Log script start; console and syslog"\
          "    stop                 :"\
          "  Log script stop; console and syslog"\
          "    syslog               :"\
          "  Log ONLY to syslog";

  read -p "(Press ${BOLD}<Enter>${NORM} for the next page)";

  printf "\n%s\n%s%s\n%s%s\n%s\n%s\n%s%s\n%s\n%s%s\
          \n\n%s\n%s\n%s%s\n%s\n%s%s\n%s%s\n%s\n%s%s\n%s\
          \n\n%s%s\n\n%s\n"\
          "  Output conventions"\
          "    [${BOLD_GREEN}INFO${NORM}]"\
          "  General debugging information."\
          "    [${BOLD_YELLOW}WARN${NORM}]"\
          "  Mostly non-fatal errors, like conflicts with "\
          "            existing sessions or genuine warnings. Script may "\
          "            or may not exit."\
          "    [${BOLD_RED}ERROR${NORM}]"\
          " Major errors. Script will exit (with limited"\
          "            exceptions). Syntax errors fall into this category."\
          "    [${BOLD_BG_RED}FATAL${NORM}]"\
          " Fatal errors. Script will exit (no exceptions)."\
          "  ${BOLD}sudo${NORM} requirement"\
          "    To help minimize security issues related to elevated"\
          "    permissions, this script must be executed with "\
          "${BOLD}sudo${NORM}; "\
          "    SUID and SGID must never be used. For execution by"\
          "    ${BOLD}sudo${NORM}, this script must either be placed "\
          "in a location"\
          "    defined by the ${BOLD}/etc/sudoers${NORM} "\
          "variable ${UL}secure_path${NO_UL},"\
          "    or your desired execution location should be added"\
          "    to ${UL}secure_path${NO_UL} in ${BOLD}/etc/sudoers${NORM} "\
          "by editing the file"\
          "    with ${BOLD}sudo visudo${NORM}."\
          "    ${BOLD}TIP${NORM} You can view your current sudo settings "\
          "with ${BOLD}sudo sudo -V${NORM}."\
          "  Further documentation can be found within the script.";

  # Logging never started - no need to stop it

  # Check for "NOEXIT" being passed to usage function
  # Used only by "docs" function to prevent script termination
  if [[ $1 != "NOEXIT" ]]; then
    # Exit
    exit $updater_exit;
  #else
    # continue
  fi
}


##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: find_apt
# PURPOSE: Find apt-get executable
# ARGUMENTS:
# - None
# OUTPUT: 
# - Apt-get location location logged if found
# - Exits with error if apt-get is not found
##############################################################################
function find_apt()
{
  # Find apt-get and verify it's executable
  if [[ -x $(which apt-get) ]]; then
    aptcmd=`which apt-get`;

    brainbox_logger "debug2"\
                    "Apt-get found at $aptcmd, continuing..."\
                    "0";
  else
    # Set exit code
    updater_exit=5;

    # Send update to syslog/console
    brainbox_logger "fail"\
                    "$aptcmd is not executable"\
                    "$updater_exit";

    # Exit with code 5
    exit 5;
  fi
}


##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: force_fail
# PURPOSE: Output fail-whale ASCII art when forced or when all 
#          else fails.
# ARGUMENTS:
# - None
# OUTPUT: 
# - Fail-whale ASCII art
##############################################################################
function force_fail()
{
  # Force failure
  if [[ -e $(dirname $0)/brainbox-failwhale.sh ]]; then
    # Call the failwhale
    $(dirname $0)/brainbox-failwhale.sh;

    # Set exit code to 11
    updater_exit=11;

    # Call fail logging
    brainbox_logger "fail"\
                    "Abnormal failure"\
                    "$updater_exit";

    # Exit with code 11
    exit 11;
  else
    # Set exit code to 11
    updater_exit=11;

    # Failwhale not found; this shouldn't happen
    # Exit with code 11 quietly
    exit 11;
  fi
}


##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: check_notify
# PURPOSE:  Check for notify-send for use with the GUI flag. When 
#           the flag is called, notify-osd will be used to show 
#           GUI alerts for the updater process.
# ARGUMENTS:
# - None
# OUTPUT:
# - Debug logging on success, if enabled
# - Debug logging on failure, at all times
# NOTES:
# - notify-send is provided by notify-osd
# - notify-send should be located in /usr/bin/notify-send on Ubuntu
# - script should return an error code for logging and then continue
#   without GUI prompts.
#####################################################################
function check_notify()
{
  # notify-send is provided by notify-osd package
  
  if [[ -x $(which notify-send) ]]; then
    notify_send_cmd=`which notify-send`;

    # Notify-send was found,
    gui=true;

    brainbox_logger "debug4"\
                    "Notify-send found at $notify_send_cmd, continuing..."\
                    "0";
  else
    # Set exit code
    updater_exit=12;

    # Notify-send was not found, don't attempt to use notify-send
    gui=false;

    # Send update to syslog/console
    brainbox_logger "fail"\
                    "$notify_send_cmd is not executable"\
                    "$updater_exit";

    # Return code 12
    return 12;
  fi
}


##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: check_force
# PURPOSE: Confirm the use of "--force-yes"
# ARGUMENTS:
# - None (triggered by global var value)
# OUTPUT: 
# - Prompt user to confirm "--force-yes"
##############################################################################
function check_force()
{
  local choice;
  choice="";

  if [[ $force == true && `echo $aptopts | grep -o '\--force-yes'` == "--force-yes" ]]; then
    long_log="--force-yes was in options. Check forced to ensure it was \
              intended.";
    brainbox_logger "debug3"\
                    "--force-yes was found in options."\
                    "Check forced to ensure it was intended."\
                    "0";

    printf "%s %s%s\n%s"\
            "[${BOLD_YELLOW}WARN${NORM}]"\
            "${BOLD_RED}You've chosen to use \"--foce-yes\""\
            "which can be destructive."\
            "       Do you want to continue [yes/NO]? ${NORM}";
    read -t 30 choice;

    echo "";

    # Process user choice
    case $choice in
      n | N | no | NO)
        # Update logging
        brainbox_logger "update"\
                        "Always better to be safe than sorry,"\
                        "script will exit."\
                        "0";

        # User opted to exit, exit code 6
        updater_exit=6;
        brainbox_logger "stop" "n/a" "0";

        # stop_logging should handle the exit, but just in case
        exit $updater_exit;
      ;;
      yes | YES)
        # Update logging
        brainbox_logger "update"\
                        "--force-yes confirmed. Continuing..."\
                        "0";
      ;;
      *)
        brainbox_logger "update"\
                        "I didn't understand you."\
                        "Assuming \"NO\" and exiting."\
                        "0";

        # Choice was invalid, exit code 7
        updater_exit=7;
        brainbox_logger "fail"\
                        "--force-yes prompt yielded invalid choice. Exiting."\
                        "$updater_exit";
        exit $updater_exit;
      ;;
    esac
  fi
  # Returns to main if nothing is found
}


##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: apt_update
# PURPOSE: Run apt-get update
# ARGUMENTS:
# - None (uses global vars)
# OUTPUT: 
# - Apt-get update output if debugging enabled
##############################################################################
function apt_update()
{
  # Apt-get Update
  brainbox_logger "update"\
                  "Starting APT acquire"\
                  "0";

  # Run `apt-get update`
  # Output to log and console if verbose, log only otherwise
  if [[ $debug1 == true ]]; then
    $aptcmd update | tee -a $log_path/$updater_log;
  else
    $aptcmd update >> $log_path/$updater_log;
  fi

  # Catch updater success/failure
  if [[ $? -eq 0 ]]; then
    brainbox_logger "debug2"\
                    "APT acquire ($aptcmd) is complete"\
                    "0";
    brainbox_logger "update"\
                    "APT acquire is complete"\
                    "0";

    # Return to main (should hit apt_upgrade() next)
  else
    # Set update exit code to 2 (apt-get update failure)
    updater_exit=2;

    # Call fail logging function (console and syslog)
    brainbox_logger "fail"\
                    "$aptcmd failure"\
                    "$updater_exit";

    # Exit with code 2 (apt-get update failure)
    exit $updater_exit;
  fi
}


##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: apt_upgrade
# PURPOSE: Run apt-get dist-upgrade
# ARGUMENTS:
# - None (uses global vars)
# OUTPUT: 
# - Apt-get dist-upgrade messages
##############################################################################
function apt_upgrade()
{
  # Status message
  brainbox_logger "update"\
                  "Starting APT install. This may take some time..."\
                  "0";

  # Run `apt-get dist-upgrade` with chosen flags
  if [[ $debug1 == true ]]; then
    $aptcmd dist-upgrade $aptopts | tee -a $log_path/$updater_log;
  else
    $aptcmd dist-upgrade >> $log_path/$updater_log;
  fi

  # CATCH UPDATER SUCCESS/FAILURE
  if [[ $? -eq 0 ]]; then
    # Apt-get dist-upgrade has succeeded
    brainbox_logger "debug2"\
                    "APT install ($aptcmd) is complete"\
                    "0";
    brainbox_logger "update"\
                    "APT install is complete"\
                    "0";
    # Return to main (should cleanup logs next)
  else
    # Set update exit code to 3 (apt-get upgrade failure)
    updater_exit=3;

    # Call fail logging function (console and syslog)
    brainbox_logger "fail"\
                    "$aptcmd failure"\
                    "$updater_exit";

    # Exit with code 3 (apt-get upgrade failure)
    exit $updater_exit;
  fi
}




##############################################################################
##############################################################################
# MAIN
##############################################################################
##############################################################################



##############################################################################
##############################################################################
# MAIN
##############################################################################
# PURPOSE: Command line argument parsing
# ARGUMENTS: 
# - $@  : Command line arguments
# OUTPUT: 
# - usage_short() function if explicitly called in a flag or script is run
#     without `sudo`
##############################################################################


# Experimental: Check for flags with dash or double-dash using RegEx
# if [[ "$l_xcode" =~ ^-?[0-9]+$ ]];

# Parse arguments if > 0, otherwise exit
if [[ $# -ge 0 && "$(whoami)" == "root" ]]; then
  # Used to reference original set of arguments
  allargs="$@";

  # Check for verbose flag as first argument ($1)
  # if-statement requires obvious intent through syntax matching
  if [[ "$1" =~ "v" ]]; then
    case "$1" in
      -v|--v)  
        # Verbosity/debug 1
        # No console confirmation for debug level 1
        debug1=true;
      ;;   
      -vv|--vv)
        # Verbosity/debug 2
        # No console confirmation for debug level 2
        debug1=true;
        debug2=true;
      ;;   
      -vvv|--vvv)
        # Verbosity/debug 3
        printf "\n%s %s\n\n"\
                "${BOLD_YELLOW}WARN${NORM}"\
                "Debug level 3 enabled";
        debug1=true;
        debug2=true;
        debug3=true;
      ;;   
      -vvvv|--vvvv)
        # Verbosity/debug 4
        printf "\n%s %s\n\n"\
                "${BOLD_YELLOW}WARN${NORM}"\
                "Debug level 4 enabled";
        debug1=true;
        debug2=true;
        debug3=true;
        debug4=true;
      ;;
    esac
    
    # Shift argument list, removing verbose flag from the list
    shift;
  fi

  # Check for flags that will immediately terminate
  # These can be the first (and only) or second argument (after verbose)
  # If they follow a verbose flag, the argument list will have been shifted
  #   so this should check $1 no matter what.
  case "$1" in
    --help | -help | -h | --h | ?)
      # Help option, exit code = 1
      updater_exit=1;

      # Send update to syslog
      brainbox_logger "syslog"\
                      "$updater_nickname Updater called with HELP flag."
                      "Showing usage and exiting."\
                      "$updater_exit";

      # Help key, show usage and exit 1
      usage_short $updater_exit;
    ;;
    --helpfull | -helpfull)
      # Help option, exit code = 1
      updater_exit=1;

      # Send update to syslog
      brainbox_logger "syslog"\
                      "$updater_nickname Updater called with HELP flag."
                      "Showing usage and exiting."\
                      "$updater_exit";

      # Help key, show usage and exit 1
      usage_full $updater_exit;
    ;;
    --debug-exitcodes | -debug-exitcodes)
      # Show exit codes and exit
      exit_codes "EXIT";

      # Exit handled by exit_codes function
    ;;
    --debug-functions | -debug-functions)
      # Show functions reference and exit
      functions_reference "EXIT";

      # Exit handled by functions_reference function
    ;;
    --debug-apt-get-ref | -debug-apt-get-ref)
      # Show customized apt-get reference
      apt_get_reference "EXIT";

      # Exit handled by apt_get_reference function
    ;;
    --docs | -docs)
      # Show all available documentation and exit
      docs;

      # Exit handled by docs function
    ;;
    --debug-forcefail | -debug-forcefail)
      forcefail=true;
      force_fail;

      # Exit handled by force_fail function
    ;;
  esac

  # Parse the arguments
  # If a verbose flag was found, $@ has been shifted left and the 
  #   verbose flag is now out of the array.
  # If a debug function was called, the script should exit before
  #   reaching this point.

  for OPT in "$@"
  do
    case $OPT in
      --updatername=* | -updatername=*)
        # Parse "updatername" flag for new updater nickname
        updater_nickname=${OPT##*updatername=};
        ;;
      --gui | -gui | -g | --g)
        trygui=true;
        ;;
      --updateonly | -updateonly | --update-only | -update-only)
        updateonly=true;
        ;;
      --upgradeonly | -upgradeonly | --upgrade-only | -upgrade-only)
        upgradeonly=true;
        ;;
      --testonly | -t | --t)
        testonly=true;
        aptopts="$aptopts -s";
        ;;
      --force-yes | -f | --f)
        force=true;
        aptopts="$aptopts --force-yes";
        ;;
      --keep-logs | -k)
        keeplogs=true;
        ;;
      *)
        # Check for verbose flag and alert if found. 
        # Do not process verbose flag here.
        if [[ "$OPT" =~ "-v" ]];
        then
          # Bad flag
          updater_exit=1;

          # Send update to syslog
          brainbox_logger "syslog"\
                          "Invalid flag detected"\
                          "(verbose flag is out of place) (flag = $OPT)"\
                          "$updater_exit";

          # Invalid option, show usage and exit 1
          printf "\n%s %s\n%s\n"\
                  "${BOLD_RED}Ahoy there captain, you're flying the"\
                  "verbose flag in the wrong spot."\
                  "Try again. (flag = $OPT)${NORM}";

          usage_short $updater_exit;
        else
          # Bad flag
          updater_exit=1;

          # Send update to syslog
          brainbox_logger "syslog"\
                          "Invalid flag detected (flag = $OPT)"\
                          "$updater_exit";

          # Invalid option, show usage and exit 1
          printf "\n%s %s\n"\
                  "${BOLD_RED}Ahoy there captain, you're flying the"\
                  "wrong flag (flag = $OPT). Try again.${NORM}";

          usage_short $updater_exit;
        fi
        ;;
    esac
  done
else
  # Not root
  printf "\n%s %s\n"\
          "${BOLD_BG_RED}Magic 8-ball says \"Root is required.\""\
          "Try running this with 'sudo'${NORM}";

  # Exit code 4
  updater_exit=4;

  # Send update to syslog
  brainbox_logger "syslog"\
                  "$updater_nickname Updater requires root privileges."\
                  "Try running updater with \`sudo\`"\
                  "$updater_exit";

  # Set exit code to 4 and call usage function. 
  # See documentation for more exit codes.
  usage_short $updater_exit;
fi


##############################################################################
##############################################################################
# MAIN
##############################################################################
# PURPOSE: Output debugging information, if enabled
# ARGUMENTS:
# - None
# OUTPUT: 
# - Flags status
##############################################################################
brainbox_logger "debug4" "Arguments: $allargs" "0";
brainbox_logger "debug4" "Debug1? $debug1" "0";
brainbox_logger "debug4" "Debug2? $debug2" "0";
brainbox_logger "debug4" "Debug3? $debug3" "0";
brainbox_logger "debug4" "Debug4? $debug4" "0";
brainbox_logger "debug4" "Test? $testonly" "0";
brainbox_logger "debug4" "Assume yes? $assumeyes" "0";
brainbox_logger "debug4" "Force? $force" "0";
brainbox_logger "debug4" "Keep logs? $keeplogs" "0";
brainbox_logger "debug4" "Update only? $updateonly" "0";
brainbox_logger "debug4" "Upgrade only? $upgradeonly" "0";
brainbox_logger "debug4" "Apt-Get Options? $aptopts" "0";
brainbox_logger "debug4" "Forced failure? $forcefail" "0";
brainbox_logger "debug4" "Notification GUI enabled? $gui" "0";


##############################################################################
##############################################################################
# MAIN: CHECK FOR NOTIFY_SEND
##############################################################################
if [[ $trygui == true ]];
then
  check_notify;
fi


##############################################################################
##############################################################################
# MAIN: START LOGGING 
##############################################################################
brainbox_logger "start" "n/a" "0";


##############################################################################
##############################################################################
# MAIN: CHECK FOR FORCE-YES -- PROMPT 
##############################################################################
check_force;


##############################################################################
##############################################################################
# MAIN: VERIFY APT-GET IS EXECUTABLE 
##############################################################################
find_apt;


##############################################################################
##############################################################################
# MAIN
##############################################################################
# PURPOSE: Output apt-get command in use if debugging is enabled
# ARGUMENTS:
# - None
# OUTPUT: 
# - If enabled, the apt-get command line in use
##############################################################################
# Apt-get should be found by now, show the path
brainbox_logger "debug4"\
                "Apt-Get command? $aptcmd"\
                "0";


##############################################################################
##############################################################################
# MAIN: CHECK LOG DESTINATION 
##############################################################################
check_logs_dir;


##############################################################################
##############################################################################
# MAIN: UPDATE AND UPGRADE
##############################################################################
# Check for simulation mode
if [[ $testonly == true ]]; then
  printf "%s\n\n"\
          "${BOLD}Simulation mode enabled.${NORM}";
fi

# Update-only/upgrade-only logic
if [[ $updateonly == true && $upgradeonly == false ]]; then
  # Only run update, but also check that upgrade-only is false
  apt_update;
  brainbox_logger "update"\
                  "APT install skipped at user request."\
                  "0";
elif [[ $upgradeonly == true && $updateonly == false ]]; then
  # Only run upgrade, but also check that update-only is false
  apt_upgrade;
  brainbox_logger "update"\
                  "APT acquire skipped at user request."\
                  "0";
elif [[ $updateonly == false && $upgradeonly == false ]]; then
  # Update-only and upgrade-only are false, run both
  apt_update;
  apt_upgrade;
elif [[ $upgradeonly == true && $updateonly == true ]]; then
  # Both upgrade-only and update-only were detected. 
  # A prior check should have caught this.
  # Set exit code
  updater_exit=10;

  # Log useful info
  brainbox_logger "fail"\
                  "Incompatible options detected,"\
                  "upgrade-only and update-only flags are both true."\
                  "This means a prior check has failed."\
                  "$updater_exit";

  # Exit
  exit $updater_exit;
else
  # Unknown failure
  # Set exit code
  updater_exit=10;

  # Log useful info
  brainbox_logger "fail"\
                  "Something was lost in translation."\
                  "Something went really wrong."\
                  "$updater_exit";

  # Exit
  exit $updater_exit;
fi



##############################################################################
##############################################################################
# MAIN: LOG CLEANUP 
##############################################################################
cleanup_logs;


##############################################################################
##############################################################################
# MAIN: SET UPDATER EXIT 
##############################################################################
updater_exit=0;


##############################################################################
##############################################################################
# MAIN: STOP LOGGING 
##############################################################################
brainbox_logger "stop" "n/a" "$updater_exit";


##############################################################################
##############################################################################
# MAIN: RESET TERMINAL COLORS (JUST IN CASE) 
##############################################################################
printf "%s\n" "${NORM}";


##############################################################################
##############################################################################
# EOF
##############################################################################
