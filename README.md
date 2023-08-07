# esta-shoot
Setup steps to boot archlinux into a browser on a Fujitsu S740 Futro Mini PC (Intel)

## Boot from Archlinux installation ISO

Whenever I need this repo for myself and Arch has a new installation ISO I will ceate a subfolder with a working version
for that release.

- create a [USB flash installation medium](https://wiki.archlinux.org/title/USB_flash_installation_medium)
- connect power, a monitor and a keyboard to the machine
- connect a network cable (or optionally none if using WiFi - not recommended) and make sure the network has internet connectivity
- connect the USB media to the machine and boot from it
- choose the `Arch Linux install medium (x86_64, BIOS)` option
- prepare a second machine that can connect to another machine via SSH on the same network

You should now be at a root prompt showing `root@archiso ~ #`.

## connect to the internet

By default DHCP is enabled and if you have connected the machine to an internet capable network with a DHCP server you should be online now. If not, follow the [Network Configuration Guide](https://wiki.archlinux.org/title/Network_configuration).

Verify your connection by executing a ping:

```bash
ping -c 5 ipinfo.io
```

You should see something similar to this:

```
root@archiso ~ # ping -c 5 ipinfo.io
PING ipinfo.io (34.117.59.81) 56(84) bytes of data.
64 bytes from 81.59.117.34.bc.googleusercontent.com (34.117.59.81): icmp_seq=1 ttl=114 time=8.50 ms
64 bytes from 81.59.117.34.bc.googleusercontent.com (34.117.59.81): icmp_seq=2 ttl=114 time=7.94 ms
64 bytes from 81.59.117.34.bc.googleusercontent.com (34.117.59.81): icmp_seq=3 ttl=114 time=8.60 ms
64 bytes from 81.59.117.34.bc.googleusercontent.com (34.117.59.81): icmp_seq=4 ttl=114 time=8.68 ms
64 bytes from 81.59.117.34.bc.googleusercontent.com (34.117.59.81): icmp_seq=5 ttl=114 time=8.95 ms

--- ipinfo.io ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4006ms
rtt min/avg/max/mdev = 7.937/8.534/8.945/0.332 ms
```
## change keyboard layout in installer

```bash
root@archiso ~ # loadkeys de-latin1
```

## set root password in installer

After booting from the installation media an SSH server is already running but remote logins are not possible as long as the user `root` has no password set.
Set the password for the root user by executing `passwd`.

```bash
root@archiso ~ # passwd
New password: <password>
Retype new password: <password>
passwd: password updated successfully
```

## get the current IP address

Now let's get the current IP of the machine using the `ip addr` command.

```bash
root@archiso ~ # ip addr
```

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:d5:bc:58 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 metric 100 brd 10.0.2.255 scope global dynamic enp0s3
       valid_lft 85575sec preferred_lft 85575sec
    inet6 fe80::a00:27ff:fed5:bc58/64 scope link proto kernel_ll
       valid_lft forever preferred_lft forever
```

In the example above the IP address is `10.0.2.15`.

## SSH into the machine

You could continue directly in the terminal but it is very convenient to be able to copy/paste so we will now logon using SSH. Make sure you replace `10.0.2.15` with the IP address you determined.

```bash
pcfreak@DESKTOP:~$ ssh root@10.0.2.15
```

```
To install Arch Linux follow the installation guide:
https://wiki.archlinux.org/title/Installation_guide

For Wi-Fi, authenticate to the wireless network using the iwctl utility.
For mobile broadband (WWAN) modems, connect with the mmcli utility.
Ethernet, WLAN and WWAN interfaces using DHCP should work automatically.

After connecting to the internet, the installation guide can be accessed
via the convenience script Installation_guide.


Last login: Wed Jul 26 11:31:40 2023 from 10.0.2.2
root@archiso ~ #
```

**Now on SSH we can easily copy/paste and download scripts/configurations from this repo!**

## manual installation

You can now run `archinstall` and do a guided installation. If doing so I would recommend you store your configuration files

```
user_configuration.json
user_credentials.json
```

for later use.

## semi-automated installation (my choice)

**the preferred way!**

For semi-automated installation you can clone [this](https://github.com/boschkundendienst/esta-shoot/) git repository which contains `user_configuration.json`, `user_credentials.json`, and `user_disk_layout.json`.

```bash
root@archiso ~ # pacman -Sy git --noconfirm
root@archiso ~ # git clone https://github.com/boschkundendienst/esta-shoot.git
root@archiso ~ # cd esta-shoot
root@archiso ~/esta-shoot (git)-[main] #
```

Then take a quick look at the 3 files:

Optionally change parameters like `sys-encoding`, `sys-language`, `audio`, bootloader`, `grub-install`, `hostname` and `keyboard-layout` in `user_configuration.json`

Optionally change the partitioning scheme also within that file..

Optionally change the user account creationg (including password) in `user_credentials.json`. (Default `adminuser/esta`)

And finally run the installer in silent/unattended mode:

```bash
root@archiso ~/esta-shoot (git)-[main] # archinstall --config 2023.08.01/user_configuration.json --creds 2023.08.01/user_credentials.json --silent --debug
```

After a lot of output, the installer should end with:

```
Testing connectivity to the Arch Linux mirrors ...
 ! Formatting [BlockDevice(/dev/sda, size=8.0GB, free_space=3145kB+3146kB, bus_type=sata)] in 5....4....3....2....1....
Creating a new partition label on /dev/sda
...
...
Updating /mnt/archinstall/etc/fstab
Installation completed without any errors. You may now reboot.
```

And voila, Arch Linux is installed. Remove the USB-drive and enter the command `reboot` to boot into your new, minimal Arch Linux installation.

## setup boot into browser

Within your new Arch installation enter the following commands:

```
[adminuser@shootbox ~]$ sudo -i
[root@shootbox ~]# pacman -S openssh git
[root@shootbox ~]# systemctl enable --now sshd
```

Now SSH into the new installation and do a:

```
[adminuser@shootbox ~]$ sudo -i
[root@shootbox ~]# git clone https://github.com/boschkundendienst/esta-shoot 
[root@shootbox ~]# chmod +x 2023.08.01/install.bash 
[root@shootbox ~]# ./2023.08.01/install.bash 
```

The script should end with the following lines:


```
Even your system may work properly at this point
you should now reboot the machine with the command 'reboot'
```

So let's reboot and see the magic happen (if not already happened)!

```bash
[root@shootbox ~]# reboot
```
