#!/bin/busybox ash

UNATTENDED=TRUE
DEBUGGING_MODE=TRUE  # "FALSE" if you want all the reboot/dd happens
S_R_PASSWORD=scgyers

RESTORE_BLK_PATH="ftp://scgy-upload:upl-scgy@192.168.0.251/scgy-pxeinfo/"
INFO_FILENAME="info.sh"
RESTORE_TMPFS_SIZE="120M"
RESTORE_DEVICE="/dev/sda"
RESTORE_DEVICE_SIZE=""
