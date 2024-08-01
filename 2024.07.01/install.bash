#!/bin/bash
# quick dsplayer (autostart browser for x86)
# just execute script as 'root' on a fresh
# archlinux installation
########################################################################
# Run this script after first boot on the new system as root!          #
# You only need to run it once!                                        #
# It will                                                              #
#  - setup autologin for user 'alarm'                                  #
#  - setup a working X system with lightdm, fluxbox, etc.              #
#  - autostarts a browser with given URL in fullscreen kiosk mode      #
#                                                                      #
# AN INTERNET CONNECTION IS REQUIRED !                                 #
########################################################################

########################################################################
# check internet connection (archlinuxarm.org)                         #
########################################################################
while ! timeout 5 curl -s https://archlinuxarm.org/ &> /dev/null
do
    printf "%s\n" "no internet connection, please check! - Long press Ctrl+C to exit!"
    sleep 1
done
printf "\n%s\n"  "Internet is accessible."

########################################################################
# update package list, install reflector and create a fast mirrorlist
########################################################################
pacman -Syy --noconfirm
pacman -S reflector --noconfirm
reflector --save /etc/pacman.d/mirrorlist --country Germany --protocol https --latest 10

########################################################################
# fully update the system
########################################################################
pacman -Syu --noconfirm

########################################################################
# Install packages we need
# - fluxbox
# - xorg-server
# - xf86-video-fbdev
# - xorg-xmodmap
# - xorg-xinit
# - xorg-xset
# - accountsservice
# - lightdm
# - lightdm-gtk-greeter
# - unclutter
# - firefox
# - chromium
# - youtube-dl
# - ttf-liberation
# - feh
########################################################################
# get list of already installed packages and store them in $installed
# --force can be used as "$1" to ignore the variable completely
########################################################################
installed=$(pacman -Q | cut -d ' ' -f 1 | tr '\n' '|')
if [ "$1" == "--force" ];then installed='';fi # override when --force
# list of packages to install
# if you can afford arround 600 MiB more disk space, you can install all
# the noto-fonts packages from the list below
#
# noto-fonts-cjk   (294 MB)
# noto-fonts-emoji (  9 MB)
# noto-fonts-extra (321 MB)
#
packages="fbida,fluxbox,xorg-server,xf86-video-fbdev,xorg-xmodmap,xorg-xinit,xorg-xset,xorg-xmessage,accountsservice,lightdm,lightdm-gtk-greeter,unclutter,firefox,chromium,ttf-liberation,ttf-dejavu,feh,alsa-tools,alsa-utils,alsa-firmware,youtube-dl,yt-dlp,rtmpdump,python-pycryptodome,vim,cronie,htop,touchegg,noto-fonts,noto-fonts-cjk,noto-fonts-emoji,noto-fonts-extra"
# install packages from list
for i in $(echo $packages | sed "s/,/ /g")
do
 if ! echo "$installed"|grep -q "$i" # only if not yet installed
 then
  LANG=C pacman -Si "$i" | grep -E "Name|Depends"; echo "----"
  pacman -S "$i" --noconfirm
 fi
done

########################################################################
# multitouch for ViewSonic
########################################################################
modprobe hid-multitouch
touch '/sys/module/hid_multitouch/drivers/hid:hid-multitouch/new_id'
echo '1 222a 0001 12' | tee '/sys/module/hid_multitouch/drivers/hid:hid-multitouch/new_id'

########################################################################
# add user alarm to group video and audio
########################################################################
# create user alarm
useradd -m alarm
echo -e "alarm\nalarm" | passwd alarm
gpasswd -a alarm video
gpasswd -a alarm audio

systemctl start cronie
systemctl enable cronie
########################################################################
# create system group autologin and add user alarm to group
########################################################################
groupadd -f -r autologin
gpasswd -a alarm autologin

########################################################################
# create .xinitrc for user alarm
########################################################################
cat >"/home/alarm/.xinitrc" <<EOL
#!/bin/sh
userresources=\$HOME/.Xresources
usermodmap=\$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap
# merge in defaults and keymaps
if [ -f \$sysresources ]; then
    xrdb -merge \$sysresources
fi
if [ -f \$sysmodmap ]; then
    xmodmap \$sysmodmap
fi
if [ -f "\$userresources" ]; then
    xrdb -merge "$userresources"
fi
if [ -f "\$usermodmap" ]; then
    xmodmap "\$usermodmap"
fi
# start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "\$f" ] && . "\$f"
 done
 unset f
fi
twm &
xclock -geometry 50x50-1+1 &
xterm -geometry 80x50+494+51 &
xterm -geometry 80x20+494-0 &
exec startfluxbox
EOL
chown alarm:alarm /home/alarm/.xinitrc

########################################################################
# create /etc/lightdm
########################################################################
[[ -d /etc/lightdm ]] || mkdir -p /etc/lightdm/
########################################################################
# configure lightdm.conf for autologin of user alarm and more
########################################################################
cat >"/etc/lightdm/lightdm.conf" <<EOL
[LightDM]
logind-check-graphical=true
start-default-seat=true
greeter-user=lightdm
minimum-display-number=0
minimum-vt=7 # Setting this to a value < 7 implies security issues, see FS#46799
user-authority-in-system-dir=false
run-directory=/run/lightdm
dbus-service=true
[Seat:*]
autologin-user=alarm
autologin-user-timeout=0
xserver-display-number=7
greeter-session=lightdm-gtk-greeter
user-session=fluxbox
session-wrapper=/etc/lightdm/Xsession
[XDMCPServer]
[VNCServer]
EOL


########################################################################
# prepare splashscreen setup
########################################################################
# download raspisignage splashimage to /usr/share/pixmaps/splash.png
curl 'https://raw.githubusercontent.com/boschkundendienst/raspisignage/master/documentation_DE/images/raspisignage-boot-splash.png' -o /usr/share/pixmaps/splash.png
cat /etc/default/grub | sed -i "s@^#\(GRUB_BACKGROUND=\)\"\(.*\)\"@\1\"/usr/share/pixmaps/splash.png\"@g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
cat /etc/lightdm/lightdm-gtk-greeter.conf | sed -i "s@^\(background=\)@\1\"/usr/share/pixmaps/splash.png\"@g" /etc/lightdm/lightdm-gtk-greeter.conf
cat /etc/lightdm/lightdm-gtk-greeter.conf | sed -i "s@^#\(background=\)@\1\"/usr/share/pixmaps/splash.png\"@g" /etc/lightdm/lightdm-gtk-greeter.conf

########################################################################
# create .fluxbox folder in home of user alarm and fix permissions
########################################################################
[[ -d /home/alarm/.fluxbox ]] || mkdir -p /home/alarm/.fluxbox/
chown alarm:alarm /home/alarm/.fluxbox
########################################################################
# create fluxbox startup script to autostart browser for our URL
########################################################################
cat >"/home/alarm/.fluxbox/startup" <<EOL
xmodmap "/home/alarm/.Xmodmap"
########################################################################
# disable screensaver and blanking of monitor
########################################################################
xset s off
xset s noblank
xset -dpms

########################################################################
# set url for Browsers
########################################################################
url='https://chemnitzer.linux-tage.de/'
########################################################################

########################################################################
# applications to run with fluxbox add & at the end
########################################################################
########################################################################
# hide mouse cursor on inactivity with unclutter
unclutter &
########################################################################

########################################################################
# set raspisignage wallpaper
########################################################################
/usr/bin/fbsetbg -f /usr/share/pixmaps/splash.png

########################################################################
# switch to HDMI sound
########################################################################
/usr/bin/pactl set-card-profile 0 output:hdmi-stereo
/usr/bin/pactl set-default-sink alsa_output.pci-0000_00_01.1.hdmi-stereo

########################################################################
# PREPARE FOR FIREFOX
########################################################################
# remove links/folders in alarms home dir for firefox
rm -r -f /home/alarm/.mozilla
rm -r -f /home/alarm/.cache/mozilla
# remove mozilla ramdisk folder if exists
rm -r -f /dev/shm/mozilla
# (re)create mozilla folder in ramdisk /dev/shm
mkdir -p /dev/shm/mozilla
# point firefox folders to /dev/shm/mozilla
ln -sfrn /dev/shm/mozilla /home/alarm/.mozilla
ln -sfrn /dev/shm/mozilla /home/alarm/.cache/mozilla

########################################################################
# PREPARE FOR CHROMIUM
########################################################################
# kill all chromium instances
killall chromium
# remove chromium singleton files and folder  if any
rm -r -f /tmp/.org.chromium.Chromium*
# remove links/folders in alarms home dir for chromium
rm -r -f /home/alarm/.config/chromium
rm -r -f /home/alarm/.cache/chromium
# remove chromium ramdisk folder if exists
rm -r -f /dev/shm/chromium
# (re)create chromium folder in ramdisk /dev/shm
mkdir -p /dev/shm/chromium
# point chromium folders to /dev/shm/chromium
ln -sfrn /dev/shm/chromium /home/alarm/.config/chromium
ln -sfrn /dev/shm/chromium /home/alarm/.cache/chromium

########################################################################
# START BROWSER
########################################################################
# Firefox in kiosk mode with url (make sure there is an '&' at the end
# Firefox needs ~150MB more RAM
#/usr/lib/firefox/firefox --kiosk \$url &

# mlbrowser
# look in the build_mlbrowser subfolder of the project
# for a documentation how to compile it yourself.
# /usr/local/bin/mlbrowser -z 1 -platform eglfs \$url

# Chromium in kiosk mode with url (make sure there is an '&' at the end
# --no-xshm makes Chromium work again!
# see https://archlinuxarm.org/forum/viewtopic.php?f=15&t=15001&p=65896&hilit=chromium#p65717
#/usr/bin/chromium --ignore-certificate-errors --disable-features=TranslateUI --disable-features=Translate --disable-breakpad --start-fullscreen --incognito --no-first-run --disable-session-crashed-bubble --temp-profile --disable-infobars --noerrdialogs --noerrors --kiosk --no-xshm --no-shm --disable-gpu \$url &
/usr/bin/chromium --ignore-certificate-errors --disable-features=TranslateUI --disable-features=Translate --disable-breakpad --start-fullscreen --incognito --no-first-run --disable-session-crashed-bubble --temp-profile --disable-infobars --noerrdialogs --noerrors --kiosk \$url &

########################################################################
# finally start all of the above with fluxbox
########################################################################
exec fluxbox
EOL
chown alarm:alarm /home/alarm/.fluxbox/startup


########################################################################
# enable and start lightdm
########################################################################
systemctl enable lightdm
systemctl start lightdm

########################################################################
# point /home/alarm/.mozilla/firefox and /home/alarm/.cache/mozilla
# to ramdisk (/dev/shm)
#
# your Pi should have a minimum of 1GB RAM if you do that!
# could possibly work with 512MB
########################################################################
# /home/alarm/.mozilla/firefox
mkdir -p /home/alarm/.mozilla
chown alarm:alarm /home/alarm/.mozilla/
ln -sf /dev/shm /home/alarm/.mozilla/firefox
chown alarm:alarm /home/alarm/.mozilla/firefox
# /home/alarm/.cache/mozilla
mkdir -p /home/alarm/.cache
chown alarm:alarm /home/alarm/.cache
ln -sf /dev/shm /home/alarm/.cache/mozilla

########################################################################
# show pacnew files if any
########################################################################
echo "If any .pacnew files are listed here you have to manually take care!"
find / -xdev -iname "*.pacnew" -exec echo '{}' \;

########################################################################
# reboot info
########################################################################
echo -e "\n\nEven your system may work properly at this point"
echo -e "you should now reboot the machine with the command 'reboot'\n\n"

########################################################################
#  END END END END END END END END END END END END END END END END END #
########################################################################
