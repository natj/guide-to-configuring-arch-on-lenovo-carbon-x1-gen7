# Configuring Arch Linux on Thinkpad X1 Carbon Gen7

For installation notes check installation guide e.g. on [X1C6](https://github.com/ejmg/an-idiots-guide-to-installing-arch-on-a-lenovo-carbon-x1-gen-6). These notes focus on configuring the OS to work with X1C7 and assume that you have already successfully installed the basic Arch Linux distribution.

Finally, as per unwritten Arch Linux community rules apparently these tips/guides should not exists in the first place so do not read this. These are my own personal notes.



## basic commands needed

There are few stuff that gets done repeatedly in Arch. I write these down as a reference. 

### systemctl

Few useful commands are:

Check status of running services:
```
systemctl status
```

Start/stop new services
```
systemctl start <service_name>
```

### installing from AUR

Sooner or later some package is missing and needs to be installed from AUR instead. There are many tools to automate this but the compilation and dependency checking is automated well enough so that only a few steps are needed anyway. Therefore, I prefer to do this by hand as follows.

Create e.g. a `~/pkg` directory and git clone the pkg repo
```
git clone address
```
then compile and check dependencies
```
makepkg -s 
```
As an annoying feature sometimes the PGP key is missing. If you want to live dangerously and proceed anyway you can add `--skippgpcheck` option to skip the check.

Then install the new package
```
makepkg -i
```
that corresponds to `pacman -U pkgname`


## time

If you have opened Windows before installing Linux it might have messed your internal system clock. This is the clock that stores time when you shutdown the computer and reload. Win10 apparently overwrites the time with timezone settings so there might be +-few hour mismatch to real time in Linux.

To update it reliable and easily install `ntp` then get the global time with
```
sudo ntpd -qg
```

and write it back to the system clock
```
sudo hwclock --systohc
```

you can then check that everything went ok by looking
timedatectl status

that should show correct timezone and correct localtime.

System clock is quite stable and robust so I don't see any point launching a daemon to keep it up to date. One can do this manually with the above commands instead once per year or so if you like your seconds to be correct.


## wifi
s
For wifi you have two options: `netctl` or `NetworkManager`. Both are relatively easy to use BUT do not work if they are both running simultaneously. Pick one.

TODO: write how to save wlan configurations and autoconnect.

## intel gpu

TODO: `intel_agp`  and `i915`

https://wiki.archlinux.org/index.php/intel_graphics
https://bbs.archlinux.org/viewtopic.php?id=127953


## terminal

A good and flexible terminal is a must. Many recommend `rxvt-unicode`.

A reasonable terminal font is the hand-groomed hack (install with pkg `ttf-hack`).

To load these we can modify the `.Xresources` as

```
! fix HiDpi scaling 
Xft.dpi: 192

! TODO: define basic colors here< whatever you like

urxvt*scrollBar: False

URxvt.transparent: true
URxvt.shading: 20

urxvt*transparent: true
urxvt*shading: 20

URxvt.font:       xft:Hack-Regular:pixelsize=22
URxvt.boldFont:   xft:Hack-Bold:pixelsize=22
URxvt.italicFont: xft:Hack-RegularOblique:pixelsize=22:slant=italic
URxvt.letterSpace: 0

```

## login prompt

Login greeter can be tweaked to include the username by adding the `-o` option to `agetty`. Additionally, it seems reasonable to put a 1s delay into it since otherwise the intel microcode will dump some garbage on the screen.

Create a file `/etc/systemd/system/getty@tt1.service.d/override.conf` with content:

```
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty -n --delay 1 -o USERNAME %I
TTYVTDisallocate=no
```

Replace `USERNAME` with your own.

## audio

Audio needs the sof firmware driver.

TODO: add correct package.

TODO: pulse audio is actually also needed

To set and modify the audio levels install also:
```
alsa-utils
```

In addition, we need to tell the pulse audio library to use the new sof drivers. Add this file
```
%etc/pulse/default.pa:

module-load module-alsa-sink hw:0,0 channels=4
module-load module-alsa-source hw:0,6 channels=4
```

Set Speaker to Mute to remove hollow/thin sound in alsamixer.

TODO: make it stick

### Remove and blacklist PC speaker

I find it nice to remove the internal PC speaker from beeping. Do
```
sudo rmmod pcspkr
```
to test the eerie silence. Then make it permanent by blacklisting the module from being loaded by udev with

```
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
```


## keyboard 

### thinkpad keyboard shortcuts

In order to get the thinkpad extra keyboard keys working the running kernel needs to be updated with the thinkpad_acpi module.

TODO: Add installation notes


Next we need a script that listens to keypresses, captures them and lets us perform stuff based on them.

Install `acpid` for that. Enabled it to systemctl.

Try with live capturing:
```
journalctl -f 
```
and record what button/combination is called what.

Button action can be configured by modifying an event handler script at `/etc/acpi/handler.sh` and by restarting `acpi.service` / booting the machine.

My script is at the bottom of this section.


### display brigthness controls

You can check the current brigthness with:
```
cat /sys/class/backlight/intel_backlight/brigthness
```
and maximum possible brightness (to get a feeling of the scaling) with
```
cat /sys/class/backlight/intel_backlight/max_brigthness
```

Different machines might have different `bl_device` so check that if `intel_backlight` is not there.


For the actual brightness control we need to add user to `video` grop in addition to have permission to write to the needed configuration files.

Add a file `/etc/udev/rules.d/backlight.rules` with:
```
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
```

Ref: [wiki/backlight](https://wiki.archlinux.org/index.php/Backlight)


then
```
sudo usermod -aG <user>
```

after this you have permission to change `bl_dev` and fn+f5/f6 should work.

### clipboard and copy-pasting

Copypasting with `neovim` and `urxvt` is weird. It works if you add
```
set clipboard=unnamedplus
```
to vim config (`~/.config/nvim/init.vim` for `neovim`). Importantly, after this the X clipboard can be accessed with `shift`+`mouse-middle-button`.



### Event handler script `handler.sh`

This is my `/etc/acpi/handler.sh`:
```
#!/bin/bash

# backlight devide and increment step size
bl_dev=/sys/class/backlight/intel_backlight
bl_step=1000

case "$1" in
    button/volumedown)
	    logger 'Volume down'
	    amixer set Master 5-
        ;;
    button/volumeup)
	    logger 'Volume up'
	    amixer set Master 5+
        ;;
    button/mute)
	    logger 'Volume mute toggle'
	    amixer set Master toggle
        ;;
    video/brightnessup)
	    logger 'Brightness up'
	    echo $(($(<$bl_dev/brightness) + $bl_step)) >$bl_dev/brightness
        ;;
    video/brightnessdown)
	    logger 'Brightness down'
	    echo $(($(<$bl_dev/brightness) - $bl_step)) >$bl_dev/brightness
        ;;
    *)
        logger "ACPI group/action undefined: $1 / $2"
        ;;
esac
```


### typomatic keyboard tweaks

Disable capslock 

add `.xinitrc` with:
```
setxkbmap -option caps:none
```

Increase typomatic delay by again adding to `.xinitrc`:
```
xset r rate 225 33
```


## tiling window manager Awesome

Tiling window managers are the best. I installed Awesome to my Arch. 

Process is relatively straightforward but to get transparency also working you need these packages:

```
xcompmgr
transset-df
awesome
```

In addition, the `.xinitrc` needs to be modified. Add these lines to the **end** of the file:

```
exec xcompmgr -c &

exec awesome
```


### Automatic window opening & setup

Add these to the end of the `.config/awesome/rc.lua` to automatically load some apps at startup

```
-- background apps
awful.spawn.once("dropbox")
awful.spawn.once("TogglDesktop", {minimized = true} )

-- make tag 2 ready with 3 terminals
awful.spawn(terminal, { screen = 1, tag = "2", focus = false} )
awful.spawn(terminal, { screen = 1, tag = "2", focus = false} )
awful.spawn(terminal, { screen = 1, tag = "2", focus = false} )

-- autostart common apps
awful.spawn.once("slack",   { screen = 1, tag = screen[1].tags[9], maximized = true, focus = false} )
awful.spawn.once("firefox", { screen = 1, tag = screen[1].tags[1], maximized = true, } )
```

Change tags and screen as necessary.


## openssh

Default ssh app from the public `openssh` package does not support kerberos tickets that need gssapi key exchange support. Instead, one needs to manually install `openssh-gssapi` from the AUR.


## fingerprint reader

Packages we need:
```
fwupdmgr
usbutils
fprintd
imagemagic
```
 
First, let's check the status of the firmware with:
```
fwupdmgr get-devices
```

Check that you have:
```
├─Prometheus:
│ │   Summary:             Fingerprint reader
│ │   Current version:     10.02.3110269
│ │   Vendor:              Synaptics (USB:0x06CB)
│ │ 
│ └─Prometheus IOTA Config:
│       Current version:   0022
│       Minimum Version:   0022
│       Vendor:            Synaptics (USB:0x06CB)
```
with at least version 10.02 for Prometheus and 0022 for Prometheys IOTA config drivers.

If not, we need to update it from the lvfs-testing repository (i.e. not stable updates). Enable lvfs testing with:
```
sudo fwupdmgr enable-remote lvfs-testing
```
then use fwupdmgr to refresh the driver list, download updates, and update:
```
fwupdmgr refresh
fwupdmgr get-updates
fwupdmgr update
```

Now we can proceed to the actual `fprint` installation with pacman, as usual.

After that you might want to remove the testing branch remote with
```
sudo fwupdmgr disable-remote lvfs-testing
```
because pushing unstable firmware BIOS drivers to your machine might not be the best idea.


Next we need to setup fingerprints and enable login. Run
```
fprintd-enroll
```
and give your right index finger (or whatever) as many times as the application wants (8 times for me)

After this the print should appear in `/var/lib/fprint/USER/synaptics`. You can check that it works with
```
fprintd-verify -f right-index USER
Using device /net/reactivated/Fprint/Device/0
Listing enrolled fingers:
 - #0: right-index-finger
Verify result: verify-match (done)
```

Finally, we can put that fingerprint reader to good use by enabling it as a sufficient local login authentication method. Modify `/etc/pam.d/system-local-login` as:

```
auth		sufficient	pam_fprintd.so
```
by inserting this to the top of the list.

Similarly, one could edit `/etc/pam.d/sudo`. However, not sure if this is wise.

By using the `sufficient` optoin the reader will ask for the index finger 3 times and if failed it will open the password box as normal.


Refs:

- [wiki/fprint](https://wiki.archlinux.org/index.php/Fprint)
- [blog1](https://curryncode.com/2018/11/27/using-the-fingerprint-reader-to-unlock-arch-linux/)


## bluetooth

Packages needed:
```
bluez
bluez-utils
pulseaudio-bluetooth
blueman
bluez-hid2hci
```

Begin by checking that bluetooth module is loaded to kernel:
```
modinfo btusb
```
and see that you get output.

```
systemctl enable bluetooth.service
```

next, add user to lp group to get acces to bl devices
group for acces to parallel port devices (printers and others)

display current groups
```
groups user
gpasswd -a user group
```

### checking device status

Now we are ready to start tweaking.

tried this package for thinkpad:
bluez-hid2hci

There seems to be also a hardware-based on-off switch. Check its status with:
```
rfkill list
```
that shows status of wireless devices.
Then press Fn=F10 (bluetooth symbol) and try again. Soft blocked should turn from yes to no or vice versa.

Same info is available from
```
cat /proc/acpi/ibm/bluetooth 
status:		enabled
commands:	enable, disable
```

and is controllable from 
```
cat /sys/devices/platform/thinkpad_acpi/bluetooth_enable 
```
by inserting `0` or `1` to the file.


### debugging bluetooth device and service

test bluetooth device with `bluetoothctl` that is part of the `bluez` package.

Then inside the cli app try these commands:
```
show
power on
scan on
pair MAC_ADDRESS
connect MAC_ADDRESS
```
NOTE: blueman automates all of this so not really needed in real life usage scenario.

Apparantly, a better way to debug this is by first stoppign the service
```
systemctl stop bluetooth
```
and then loading it manually
TODO: with or without sudo?
```
/usr/lib/bluetoothd -n -d
```
and checking the output.


another tool is the 
```
btmgmt
```
with comands
```
info
select hci0
power on
```


### removing wifi & bluetooth interference settings

/etc/modprobe.d/iwlwifi.conf
add
options iwlwifi bt_coex_active=0


### actual usage with `blueman`

Finally, you can easily pair and connect to devices by launching
```
blueman-applet
```

Refs:

- [wiki/bluetooth](https://wiki.archlinux.org/index.php/bluetooth)
- [wiki/blueman](https://wiki.archlinux.org/index.php/Blueman)
- [wiki/bluetooth_headset](https://wiki.archlinux.org/index.php/Bluetooth_headset)

https://200ok.ch/posts/2018-12-17_making_bluetooth_work_on_lenovo_x1_carbon_6th_gen_with_linux.html
http://www.thinkwiki.org/wiki/How_to_setup_Bluetooth
https://askubuntu.com/questions/180744/how-to-enable-hard-blocked-bluetooth-in-thinkpad-edge-320


### delay bluetooth powering from restart

Create the file /etc/systemd/system/bluetooth-poweron.service as root and put the following code into it :

[Unit]
Description=Bluetooth Power Fix
After=bluetooth.target

[Service]
Type=simple
ExecStart=/usr/bin/bluetoothctl -- power on
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target

then run systemctl enable bluetooth-poweron



### Old appendix:

Modify `/etc/pulse/default.pa`
```
load-module bluetooth-xx
load-module bluetooth-yy

### auto switch on connect
load-module module-switch-on-connect
```

NOTE: `blueman-applet` does pulseaudio switching automatically.



## misc apps that work well in browser:

Many apps work well in browser (some in `firefox`, some in `chromium`).

- email -> gmail
- whatsapp -> whatsapp web
- spotify -> web.spotify


----


# Work in Progress:


## throttled

TODO: is it needed? Seems to work fine without.

## sleep/hibernation

TODO: there is no sleep by default, however power consumption is quite low at idle so not very urgent

TODO: check `i3lock` for screen lock


## disk usage

https://github.com/amanusk/s-tui
https://gitlab.freedesktop.org/drm/igt-gpu-tools
https://www.archlinux.org/packages/community/x86_64/powertop/

## thinkpad hw controls

tpacpi controls are in directory:
```
/sys/devices/platform/thinkpad_acpi
```



## TODO / missing

TODO: modify default window positions to have 2/3 ratios.

TODO: password storing

TODO: terminal does not always update

TODO: reasonable `bashrc`

TODO: only make terminal transparent

TODO: proper folder viewer 

TODO: open script to open every file type


## kernel compilation

Some generla notes about kernel compilation.

### initial ramdisk

"Initial ramdisk is in essence a very small environment (early userspace) which loads various kernel modules and sets up necessary things before handing over control to `init`." - wiki/mkinitcpio

First an initial ramdisk image is created with
```
mkinitcpio
```
This creates both the `default` (optimized) image and a `fallback` image (that skips autodetect hook of drivers and embeds everything into the image just in case).


TODO:

There might be messages during compile time about missing firmware:
```
aic94xx
wd719x
```
see https://wiki.archlinux.org/index.php/Mkinitcpio#Possibly_missing_firmware_for_module_XXXX

These appear harmless as they are both some HDD/RAID drivers.

TODO:

warning: /etc/fwupd/remotes.d/lvfs-testing.conf installed as /etc/fwupd/remotes.d/lvfs-testing.conf.pacnew
warning: /etc/fwupd/remotes.d/lvfs.conf installed as /etc/fwupd/remotes.d/lvfs.conf.pacnew


Configuration is in `/etc/mkinitcpio.conf`



----

# Appendix

## boot into live iso

When all goes wrong you can always boot and debug by using the live iso USB.

TODO: describe these in more detail:

- boot live iso
- mount partitions
- chroot into your system




