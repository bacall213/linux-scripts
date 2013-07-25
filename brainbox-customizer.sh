#!/bin/bash

#############################################################################
#                             BRAINBOX UPDATER
#############################################################################
# 
# 
# 
# 
#
#
#
#
#
#
#
#
#
#
#
# 
# 
# 
# 
# 
# 
#############################################################################

#############################################################################
#                           FILESYSTEM STRUCTURE
#############################################################################
#	$HOME
#	
#	
#	
#
#
#
#
#
#
#
#############################################################################

####################
# GLOBAL VARIABLES #
####################
#
GLOBAL_ARGS=$@;
BIN_DIR="$HOME/bin";
HOST=$HOSTNAME;
DEBUG=false;
GUI=false;
HELP=false;






#####################
# FILES/DIRECTORIES #
#####################
create_bin() {
	##################
	# LOCAL VARIABLES
	##################
	#
	#
	#
	#
	#

	# Bin destination - globally assigned and modifiable (reference only)
	# BIN_DIR

	# Status
	echo "Creating binaries directory (if necessary) and copying all scripts into place.";
	echo "";

	if [[ -d "$BIN_DIR" ]]
	then
		# Copy scripts into place
		echo "Copy scripts... (not implemented)";
	else
		# Create 'bin' dir
		mkdir $BIN_DIR;

		if [[ -d "$BIN_DIR" ]]
		then
			# Copy scripts into place
			echo "Copy scripts - after creating directory... (not implemented)";
		else
			# Binaries destination directory could not be created
			# ERROR
			echo "ERROR: Binaries directory could not be created!";
		fi
	fi

	# Add some debugging to the end of the function
	if [[ $DEBUG == true ]]
	then
		echo -e "$(tput bold)[DEBUG] End of create_bin() has been reached.$(tput sgr0)";
	fi
}

check_for_bin_path() {
	##################
	# LOCAL VARIABLES
	##################
	#
	#
	#
	#

	# Check for $BIN_DIR in $PATH: Fix if not; Otherwise, acknowledge and continue
	if [[ ! $(echo $PATH | grep -o "$BIN_DIR") ]]
	then
		if [[ $DEBUG == true ]]
		then
			echo -ne "$(tput bold)[DEBUG] The expected binaries path was not found in your PATH variable! $(tput sgr0)";
			echo -ne "$(tput bold)Ubuntu should take care of this in .profile, but only if your $(tput sgr0)";
			echo -e "$(tput bold)binaries path is the default, ~/bin$(tput sgr0)";
			echo -ne "$(tput bold)Your chosen binaries path ($BIN_DIR) will be added to your path $(tput sgr0)";
			echo -e "$(tput bold)via .bashrc$(tput sgr0)";

			# Add $BIN_DIR to $PATH by appending .bashrc
			echo "# Add binaries path for brainbox customizer to system path" >> $HOME/.bashrc_test;
			echo "# PATH=\"\$HOME/bin:\$PATH\"" >> $HOME/.bashrc_test;
			echo "PATH=\"\$HOME/bin:\$PATH\"" >> $HOME/.bashrc_test;
			#
			#
		else
			#
			#
			# Same issue, same resolution, no debug text
			
			# Add $BIN_DIR to $PATH by appending .bashrc
			echo "# Add binaries path for brainbox customizer to system path" >> $HOME/.bashrc_test;
			echo "# PATH=\"\$HOME/bin:\$PATH\"" >> $HOME/.bashrc_test;
			echo "PATH=\"\$HOME/bin:\$PATH\"" >> $HOME/.bashrc_test;
		fi
	else
		if [[ $DEBUG == true ]]
		then
			echo "";
			echo -e "$(tput bold)[DEBUG] Your binaries path was found in the system path (this is a good thing).$(tput sgr0)";
			echo -e "$(tput bold)[DEBUG] Binaries path: " $BIN_DIR "$(tput sgr0)";
			echo -e "$(tput bold)[DEBUG] System path: " $PATH "$(tput sgr0)";
			echo "";
		fi
	fi

	# Add some debugging to the end of the function
	if [[ $DEBUG == true ]]
	then
		echo -e "$(tput bold)[DEBUG] End of check_for_bin_path() has been reached.$(tput sgr0)";
	fi
}


process_files() {
	##################
	# LOCAL VARIABLES
	##################
	#
	#
	#
	#
	#

	echo "not implemented";

	# Add some debugging to the end of the function
	if [[ $DEBUG == true ]]
	then
		echo -e "$(tput bold)[DEBUG] End of process_files() has been reached.$(tput sgr0)";
	fi
}





#############
# UTILITIES #
#############


################################
# GOOGLIZER (COLORIZED PROMPT) #
################################
googlize() {
	##################
	# LOCAL VARIABLES
	##################
	#
	INWORD="";
	OUTWORD="";
	OUTCMD="";
	#
	#
	#

	# Grab input from menu system
	INWORD=$1;

	# Execute googlizer script against input
	COLORIZE=$(./googlizer.sh $1);

	# Find colorized output
	OUTWORD=$(echo $COLORIZE | cut -d":" -f2 | cut -d" " -f2);

	# Find colorized command
	OUTCMD=$(echo $COLORIZE | cut -d":" -f 3);

	echo "";
	echo "Googlizing...";
	echo "";
	echo $INWORD " >> " $OUTWORD;
	echo "Copy-friendly output: " $OUTCMD;


	# Make the variables available outside of this function
	export OUTWORD;
	export OUTCMD;

	# Add some debugging to the end of the function
	if [[ $DEBUG == true ]]
	then
		echo -e "$(tput bold)[DEBUG] End of googlize() has been reached.$(tput sgr0)";
	fi

	# Exit the Googlizer
	#exit 0;
}



################
# ASCII BRAIN! #
################
# ASCII Brain must be configured as the last set of lines in ~/.bashrc
create_ascii_brain() {
	echo -E "       _---~~(~~-_.";
	echo -E "     _{  brain )   )";
	echo -E "   ,   ) -~~- ( ,-' )_";
	echo -E "  (  \`-,_..\`., )-- '_,)";
	echo -E "( \` _)  (  -~( -_ \`,  }";
	echo -E "(_-  _  ~_-~~~~\`,  ,' )";
	echo -E "  \`~ -^(    __;-,((()))";
	echo -E "        ~~~~ {_ -_(())";
	echo -E "               \`\  }";
	echo -E "                 { }";
	echo "";
}



##########
# BASHRC #
##########

# Copy/merge/update .bashrc for user
# --> Ensure path for uilities (bin) directory is in bashrc




#



#################
# USAGE DISPLAY #
#################
print_cli_usage() {
	##################
	# LOCAL VARIABLES
	##################
	#
	#
	#
	#
	#

	# Print help menu specifically for the CLI options
	printf "~~~~~~~~~~~~~~~~~~~~\n";
	printf "COMMAND LINE OPTIONS\n";
	printf "~~~~~~~~~~~~~~~~~~~~\n\n";
	# Blank line
	printf " USAGE: $0 [flags]\n";
	printf "\t( No flags )\t\t:\tNormal Mode; Use Shell Menus\n";
	printf "\t[--debug | -d | --d]\t:\tDebug Mode\n";
	printf "\t[--gui | -g | --g]\t:\tGUI Mode; Use Zenity Menus\n";
	printf "\t[--help | -h | --h]\t:\tHelp!\n";


	# Add some debugging to the end of the function
	if [[ $DEBUG == true ]]
	then
		echo -e "$(tput bold)[DEBUG] End of print_cli_usage() has been reached.$(tput sgr0)";
	fi
}

print_menu_usage() {
	##################
	# LOCAL VARIABLES
	##################
	#
	#
	#
	#
	#

	# Print help menu specifically for the menu system
	printf "~~~~~~~~~~~~~~~~~~~\n";
	printf "MENU SYSTEM OPTIONS\n";
	printf "~~~~~~~~~~~~~~~~~~~\n\n";
	# Blank line
	printf ' %-25s %-55s\n' "Menu Option" "Description";
	printf ' %-25s %-55s\n' "~~~~~~~~~~~" "~~~~~~~~~~~";
	printf ' %-25s %-55s\n' "1) Full Installation" "* Creates supporting filesystem structures";
	printf ' %-25s %-55s\n' "" "* Installs scripts (~/bin)";
	printf ' %-25s %-55s\n' "" "* Generates a Googlized PS1 prompt";
	printf ' %-25s %-55s\n' "" "* Modifies bashrc";
	# Blank line
	printf '\n %-25s %-55s\n' "2) Custom Installation" "* Component selection";
	printf ' %-25s %-55s\n' "" "* Destination selection";
	# Blank line
	printf '\n %-25s %-55s\n' "3) BrainBox Updater" "* Executes the BrainBox Updater";
	# Blank line
	printf '\n %-25s %-55s\n' "4) Googlizer" "* Produce a \"Googlized\" string of text";
	printf '\n %-25s %-55s\n' "" "* Provides relevant code for inclusion elsewhere";
	# Blank line
	printf '\n %-25s %-55s\n' "5) Help" "* Help!";
	# Blank line
	printf '\n %-25s %-55s\n' "6) Quit" "* Quit script and make no further changes";

	# Add some debugging to the end of the function
	if [[ $DEBUG == true ]]
	then
		echo -e "$(tput bold)[DEBUG] End of print_menu_usage() has been reached.$(tput sgr0)";
	fi
}

usage() {
	##################
	# LOCAL VARIABLES
	##################
	#
	# Set usage type variable to $1 to get passed value
	USAGE_TYPE=$1;
	RETURN=$2;
	#
	#
	#

	case $USAGE_TYPE in
		"menu")
			if [[ $RETURN == true ]]
			then
				# Print basic usage menu
				print_menu_usage;

				# We need to add some formatting before returning to the menu
				echo "";

				# Return to menu instead of exiting
				main_menu;
			else
				# Print basic usage menu
				print_menu_usage;

				# Exit clean
				exit 0;
			fi
		;;
		"all")
			if [[ $RETURN == true ]]
			then
				# Print CLI usage
				print_cli_usage;

				# Blank lines for formatting
				printf "\n\n";

				# Print menu usage
				print_menu_usage;

				# We need to add some formatting before returning to the menu
				echo "";

				# Return to menu instead of exiting
				main_menu;
			else
				# Print CLI usage
				print_cli_usage;

				# Blank lines for formatting
				printf "\n\n";

				# Print menu usage
				print_menu_usage;

				# Exit clean
				exit 0;
			fi
		;;
		*)
			echo "";
			echo -e "$(tput bold)[DEBUG] Oops! This option shouldn't be exposed.$(tput sgr0)";
			echo -e "$(tput bold)[DEBUG] Function :: usage()$(tput sgr0)";
			echo -e "$(tput bold)[DEBUG] Component :: case statement for usage type$(tput sgr0)";
			echo -e "$(tput bold)[DEBUG] Option :: * (no match)$(tput sgr0)";
			echo "";
			
			# Exit with error
			exit 1;
		;;
	esac

	# Add some debugging to the end of the function
	if [[ $DEBUG == true ]]
	then
		echo -e "$(tput bold)[DEBUG] End of usage() has been reached.$(tput sgr0)";
	fi
}


###############
# MENU SYSTEM #
###############
main_menu() {
	##################
	# LOCAL VARIABLES
	##################
	#
  MENU_PROMPT="Select an option:  ";
	PS3=$MENU_PROMPT;
  MENU_OPTS=("Full Installation" "Custom Installation" "BrainBox Updater" "Googlizer" "Help" "Quit"); 
  MENU_CHOICE_TEXT="undefined";
  MENU_CHOICE_INDEX=999;
	MENU_INTRO_L1="~~~~~~~~~~~~~~~~~~~";
	MENU_INTRO_L2="BRAINBOX CUSTOMIZER";
	MENU_INTRO_L3="~~~~~~~~~~~~~~~~~~~";
	MENU_INTRO_L4="";	
	CCHOICE="";
	NEWWORD="";
	#
	#
	#

	# Clear screen before displaying menu
	#clear;

	# Set a different IFS for the menu intro
	IFS='%';

	# Display menu intro
	echo "";
  echo $MENU_INTRO_L1;
	echo $MENU_INTRO_L2; 
	echo $MENU_INTRO_L3; 
	echo $MENU_INTRO_L4;
	
	# Return the IFS to the default value
	unset IFS;
	
  select option in "${MENU_OPTS[@]}"
  do
    case $option in
      ${MENU_OPTS[0]})
				# Full Installation
        MENU_CHOICE_TEXT="${MENU_OPTS[0]}";
        MENU_CHOICE_INDEX=0;

				if [[ $DEBUG == true ]]
				then
					echo "";
	        echo -e "$(tput bold)[DEBUG] Choice text: " $MENU_CHOICE_TEXT "$(tput sgr0)";
	        echo -e "$(tput bold)[DEBUG] Choice index: " $MENU_CHOICE_INDEX "$(tput sgr0)";
					echo "";
				fi

				# Begin Full Install
				echo "";
				echo "------------------";
				echo "-- Full Install --";
				echo "------------------";
				echo "";

				# Task 1
				echo "Create file system structures.";

				# Task 2
				echo "Copy files/folders";

				# Task 3
				echo "Call Googlizer and create custom prompt";

				# Task 4
				echo "Write bashrc modifications";

				# Task 5
				echo "Final task?";

				# Nothing happened?! Call the main menu
				main_menu;
        ;;
      ${MENU_OPTS[1]})
				# Custom Installation
        MENU_CHOICE_TEXT="${MENU_OPTS[1]}";
        MENU_CHOICE_INDEX=1;

				if [[ $DEBUG == true ]]
				then
					echo "";
        	echo -e "$(tput bold)[DEBUG] Choice text: " $MENU_CHOICE_TEXT "$(tput sgr0)";
	       	echo -e "$(tput bold)[DEBUG] Choice index: " $MENU_CHOICE_INDEX "$(tput sgr0)";
					echo "";
				fi

				# Begin Custom Install
				echo "";
				echo "--------------------";
				echo "-- Custom Install --";
				echo "--------------------";
				echo "";

				# Task 1
				echo "Do you want to... create file system structures?";

				# Task 2
				echo "Do you want to... Copy files/folders";

				# Task 3
				echo "Do you want to... Call Googlizer and create custom prompt";

				# Task 4
				echo "Do you want to... Write bashrc modifications";

				# Task 5
				echo "Do you want to... Final task?";

				# Nothing happened?! Call the main menu
				main_menu;
        ;;
      ${MENU_OPTS[2]})
				# BrainBox Updater
        MENU_CHOICE_TEXT="${MENU_OPTS[2]}";
        MENU_CHOICE_INDEX=2;

				if [[ $DEBUG == true ]]
				then
					echo "";
        	echo -e "$(tput bold)[DEBUG] Choice text: " $MENU_CHOICE_TEXT "$(tput sgr0)";
        	echo -e "$(tput bold)[DEBUG] Choice index: " $MENU_CHOICE_INDEX "$(tput sgr0)";
					echo "";
				fi

				# Brainbox updater
				echo "";
				echo "----------------------";
				echo "-- Brainbox Updater --";
				echo "----------------------";
				echo "";

				# Nothing happened?! Call the main menu
				main_menu;
        ;;
      ${MENU_OPTS[3]})
				# Googlizer
        MENU_CHOICE_TEXT="${MENU_OPTS[3]}";
        MENU_CHOICE_INDEX=3;

				if [[ $DEBUG == true ]] 
				then
					echo "";
        	echo -e "$(tput bold)[DEBUG] Choice text: " $MENU_CHOICE_TEXT "$(tput sgr0)";
        	echo -e "$(tput bold)[DEBUG] Choice index: " $MENU_CHOICE_INDEX "$(tput sgr0)";
					echo "";
				fi

				# Googlizer
				echo "";
				echo "---------------";
				echo "-- Googlizer --";
				echo "---------------";
				echo "";
				echo -n "This will, for each character of your hostname, or a given ";
				echo -n "word, randomly assign one of the four Google colors to the ";
				echo "letter.";
				echo "";
				echo "- Red";
				echo "- Green";
				echo "- Blue";
				echo "- Yellow";
				echo "";
				echo -n "The output will provide the original word along side ";
				echo "the colorized word and offer you the chance to:";
				echo "";
				echo "- Save the word as your hostname prompt (PS1)";
				echo -n "- Regenerate the colorized word if you're not happy ";
				echo "with the random output";
				echo "- Save the output for other uses";
				echo "- Cancel all changes"; 
				echo "";
				
				echo "--";
				echo "";
				echo "(1) Googlize your current (H)ostname ($HOSTNAME)?";
				echo "(2) Choose another (W)ord?";
				echo "(3) (C)ancel and return to the main menu?";
				echo "(4) (E)xit this script entirely?";
				echo "";
				
				# Get user choice
				read -p "What would you like to do? " CCHOICE;

				case $CCHOICE in
					"1" | "h" | "H")
						# Use hostname
						if [[ $DEBUG == true ]]
						then
							echo "";
							echo -e "$(tput bold)[DEBUG] Googlizer choice: " $CCHOICE "$(tput sgr0)";
							echo -e "$(tput bold)[DEBUG] Case match: 1, Use Hostname $(tput sgr0)";
							echo -e "$(tput bold)[DEBUG] Action: Googlize the hostname (" $HOSTNAME ") $(tput sgr0)";
							echo "";
						fi

						# Call googlizer with current hostname
						googlize $HOSTNAME;
					;;
					"2" | "w" | "W")
						# Choose another word
						if [[ $DEBUG == true ]]
						then
							echo "";
							echo -e "$(tput bold)[DEBUG] Googlizer choice: " $CCHOICE "$(tput sgr0)";
							echo -e "$(tput bold)[DEBUG] Case match: 2, Choose another word $(tput sgr0)";
							echo -e "$(tput bold)[DEBUG] Action: Prompt for new word $(tput sgr0)";
							echo "";
						else
							# Blank line for formatting only if DEBUG isn't enabled
							echo "";
						fi

						# Prompt for new word and call googlizer with custom input
						read -p "Enter a new word to googlize: " NEWWORD;
						googlize $NEWWORD;
					;;
					"3" | "c" | "C" | "return" | "menu")
						# Cancel and return to menu
						if [[ $DEBUG == true ]]
						then
							echo "";
							echo -e "$(tput bold)[DEBUG] Googlizer choice: " $CCHOICE "$(tput sgr0)";
							echo -e "$(tput bold)[DEBUG] Case match: 3, Cancel $(tput sgr0)";
							echo -e "$(tput bold)[DEBUG] Action: Return to main menu $(tput sgr0)";
							echo "";
						fi

						# Cancel and return to main menu
						main_menu;
					;;
					"4" | "e" | "E" | "q" | "Q")
						# Exit
						if [[ $DEBUG == true ]]
						then
							echo "";
							echo -e "$(tput bold)[DEBUG] Googlizer choice: " $CCHOICE "$(tput sgr0)";
							echo -e "$(tput bold)[DEBUG] Case match: 4, Exit $(tput sgr0)";
							echo -e "$(tput bold)[DEBUG] Action: Exit $(tput sgr0)";
							echo "";
						fi

						# Exit script entirely
						exit 0;
					;;
					*)
						if [[ $DEBUG == true ]]
						then
							echo "";
							echo -e "$(tput bold)[DEBUG] Googlizer choice: " $CCHOICE "$(tput sgr0)";
							echo -e "$(tput bold)[DEBUG] Case match: Wildcard $(tput sgr0)";
							echo -e "$(tput bold)[DEBUG] Action: Exit $(tput sgr0)";
							echo "";
						fi

						# Invalid choice!
						echo "";
						echo "Invalid choice. Returning to the main menu...";
						echo "";

						# Call main menu
						main_menu;

						# Exit: This should never be reached!
						echo -en "$(tput bold)[ERROR] About to exit from main_menu() ";
						echo -en "from the Googlizer sub-menu's CASE statement. This ";
						echo -e "should NEVER occur.$(tput sgr0)";

						# Exit 1
						exit 1;
					;;
				esac

				# Googlizer is done, call main menu
				main_menu;

				# Exit: This should never be reached!
				echo -en "$(tput bold)[ERROR] About to exit from main_menu() ";
				echo -e "SELECT statement, Googlizer sub-menu $(tput sgr0)";

				# Exit 1
				exit 1;
        ;;
      ${MENU_OPTS[4]})
				# Help
        MENU_CHOICE_TEXT="${MENU_OPTS[4]}";
        MENU_CHOICE_INDEX=4;

				if [[ $DEBUG == true ]]
				then
					echo "";
        	echo -e "$(tput bold)[DEBUG] Choice text: " $MENU_CHOICE_TEXT "$(tput sgr0)";
        	echo -e "$(tput bold)[DEBUG] Choice index: " $MENU_CHOICE_INDEX "$(tput sgr0)";
					echo "";
				fi

				# "Help" selected, call usage function
				usage "all" true;
        ;;
      ${MENU_OPTS[5]})
				# Quit
        MENU_CHOICE_TEXT="${MENU_OPTS[5]}";
        MENU_CHOICE_INDEX=5;

				if [[ $DEBUG == true ]]
				then
					echo "";
	        echo -e "$(tput bold)[DEBUG] Choice text: " $MENU_CHOICE_TEXT "$(tput sgr0)";
	        echo -e "$(tput bold)[DEBUG] Choice index: " $MENU_CHOICE_INDEX "$(tput sgr0)";
					echo "";
				fi
				
				# "Quit" selected, exit script
				exit 0;
        ;;
      *)
				# Check if the "invalid input" was a command to exit
				for i in "q" "quit" "Q" "Quit" "e" "exit" "Exit" "E"
				do
					if [[ $REPLY == $i ]]
					then
						if [[ $DEBUG == true ]]
						then
							echo "";
			      	echo -e "$(tput bold)[DEBUG] Choice text: " $REPLY "$(tput sgr0)";
							echo "";
						fi

						# Exit script
						exit 0;
					fi
				done
				
				# Truly an invalid choice
				echo "";
       	echo -e "$(tput bold)[ALERT] INVALID CHOICE -- " $REPLY "$(tput sgr0)";
				echo "";
       
				# Call usage function
				usage "menu" true;
        ;;
    esac
  done

	# Add some debugging to the end of the function
	if [[ $DEBUG == true ]]
	then
		echo -e "$(tput bold)[DEBUG] End of main_menu() has been reached.$(tput sgr0)";
	fi
}

demo_gui_menu() {
	##################
	# LOCAL VARIABLES
	##################
	#
	#
	#

	while option=$(zenity --title="BrainBox Updater" --text="Select an option:" --list \
		                 --column="Options" "${MENU_OPTS[@]}"); do

		  case "$option" in
		  "${MENU_OPTS[0]}" ) zenity --info --text="You picked $option, option 1";;
		  "${MENU_OPTS[1]}" ) zenity --info --text="You picked $option, option 2";;
		  "${MENU_OPTS[2]}" ) zenity --info --text="You picked $option, option 3";;
		  *) zenity --error --text="Invalid option. Try another one.";;
		  esac

	done

	# Add some debugging to the end of the function
	if [[ $DEBUG == true ]]
	then
		echo -e "$(tput bold)[DEBUG] End of demo_gui_menu() has been reached.$(tput sgr0)";
	fi
}

demo_menu() {
	##################
	# LOCAL VARIABLES
	##################
	#
  PS3='Please enter your choice: '
  options=("Option 1" "Option 2" "Option 3" "Quit")
	#
	#
	#

  select opt in "${options[@]}"
  do
    case $opt in
      "Option 1")
        echo "you chose choice 1"
        ;;
      "Option 2")
        echo "you chose choice 2"
        ;; 
      "Option 3")
        echo "you chose choice 3"
        ;;
      "Quit")
        break
        ;;
      *) 
        echo "Invalid option: " $opt
        ;;
    esac
  done 

	# Add some debugging to the end of the function
	if [[ $DEBUG == true ]]
	then
		echo -e "$(tput bold)[DEBUG] End of demo_menu() has been reached.$(tput sgr0)";
	fi

}


####################
# ARGUMENT PARSING #
####################
check_args() {
	##################
	# LOCAL VARIABLES
	##################
	#
	# Set a local arguments variable
	ARG_LIST=$GLOBAL_ARGS;
	#
	#

	if [[ ${#ARG_LIST} -gt 0 ]]
	then
		for ARG in ${ARG_LIST[*]}
		do
			case $ARG in
				--debug | -d | --d)
					# Set DEBUG=true for future processing
					DEBUG=true;

					echo -e "$(tput bold)\n** DEBUGGING ENABLED **\n $(tput sgr0)";
					echo -en "$(tput bold)[DEBUG] Startup info :: ";
					echo -e "Args=" ${ARG_LIST[*]} ", Count=" ${#ARG_LIST} "$(tput sgr0)";
					echo "";
				;;
				--help | -h | --h)
					# Set HELP=true for future processing
					HELP=true;

					# Call help from the CLI
					usage "all";
				;;
				--gui | -g | --g)
					# Set GUI=true for future processing
					GUI=true;

					# Launch Zenity version
					# NOT IMPLEMENTED
					echo "";
					echo -ne "$(tput bold)[ERROR] This feature has not yet been ";
					echo -e "implented. Try the shell menus first :) $(tput sgr0)";
					echo "";
					
					############## REPLACE ME WITH THE GUI FUNCTION ############
					# Call main menu
					main_menu;
					############################################################
				;;
				*)
					# Invalid option, output an error and continue to the main menu
					echo "";
					echo -en "$(tput bold)[ALERT] Bad option, continuing to the ";
					echo -e "main menu... $(tput sgr0)";
					echo "";
					
					# Call main menu
					main_menu;
				;;
			esac	# End argument parsing case statement
		done	# End argument parsing for loop

		# Call the main menu
		# At this point, the following may be true:
		#		- DEBUG may be on
		# 	- If HELP is set to TRUE, this won't be reached
		#		- If GUI is set to true, this won't be reached
		#		- An invalid option was NOT detected
		main_menu;
	else
		# No command line arguments, call the main menu
		main_menu;
	fi

	# Add some debugging to the end of the function
	if [[ $DEBUG == true ]]
	then
		echo -e "$(tput bold)[DEBUG] End of check_args() has been reached.$(tput sgr0)";
	fi
}

########
# MAIN #
########
check_args $GLOBAL_ARGS;

#demo_menu;
#demo_gui_menu


##############
# END SCRIPT #
##############
#############
############
###########
##########
#########
########
#######
######
#####
####
###
##
#
