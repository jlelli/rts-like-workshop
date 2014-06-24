Xubuntu Live (SCHED_DEADLINE remix)
=========

This document explains how you can

  - Install a Xubuntu Live system (modified to use SCHED_DEADLINE) on a USB key
  - Setup a basic workspace where experimenting with SCHED_DEADLINE

Download and Install the live system
-----------

You can download the live image from [here].

If you are working in a terminal instead get it with

```sh
wget http://retis.sssup.it/~jlelli/xubuntu-live/xubuntu-14.04-dl-rc1.iso
```

It is recommended to use a USB flash drive of at least 8GB to host both the
live system and the workspace. However, different configuration may work as
well (e.g., small USB key to host just the live system and HD partition for the
workspace).

Two partitions has to be created in the flash drive. First one (2GB) will host
the live system, second one the workspace. You should end up with a situation
like this:

```sh
fdisk -l /dev/sdd

Disk /dev/sdd: 16.0 GB, 16043212800 bytes
45 heads, 34 sectors/track, 20480 cylinders, total 31334400 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x0008f1bf

   Device Boot      Start         End      Blocks   Id  System
/dev/sdd1   *        2048     6332415     3165184    c  W95 FAT32 (LBA)
/dev/sdd2         6332416    31334399    12500992   83  Linux
```

The live system can be now installed on first partition with automated tools,
like usb-creator-gtk, or [other means]. You can also use the [mk_live_usb.sh]
script (!!!AT YOUR OWN RISK!!!), doing something like this:

```sh
sudo ./mk_live_usb.sh -d /dev/sdd -e -f -i ./xubuntu-14.04-dl.iso -I
```

Once installation has finished, shutdown the system and boot from the USB key.

Configure the workspace
-----------------------

Once you booted into the live system you have to mount and setup the workspace.
If you partitioned your USB key as above, open a terminal and do:

```sh
sudo ./setup_env.sh
cd /media/workshop
```

This will mount the second partition at /media/workshop and cd into it.

A bootstrap environment is provided in a github repo. You can clone it, cd into
it and start the bootstrapping. This last step will require some amount of
time, depending on your network and CPU speed. In my case, very fast network
and an Intel i7 quad-core machine, it took about 15 minutes.

```sh
git clone https://github.com/jlelli/rts-like-workshop.git
cd rts-like-workshop
#setup configuration parameters
vim config_params.sh
#get sources, configure and compile them
./setup_workspace.sh -dcC
```

You are now ready to follow the hands-on sessions. Yay!!!

Debian-based virtual machine
----------------------------

TODO: add info on ready to be used virtual machine for debugging


[here]:http://retis.sssup.it/~jlelli/xubuntu-live/xubuntu-14.04-dl-rc1.iso
[other means]:https://help.ubuntu.com/community/Installation/FromUSBStick
[mk_live_usb.sh]:http://retis.sssup.it/~jlelli/xubuntu-live/mk_live_usb.sh
