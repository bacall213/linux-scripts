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
#   - Ubuntu 14.04 LTS (64-bit)
#                                                                   
# REQUIRED PACAKGES:
#   - tmux (provides /usr/bin/tmux, man pages, etc)
#
# FILES:
#   - brainmux.sh (this script)
#
# OPTIONAL COMPONENTS:
#   - $HOME/.tmux.conf 
#     - User-specific config (keybindings, terminal settings, etc)
#     - tmux interprets the config file, if present, NOT this script
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
#   - v1.2.2015-b2
#     - Continued echo => printf conversion
#
#   - v1.2.2015-b1
#     - Started echo => printf conversion
#     - Started reducing line length to <=80 chars
#     - Added check for quotes array length < 1
#
#   - v1.8.2014-b6
#     - Eliminated uncaught error output from 'attach' function
#     - Added more helpful output to 'attach' function
#     - Added ability to instruct 'sessions' function to exit or not
#     - Started shortening lines to < 78 chars
#     - Removed brackets from colorized console output to make it more
#       friendly.
#     - Added 'list' as natural alias for 'sessions'
#     - Added 'config' as alias for 'defaults'
#     - Updated 'autocompletelist' in case I get around to including that
#       level of functionality.
#     - Google Style Guide
#       - "Put ; do and ; then on the same line as the while, for or if."
#         (https://google-styleguide.googlecode.com/svn/trunk/shell.xml?
#           showone=Loops#Loops)
#
#   - v1.8.2014-b5
#     - Moved unnamed session identification to own function
#     - Cleaned up process for unnamed session auto-attach
#     - Implemented --attach|-attach for named sessions
#
#   - v1.8.2014-b4
#     - Removed "custom session" flag
#         - tmux configs are too complex for it to be realistic to 
#           consider someone would want to enter a custom config at a 
#           command line
#     - Added "--attach|-attach" flag for unnamed session creation
#         - Automatically attaches to newly created session
#
#   - v1.8.2014-b3
#     - Put CLI parsing in alphabetical order
#     - Added friendly message for sessions() when there are no sessions
#
#   - v1.8.2014-b2
#     - create() function not as dependant on defaults array order
#     - Updated a few messages
#
#   - v1.8.2014-b1
#     - Fixed symlink checker function (flawed logic)
#
#   - v1.7.2014-b2
#     - check_symlink function created
#     - Warning message for bad verbose flags added
#
#   - v1.7.2014-b1
#     - Initial public release

# TODO:
#   1) Read and intelligently output .tmux.conf or /etc/tmux.conf in
#      defaults function.
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

# Session Defaults Array
# NOTE: create() expects these commands to be in a particular order.
#       Changing the order will have unexpected consequences.
declare -r SESSION_DEFAULTS=('tmux new-session -d'
                              'tmux new-window'
                              'tmux new-window'
                              'tmux new-window'
                              'tmux new-window'
                              'tmux new-window'
                              'tmux select-window -t:0');
#                              'tmux select-pane -L -t:0')

# Failure Quotes Array
declare -r FAIL_QUOTES=(
  "My great concern is not whether you have failed, but whether you are
        content with your failure. --Abraham Lincoln"
  "Many of life's failures are people who did not realize how close they were
        to success when they gave up. --Thomas A. Edison"
  "Failure is not fatal, but failure to change might be. --John Wooden"
  "If you learn from defeat, you haven't really lost. --Zig Ziglar"
  "Remember that failure is an event, not a person. --Zig Ziglar"
  "I don't believe in failure. It is not failure if you enjoyed the process. 
        --Oprah Winfrey"
  "They don't make bugs like Bunny anymore. --Olav Mjelde."
  "Talk is cheap. Show me the code. --Linus Torvalds"
  "Life is full of screwups. You're supposed to fail sometimes. It's a 
        required part of the human existance. --Sarah Dessen"
  "Only those who dare to fail greatly can ever achieve greatly. 
        --Robert F. Kennedy"
  "Giving up is the only sure way to fail. --Gena Showalter"
  "The phoenix must burn to emerge. --Janet Fitch"
  "There is no failure except in no longer trying. --Chris Bradford"
  "The only real mistake is the one from which we learn nothing. 
        --Henry Ford");

# Initialization for various global variables
cli_cmd="";                   # Tracks current argument
arg_pos="";                   # Tracks argument position in array
tmux_status="999";            # Impossible value
cli_args=("$@");              # Store all args
debug1=false;                 # -v    : Minimal debug info
debug2=false;                 # -vv   : Some debug info
debug3=false;                 # -vvv  : Most debug info
debug4=false;                 # -vvvv : All debug info
newest_tmux_session="-1";     # Used by find_newest_session() function
                              #  Stores session name for last-created,
                              #  nameless, session
newest_tmux_timestamp="-1";   # Used by find_newest_session() function
                              #  Stores session timestamp for last-created,
                              #  nameless, session


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
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][QUICKHELP][${BOLD_GREEN}INFO${NORM}]"\
            "Entering 'quickhelp' function";
  fi

  printf "\n%s %s\n\
          \n%s\n%s %s\n%s\n\n%s\n%s\n\
          \n%s\n%s\n%s\n\n%s\n%s\n\
          \n%s\n%s\n%s\n%s\n\
          \n%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n"\
          "${BOLD}USAGE :: $0${NORM} [-v|vv|vvv|vvvv] ${BOLD}command${NORM}"\
          "${UL}options${NO_UL}"\
          "  ${UL}Create and Destroy Sessions${NO_UL}"\
          "    ${BOLD}create${NORM} [${UL}session_1${NO_UL}"\
          "${UL}session_2${NO_UL} ${UL}session_3${NO_UL} ...]"\
          "        (alias: ${BOLD}new${NORM}, ${BOLD}start${NORM})"\
          "    ${BOLD}destroy${NORM} [all] ${UL}existing_session${NO_UL}"\
          "        (aliases: ${BOLD}stop${NORM}, ${BOLD}kill${NORM})"\
          "  ${UL}Connect and Disconnect Sessions${NO_UL}"\
          "    ${BOLD}connect${NORM} ${UL}existing_session${NO_UL}"\
          "        (alias: ${BOLD}attach${NORM})"\
          "    ${BOLD}disconnect${NORM} ${UL}existing_session${NO_UL}"\
          "        (alias: ${BOLD}detach${NORM})"\
          "  ${UL}Session Information${NO_UL}"\
          "    ${BOLD}info${NORM}"\
          "    ${BOLD}defaults${NORM} (alias: ${BOLD}config${NORM})"\
          "    ${BOLD}sessions${NORM} (alias: ${BOLD}list${NORM})"\
          "  ${UL}General Script Options${NO_UL}"\
          "    ${BOLD}help${NORM} (this menu)"\
          "    ${BOLD}helpfull${NORM}"\
          "    Debug/Verbose Mode (${BOLD}Must be first argument${NORM})"\
          "      -v    : Minimal verbosity/debug information"\
          "      -vv   : More verbose/some internal debug information"\
          "      -vvv  : Most debug information"\
          "      -vvvv : Full verbosity/All debug information";

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][QUICKHELP][${BOLD_GREEN}INFO${NORM}]"\
            "Leaving 'quickhelp' function";
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
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][FULLHELP][${BOLD_GREEN}INFO${NORM}]"\
            "Entering 'fullhelp' function";
  fi


  printf "\n%s %s\n\
          \n%s\n%s %s\n%s\n\n%s\n%s\n%s\n%s\n\
          \n%s\n%s\n\n%s\n%s %s\n%s\n\
          \n%s\n%s\n%s\n\n%s\n\n%s\n%s\n\n%s\n\n"\
          "${BOLD}USAGE :: $0${NORM} [-v|vv|vvv|vvvv] ${BOLD}command${NORM}"\
          "${UL}options${NO_UL}"\
          "  ${UL}Create and Destroy Sessions${NO_UL}"\
          "    ${BOLD}create${NORM} [${UL}session_1${NO_UL}"\
          "${UL}session_2${NO_UL} ${UL}session_3${NO_UL} ...]"\
          "        (alias: ${BOLD}new${NORM}, ${BOLD}start${NORM})"\
          "        Create one or multiple tmux sessions. If no session name"\
          "        is specified, tmux will create a new session named using"\
          "        its own mechanisms. If a specified session already"\
          "        exists, this script will skip over that session."\
          "    ${BOLD}destroy${NORM} [all] ${UL}existing_session${NO_UL}"\
          "        (aliases: ${BOLD}stop${NORM}, ${BOLD}kill${NORM})"\
          "        Destroy single, or all, existing tmux sessions. If 'all'"\
          "        is specified, this script will try to destroy all"\
          "existing"\
          "        sessions."\
          "  ${UL}Connect and Disconnect Sessions${NO_UL}"\
          "    ${BOLD}connect${NORM} ${UL}existing_session${NO_UL}"\
          "        (alias: ${BOLD}attach${NORM})"\
          "        Connect to an existing tmux session."\
          "    ${BOLD}disconnect${NORM} ${UL}existing_session${NO_UL}"\
          "        (alias: ${BOLD}detach${NORM})"\
          "        Disconnect from  an existing tmux session.";

  read -p "(${BOLD}Press <Enter> for next page${NORM})";

  printf "\n%s\n%s\n%s\n\n%s\n%s %s\n\n%s\n%s\n\
          \n%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n\
          \n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s %s\n"\
          "  ${UL}Session Information${NO_UL}"\
          "    ${BOLD}info${NORM}"\
          "        Show tmux session information, if tmux server is active."\
          "    ${BOLD}defaults${NORM} (alias: ${BOLD}config${NORM})"\
          "        Show the session defaults that are hard-coded into this"\
          "script."\
          "    ${BOLD}sessions${NORM} (alias: ${BOLD}list${NORM})"\
          "        Show running tmux sessions."\
          "  ${UL}General Script Options${NO_UL}"\
          "    ${BOLD}help${NORM} (this menu)"\
          "    ${BOLD}helpfull${NORM}"\
          "    Debug/Verbose Mode (${BOLD}Must be first argument${NORM})"\
          "      -v    : Minimal verbosity/debug information"\
          "      -vv   : More verbose/some internal debug information"\
          "      -vvv  : Most debug information"\
          "      -vvvv : Full verbosity/All debug information"\
          "    Output conventions"\
          "      [${BOLD_GREEN}INFO${NORM}]  General debugging information."\
          "      [${BOLD_YELLOW}WARN${NORM}]  Most non-fatal errors, like"\
          "              conflicts with existing sessions. Script may or may"\
          "              not exit."\
          "      [${BOLD_RED}ERROR${NORM}] Major errors. Script will exit"\
          "              (with limited exceptions). Syntax errors fall into"\
          "              this category."\
          "      [${BOLD_BG_RED}FATAL${NORM}] Fatal errors. Script will exit"\
          "(no exceptions).";

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][FULLHELP][${BOLD_GREEN}INFO${NORM}]"\
            "Leaving 'fullhelp' function";
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
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][CHECK_SYMLINK][${BOLD_GREEN}INFO${NORM}] Entering"\
            "'check_symlink' function";
  fi

  # If NOT symlink...
  if [[ ! $(test -L "$0" && readlink "$0") ]]; then
    if [[ $debug4 == true ]]; then
      printf "%s %s\n"\
              "[DEBUG][CHECK_SYMLINK][${BOLD_GREEN}INFO${NORM}]"\
              "$SCRIPT_NAME_FULL_LONG is NOT a symlink.";
    fi

    # Check for a symlink
    if [[ ! $(test -L "$SCRIPT_NAME_BASE_LONG" && 
      readlink "$SCRIPT_NAME_BASE_LONG") ]]; then

      # No symlink found in current directory
      printf "%s\n" "No symbolink found in execution directory.";
      
      # Use full path so the command is universal
      printf "%s %s\n"\
              "Run ${BOLD}ln -s $SCRIPT_NAME_FULL_LONG"\
              "$SCRIPT_NAME_BASE_LONG${NORM} if you would like one.";
    else
      # Symlink found: Silently continue, unless debugging
      if [[ $debug4 == true ]]; then
        printf "%s %s\n%s\n"\
                "[DEBUG][CHECK_SYMLINK][${BOLD_GREEN}INFO${NORM}] Found a"\
                "symlink during second check:"\
                " >> $SCRIPT_NAME_BASE_LONG";
      fi
    fi
  else
    # Is a symlink
    # Silently continue, unless debugging
    if [[ $debug4 == true ]]; then
      printf "%s %s\n%s\n"\
              "[DEBUG][CHECK_SYMLINK][${BOLD_GREEN}INFO${NORM}] I am a"\
              "symlink; actual script name:"\
              " >> $SCRIPT_NAME_FULL_LONG";
    fi
  fi

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][CHECK_SYMLINK][${BOLD_GREEN}INFO${NORM}] Leaving"\
            "'check_symlink' function";
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
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][DEFAULTS][${BOLD_GREEN}INFO${NORM}] Entering 'defaults'"\
            "function";
  fi

  # Window layout
  printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n\
          \n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n\n"\
          " ################ ################"\
          " #   Window 0   # #   Window 1   #"\
          " ################ ################"\
          " #              # #              #"\
          " #    (bash)    # #    (bash)    #"\
          " #              # #              #"\
          " #     100%     # #     100%     #"\
          " ################ ################"\
          " ################ ################"\
          " #   Window  2  # #   Window 3   #"\
          " ################ ################"\
          " #              # #              #"\
          " #    (bash)    # #    (bash)    #"\
          " #              # #              #"\
          " #     100%     # #     100%     #"\
          " ################ ################"\
          " ################"\
          " #   Window 4   #"\
          " ################"\
          " #              #"\
          " #    (bash)    #"\
          " #              #"\
          " #     100%     #"\
          " ################";

  # Options
  printf "%s\n\n" "${BOLD}Session creation commands:${NORM}";
  
  # Output default session creation parameters
  # Use 'sdefault' to prevent potential collisions with 'default'
  for sdefault in "${SESSION_DEFAULTS[@]}"; do
    printf "   %s\n" "$sdefault";
  done

  # Print tmux.conf
  if [[ -e ~/.tmux.conf ]]; then
    printf "\n%s\n\n"\
            "${BOLD}Contents of ${UL}~/.tmux.conf${NO_UL}:${NORM}";

    while read line; do
      printf "%s\n" "$line";

    done < ~/.tmux.conf
  fi
  
  if [[ -e /etc/tmux.conf ]]; then
    printf "\n%s\n\n"\
            "${BOLD}Contents of ${UL}/etc/tmux.conf${NO_UL}:${NORM}";
    cat /etc/tmux.conf;
  fi

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][DEFAULTS][${BOLD_GREEN}INFO${NORM}] Leaving 'defaults'"\
            "function";
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
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][CHECK_SESSION][${BOLD_GREEN}INFO${NORM}] Entering"\
            "'check_session' function";
  fi

  tmux_status="999";         # Reset at start of function as a safeguard
  local tmuxSession="$1";   # Contains a passed in session name

  tmux has-session -t "$tmuxSession" &>/dev/null;
  tmux_status=$?;

  # [debug] Session check
  if [[ $debug4 == true ]]; then
    printf "%s %s\n%s %s\n"\
            "[DEBUG][CHECK_SESSION][${BOLD_GREEN}INFO${NORM}] Session"\
            "tested = $tmuxSession"\
            "[DEBIG][CHECK_SESSION][${BOLD_GREEN}INFO${NORM}]"\
            "tmux_status = $tmux_status";
  fi

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][CHECK_SESSION][${BOLD_GREEN}INFO${NORM}] Leaving"\
            "'check_session' function";
  fi
}


##############################################################################
##############################################################################
# FUNCTION
##############################################################################
# NAME: find_newest_session
# PURPOSE: Identify the newest tmux session created based on timestamp
# ARGUMENTS: 
# - None
# OUTPUT:
# - Sets global variable 'newest_tmux_session' to the name of the 
#     last-created tmux session
# - Sets global variable 'newest_tmux_timestamp' to the timestamp for the
#     last-created tmux session
##############################################################################
function find_newest_session()
{
  # [debug] Function start
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][FIND_NEWEST_SESSION][${BOLD_GREEN}INFO${NORM}] Entering"\
            "'find_newest_session' function";
  fi

  local active_tmux_sessions;
  active_tmux_sessions=( $(tmux list-sessions -F "#{session_created} #{session_name}") );

  if [[ $debug4 == true ]]; then
    printf "%s %s\n%s\n"\
            "[DEBUG][FIND_NEWEST_SESSION][${BOLD_GREEN}INFO${NORM}]"\
            "tmux session list..."\
            "${active_tmux_sessions[@]}";
  fi

  # Parse active sessions list
  for (( session_index = 0 ; session_index < ${#active_tmux_sessions[@]} ; session_index++ )); do
    # Even values are the timestamp
    if [[ $(( session_index % 2 )) == 0 ]]; then
      if [[ ${active_tmux_sessions[$session_index]} > $newest_tmux_timestamp ]]; then
        newest_tmux_timestamp=${active_tmux_sessions[$session_index]};
        newest_tmux_session=${active_tmux_sessions[$session_index+1]};
      fi
    fi
  done

  if [[ $debug4 == true ]]; then
    printf "%s %s\n%s\n"\
            "[DEBUG][FIND_NEWEST_SESSION][${BOLD_GREEN}INFO${NORM}] Newest"\
            "session ID found = $newest_tmux_session"\
            "(timestamp=$newest_tmux_timestamp)";
  fi

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][FIND_NEWEST_SESSION][${BOLD_GREEN}INFO${NORM}] Leaving"\
            "'find_newest_session' function";
  fi

  # Return
  # newest_tmux_session is a global variable set by this function
  # newest_tmux_timestamp is a global variable set by this function

  # No exit
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
  if [[ $debug4 == true ]]; then
    echo "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM}] Entering 'create'" \
          "function";
  fi

  # Variables
  local session_args;

  session_args=("${cli_args[@]}");

  # Check for no session name or "-attach|--attach"
  if [[ "${session_args[$arg_pos]}" == "" || "${session_args[$arg_pos]}" == "--attach" || "${session_args[$arg_pos]}" == "-attach" ]]; then
    # [debug] No session specified, creating generic session
    if [[ $debug4 == true ]]; then
      echo "[DEBUG][CREATE][${BOLD_YELLOW}WARN${NORM}] No session names specified"
      echo "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM}] Creating unnamed session";
    fi
    # Parse SESSION_DEFAULTS array and execute commands
    # Order doesn't matter here, except for any order tmux requires
    for param in "${SESSION_DEFAULTS[@]}"; do
      `$param`;
    done

    # Check for "--attach" or "-attach" flags
    if [[ "${session_args[$arg_pos]}" == "--attach" || "${session_args[$arg_pos]}" == "-attach" ]]; then
      if [[ $debug4 == true ]]; then
        echo "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM}] Found --attach or" \
              "-attach flag with unnamed session creation";
      fi

      # Call find_newest_session function to identify last-created tmux session
      find_newest_session;

      # Check for a sane return value
      if [[ "$newest_tmux_session" != "-1" ]]; then
        if [[ $debug4 == true ]]; then
          echo "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM}]" \
                "find_newest_session() returned session name:" \
                "$newest_tmux_session";
        fi

        # Attach to newly created, unnamed, session
        tmux attach-session -t $newest_tmux_session;
      else
        echo "${BOLD_YELLOW}WARNING${NORM} 'newest_tmux_session' was not set" \
              "correctly. This script will continue, but cannot auto-attach" \
              "to the newly created session.";
      fi
    else
      # [console] No session specified, creating generic session
      echo "${BOLD_YELLOW}WARNING${NORM} No session name specified," \
            "tmux will choose one for you. Run this script with the" \
            "'sessions' command to identify running tmux sessions.";
    fi
  elif [[ "${session_args[$arg_pos+1]}" == "--attach" || "${session_args[$arg_pos+1]}" == "-attach" ]]; then
    # Catch the creation of a named session and attach it

    # [debug] Identify parsed session name
    # Indicate "--attach|-attach" was found
    if [[ $debug4 == true ]]; then
      printf "%s %s\n%s %s\n%s %s\n"\
              "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM} Noticed request to"\
              "attach session after creation"\
              "(-attach|--attach parsed from"\
              "'\${session_args[\$arg_pos+1]}')"\
              "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM}] Parsed session"\
              "name: ${session_args[$arg_pos]}";
    fi

    # Check to see if a session by the same name exists
    # 'check_session' updates $tmux_status variable
    # Session does not exist: tmux_status = 1
    # Session exists: tmux_status = 0
    check_session "${session_args[$arg_pos]}";
    
    # If check_session didn't find an existing session, create it
    if [[ "$tmux_status" == "1" ]]; then
      # [debug] Creating session
      if [[ $debug3 == true ]]; then
        printf "%s %s\n"\
                "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM}] Creating session"\
                "${session_args[$arg_pos]}";
      fi

      # Relies on array matching these base values
      #{tmux new-session -d} -s ${session_args[$arg_pos]};
      #{tmux split-window -h -p 50} -t ${session_args[$arg_pos]};
      #{tmux new-window} -t ${session_args[$arg_pos]};
      #{tmux new-window} -t ${session_args[$arg_pos]};
      #{tmux new-window} -t ${session_args[$arg_pos]};
      #{tmux select-window -t:0} -t ${session_args[$arg_pos]}:0;

      # Actual defaults array
      # tmux new-session -d
      # tmux split-window -h -p 50
      # tmux new-window
      # tmux new-window
      # tmux new-window
      # tmux select-window -t:0

      # Parse SESSION_DEFAULTS array and execute commands
      # Order matters, but shouldn't be dependent on the array
      # Check each argument first
      # Requires checks for 5 unique arguments
      for param in "${SESSION_DEFAULTS[@]}"; do
        case $param in
          "tmux new-session -d")
            $param -s ${session_args[$arg_pos]};

            if [[ $debug4 == true ]]; then
              printf "%s %s\n"\
                      "[DEBUG][CREATE] Create session executing: $param -s"\
                      "${session_args[$arg_pos]}";
            fi
          ;;
          "tmux split-window -h -p 50")
            $param -t ${session_args[$arg_pos]};

            if [[ $debug4 == true ]]; then
              printf "%s %s\n"\
                      "[DEBUG][CREATE] Create session executing: $param -t"\
                      "${session_args[$arg_pos]}";
            fi
          ;;
          "tmux new-window")
            $param -t ${session_args[$arg_pos]};

            if [[ $debug4 == true ]]; then
              printf "%s %s\n"\
                      "[DEBUG][CREATE] Create session executing: $param -t"\
                      "${session_args[$arg_pos]}";
            fi
          ;;
          "tmux select-window -t:0")
            $param -t ${session_args[$arg_pos]}:0;

            if [[ $debug4 == true ]]; then
              printf "%s %s\n"\
                      "[DEBUG][CREATE] Create session executing: $param -t"\
                      "${session_args[$arg_pos]}:0";
            fi
          ;;
          "tmux select-pane -L -t:0")
            $param -t ${session_args[$arg_pos]}:0;

            if [[ $debug4 == true ]]; then
              printf "%s %s\n"\
                      "[DEBUG][CREATE] Create session executing: $param -t"\
                      "${session_args[$arg_pos]}:0";
            fi
          ;;
          *)
            if [[ $debug4 == true ]]; then
              printf "%s %s %s\n"\
                      "[DEBUG][CREATE][${BOLD_RED}ERROR${NORM}] A tmux"\
                      "session creation command does not match an expected"\
                      "value: $param";
            else
              printf "%s %s\n"\
                      "${BOLD_YELLOW}WARNING${NORM} Potentially fatal"\
                      "session creation error. Run with -vvvv for details.";
            fi
        esac
      done

      # Attach to named session
      tmux attach-session -t ${session_args[$arg_pos]};
    else
      printf "%s %s\n"\
              "${BOLD_YELLOW}WARNING${NORM} Session"\
              "'${BOLD}${session_args[$arp_pos]}${NORM}' exists. Skipped.";
    fi
  else
    # No special circumstances, process all provided session names and 
    #   create them if possible
    
    # Check sessions at command line, create if they don't exist, otherwise error
    # Start from array element 1 = elements after "create" command
    for i in "${session_args[@]:$arg_pos}"; do
      # [debug] Identify parsed session name
      if [[ $debug4 == true ]]; then
        echo "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM}] Parsed session name: $i"; 
      fi

      # Check to see if a session by the same name exists
      # 'check_session' updates $tmux_status variable
      # Session does not exist: tmux_status = 1
      # Session exists: tmux_status = 0
      check_session "$i";
    
      # If check_session didn't find an existing session, create it
      if [[ "$tmux_status" == "1" ]]; then
        # [debug] Creating session
        if [[ $debug3 == true ]]; then
          echo "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM}] Creating session $i";
        fi

        # Relies on array matching these base values
        #{tmux new-session -d} -s $i;
        #{tmux split-window -h -p 50} -t $i;
        #{tmux new-window} -t $i;
        #{tmux new-window} -t $i;
        #{tmux new-window} -t $i;
        #{tmux select-window -t:0} -t $i:0;

        # Actual defaults array
        # tmux new-session -d
        # tmux split-window -h -p 50
        # tmux new-window
        # tmux new-window
        # tmux new-window
        # tmux select-window -t:0

        # Parse SESSION_DEFAULTS array and execute commands
        # Order matters, but shouldn't be dependent on the array
        # Check each argument first
        # Requires checks for 5 unique arguments
        for param in "${SESSION_DEFAULTS[@]}"; do
          case $param in
            "tmux new-session -d")
              if [[ $debug4 == true ]]; then
                printf "%s %s\n"\
                        "[DEBUG][CREATE] Create session executing:"\
                        "$param -s $i";
                $param -s $i;
              else
                $param -s $i;
              fi
            ;;
            "tmux split-window -h -p 50")
              if [[ $debug4 == true ]]; then
                printf "%s %s\n"\
                        "[DEBUG][CREATE] Create session executing:"\
                        "$param -t $i";
                $param -t $i;
              else
                $param -t $i;
              fi
            ;;
            "tmux new-window")
              if [[ $debug4 == true ]]; then
                printf "%s %s\n"\
                        "[DEBUG][CREATE] Create session executing:"\
                        "$param -t $i";
                $param -t $i;
              else 
                $param -t $i;
              fi
            ;;
            "tmux select-window -t:0")
              if [[ $debug4 == true ]]; then
                printf "%s %s\n"\
                        "[DEBUG][CREATE] Create session executing:"\
                        "$param -t $i:0";
                $param -t $i:0;
              else 
                $param -t $i:0;
              fi
            ;;
            "tmux select-pane -L -t:0")
              if [[ $debug4 == true ]]; then
                printf "%s %s\n"\
                        "[DEBUG][CREATE] Create session executing:"\
                        "$param -t $i:0";
                $param -t $i:0;
              else
                $param -t $i:0;
              fi
            ;;
            *)
              if [[ $debug4 == true ]]; then
                printf "%s %s %s\n"\
                        "[DEBUG][CREATE][${BOLD_RED}ERROR${NORM}] A tmux"\
                        "session creation command does not match an expected"\
                        "value: $param";
              else
                printf "%s %s\n"\
                        "${BOLD_YELLOW}WARNING${NORM} Potentially fatal"\
                        "session creation error. Run with -vvvv for details.";
              fi
          esac
        done
      else
        # [debug] Session exists, skipped
        if [[ $debug3 == true ]]; then
          echo "[DEBUG][CREATE][${BOLD_YELLOW}WARN${NORM}] Session" \
                "'${BOLD}$i${NORM}' exists. Skipped.";
        fi

        # [console] Session exists, skipped
        echo "${BOLD_YELLOW}WARNING${NORM} Session '${BOLD}$i${NORM}'" \
              "exists. Skipped.";
      fi
    done
  fi

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    echo "[DEBUG][CREATE][${BOLD_GREEN}INFO${NORM}] Leaving 'create'" \
          "function";
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
  if [[ $debug4 == true ]]; then
    echo "[DEBUG][DESTROY][${BOLD_GREEN}INFO${NORM}] Entering 'destroy'" \
          "function";
  fi

  # Variables
  local session_args;
  session_args=("${cli_args[@]}");

  # Kill all sessions if 'all' is the first argument after command
  if [[ "${session_args[$arg_pos]}" == "" ]]; then
    # [debug] No session specified
    if [[ $debug3 == true ]]; then
      echo "[DEBUG][DESTROY][${BOLD_RED}ERROR${NORM}] No session names specified";
    fi

    # [console] No session specified
    echo "[${BOLD_RED}ERROR${NORM}] No session names specified";
    echo -en "\n${BOLD}USAGE :: $0${NORM} [-v|vv|vvv|vvvv] ${BOLD}command${NORM} ${UL}options${NO_UL}\r\n
      ${BOLD}destroy${NORM} [all] ${UL}existing_session${NO_UL}\r
      \t(aliases: ${BOLD}stop${NORM}, ${BOLD}kill${NORM})\r

      \tDestroy single, or all, existing tmux sessions. If 'all' is \r
      \tspecified, this script will try to destroy all existing sessions. \r\n";
  elif [[ "${session_args[$arg_pos]}" == "all" ]]; then
    # Kill the server
    echo -ne "${BOLD_BG_RED}CAUTION${NORM} You're about to kill the tmux" \
              "server and all sessions. \n\n${BOLD}Running sessions...${NORM}\n";

    # Show existing sessions (if any)
    sessions "false";

    echo -ne "\nContinue [y/N]? ";
    read -t 10 KILLCHOICE;
    
    case $KILLCHOICE in
      y|Y|yes|Yes|YES)
        # Kill server
        tmux kill-server &>/dev/null;
        
        # [console] All tmux sessions killed
        echo "All tmux server/sessions have been ${BOLD}killed${NORM}.";
      ;;
      n|N|no|No|NO)
        echo "Kill ${BOLD}aborted${NORM}.";
      ;;
      *)
        echo -e "\nInvalid choice, server/sessions were ${BOLD}not${NORM} killed.";
      ;;
    esac
  else
    # Check sessions at command line, delete them if they exist, otherwise 
    #   throw error
    # Start from array element 1 = elements after "destroy" command
    for i in "${session_args[@]:$arg_pos}"; do
      # [debug] Identify parsed session name
      if [[ $debug4 == true ]]; then
        echo "[DEBUG][DESTROY][${BOLD_GREEN}INFO${NORM}] Parsed session" \
              "name: $i"; 
      fi

      # Check to see if a session by the same name exists
      # 'check_session' updates $tmux_status variable
      # Session does not exist: tmux_status = 1
      # Session exists: tmux_status = 0
      check_session "$i";

      # If check_session found an existing session, kill it
      if [[ "$tmux_status" == "0" ]]; then
        # [debug] Destroying session
        if [[ $debug3 == true ]]; then
          echo "[DEBUG][DESTROY][${BOLD_GREEN}INFO${NORM}] Destroying" \
                "session '${BOLD}$i${NORM}'";
        fi

        # Destroy session
        tmux kill-session -t $i;
      else
        # [debug] Session does not exist, skipped
        if [[ $debug3 == true ]]; then
          echo "[DEBUG][DESTROY][${BOLD_YELLOW}WARN${NORM}] Session" \
                "'${BOLD}$i${NORM}' does not exist. Skipped.";
        fi

        # [console] Session does not exist, skipped
        echo "${BOLD_YELLOW}WARNING${NORM} Session '${BOLD}$i${NORM}'" \
              "does not exist. Skipped.";
      fi
    done
  fi

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    echo "[DEBUG][DESTROY][${BOLD_GREEN}INFO${NORM}] Leaving 'destroy'" \
          "function";
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
  if [[ $debug4 == true ]]; then
    echo "[DEBUG][ATTACH][${BOLD_GREEN}INFO${NORM}] Entering 'attach'" \
          "function";
  fi

  # Variables
  local session_args;
  local session_count;
  session_args=("${cli_args[@]}");
  session_count=$(tmux list-sessions 2> /dev/null | wc -l);

  if [[ "${session_args[$arg_pos]}" == "" ]]; then
    # [debug] No session specified, attach to session if only one session exists
    if [[ $debug3 == true ]]; then
      echo "[DEBUG][ATTACH][${BOLD_YELLOW}WARN${NORM}] No session names specified";
    fi

    if [[ $session_count -eq 1 ]]; then
      # [console] No session specified, attach to only session
      echo "${BOLD_YELLOW}WARNING${NORM} No session specified, attaching to" \
            "the only running session.";

      # More processor intensive, but defines a specific session to attach to 
      # help prevent MITM attacks.
      tmux attach -t $(tmux list-sessions -F "#{session_name}");
    elif [[ $session_count -ge 2 ]]; then
      # [console] More than one session found
      echo -e "${BOLD_RED}ERROR${NORM} More than one session found; unable" \
              "to connect without first specifying a session name." \
              "\n\n${BOLD}Running sessions...${NORM}";

      # Show running sessions
      sessions "true";
    else
      # [console] No session specified and none to attach to
      echo "${BOLD_RED}ERROR${NORM} No session specified and no usable" \
            "session found to attach to.";
    fi
  else
    # [debug] Identify parsed session name
    if [[ $debug4 == true ]]; then
      echo "[DEBUG][ATTACH][${BOLD_GREEN}INFO${NORM}] Parsed session name:" \
            "${session_args[$arg_pos]}";
    fi

    # Check to see if session exists
    check_session "${session_args[$arg_pos]}";

    if [[ "$tmux_status" == "0" ]]; then
      # [debug] Found session, connecting...
      if [[ $debug3 == true ]]; then
        echo "[DEBUG][ATTACH][${BOLD_GREEN}INFO${NORM}] Found session," \
              "${BOLD}${session_args[$arg_pos]}${NORM}, attaching...";
      fi

      # [console] Found session, connecting... 
      echo "Found session, ${BOLD}${session_args[$arg_pos]}${NORM}, attaching...";

      # Attach session
      tmux attach-session -t ${session_args[$arg_pos]};
    else
      # [debug] Specified session does not exist
      if [[ $debug3 == true ]]; then
        echo "[DEBUG][ATTACH][${BOLD_RED}ERROR${NORM}] Specified session" \
              "does not exist";
      fi

      # [console] Specified session does not exist
      echo "${BOLD_RED}ERROR${NORM} Specified session," \
            "${BOLD}${session_args[$arg_pos]}${NORM}, does not exist";
    fi
  fi

  # [debug] Function end
  if [[ $debug4 == true ]]; then
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
  if [[ $debug4 == true ]]; then
    echo "[DEBUG][DETACH][${BOLD_GREEN}INFO${NORM}] Entering 'detach' function";
  fi

  # Variables
  local session_args;
  session_args=("${cli_args[@]}");

  if [[ "${session_args[$arg_pos]}" == "" ]]; then
    # [debug] No session specified, error and exit
    if [[ $debug3 == true ]]; then
      echo "[DEBUG][DETACH][${BOLD_RED}ERROR${NORM}] No session specified," \
            "cannot continue.";
    fi

    # [console]
    echo -e "\n${BOLD_RED}ERROR${NORM} No session specified, cannot continue.";

    quickhelp;
  else
    # [debug] Identify parsed session name
    if [[ $debug4 == true ]]; then
      echo "[DEBUG][DETACH][${BOLD_GREEN}INFO${NORM}] Parsed session name:" \
            "${session_args[$arg_pos]}";
    fi

    # Check to see if session exists
    check_session "${session_args[$arg_pos]}";

    if [[ "$tmux_status" == "0" ]]; then
      # [debug] Found session, trying to detach it...
      if [[ $debug3 == true ]]; then
        echo "[DEBUG][DETACH][${BOLD_GREEN}INFO${NORM}] Found session," \
              "${BOLD}${session_args[$arg_pos]}${NORM}, trying to detach it...";
      fi

      # [console] Found session, trying to detach it... 
      echo "Found session, ${BOLD}${session_args[$arg_pos]}${NORM}, trying"\
            "to detach it...";

      # Attach session
      tmux detach-client -s ${session_args[$arg_pos]};
    else
      # [debug] Specified session does not exist
      if [[ $debug3 == true ]]; then
        echo "[DEBUG][DETACH][${BOLD_RED}ERROR${NORM}] Specified session" \
              "does not exist.";
      fi

      # [console] Specified session does not exist
      echo "${BOLD_RED}ERROR${NORM} Specified session," \
            "${BOLD}${session_args[$arg_pos]}${NORM}, does not exist. Run" \
            "this script with the ${BOLD}sessions${NORM} command to show" \
            "existing tmux sessions.";
    fi
  fi

  # [debug] Function end
  if [[ $debug4 == true ]]; then
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
  if [[ $debug4 == true ]]; then
    echo "[DEBUG][INFO][${BOLD_GREEN}INFO${NORM}] Entering 'info' function";
  fi

  # Get information on running tmux sessions
  tmux info &>/dev/null

  # Grab exit code from 'tmux info' output
  tmux_status=$?;

  if [[ $tmux_status -eq 1 ]]; then
    echo "${BOLD_BG_RED}FATAL${NORM} tmux is not running";
  else
    # Execute native tmux info command
    tmux info;
  fi

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    echo "[DEBUG][INFO][${BOLD_GREEN}INFO${NORM}] Leaving 'info' function";
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
  # Local variables
  local status;
  local exit_after;
  
  case $1 in 
    "true")
      exit_after=true;
      if [[ $debug4 == true ]]; then
        printf "%s %s\n"\
                "[DEBUG][SESSIONS][${BOLD_GREEN}INFO${NORM} Sessions"\
                "function ${BOLD}WILL${NORM} exit after execution.";
      fi
      ;;
    "false")
      exit_after=false;
      if [[ $debug4 == true ]]; then
        printf "%s %s\n"\
                "[DEBUG][SESSIONS][${BOLD_GREEN}INFO${NORM} Sessions"\
                "function will ${BOLD}NOT${NORM} exit after execution.";
      fi
      ;;
    *)
      exit_after=true;
      if [[ $debug4 == true ]]; then
        printf "%s %s %s\n"\
                "[DEBUG][SESSIONS][${BOLD_GREEN}INFO${NORM} Sessions"\
                "function received unknown flag for exit ($1) and will"\
                "default to exit after execution.";
      fi
    ;;
  esac

  # [debug] Function start
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][SESSIONS][${BOLD_GREEN}INFO${NORM}] Entering 'sessions'"\
            "function";
  fi

  # Call native tmux command for listing current sessions
  # Errors are piped to /dev/null
  tmux list-sessions > /dev/null 2>&1;
  status="$?" || return;

  # If no sessions exist, display a special message, otherwise STDOUT from
  #   'tmux list-sessions' will be used to show the existing session info
  if [[ "$status" == "1" ]]; then
    printf "%s\n" "No tmux sessions exist.";
  else
    tmux list-sessions 2> /dev/null;
  fi

  # [debug] Function end
  if [[ $debug4 == true ]]; then
    printf "%s %s\n"\
            "[DEBUG][SESSIONS][${BOLD_GREEN}INFO${NORM}] Leaving 'sessions'"\
            "function";
  fi

  # Exit (or not)
  if [[ $exit_after == true ]]; then
    exit 0;
  #elif [[ $exit_after == false ]]; then
    # No exit
  fi
}


##############################################################################
##############################################################################
# MAIN
##############################################################################
if [[ $# -gt 0 ]]; then
  cli_cmd="$1";
  arg_pos="1";

  if [[ "$cli_cmd" =~ "-v" ]]; then
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
        printf "\n%s %s\n\n"\
                "[DEBUG][MAIN][${BOLD_YELLOW}WARN${NORM}] Debug level 3"\
                "enabled";
      ;;
      -vvvv)
        debug1=true;
        debug2=true;
        debug3=true;
        debug4=true;
        printf "\n%s %s\n\n"\
                "[DEBUG][MAIN][${BOLD_YELLOW}WARN${NORM}] Debug level 4"\
                "enabled";
      ;;
      *)
        # Bad verbose flag
        printf "%s %s\n"\
                "${BOLD_YELLOW}WARN${NORM} Bad verbose flag,"\
                "'${BOLD}$cli_cmd${NORM}.' Continuing without verbosity.";
      ;;
    esac
    
    cli_cmd="$2";
    arg_pos="2";
  fi

  # Check for symlink
  check_symlink;

  case $cli_cmd in
    attach|Attach|ATTACH|connect|Connect|CONNECT)
      # Attach tmux session
      attach;

      # Just-in-case... (but this shouldn't be reached)
      exit 1;
    ;;
    create|Create|CREATE|start|Start|START|new|New|NEW)
      # Start tmux session
      # Session names parsed from global arguments variable
      create;

      # Just-in-case... (but this shouldn't be reached)
      exit 0;
    ;;
    defaults|Defaults|DEFAULTS|config|Config|CONFIG)
      # Show script-default laytout
      defaults;

      # Just-in-case... (but this shouldn't be reached)
      exit 1;
    ;;
    destroy|Destroy|DESTROY|kill|Kill|KILL|stop|Stop|STOP)
      # Kill tmux session
      destroy;

      # Just-in-case... (but this shouldn't be reached)
      exit 0;
    ;;
    detach|Detach|DETACH|disconnect|Disconnect|DISCONNECT)
      # Detach tmux session
      detach;

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
    info|Info|INFO)
      # Get information on running tmux sessions
      info;

      # Just-in-case... (but this shouldn't be reached)
      exit 1;
    ;;
    restore|Restore|RESTORE|load|Load|LOAD)
      printf "%s\n" "[TODO] Restore function not yet implemented."; 
    ;;
    save|Save|SAVE)
      printf "%s\n" "[TODO] Save function not yet implemented";
    ;;
    sessions|Sessions|SESSIONS|list|List|LIST)
      # Show current tmux sessions
      sessions "true";

      # Just-in-case... (but this shouldn't be reached)
      exit 1;
    ;;
    *)
    # Bad flag
    printf "%s\n"\
            "${BOLD_RED}ERROR${NORM} Bad flag, '${BOLD}$cli_cmd${NORM}'";
    
    quickhelp;

    # Just-in-case... (but this shouldn't be reached)
    exit 1;
    ;;
  esac
else
  # FAILURE: Script requires at least one argument, show error and call 
  #   quick help function
  
  # Random number generation localized so it's not called unless needed
  # Generate random number within range 0 - ARRAY_LEN
  RAND=$RANDOM;

  if [[ ${#FAIL_QUOTES[@]} -ge 1 ]]; then
    let RAND%=${#FAIL_QUOTES[@]};
    
    # Print a funny quote when no command is entered
    printf "\n%s\n"\
            "${BOLD_RED}FAILURE${NORM} ${FAIL_QUOTES[$RAND]}";
  else
    printf "\n%s %s\n%s\n"\
            "${BOLD_RED}FAILURE${NORM} This script requires at least one"\
            "argument."\
            "        [INTERNAL BUG: Quotes array does not have >=1 element]";
  fi

  # Show the documentation
  quickhelp;

  # Just-in-case... (but this shouldn't be reached)
  exit 0;
fi
