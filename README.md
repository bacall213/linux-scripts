Linux Scripts Repository
========================
Author: Brian Call
Status: Unstable
License: ?


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

Note: Each path is separated by a colon (:)


## Notes
- Paths in /etc/sudoers are separated by colons (:)
- These scripts are under constant development and should be considered unstable. Use at your own risk.
- It's worth repeating that last bullet, USE AT YOUR OWN RISK.
