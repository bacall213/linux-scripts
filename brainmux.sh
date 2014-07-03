#!/bin/bash

######################################################################
# BRAINBOX TMUX SESSION MANAGER
######################################################################
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
#   3) 
#
# CONVENTIONS USED:
#   - Versioning standard: 
#     - v[major_version].[month(M)].[year(YYYY)]-b[build_num]
#     - e.g. v1.1.2014-b20 = Major version 1, January 2014, build 20
#
# REVISION HISTORY:
#   - v1.6.2014-b1
#     - Initial public release
#
# TODO:
#   1) Custom session
#   2) Read and intelligently output .tmux.conf or /etc/tmux.conf in
#      defaults function.
#   3) Ensure all inputs are sanitized
#
######################################################################

######################################################################
######################################################################
# VARIABLES
######################################################################
CLI_CMD="";
ARG_POS="";
tmuxStatus="999";
CLI_ARGS=("$@");
DEBUG1=false;                         # -v    : Minimal debug info
DEBUG2=false;                         # -vv   : Some debug info
DEBUG3=false;                         # -vvv  : Most debug info
DEBUG4=false;                         # -vvvv : All debug info

# Formatting variables
bold=$(tput bold);                    # Bold
ul=$(tput smul);                      # Underline
noul=$(tput rmul);                    # No underline
norm=$(tput sgr0);                    # Normal (not bolded)
boldbgred=${bold}$(tput setab 1);     # Bold w/red background
boldred=${bold}$(tput setaf 1);       # Bold red
boldbgyellow=${bold}$(tput setab 3);  # Bold w/yellow background
boldyellow=${bold}$(tput setaf 3);    # Bold yellow
boldgreen=${bold}$(tput setaf 2);     # Bold green
boldbggreen=${bold}$(tput setab 2);   # Bold w/green background

# Session defaults
# CAUTION: create() depends on these values being in a particular order
SESSION_DEFAULTS=('tmux new-session -d'
                  'tmux split-window -h -p 50'
                  'tmux new-window'
                  'tmux new-window'
                  'tmux new-window'
                  'tmux select-window -t:0'
                  'tmux select-pane -L -t:0');

# Failure quotes array
FAILURE_QUOTES=("My great concern is not whether you have failed, but whether you are content with your failure. --Abraham Lincoln"
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



#####################################################################
#####################################################################
# FUNCTION
#####################################################################
# NAME: quickhelp
# PURPOSE: Display short script help information
# ARGUMENTS:
# - None
# OUTPUT:
# - Script help information
#####################################################################
function quickhelp()
{
  # [debug] Function start
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][QUICKHELP][${boldgreen}INFO${norm}] Entering 'quickhelp' function";
  fi

  echo -en "\n${bold}USAGE :: $0${norm} [-v|vv|vvv|vvvv] ${bold}command${norm} ${ul}options${noul}\r\n
  ${ul}Create and Destroy Sessions${noul}\r
    ${bold}create${norm} [${ul}session_1${noul} ${ul}session_2${noul} ${ul}session_3${noul} ...]\r
    \t(aliases: ${bold}new${norm}, ${bold}start${norm})\r

    ${bold}destroy${norm} [all] ${ul}existing_session${noul}\r
    \t(aliases: ${bold}stop${norm}, ${bold}kill${norm})\r

  ${ul}Connect and Disconnect Sessions${noul}\r
    ${bold}connect${norm} ${ul}existing_session${noul}\r
    \t(alias: ${bold}attach${norm})\r

    ${bold}disconnect${norm} ${ul}existing_session${noul}\r
    \t(alias: ${bold}detach${norm})\r

  ${ul}Create a Custom Session${noul}\r
    ${bold}custom${norm} ${ul}session_properties${noul}\r

  ${ul}Session Information${noul}\r
    ${bold}info${norm}\r
    ${bold}defaults${norm}\r
    ${bold}sessions${norm}\r

  ${ul}General Script Options${noul}\r
    ${bold}help${norm} (this menu)\r
    ${bold}helpfull${norm}\r
    
    Debug/Verbose Mode (${bold}Must be first argument${norm})\r
      -v    : Minimal verbosity/debug information\r
      -vv   : More verbose/some internal debug information\r
      -vvv  : Most debug information\r
      -vvvv : Full verbosity/All debug information\n\n";

  # [debug] Function end
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][QUICKHELP][${boldgreen}INFO${norm}] Leaving 'quickhelp' function";
  fi

  # Exit gracefully
  exit 0;
}




#####################################################################
#####################################################################
# FUNCTION
#####################################################################
# NAME: fullhelp
# PURPOSE: Display full script help information
# ARGUMENTS:
# - None
# OUTPUT:
# - Script help information
#####################################################################
function fullhelp()
{
  # [debug] Function start
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][FULLHELP][${boldgreen}INFO${norm}] Entering 'fullhelp' function";
  fi

  echo -en "\n${bold}USAGE :: $0${norm} [-v|vv|vvv|vvvv] ${bold}command${norm} ${ul}options${noul}\r\n
  ${ul}Create and Destroy Sessions${noul}\r
    ${bold}create${norm} [${ul}session_1${noul} ${ul}session_2${noul} ${ul}session_3${noul} ...]\r
    \t(aliases: ${bold}new${norm}, ${bold}start${norm})\r

    \tCreate one or multiple tmux sessions. If no session name is specified, \r
    \ttmux will create a new session named using its own mechanisms. If a \r
    \tspecified session already exists, this script will skip over that \r
    \tsession.\r

    ${bold}destroy${norm} [all] ${ul}existing_session${noul}\r
    \t(aliases: ${bold}stop${norm}, ${bold}kill${norm})\r

    \tDestroy single, or all, existing tmux sessions. If 'all' is \r
    \tspecified, this script will try to destroy all existing sessions. \r

  ${ul}Connect and Disconnect Sessions${noul}\r
    ${bold}connect${norm} ${ul}existing_session${noul}\r
    \t(alias: ${bold}attach${norm})\r

    \tConnect to an existing tmux session.\r

    ${bold}disconnect${norm} ${ul}existing_session${noul}\r
    \t(alias: ${bold}detach${norm})\r

    \tDisconnect from an existing tmux session.\r
 
  ${ul}Create a Custom Session${noul}\r
    ${bold}custom${norm} ${ul}session_properties${noul}\r

    \tCreate a custom tmux session using provided ${ul}session_properties${noul}.\r
    \tAll tmux.conf defaults and script defaults are ignored.\r

    \tFormat: ${boldyellow}<TODO>${norm}\r

  ${ul}Session Information${noul}\r
    ${bold}info${norm}\r
    \tShow tmux session information, if tmux server is active.\r

    ${bold}defaults${norm}\r
    \tShow the session defaults that are hard-coded into this script.\r

    ${bold}sessions${norm}\r
    \tShow running tmux sessions.\r

  ${ul}General Script Information${noul}\r
    ${bold}help${norm}\r
    ${bold}helpfull${norm} (this menu)\r
    
    Debug/Verbose Mode (${bold}Must be first argument${norm})\r
      -v    : Minimal verbosity/debug information\r
      -vv   : More verbose/some internal debug information\r
      -vvv  : Most debug information\r
      -vvvv : Full verbosity/All debug information\r
  
    Output conventions\r
      [${boldgreen}INFO${norm}]  General debugging information.
      [${boldyellow}WARN${norm}]  Most non-fatal errors, like conflicts \r
              with existing sessions. Script may or may not exit.\r
      [${boldred}ERROR${norm}] Major errors. Script will exit (with \r 
              limited exceptions). Syntax errors fall into this category.\r
      [${boldbgred}FATAL${norm}] Fatal errors. Script will exit (no exceptions).\n\n";

  # [debug] Function end
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][FULLHELP][${boldgreen}INFO${norm}] Leaving 'fullhelp' function";
  fi

  # Exit gracefully
  exit 0;
}




#####################################################################
#####################################################################
# FUNCTION
#####################################################################
# NAME: check_symlink
# PURPOSE: Make sure a symlink for the script without ".sh"
#           still exists.
# ARGUMENTS: 
# - None
# OUTPUT:
# - No console
# - Create 'brainmux' symlink in current directory if it doesn't
#   exist and it's possible.
#####################################################################
function check_symlink()
{
  echo "<TODO> Checking for symlink";


  # No exit
}




#####################################################################
#####################################################################
# FUNCTION
#####################################################################
# NAME: defaults
# PURPOSE: Read tmux defaults and display them
# ARGUMENTS:
# - None
# OUTPUT:
# - tmux defaults as defined by SESSION_DEFAULTS array
#####################################################################
function defaults()
{
  # [debug] Function start
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][DEFAULTS][${boldgreen}INFO${norm}] Entering 'defaults' function";
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
  echo -e "${bold}Session creation commands:${norm}\n";
  
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
    echo -e "\n${bold}Contents of ${ul}~/.tmux.conf${norm}\n";
    cat ~/.tmux.conf;
  fi
  
  if [[ -e /etc/tmux.conf ]];
  then
    echo -e "\n${bold}Contents of ${ul}/etc/tmux.conf${norm}\n";
    cat /etc/tmux.conf;
  fi

  # [debug] Function end
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][DEFAULTS][${boldgreen}INFO${norm}] Leaving 'defaults' function";
  fi

  # Exit gracefully
  exit 0;
}




#####################################################################
#####################################################################
# FUNCTION 
##################################################################### 
# NAME: check_session
# PURPOSE: Check if specified session exists
# ARGUMENTS:
# - $1 : Session to check for
# OUTPUT:
# - Sets status of $tmuxStatus
#####################################################################
function check_session()
{
  # [debug] Function start
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][CHECK_SESSION][${boldgreen}INFO${norm}] Entering 'check_session' function";
  fi

  # Variables
  tmuxStatus="999";         # Reset at start of function as a safeguard
  local tmuxSession="$1";   # Contains a passed in session name

  # Check for existing session
  tmux has-session -t "$tmuxSession" &>/dev/null;

  # Grab exit from check
  tmuxStatus=$?;

  # [debug] Session check
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][CHECK_SESSION][${boldgreen}INFO${norm}] Session tested = $tmuxSession";
    echo "[DEBUG][CHECK_SESSION][${boldgreen}INFO${norm}] tmuxStatus = $tmuxStatus";
  fi

  # [debug] Function end
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][CHECK_SESSION][${boldgreen}INFO${norm}] Leaving 'check_session' function";
  fi
}




#####################################################################
#####################################################################
# FUNCTION
#####################################################################
# NAME: create 
# PURPOSE: Create/start new tmux session
# ARGUMENTS:
# - Command line args : ${CLI_ARGS[@]}
# OUTPUT:
# - None (sessions created silently)
#####################################################################
function create()
{
  # create() function also aliased as 'start' and 'new'

  # [debug] Function start
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][CREATE][${boldgreen}INFO${norm}] Entering 'create' function";
  fi

  # Variables
  local sessionArgs=("${CLI_ARGS[@]}");

  if [[ "${sessionArgs[$ARG_POS]}" == "" ]];
  then
    # [debug] No session specified, creating generic session
    if [[ $DEBUG3 == true ]];
    then
      echo "[DEBUG][CREATE][${boldyellow}WARN${norm}] No session names specified";
    fi

    # [console] No session specified, creating generic session
    echo "[${boldyellow}WARNING${norm}] No session name specified," \
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
    for i in "${sessionArgs[@]:$ARG_POS}"
    do
      # [debug] Identify parsed session name
      if [[ $DEBUG4 == true ]];
      then
        echo "[DEBUG][CREATE][${boldgreen}INFO${norm}] Parsed session name: $i"; 
      fi

      # Check to see if a session by the same name exists
      # 'check_session' updates $tmuxStatus variable
      # Session does not exist: tmuxStatus = 1
      # Session exists: tmuxStatus = 0
      check_session "$i";
    
      # If check_session didn't find an existing session, create it
      if [[ "$tmuxStatus" == "1" ]];
      then
        # [debug] Creating session
        if [[ $DEBUG3 == true ]];
        then
          echo "[DEBUG][CREATE][${boldgreen}INFO${norm}] Creating session $i";
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
        if [[ $DEBUG4 == true ]];
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
        if [[ $DEBUG3 == true ]];
        then
          echo "[DEBUG][CREATE][${boldyellow}WARN${norm}] Session '${bold}$i${norm}' exists. Skipped.";
        fi

        # [console] Session exists, skipped
        echo "[${boldyellow}WARNING${norm}] Session '${bold}$i${norm}' exists. Skipped.";
      fi
    done
  fi

  # [debug] Function end
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][CREATE][${boldgreen}INFO${norm}] Leaving 'create' function";
  fi

  # Exit gracefully
  exit 0;
}




#####################################################################
#####################################################################
# FUNCTION
#####################################################################
# NAME: destroy 
# PURPOSE: Kill/destroy existing tmux sessions
# ARGUMENTS:
# - session name to kill
# OUTPUT:
# - None
#####################################################################
function destroy()
{
  # destroy() function also aliased as 'kill' and 'stop'

  # [debug] Function start
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][DESTROY][${boldgreen}INFO${norm}] Entering 'destroy' function";
  fi

  # Variables
  local sessionArgs=("${CLI_ARGS[@]}");

  # Kill all sessions if 'all' is the first argument after command
  if [[ "${sessionArgs[$ARG_POS]}" == "" ]];
  then
    # [debug] No session specified
    if [[ $DEBUG3 == true ]];
    then
      echo "[DEBUG][DESTROY][${boldred}ERROR${norm}] No session names specified";
    fi

    # [console] No session specified
    echo "[${boldred}ERROR${norm}] No session names specified";
  elif [[ "${sessionArgs[$ARG_POS]}" == "all" ]];
  then
    # Kill the server
    echo -n "${boldbgred}CAUTION${norm} You're about to kill the tmux server and all sessions. Continue [y/N]? ";
    read -t 10 KILLCHOICE;
    
    case $KILLCHOICE in
      y|Y|yes|Yes|YES)
        # Kill server
        tmux kill-server &>/dev/null;
        
        # [console] All tmux sessions killed
        echo "tmux server and all sessions have been ${boldred}killed${norm}.";
      ;;
      n|N|no|No|NO)
        echo "Kill server ${boldgreen}aborted${norm}.";
      ;;
      *)
        echo "Invalid choice, server was ${boldred}not${norm} killed.";
      ;;
    esac
  else
    # Check sessions at command line, delete them if they exist, otherwise throw error
    # Start from array element 1 = elements after "destroy" command
    for i in "${sessionArgs[@]:$ARG_POS}"
    do  
      # [debug] Identify parsed session name
      if [[ $DEBUG4 == true ]];
      then
        echo "[DEBUG][DESTROY][${boldgreen}INFO${norm}] Parsed session name: $i"; 
      fi

      # Check to see if a session by the same name exists
      # 'check_session' updates $tmuxStatus variable
      # Session does not exist: tmuxStatus = 1
      # Session exists: tmuxStatus = 0
      check_session "$i";
    
      # If check_session found an existing session, kill it
      if [[ "$tmuxStatus" == "0" ]]; 
      then
        # [debug] Destroying session
        if [[ $DEBUG3 == true ]];
        then
          echo "[DEBUG][DESTROY][${boldgreen}INFO${norm}] Destroying session '${bold}$i${norm}'";
        fi

        # Destroy session
        tmux kill-session -t $i;
      else
        # [debug] Session does not exist, skipped
        if [[ $DEBUG3 == true ]];
        then
          echo "[DEBUG][DESTROY][${boldyellow}WARN${norm}] Session '${bold}$i${norm}' does not exist. Skipped.";
        fi

        # [console] Session does not exist, skipped
        echo "[${boldyellow}WARNING${norm}] Session '${bold}$i${norm}' does not exist. Skipped.";
      fi  
    done
  fi

  # [debug] Function end
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][DESTROY][${boldgreen}INFO${norm}] Leaving 'destroy' function";
  fi

  # Exit gracefully
  exit 0;
}




#####################################################################
#####################################################################
# FUNCTION
#####################################################################
# NAME: attach
# PURPOSE: Attach to existing tmux session
# ARGUMENTS:
# - Session name
# OUTPUT:
# - None
#####################################################################
function attach()
{
  # [debug] Function start
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][ATTACH][${boldgreen}INFO${norm}] Entering 'attach' function";
  fi

  # Variables
  local sessionArgs=("${CLI_ARGS[@]}");

  if [[ "${sessionArgs[$ARG_POS]}" == "" ]]; 
  then
    # [debug] No session specified, attach to session if only one session exists
    if [[ $DEBUG3 == true ]];
    then
      echo "[DEBUG][ATTACH][${boldyellow}WARN${norm}] No session names specified";
    fi

    if [[ `tmux list-sessions | wc -l 2>/dev/null` -eq 1 ]];
    then
      # [console] No session specified, attach to only session
      echo "[${boldyellow}WARNING${norm}] No session specified, attaching to the only running session."

      # More processor intensive, but defines a specific session to attach to 
      # help prevent MITM attacks.
      tmux attach -t `tmux list-sessions | cut -d':' -f1`;
    else
      # [console] No session specified and none to attach to
      echo "[${boldred}ERROR${norm}] No session specified and no usable session found to attach to."
    fi
  else
    # [debug] Identify parsed session name
    if [[ $DEBUG4 == true ]];
    then
      echo "[DEBUG][ATTACH][${boldgreen}INFO${norm}] Parsed session name: ${sessionArgs[$ARG_POS]}";
    fi

    # Check to see if session exists
    check_session "${sessionArgs[$ARG_POS]}";

    if [[ "$tmuxStatus" == "0" ]];
    then
      # [debug] Found session, connecting...
      if [[ $DEBUG3 == true ]];
      then
        echo "[DEBUG][ATTACH][${boldgreen}INFO${norm}] Found session, ${bold}${sessionArgs[$ARG_POS]}${norm}, attaching...";
      fi

      # [console] Found session, connecting... 
      echo "Found session, ${bold}${sessionArgs[$ARG_POS]}${norm}, attaching...";

      # Attach session
      tmux attach-session -t ${sessionArgs[$ARG_POS]};
    else
      # [debug] Specified session does not exist
      if [[ $DEBUG3 == true ]];
      then
        echo "[DEBUG][ATTACH][${boldred}ERROR${norm}] Specified session does not exist";
      fi

      # [console] Specified session does not exist
      echo "[${boldred}ERROR${norm}] Specified session, ${bold}${sessionArgs[$ARG_POS]}${norm}, does not exist";
    fi
  fi

  # [debug] Function end
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][ATTACH][${boldgreen}INFO${norm}] Leaving 'attach' function";
  fi

  # Exit gracefully
  exit 0;
}




#####################################################################
#####################################################################
# FUNCTION
#####################################################################
# NAME: detach
# PURPOSE: Detach existing tmux session
# ARGUMENTS:
# - Session name
# OUTPUT:
# - None
#####################################################################
function detach()
{
  # [debug] Function start
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][DETACH][${boldgreen}INFO${norm}] Entering 'detach' function";
  fi

  # Variables
  local sessionArgs=("${CLI_ARGS[@]}");

  if [[ "${sessionArgs[$ARG_POS]}" == "" ]]; 
  then
    # [debug] No session specified, error and exit
    if [[ $DEBUG3 == true ]];
    then
      echo "[DEBUG][DETACH][${boldred}ERROR${norm}] No session specified, cannot continue.";
    fi

    # [console]
    echo -e "\n[${boldred}ERROR${norm}] No session specified, cannot continue.";

    quickhelp;
  else
    # [debug] Identify parsed session name
    if [[ $DEBUG4 == true ]];
    then
      echo "[DEBUG][DETACH][${boldgreen}INFO${norm}] Parsed session name: ${sessionArgs[$ARG_POS]}";
    fi

    # Check to see if session exists
    check_session "${sessionArgs[$ARG_POS]}";

    if [[ "$tmuxStatus" == "0" ]];
    then
      # [debug] Found session, trying to detach it...
      if [[ $DEBUG3 == true ]];
      then
        echo "[DEBUG][DETACH][${boldgreen}INFO${norm}] Found session, ${bold}${sessionArgs[$ARG_POS]}${norm}, trying to detach it...";
      fi

      # [console] Found session, trying to detach it... 
      echo "Found session, ${bold}${sessionArgs[$ARG_POS]}${norm}, trying to detach it...";

      # Attach session
      tmux detach-client -s ${sessionArgs[$ARG_POS]};
    else
      # [debug] Specified session does not exist
      if [[ $DEBUG3 == true ]];
      then
        echo "[DEBUG][DETACH][${boldred}ERROR${norm}] Specified session does not exist.";
      fi

      # [console] Specified session does not exist
      echo "[${boldred}ERROR${norm}] Specified session," \
      "${bold}${sessionArgs[$ARG_POS]}${norm}, does not exist. Run" \
      "this script with the ${bold}sessions${norm} command to show" \
      "existing tmux sessions.";
    fi
  fi

  # [debug] Function end
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][DETACH][${boldgreen}INFO${norm}] Leaving 'detach' function";
  fi

  # Exit gracefully
  exit 0;
}




#####################################################################
#####################################################################
# FUNCTION
#####################################################################
# NAME: info
# PURPOSE: Display info on current tmux sessions
# ARGUMENTS:
# - None
# OUTPUT:
# - Tmux session information
#####################################################################
function info()
{
  # [debug] Function start
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][INFO][${boldgreen}INFO${norm}] Entering 'info' function";
  fi
 
  # Get information on running tmux sessions
  tmux info &>/dev/null
      
  # Grab exit code from 'tmux info' output
  tmuxStatus=$?;

  if [[ $tmuxStatus -eq 1 ]];
  then
    echo "[${boldbgred}FATAL${norm}] tmux is not running";
  else
    # Execute native tmux info command
    tmux info;
  fi

  # [debug] Function end
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][INFO][${boldgreen}INFO${norm}] Leaving 'info' function";
  fi

  # Exit gracefully
  exit 0;
}




#####################################################################
#####################################################################
# FUNCTION 
#####################################################################
# NAME: custom
# PURPOSE: Create a custom tmux session
# ARGUMENTS:
# - Session properties
# OUTPUT:
# - None
#####################################################################
function custom()
{
  # [debug] Function start
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][CUSTOM][${boldgreen}INFO${norm}] Entering 'custom' function";
  fi

  echo "${boldyellow}<TODO>${norm}";

  # [debug] Function end
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][CUSTOM][${boldgreen}INFO${norm}] Leaving 'custom' function";
  fi

  # Exit gracefully
  exit 0;
}





#####################################################################
#####################################################################
# FUNCTION
#####################################################################
# NAME: sessions
# PURPOSE: List active tmux sessions
# ARGUMENTS:
# - None
# OUTPUT:
# - tmux session list, if tmux is running
#####################################################################
function sessions()
{
  # [debug] Function start
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][SESSIONS][${boldgreen}INFO${norm}] Entering 'sessions' function";
  fi

  # Call native tmux command for listing current sessions
  tmux list-sessions;

  # [debug] Function end
  if [[ $DEBUG4 == true ]];
  then
    echo "[DEBUG][SESSIONS][${boldgreen}INFO${norm}] Leaving 'sessions' function";
  fi

  # Exit gracefully
  exit 0;
}




#####################################################################
#####################################################################
# MAIN
#####################################################################
if [[ $# -gt 0 ]];
then
  CLI_CMD="$1";
  ARG_POS="1";

  # Check for script symlink
  # <TODO>

  if [[ "$CLI_CMD" =~ "-v" ]];
  then
    case $CLI_CMD in
      -v)
        DEBUG1=true;
        # No console confirmation for debug level 1
      ;;
      -vv)
        DEBUG1=true;
        DEBUG2=true;
        # No console confirmation for debug level 2
      ;;
      -vvv)
        DEBUG1=true;
        DEBUG2=true;
        DEBUG3=true;
        echo -e "\n[DEBUG][MAIN][${boldyellow}WARN${norm}] Debug level 3 enabled\n";
      ;;
      -vvvv)
        DEBUG1=true;
        DEBUG2=true;
        DEBUG3=true;
        DEBUG4=true;
        echo -e "\n[DEBUG][MAIN][${boldyellow}WARN${norm}] Debug level 4 enabled\n";
    esac
    
    CLI_CMD="$2";
    ARG_POS="2";
  fi

  case $CLI_CMD in
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
    helpfull|Helpfull|HELPFULL|??)
      # Call full help function
      fullhelp;

      # Just-in-case... (but this shouldn't be reached)
      exit 1;
    ;;
    *)
    # [console] Bad flag, show error and call quick help function
    echo "[${boldred}ERROR${norm}] Bad flag, '${bold}$CLI_CMD${norm}'";
    
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
  ((RAND %= ${#FAILURE_QUOTES[@]}));

  # Print a funny quote from FAILURE_QUOTES array for instances when no command is entered
  echo -e "\n[${boldred}FAILURE${norm}] ${FAILURE_QUOTES[$RAND]}";

  # Show the documentation
  quickhelp;

  # Just-in-case... (but this shouldn't be reached)
  exit 0;
fi
