# Configuring Arch Linux on Thinkpad X1 Carbon Gen7

For installation notes check installation guide e.g. on [X1C6](https://github.com/ejmg/an-idiots-guide-to-installing-arch-on-a-lenovo-carbon-x1-gen-6). These notes focus on configuring the OS to work with X1C7 and assume that you have already succesfully installed the basic Arch Linux distribution.

I also assume that you are like me and know something about programming but not too much about Linux. Therefore, I've written many commands and their explanation explicitly but have not elaborated much on code snippets (like bash scripts etc).

Finally, as per unwritten Arch linux community rules apparently these tips/guides should not exists in the first place so do not read this. These are my own personal notes.


## Basic commands needed

There are few stuff that gets done repeatedly in Arch. I write these down as a reference. 

TODO: launching services.

### Systemctl

Few useful commands are:

Check status of running services:
```
systemctl status
```

Start/stop new services
```
systemctl start <service_name>
```




## time

If you have opened Windows before installing Linux it might have messed your internal system clock. This is the clock that stores time when you shutdown the computer and reload. Win10 apparently overwrites the time with timezone settings so there might be +-few hour mismatch to real time in Linux.

To update it reliable and easily install ntp then get the global time with
sudo ntpd -qg

and write it back to the system clock
sudo hwclock --systohc

you can then check that everything went ok by looking
timedatectl status

that should show correct timezone and correct localtime.

System clock is quite stable and robust so I don't see any point launching a daemon to keep it up to date. One can do this manually with the above commands instead once per year or so if you like your seconds to be correct.


## bootctl

## throttled

## wifi

For wifi you have to options: `netctl` or `NetworkManager`. Both are relatively easy to use BUT do not work if they are both running simultaneously. Pick one.

TODO: write how to save wlan configurations and autoconnect.

## Tiling window manager awesome

Tiling window managers are the best. I installed Awesome to my Arch. 

Process is relatively straightforward but to get transparency also working you need these packages:

```
xcompmgr
transset-df
awesome
```

In addition, the xinitrc needs to be modified.
TODO: xinit mods
TODO: modified rc.lua


### automatic window opening & setup

read awesome documentation


## terminal

A good and flexible terminal is a must. Many recommend:

```
rxvt-unicode
```

In order to make it look pretty I modified .Xresoures as

TODO: add xresources mods


## audio

Audio needs the sof firmware driver.
TODO: add correct package.

To set and modify the audio levels install also:
```
alsa-utils
```

These tweaks recommended in some manual where no longer needed but might depend on how up-to-date your BIOS is:

```
%etc/pulse/default.pa:

module-load module-alsa-sink hw:0,0 channels=4
module-load module-alsa-source hw:0,6 channels=4
```

Set Speaker to Mute to remove hollow/thin sound in alsamixer.
TODO: make it stick


## keyboard shortcuts

In order to get the thinkpad extra keyboard keys working the running kernel needs to be updated with the thinkpad_acpi module.

TODO: describe it;

Next we need a script that listens to keypresses, captures them and lets us perform stuff based on them.

Install:

```
acpid 
```

enabled it to systemctl

try with live capturing:
```
journalctl -f 
```

add event handler script to `/etc/acpi/handler.sh` and restart acpi.service / boot machine.

for brightness control need to add user to video grop
```
% /etc/udev/rules.d/backlight.rules

ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
```

then
```
sudo usermod -aG <user>
```

after this you have permission to change bl_dev and fn+f5/f6 should work.



## Dropbox

rclone?


