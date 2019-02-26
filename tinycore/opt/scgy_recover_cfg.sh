#!/bin/busybox ash

UNATTENDED=TRUE
DEBUGGING_MODE=TRUE  # "FALSE" if you want all the reboot/dd happens

RESTORE_BLK_PATH="http://192.168.0.1/scgy-backup/disks"
INFO_FILENAME="info.sh"
RESTORE_TMPFS_SIZE="120M"
RESTORE_DEVICE="/dev/sda"
RESTORE_DEVICE_SIZE=""