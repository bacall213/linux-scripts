#!/bin/bash

#############################################################################
#                         LINUX TEXT GOOGLIZER
#############################################################################
# 
#                          Author: Brian Call
#                             Date: 2/2013
#
# Purpose: 
#				This script takes standard input and randomly colorizes 
#				each character to one of the four Google colors. The 
#				script then outputs the code necessary to create the 
#				same coloration elsewhere, such as in a $PS1 statement.
#
# Usage: 
#				./googlizer.sh [-d|--debug] <string_to_colorize>
#
# Caveats:
#				- No validation of input is performed, so inputs such as "$$"
#					and "!!" WILL cause unintended behavior.
#
#############################################################################

# Input variable
INWORD="";

# Output Variable
OUTWORD="";
OUTCMD="";

# Range for random (Google has 4 main colors)
RANDRANGE=4;
  
# $RANDOM has a floor of 0 by default, but we should define one JUST IN CASE
RANDFLOOR=1;


# COLOR SET
# Some info from: http://linuxtidbits.wordpress.com/2008/08/11/output-color-on-bash-scripts/

# Underline
txtund=$(tput sgr 0 1);

# Bold
txtbld=$(tput bold);

# Red
bldred=${txtbld}$(tput setaf 1);

# Blue
bldblu=${txtbld}$(tput setaf 4);

# Yellow
bldyellow=${txtbld}$(tput setaf 3);

# Green
bldgrn=${txtbld}$(tput setaf 2);

# White
bldwht=${txtbld}$(tput setaf 7);

# Reset
txtrst=$(tput sgr0);

# Feedback
info=${bldwht}*${txtrst};
pass=${bldblu}*${txtrst};
warn=${bldred}*${txtrst};
ques=${bldblu}?${txtrst};


function googlize() {
	if [[ ! $1 ]]
	then
		echo "Usage: " $0 "[-d|--debug] <string_to_colorize>";
	
		echo "";
		echo " ** WARNING: No validation of input is performed! **";
		echo "";
	else
		case $1 in
			"-d" | "--debug")
				echo "";
				echo "** DEBUG ENABLED **";
				echo "";

				# Input is now $2
				INWORD=$2;

				# Show the input
				echo "Original input: " $INWORD;

				# Color test
				echo "COLOR TEST: ${bldblu}blue ${bldyellow}yellow ${bldgrn}green ${bldred}Red ${txtrst} Reset";

				# Create an array from the input
				echo "Breaking input into array (INWORD=\${VAR})...";
				INWORD=${INWORD};

				# Determine length of input
				echo "Length of input (\${#VAR}): " ${#INWORD};
				INLENGTH=${#INWORD};

				# Blank line for formatting
				echo "";

				# Parse input and colorize
				echo "Parsing input with while() statement...";
		
				# Set loop index to 0
				index=0;

				while [[ index -lt $INLENGTH ]]
				do
		  		# Random num > 1 < 4
				  RAND=$RANDOM; 

				  while [[ $RAND -gt $RANDRANGE || $RAND -lt $RANDFLOOR ]]
				  do
				    RAND=$RANDOM;
				  done

				  # Output random num for debugging
				  echo "Random num between 1 and 4: " $RAND;

				  # debug: output current char
				  CCHAR=${INWORD:index:1};
				  echo "Current Character: ${INWORD:index:1}";

				  case $RAND in
				     1) # Blue
				        OUTWORD="$OUTWORD""$bldblu""$CCHAR""$txtrst";
								OUTCMD=$OUTCMD\$\('tput bold'\)\$\('tput setaf 4'\)$CCHAR\$\('tput sgr0'\);
				     ;;
				     2) # Red
				        OUTWORD="$OUTWORD""$bldred""$CCHAR""$txtrst";
								OUTCMD=$OUTCMD\$\('tput bold'\)\$\('tput setaf 1'\)$CCHAR\$\('tput sgr0'\);
				     ;;
				     3) # Yellow
				        OUTWORD="$OUTWORD""$bldyellow""$CCHAR""$txtrst";
								OUTCMD=$OUTCMD\$\('tput bold'\)\$\('tput setaf 3'\)$CCHAR\$\('tput sgr0'\);
				     ;;
				     4) # Green
				        OUTWORD="$OUTWORD""$bldgrn""$CCHAR""$txtrst";
								OUTCMD=$OUTCMD\$\('tput bold'\)\$\('tput setaf 2'\)$CCHAR\$\('tput sgr0'\);
				     ;;
				  esac

		  		# increase counter
				  index=$index+1;
				done

				# Output new colorized word
				echo "Colorized awesomeness:" $OUTWORD;

				# Output the code
				echo "Copy-Ready-Code:" $OUTCMD;

				# Blank line for formatting
				echo "";

				# Export variables for use by the customizer
				export GWORD=$OUTWORD;
				export GCMD=$OUTCMD;	
			;;
			*)
				# Input is now $1
				INWORD=$1;

				# Create an array from the input
				INWORD=${INWORD};

				# Determine length of input
				INLENGTH=${#INWORD};
		
				# Set loop index to 0
				index=0;

				while [[ index -lt $INLENGTH ]]
				do
		  		# Random num > 1 < 4
				  RAND=$RANDOM; 

				  while [[ $RAND -gt $RANDRANGE || $RAND -lt $RANDFLOOR ]]
				  do
				    RAND=$RANDOM;
				  done

				  # Current char
				  CCHAR=${INWORD:index:1};

				  case $RAND in
				     1) # Blue
				        OUTWORD="$OUTWORD""$bldblu""$CCHAR""$txtrst";
								OUTCMD=$OUTCMD\$\('tput bold'\)\$\('tput setaf 4'\)$CCHAR\$\('tput sgr0'\);
				     ;;
				     2) # Red
				        OUTWORD="$OUTWORD""$bldred""$CCHAR""$txtrst";
								OUTCMD=$OUTCMD\$\('tput bold'\)\$\('tput setaf 1'\)$CCHAR\$\('tput sgr0'\);
				     ;;
				     3) # Yellow
				        OUTWORD="$OUTWORD""$bldyellow""$CCHAR""$txtrst";
								OUTCMD=$OUTCMD\$\('tput bold'\)\$\('tput setaf 3'\)$CCHAR\$\('tput sgr0'\);
				     ;;
				     4) # Green
				        OUTWORD="$OUTWORD""$bldgrn""$CCHAR""$txtrst";
								OUTCMD=$OUTCMD\$\('tput bold'\)\$\('tput setaf 2'\)$CCHAR\$\('tput sgr0'\);
				     ;;
				  esac

		  		# increase counter
				  index=$index+1;
				done

				# Output new colorized word
				echo "Colorized awesomeness:" $OUTWORD;

				# Output the code
				echo "Copy-Ready-Code:" $OUTCMD;

				# Blank line for formatting
				echo "";	

				# Export variables for use by the customizer
				export GWORD=$OUTWORD;
				export GCMD=$OUTCMD;
			;;
		esac
	fi
}

# Call main Googlizer function
googlize $1 $2;
