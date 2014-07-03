Linux Scripts Repository
========================
Author: Brian Call
Status: Unstable
License: MIT


## Purpose
These scripts are written as a hobby for various purposes, including:
- Systems Administration
- For fun
- Test/develop scripting skills


## Usage
I recommend creating a 'bin' directory under your home directory and executing them from there, but this is only a preference, not a requirement. They can be placed anywhere you can execute them from. I've tried to be conscious of alternate placements and used various "location-finding" functions, where necessary, to ensure the scripts function as intended.


## Scripts
### brainbox-updater.sh
- Status: Mostly complete
- Purpose: Ubuntu updater
- Features: 
 - Sanity checks
 - Full, in-script documentation
 - Extensive help system
 - Adjustable status updates
 - Highly configurable logging
- Limitations:
 - Not tested on any other system other than Ubuntu


### googlizer.sh
- Status: Mostly complete
- Purpose: Colorizes input into the Google colors
- Features:
 - Outputs copy-paste compatible text
 - Outputs script friendly code
- Limitations:
 - No input validation

### crobuntu-updater.sh
- Status: Incomplete
- Purpose: Updater for Ubuntu on Chromeboxes/books (Crobuntu)


### brainbox-customizer.sh
- Status: Incomplete
- Purpose: Framework for fully customizing a new install
- Features:
 - Menu based
 - Scriptable
- Limitations:
 - Designed for my own personal use, many features will be irrelevant
 - Mostly incomplete


## Installation
### Step 1 - Grab the scripts
```
cd ~
mkdir ~/bin
git clone https://github.com/bacall213/linux-scripts.git ~/bin
```

### Step 2 - Open /etc/sudoers for editing
```
sudo visudo
```

### Step 3 - Add your 'bin' path to 'secure_path'
- Find the line that begins with "Defaults secure_path="
- Add "~/bin" (minus the quotes) or the absolute path to your bin directory (e.g. /home/$USER/bin) to the end of the line.


### Step 4 - Save and exit
Assuming you use vim as your default editor...
```
:wq<enter>
```

## Notes
- Paths in /etc/sudoers are separated by colons (:)
- These scripts are under constant development and should be considered unstable. Use at your own risk.
- It's worth repeating that last bullet, USE AT YOUR OWN RISK.
- If the script doesn't work, I'm probably still working on it.
