#!/bin/bash

##############################################################################
# BRAINBOX TMUX SESSION MANAGER
##############################################################################
#
# AUTHOR: Brian Call
# SOURCE: https://github.com/bacall213
# LICENSE: MIT
#
# GOALS:
#   - Create more friendly interface for tmux.
#   - Create robust and predictable tmux interface for distribution 
#     with 'brainbox' script package.
#   - Grow development skills through the creation of a suite of 
#     scripts designed to enhance common system administration tasks.
#
# NON-GOALS:
#   - Replace tmux. This script enhances tmux, not replaces it.
#
# TESTED PLATFORMS:                                                
#   - Ubuntu 12.04 LTS (64-bit)
#                                                                   
# REQUIRED PACAKGES:
#   - tmux (provides /usr/bin/tmux, man pages, etc)
#
# FILES:
#   - brainmux.sh (required, this script)
#
# OPTIONAL COMPONENTS:
#   - ~/.tmux.conf 
#     - User-specific config
#     - tmux, not this script, will read the config file, if present
#
# KNOWN ISSUES (KI):
#   1) tmux.conf misconfigurations will cause script to fail
#   2) tmux.conf settings will override script settings
#
# CONVENTIONS USED:
#   - Versioning standard: 
#     - v[major_version].[month(M)].[year(YYYY)]-b[build_num]
#     - e.g. v1.1.2014-b20 = Major version 1, January 2014, build 20
#
# REVISION HISTORY:
#   - v1.7.2014-b1
#     - Initial public release
#   - v1.7.2014-b2
#     - check_symlink function created
#     - Warning message for bad verbose flags added
#   - v1.8.2014-b1
#     - Fixed symlink checker function (flawed logic)
#
# TODO:
#   1) Custom session
#   2) Read and intelligently output .tmux.conf or /etc/tmux.conf in
#      defaults function.
#   3) Ensure all inputs are sanitized
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
# /full/cannonical/name.sh
declare -r SCRIPT_NAME_FULL_LONG=$(readlink -e "$0");

# name.sh
declare -r SCRIPT_NAME_FULL_SHORT=$(basename "$SCRIPT_NAME_FULL_LONG");

# /full/cannonical/name
declare -r SCRIPT_NAME_BASE_LONG=${SCRIPT_NAME_FULL_LONG%%.sh};

# name
declare -r SCRIPT_NAME_BASE_SHORT=$(basename "$SCRIPT_NAME_BASE_LONG");

#echo "Script name full long: $SCRIPT_NAME_FULL_LONG";
#echo "Script name full short: $SCRIPT_NAME_FULL_SHORT";
#echo "Script name base long: $SCRIPT_NAME_BASE_LONG";
#echo "Script name base short: $SCRIPT_NAME_BASE_SHORT";

# Session Defaults Array
# NOTE: create() depends on these values being in a particular order
declare -r SESSION_DEFAULTS=('tmux new-session -d'
                            'tmux split-window -h -p 50'
                            'tmux new-window'
                            'tmux new-window'
                            'tmux new-window'
                            'tmux select-window -t:0'
                            'tmux select-pane -L -t:0');

# Failure Quotes Array
declare -r FAILURE_QUOTES=("My great concern is not whether you have failed, but whether you are content with your failure. --Abraham Lincoln"
                "Many of life's failures are people who did not realize how close they were to success when they gave up. --Thomas A. Edison"
                "Failure is not fatal, but failure to change might be. --John Wooden"
                "If you learn from defeat, you haven't really lost. --Zig Ziglar"
                "Remember that failure is an event, not a person. --Zig Ziglar"
                "I don't believe in failure. It is not failure if you enjoyed the process. --Oprah Winfrey"
                "They don't make bugs like Bunny anymore. --Olav Mjelde."
                "Talk is cheap. Show me the code. --Linus Torvalds"
                "Life is full of screwups. You're supposed to fail sometimes. It's a required part of the human existance. --Sarah Dessen"
                "Only those who dare to fail greatly can ever achieve greatly. --Robert F. Kennedy"
                "Giving up is the only sure way to fail. --Gena Showalter"
                "The phoenix must burn to emerge. --Janet Fitch"
                "There is no failure except in no longer trying. --Chris Bradford"
                "The only real mistake is the one from which we learn nothing. --Henry Ford");

# Initialization for various global variables
cli_cmd="";                   # Tracks current argument
arg_pos="";                   # Tracks argument position in array
tmux_status="999";            # Impossible value
cli_args=("$@");              # Store all args
debug1=false;                 # -v    : Minimal debug info
debug2=false;                 # -vv   : Some debug info
debug3=false;                 # -vvv  : Most debug info
debug4=false;                 # -vvvv : All debug info


##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: quickhelp
# PURPOSE: Display short script help information
# ARGUMENTS:
# - None
# OUTPUT:
# - Script help information
##############################################################################
function quickhelp()
{
  # [debug] Function start
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][QUICKHELP][${BOLD_GREEN}INFO${NORM}] Entering 'quickhelp' function";
  fi

  echo -en "\n${BOLD}USAGE :: $0${NORM} [-v|vv|vvv|vvvv] ${BOLD}command${NORM} ${UL}options${NO_UL}\r\n
  ${UL}Create and Destroy Sessions${NO_UL}\r
    ${BOLD}create${NORM} [${UL}session_1${NO_UL} ${UL}session_2${NO_UL} ${UL}session_3${NO_UL} ...]\r
    \t(aliases: ${BOLD}new${NORM}, ${BOLD}start${NORM})\r

    ${BOLD}destroy${NORM} [all] ${UL}existing_session${NO_UL}\r
    \t(aliases: ${BOLD}stop${NORM}, ${BOLD}kill${NORM})\r

  ${UL}Connect and Disconnect Sessions${NO_UL}\r
    ${BOLD}connect${NORM} ${UL}existing_session${NO_UL}\r
    \t(alias: ${BOLD}attach${NORM})\r

    ${BOLD}disconnect${NORM} ${UL}existing_session${NO_UL}\r
    \t(alias: ${BOLD}detach${NORM})\r

  ${UL}Create a Custom Session${NO_UL}\r
    ${BOLD}custom${NORM} ${UL}session_properties${NO_UL}\r

  ${UL}Session Information${NO_UL}\r
    ${BOLD}info${NORM}\r
    ${BOLD}defaults${NORM}\r
    ${BOLD}sessions${NORM}\r

  ${UL}General Script Options${NO_UL}\r
    ${BOLD}help${NORM} (this menu)\r
    ${BOLD}helpfull${NORM}\r
    
    Debug/Verbose Mode (${BOLD}Must be first argument${NORM})\r
      -v    : Minimal verbosity/debug information\r
      -vv   : More verbose/some internal debug information\r
      -vvv  : Most debug information\r
      -vvvv : Full verbosity/All debug information\n\n";

  # [debug] Function end
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][QUICKHELP][${BOLD_GREEN}INFO${NORM}] Leaving 'quickhelp' function";
  fi

  # Exit gracefully
  exit 0;
}




##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: fullhelp
# PURPOSE: Display full script help information
# ARGUMENTS:
# - None
# OUTPUT:
# - Script help information
##############################################################################
function fullhelp()
{
  # [debug] Function start
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][FULLHELP][${BOLD_GREEN}INFO${NORM}] Entering 'fullhelp' function";
  fi

  echo -en "\n${BOLD}USAGE :: $0${NORM} [-v|vv|vvv|vvvv] ${BOLD}command${NORM} ${UL}options${NO_UL}\r\n
  ${UL}Create and Destroy Sessions${NO_UL}\r
    ${BOLD}create${NORM} [${UL}session_1${NO_UL} ${UL}session_2${NO_UL} ${UL}session_3${NO_UL} ...]\r
    \t(aliases: ${BOLD}new${NORM}, ${BOLD}start${NORM})\r

    \tCreate one or multiple tmux sessions. If no session name is specified, \r
    \ttmux will create a new session named using its own mechanisms. If a \r
    \tspecified session already exists, this script will skip over that \r
    \tsession.\r

    ${BOLD}destroy${NORM} [all] ${UL}existing_session${NO_UL}\r
    \t(aliases: ${BOLD}stop${NORM}, ${BOLD}kill${NORM})\r

    \tDestroy single, or all, existing tmux sessions. If 'all' is \r
    \tspecified, this script will try to destroy all existing sessions. \r

  ${UL}Connect and Disconnect Sessions${NO_UL}\r
    ${BOLD}connect${NORM} ${UL}existing_session${NO_UL}\r
    \t(alias: ${BOLD}attach${NORM})\r

    \tConnect to an existing tmux session.\r

    ${BOLD}disconnect${NORM} ${UL}existing_session${NO_UL}\r
    \t(alias: ${BOLD}detach${NORM})\r

    \tDisconnect from an existing tmux session.\r
 
  ${UL}Create a Custom Session${NO_UL}\r
    ${BOLD}custom${NORM} ${UL}session_properties${NO_UL}\r

    \tCreate a custom tmux session using provided ${UL}session_properties${NO_UL}.\r
    \tAll tmux.conf defaults and script defaults are ignored.\r

    \tFormat: ${BOLD_YELLOW}<TODO>${NORM}\n\n";

  # Page break
  read -p "(${BOLD}Press <Enter> for next page${NORM})";

  echo -en "
  ${UL}Session Information${NO_UL}\r
    ${BOLD}info${NORM}\r
    \tShow tmux session information, if tmux server is active.\r

    ${BOLD}defaults${NORM}\r
    \tShow the session defaults that are hard-coded into this script.\r

    ${BOLD}sessions${NORM}\r
    \tShow running tmux sessions.\r

  ${UL}General Script Information${NO_UL}\r
    ${BOLD}help${NORM}\r
    ${BOLD}helpfull${NORM} (this menu)\r
    
    Debug/Verbose Mode (${BOLD}Must be first argument${NORM})\r
      -v    : Minimal verbosity/debug information\r
      -vv   : More verbose/some internal debug information\r
      -vvv  : Most debug information\r
      -vvvv : Full verbosity/All debug information\r
  
    Output conventions\r
      [${BOLD_GREEN}INFO${NORM}]  General debugging information.
      [${BOLD_YELLOW}WARN${NORM}]  Most non-fatal errors, like conflicts \r
              with existing sessions. Script may or may not exit.\r
      [${BOLD_RED}ERROR${NORM}] Major errors. Script will exit (with \r 
              limited exceptions). Syntax errors fall into this category.\r
      [${BOLD_BG_RED}FATAL${NORM}] Fatal errors. Script will exit (no exceptions).\n\n";

  # [debug] Function end
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][FULLHELP][${BOLD_GREEN}INFO${NORM}] Leaving 'fullhelp' function";
  fi

  # Exit gracefully
  exit 0;
}




##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: check_symlink
# PURPOSE: Checks for a symlink named the same as the script, but 
#           without ".sh"
# ARGUMENTS: 
# - None
# OUTPUT:
# - No console
# - Create 'brainmux' symlink in current directory if it doesn't
#   exist and it's possible.
##############################################################################
function check_symlink()
{
  # [debug] Function start
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][CHECK_SYMLINK][${BOLD_GREEN}INFO${NORM}] Entering 'check_symlink' function";
  fi

  # If NOT symlink...
  if [[ ! $(test -L "$0" && readlink "$0") ]];
  then
    if [[ $debug4 == true ]];
    then
      echo "[DEBUG][CHECK_SYMLINK][${BOLD_GREEN}INFO${NORM}] $SCRIPT_NAME_FULL_LONG is NOT a symlink.";
    fi

    # Check for a symlink
    if [[ ! $(test -L "$SCRIPT_NAME_BASE_LONG" && readlink "$SCRIPT_NAME_BASE_LONG") ]];
    then
      # No symlink found in current directory
      echo "[${BOLD_GREEN}INFO${NORM}] No symlink found in execution directory.";
      # Use full path so the command is universal no matter what directory you're in
      echo "[${BOLD_GREEN}INFO${NORM}] Run ${BOLD}ln -s $SCRIPT_NAME_FULL_LONG $SCRIPT_NAME_BASE_LONG${NORM} if you would like one.";
    else
      # Symlink found: Silently continue, unless debugging
      if [[ $debug4 == true ]];
      then
        echo "[DEBUG][CHECK_SYMLINK][${BOLD_GREEN}INFO${NORM}] Found a symlink during second check: $SCRIPT_NAME_BASE_LONG";
      fi
    fi
  else
    # Is a symlink
    # Silently continue, unless debugging
    if [[ $debug4 == true ]];
    then
#      echo "[DEBUG][CHECK_SYMLINK][${BOLD_GREEN}INFO${NORM}] First check found a symlink, actual script name: $(basename "$(test -L "$0" && readlink "$0" || echo "$0")")";
      echo "[DEBUG][CHECK_SYMLINK][${BOLD_GREEN}INFO${NORM}] I am a symlink; actual script name: $SCRIPT_NAME_FULL_LONG";
    fi
  fi

  # [debug] Function end
  if [[ $debug4 == true ]];
  then 
    echo "[DEBUG][CHECK_SYMLINK][${BOLD_GREEN}INFO${NORM}] Leaving 'check_symlink' function";
  fi

  # No exit
}




##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: defaults
# PURPOSE: Read tmux defaults and display them
# ARGUMENTS:
# - None
# OUTPUT:
# - tmux defaults as defined by SESSION_DEFAULTS array
##############################################################################
function defaults()
{
  # [debug] Function start
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][DEFAULTS][${BOLD_GREEN}INFO${NORM}] Entering 'defaults' function";
  fi

  # Window layout
  echo -e " \
  ################### ###################\n \
  #      Window 1   # #     Window 2    #\n \
  ################### ###################\n \
  # Pane 1 # Pane 2 # #                 #\n \
  # (bash) # (bash) # #     (bash)      #\n \
  #        #        # #                 #\n \
  #  50%   #  50%   # #      100%       #\n \
  ################### ###################\n \
  \n \
  ################### ###################\n \
  #     Window 3    # #     Window 4    #\n \
  ################### ###################\n \
  #                 # #                 #\n \
  #      (bash)     # #      (bash)     #\n \
  #                 # #                 #\n \
  #       100%      # #       100%      #\n \
  ################### ###################\n";

  # Options
  echo -e "${BOLD}Session creation commands:${NORM}\n";
  
  # Output default session creation parameters
  # Use 'sdefault' to prevent potential collisions with 'default'
  for sdefault in "${SESSION_DEFAULTS[@]}";
  do
    echo "   $sdefault";
  done

  # Print tmux.conf
  # [console] Tmux.conf Contents
  if [[ -e ~/.tmux.conf ]];
  then
    echo -e "\n${BOLD}Contents of ${UL}~/.tmux.conf${NORM}\n";
    #cat ~/.tmux.conf;

    # Intelligent parsing
    while read line; do
      echo $line;

    done < ~/.tmux.conf
  fi
  
  if [[ -e /etc/tmux.conf ]];
  then
    echo -e "\n${BOLD}Contents of ${UL}/etc/tmux.conf${NORM}\n";
    cat /etc/tmux.conf;
  fi

  # [debug] Function end
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][DEFAULTS][${BOLD_GREEN}INFO${NORM}] Leaving 'defaults' function";
  fi

  # Exit gracefully
  exit 0;
}




##############################################################################
##############################################################################
# FUNCTION 
############################################################################## 
# NAME: check_session
# PURPOSE: Check if specified session exists
# ARGUMENTS:
# - $1 : Session to check for
# OUTPUT:
# - Sets status of $tmux_status
##############################################################################
function check_session()
{
  # [debug] Function start
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][CHECK_SESSION][${BOLD_GREEN}INFO${NORM}] Entering 'check_session' function";
  fi

  # Variables
  tmux_status="999";         # Reset at start of function as a safeguard
  local tmuxSession="$1";   # Contains a passed in session name

  # Check for existing session
  tmux has-session -t "$tmuxSession" &>/dev/null;

  # Grab exit from check
  tmux_status=$?;

  # [debug] Session check
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][CHECK_SESSION][${BOLD_GREEN}INFO${NORM}] Session tested = $tmuxSession";
    echo "[DEBUG][CHECK_SESSION][${BOLD_GREEN}INFO${NORM}] tmux_status = $tmux_status";
  fi

  # [debug] Function end
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][CHECK_SESSION][${BOLD_GREEN}INFO${NORM}] Leaving 'check_session' function";
  fi
}




##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: create 
# PURPOSE: Create/start new tmux session
# ARGUMENTS:
# - Command line args : ${cli_args[@]}
# OUTPUT:
# - None (sessions created silently)
##############################################################################
function create()
{
  # create() function also aliased as 'start' and 'new'

  # [debug] Function start
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM}] Entering 'create' function";
  fi

  # Variables
  local sessionArgs;
  sessionArgs=("${cli_args[@]}");

  if [[ "${sessionArgs[$arg_pos]}" == "" ]];
  then
    # [debug] No session specified, creating generic session
    if [[ $debug3 == true ]];
    then
      echo "[DEBUG][CREATE][${BOLD_YELLOW}WARN${NORM}] No session names specified";
    fi

    # [console] No session specified, creating generic session
    echo "[${BOLD_YELLOW}WARNING${NORM}] No session name specified," \
    "tmux will choose one for you. Run this script with the" \
    "'sessions' command to identify running tmux sessions.";

    # Parse SESSION_DEFAULTS array and execute commands
    for param in "${SESSION_DEFAULTS[@]}";
    do
      `$param`;
    done
  else
    # Check sessions at command line, create if they don't exist, otherwise error
    # Start from array element 1 = elements after "create" command
    for i in "${sessionArgs[@]:$arg_pos}"
    do
      # [debug] Identify parsed session name
      if [[ $debug4 == true ]];
      then
        echo "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM}] Parsed session name: $i"; 
      fi

      # Check to see if a session by the same name exists
      # 'check_session' updates $tmux_status variable
      # Session does not exist: tmux_status = 1
      # Session exists: tmux_status = 0
      check_session "$i";
    
      # If check_session didn't find an existing session, create it
      if [[ "$tmux_status" == "1" ]];
      then
        # [debug] Creating session
        if [[ $debug3 == true ]];
        then
          echo "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM}] Creating session $i";
        fi

        # Relies on array matching these base values
        #tmux new-session -d -s $i;
        #tmux split-window -h -p 50 -t $i;
        #tmux new-window -t $i;
        #tmux new-window -t $i;
        #tmux new-window -t $i;
        #tmux select-window -t $i:0;
        #tmux select-pane -L -t $i:0;

        # Go through SESSION_DEFAULTS array line by line and execute custom commands
        if [[ $debug4 == true ]];
        then
          echo "[DEBUG][CREATE] Create session executing: ${SESSION_DEFAULTS[0]} -s $i";
          ${SESSION_DEFAULTS[0]} -s $i;

          echo "[DEBUG][CREATE] Create session executing: ${SESSION_DEFAULTS[1]} -t $i";
          ${SESSION_DEFAULTS[1]} -t $i;

          echo "[DEBUG][CREATE] Create session executing: ${SESSION_DEFAULTS[2]} -t $i";
          ${SESSION_DEFAULTS[2]} -t $i;

          echo "[DEBUG][CREATE] Create session executing: ${SESSION_DEFAULTS[3]} -t $i";
          ${SESSION_DEFAULTS[3]} -t $i;

          echo "[DEBUG][CREATE] Create session executing: ${SESSION_DEFAULTS[4]} -t $i";
          ${SESSION_DEFAULTS[4]} -t $i;

          echo "[DEBUG][CREATE] Create session executing: ${SESSION_DEFAULTS[5]/-t:0/-t $i:0}";
          ${SESSION_DEFAULTS[5]/-t:0/-t $i:0};

          echo "[DEBUG][CREATE] Create session executing: ${SESSION_DEFAULTS[6]/-t:0/-t $i:0}";
          ${SESSION_DEFAULTS[6]/-t:0/-t $i:0};
        else
          ${SESSION_DEFAULTS[0]} -s $i;
          ${SESSION_DEFAULTS[1]} -t $i;
          ${SESSION_DEFAULTS[2]} -t $i;
          ${SESSION_DEFAULTS[3]} -t $i;
          ${SESSION_DEFAULTS[4]} -t $i;
          ${SESSION_DEFAULTS[5]/-t:0/-t $i:0};
          ${SESSION_DEFAULTS[6]/-t:0/-t $i:0};
        fi
      else
        # [debug] Session exists, skipped
        if [[ $debug3 == true ]];
        then
          echo "[DEBUG][CREATE][${BOLD_YELLOW}WARN${NORM}] Session '${BOLD}$i${NORM}' exists. Skipped.";
        fi

        # [console] Session exists, skipped
        echo "[${BOLD_YELLOW}WARNING${NORM}] Session '${BOLD}$i${NORM}' exists. Skipped.";
      fi
    done
  fi

  # [debug] Function end
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM}] Leaving 'create' function";
  fi

  # Exit gracefully
  exit 0;
}




##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: destroy 
# PURPOSE: Kill/destroy existing tmux sessions
# ARGUMENTS:
# - session name to kill
# OUTPUT:
# - None
##############################################################################
function destroy()
{
  # destroy() function also aliased as 'kill' and 'stop'

  # [debug] Function start
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][DESTROY][${BOLD_GREEN}INFO${NORM}] Entering 'destroy' function";
  fi

  # Variables
  local sessionArgs;
  sessionArgs=("${cli_args[@]}");

  # Kill all sessions if 'all' is the first argument after command
  if [[ "${sessionArgs[$arg_pos]}" == "" ]];
  then
    # [debug] No session specified
    if [[ $debug3 == true ]];
    then
      echo "[DEBUG][DESTROY][${BOLD_RED}ERROR${NORM}] No session names specified";
    fi

    # [console] No session specified
    echo "[${BOLD_RED}ERROR${NORM}] No session names specified";
  elif [[ "${sessionArgs[$arg_pos]}" == "all" ]];
  then
    # Kill the server
    echo -n "${BOLD_BG_RED}CAUTION${NORM} You're about to kill the tmux server and all sessions. Continue [y/N]? ";
    read -t 10 KILLCHOICE;
    
    case $KILLCHOICE in
      y|Y|yes|Yes|YES)
        # Kill server
        tmux kill-server &>/dev/null;
        
        # [console] All tmux sessions killed
        echo "tmux server and all sessions have been ${BOLD_RED}killed${NORM}.";
      ;;
      n|N|no|No|NO)
        echo "Kill server ${BOLD_GREEN}aborted${NORM}.";
      ;;
      *)
        echo "Invalid choice, server was ${BOLD_RED}not${NORM} killed.";
      ;;
    esac
  else
    # Check sessions at command line, delete them if they exist, otherwise throw error
    # Start from array element 1 = elements after "destroy" command
    for i in "${sessionArgs[@]:$arg_pos}"
    do
      # [debug] Identify parsed session name
      if [[ $debug4 == true ]];
      then
        echo "[DEBUG][DESTROY][${BOLD_GREEN}INFO${NORM}] Parsed session name: $i"; 
      fi

      # Check to see if a session by the same name exists
      # 'check_session' updates $tmux_status variable
      # Session does not exist: tmux_status = 1
      # Session exists: tmux_status = 0
      check_session "$i";

      # If check_session found an existing session, kill it
      if [[ "$tmux_status" == "0" ]]; 
      then
        # [debug] Destroying session
        if [[ $debug3 == true ]];
        then
          echo "[DEBUG][DESTROY][${BOLD_GREEN}INFO${NORM}] Destroying session '${BOLD}$i${NORM}'";
        fi

        # Destroy session
        tmux kill-session -t $i;
      else
        # [debug] Session does not exist, skipped
        if [[ $debug3 == true ]];
        then
          echo "[DEBUG][DESTROY][${BOLD_YELLOW}WARN${NORM}] Session '${BOLD}$i${NORM}' does not exist. Skipped.";
        fi

        # [console] Session does not exist, skipped
        echo "[${BOLD_YELLOW}WARNING${NORM}] Session '${BOLD}$i${NORM}' does not exist. Skipped.";
      fi
    done
  fi

  # [debug] Function end
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][DESTROY][${BOLD_GREEN}INFO${NORM}] Leaving 'destroy' function";
  fi

  # Exit gracefully
  exit 0;
}




##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: attach
# PURPOSE: Attach to existing tmux session
# ARGUMENTS:
# - Session name
# OUTPUT:
# - None
##############################################################################
function attach()
{
  # [debug] Function start
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][ATTACH][${BOLD_GREEN}INFO${NORM}] Entering 'attach' function";
  fi

  # Variables
  local sessionArgs;
  sessionArgs=("${cli_args[@]}");

  if [[ "${sessionArgs[$arg_pos]}" == "" ]]; 
  then
    # [debug] No session specified, attach to session if only one session exists
    if [[ $debug3 == true ]];
    then
      echo "[DEBUG][ATTACH][${BOLD_YELLOW}WARN${NORM}] No session names specified";
    fi

    if [[ `tmux list-sessions | wc -l 2>/dev/null` -eq 1 ]];
    then
      # [console] No session specified, attach to only session
      echo "[${BOLD_YELLOW}WARNING${NORM}] No session specified, attaching to the only running session."

      # More processor intensive, but defines a specific session to attach to 
      # help prevent MITM attacks.
      tmux attach -t `tmux list-sessions | cut -d':' -f1`;
    else
      # [console] No session specified and none to attach to
      echo "[${BOLD_RED}ERROR${NORM}] No session specified and no usable session found to attach to."
    fi
  else
    # [debug] Identify parsed session name
    if [[ $debug4 == true ]];
    then
      echo "[DEBUG][ATTACH][${BOLD_GREEN}INFO${NORM}] Parsed session name: ${sessionArgs[$arg_pos]}";
    fi

    # Check to see if session exists
    check_session "${sessionArgs[$arg_pos]}";

    if [[ "$tmux_status" == "0" ]];
    then
      # [debug] Found session, connecting...
      if [[ $debug3 == true ]];
      then
        echo "[DEBUG][ATTACH][${BOLD_GREEN}INFO${NORM}] Found session, ${BOLD}${sessionArgs[$arg_pos]}${NORM}, attaching...";
      fi

      # [console] Found session, connecting... 
      echo "Found session, ${BOLD}${sessionArgs[$arg_pos]}${NORM}, attaching...";

      # Attach session
      tmux attach-session -t ${sessionArgs[$arg_pos]};
    else
      # [debug] Specified session does not exist
      if [[ $debug3 == true ]];
      then
        echo "[DEBUG][ATTACH][${BOLD_RED}ERROR${NORM}] Specified session does not exist";
      fi

      # [console] Specified session does not exist
      echo "[${BOLD_RED}ERROR${NORM}] Specified session, ${BOLD}${sessionArgs[$arg_pos]}${NORM}, does not exist";
    fi
  fi

  # [debug] Function end
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][ATTACH][${BOLD_GREEN}INFO${NORM}] Leaving 'attach' function";
  fi

  # Exit gracefully
  exit 0;
}




##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: detach
# PURPOSE: Detach existing tmux session
# ARGUMENTS:
# - Session name
# OUTPUT:
# - None
##############################################################################
function detach()
{
  # [debug] Function start
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][DETACH][${BOLD_GREEN}INFO${NORM}] Entering 'detach' function";
  fi

  # Variables
  local sessionArgs;
  sessionArgs=("${cli_args[@]}");

  if [[ "${sessionArgs[$arg_pos]}" == "" ]]; 
  then
    # [debug] No session specified, error and exit
    if [[ $debug3 == true ]];
    then
      echo "[DEBUG][DETACH][${BOLD_RED}ERROR${NORM}] No session specified, cannot continue.";
    fi

    # [console]
    echo -e "\n[${BOLD_RED}ERROR${NORM}] No session specified, cannot continue.";

    quickhelp;
  else
    # [debug] Identify parsed session name
    if [[ $debug4 == true ]];
    then
      echo "[DEBUG][DETACH][${BOLD_GREEN}INFO${NORM}] Parsed session name: ${sessionArgs[$arg_pos]}";
    fi

    # Check to see if session exists
    check_session "${sessionArgs[$arg_pos]}";

    if [[ "$tmux_status" == "0" ]];
    then
      # [debug] Found session, trying to detach it...
      if [[ $debug3 == true ]];
      then
        echo "[DEBUG][DETACH][${BOLD_GREEN}INFO${NORM}] Found session, ${BOLD}${sessionArgs[$arg_pos]}${NORM}, trying to detach it...";
      fi

      # [console] Found session, trying to detach it... 
      echo "Found session, ${BOLD}${sessionArgs[$arg_pos]}${NORM}, trying to detach it...";

      # Attach session
      tmux detach-client -s ${sessionArgs[$arg_pos]};
    else
      # [debug] Specified session does not exist
      if [[ $debug3 == true ]];
      then
        echo "[DEBUG][DETACH][${BOLD_RED}ERROR${NORM}] Specified session does not exist.";
      fi

      # [console] Specified session does not exist
      echo "[${BOLD_RED}ERROR${NORM}] Specified session," \
      "${BOLD}${sessionArgs[$arg_pos]}${NORM}, does not exist. Run" \
      "this script with the ${BOLD}sessions${NORM} command to show" \
      "existing tmux sessions.";
    fi
  fi

  # [debug] Function end
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][DETACH][${BOLD_GREEN}INFO${NORM}] Leaving 'detach' function";
  fi

  # Exit gracefully
  exit 0;
}




##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: info
# PURPOSE: Display info on current tmux sessions
# ARGUMENTS:
# - None
# OUTPUT:
# - Tmux session information
##############################################################################
function info()
{
  # [debug] Function start
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][INFO][${BOLD_GREEN}INFO${NORM}] Entering 'info' function";
  fi
 
  # Get information on running tmux sessions
  tmux info &>/dev/null
      
  # Grab exit code from 'tmux info' output
  tmux_status=$?;

  if [[ $tmux_status -eq 1 ]];
  then
    echo "[${BOLD_BG_RED}FATAL${NORM}] tmux is not running";
  else
    # Execute native tmux info command
    tmux info;
  fi

  # [debug] Function end
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][INFO][${BOLD_GREEN}INFO${NORM}] Leaving 'info' function";
  fi

  # Exit gracefully
  exit 0;
}




##############################################################################
##############################################################################
# FUNCTION 
##############################################################################
# NAME: custom
# PURPOSE: Create a custom tmux session
# ARGUMENTS:
# - Session properties
# OUTPUT:
# - None
##############################################################################
function custom()
{
  # [debug] Function start
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][CUSTOM][${BOLD_GREEN}INFO${NORM}] Entering 'custom' function";
  fi

  echo "${BOLD_YELLOW}<TODO>${NORM}";


  # [debug] Function end
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][CUSTOM][${BOLD_GREEN}INFO${NORM}] Leaving 'custom' function";
  fi

  # Exit gracefully
  exit 0;
}





##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: sessions
# PURPOSE: List active tmux sessions
# ARGUMENTS:
# - None
# OUTPUT:
# - tmux session list, if tmux is running
##############################################################################
function sessions()
{
  # [debug] Function start
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][SESSIONS][${BOLD_GREEN}INFO${NORM}] Entering 'sessions' function";
  fi

  # Call native tmux command for listing current sessions
  tmux list-sessions;

  # [debug] Function end
  if [[ $debug4 == true ]];
  then
    echo "[DEBUG][SESSIONS][${BOLD_GREEN}INFO${NORM}] Leaving 'sessions' function";
  fi

  # Exit gracefully
  exit 0;
}




##############################################################################
##############################################################################
# MAIN
##############################################################################
if [[ $# -gt 0 ]];
then
  cli_cmd="$1";
  arg_pos="1";

  if [[ "$cli_cmd" =~ "-v" ]];
  then
    case $cli_cmd in
      -v)
        debug1=true;
        # No console confirmation for debug level 1
      ;;
      -vv)
        debug1=true;
        debug2=true;
        # No console confirmation for debug level 2
      ;;
      -vvv)
        debug1=true;
        debug2=true;
        debug3=true;
        echo -e "\n[DEBUG][MAIN][${BOLD_YELLOW}WARN${NORM}] Debug level 3 enabled\n";
      ;;
      -vvvv)
        debug1=true;
        debug2=true;
        debug3=true;
        debug4=true;
        echo -e "\n[DEBUG][MAIN][${BOLD_YELLOW}WARN${NORM}] Debug level 4 enabled\n";
      ;;
      *)
        # Bad verbose flag
        echo "[${BOLD_YELLOW}WARN${NORM}] Bad verbose flag, '${BOLD}$cli_cmd${NORM}.' Continuing without verbosity."
      ;;
    esac
    
    cli_cmd="$2";
    arg_pos="2";
  fi

  # Check for symlink
  check_symlink;

  case $cli_cmd in
    autocompletelist)
      # Output list of script options for the autocomplete function
      echo "attach connect create custom defaults destroy detach disconnect info help kill new sessions start stop ?";
    ;;
    create|Create|CREATE|start|Start|START|new|New|NEW)
      # Start tmux session
      # Session names parsed from global arguments variable
      create;

      # Just-in-case... (but this shouldn't be reached)
      exit 0;
    ;;
    destroy|Destroy|DESTROY|kill|Kill|KILL|stop|Stop|STOP)
      # Kill tmux session
      destroy;

      # Just-in-case... (but this shouldn't be reached)
      exit 0;
    ;;
    attach|Attach|ATTACH|connect|Connect|CONNECT)
      # Attach tmux session
      attach;

      # Just-in-case... (but this shouldn't be reached)
      exit 1;
    ;;
    detach|Detach|DETACH|disconnect|Disconnect|DISCONNECT)
      # Detach tmux session
      detach;

      # Just-in-case... (but this shouldn't be reached)
      exit 1;
    ;;
    info|Info|INFO)
      # Get information on running tmux sessions
      info;

      # Just-in-case... (but this shouldn't be reached)
      exit 1;
    ;;
    custom|Custom|CUSTOM)
      # Create a new tmux session with custom properties
      custom;

      # Just-in-case... (but this shouldn't be reached)
      exit 1;
    ;;
    defaults|Defaults|DEFAULTS)
      # Show script-default laytout
      defaults;

      # Just-in-case... (but this shouldn't be reached)
      exit 1;
    ;;
    sessions|Sessions|SESSIONS)
      # Show current tmux sessions
      sessions;

      # Just-in-case... (but this shouldn't be reached)
      exit 1;
    ;;
    h|help|Help|HELP|?)
      # Call quick help function
      quickhelp;

      # Just-in-case... (but this shouldn't be reached)
      exit 1;
    ;;
    helpfull|Helpfull|HELPFULL)
      # Call full help function
      fullhelp;

      # Just-in-case... (but this shouldn't be reached)
      exit 1;
    ;;
    *)
    # [console] Bad flag, show error and call quick help function
    echo "[${BOLD_RED}ERROR${NORM}] Bad flag, '${BOLD}$cli_cmd${NORM}'";
    
    quickhelp;

    # Just-in-case... (but this shouldn't be reached)
    exit 1;
    ;;
  esac
else
  # FAILURE: Script requires at least one argument, show error and call quick help function
  
  # Random number generation localized so it's not called unless needed
  # Generate random number within range 0 - ARRAY_LEN
  RAND=$RANDOM;
  let RAND%=${#FAILURE_QUOTES[@]};

  # Print a funny quote from FAILURE_QUOTES array for instances when no command is entered
  echo -e "\n[${BOLD_RED}FAILURE${NORM}] ${FAILURE_QUOTES[$RAND]}";

  # Show the documentation
  quickhelp;

  # Just-in-case... (but this shouldn't be reached)
  exit 0;
fi
