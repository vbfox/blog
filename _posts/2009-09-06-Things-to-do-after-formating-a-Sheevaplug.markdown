---
layout: post
title: "Things to do after formating a Sheevaplug"
date:  2009-09-06 16:28
tags: Debian, Linux, ShevaPlug, Ubuntu
---
Once a SheevaPlug is formated with sheevaplug-installer the minimum to do is :

### Set the MAC address

Connect to the serial console, enter U-Boot and set the MAC address :

```sh
setevn ethaddr 00:50:43:01:D2:94
saveenv
reset
```

### Set timezone and hostname

Login and type :

```sh
# Set the time-zone
dpkg-reconfigure tzdata
#Set the host name
echo plugfox.vbfox.local > /etc/hostname
/etc/init.d/hostname.sh
```
