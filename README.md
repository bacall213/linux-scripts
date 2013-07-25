Linux Scripts Repository
========================
Author: Brian Call
Status: Unstable
License: ?


## Purpose
These scripts are written as a hobby for various purposes, including:
- Systems Administration
- For fun
- Test/develop scripting skills


## Usage
I recommend creating a 'bin' directory under your home directory and executing them from there, but this is only a preference, not a requirement. They can be placed anywhere you can execute them from. I've tried to be conscious of alternate placements and used various "location-finding" functions, where necessary, to ensure the scripts function as intended.


## Installation
### Step 1 - Grab the scripts
```
cd ~
mkdir ~/bin
git clone https://github.com/bacall213/linux-scripts.git ~/bin
```

### Step 2 - Add 'bin' directory to /etc/sudoers
```
sudo visudo
```
Find the line that begins with "Defaults secure_path=".
Add "~/bin" or the absolute path to your bin directory (e.g. /home/$USER/bin) to the end of the line.


## Notes
- Paths in /etc/sudoers are separated by colons (:)
- These scripts are under constant development and should be considered unstable. Use at your own risk.
- It's worth repeating that last bullet, USE AT YOUR OWN RISK.
- If the script doesn't work, I'm probably still working on it.
