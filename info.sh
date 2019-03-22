# arg1 : size, eg 8M, 16G
# arg2 : mountpoint

TMPFS_DONE="False"
TMPFS_SIZE="200M"

# better non-exist dir
TMPFS_MOUNTPOINT="/tmp/scgy_bak/"

# make sure there is a slash at the end of the path
# or curl will return with (550) error
SERVER_PATH=ftp://192.168.0.251/scgy-disks/disk/
UPLOAD_USERNAME=scgy-upload
UPLOAD_PASSWORD=upl-scgy
DOWNLOAD_USERNAME=scgy-upload
DOWNLOAD_PASSWORD=upl-scgy
UPLOAD_MAX_TRIES=5
DOWNLOAD_MAX_TRIES=5

# max fragment size, in bytes (default 100M)
# - make sure it smaller than TMPFS_SIZE.
MAX_FRAGMENT=104857600

make_tmpfs () {
	if [ $TMPFS_DONE == "False" ]; then
		[ -d "$TMPFS_MOUNTPOINT" ] || sudo mkdir "$TMPFS_MOUNTPOINT"
		sudo mount -o size="$TMPFS_SIZE" -t tmpfs none "$TMPFS_MOUNTPOINT";
		TMPFS_DONE="True"
	fi
}

# check for desired device to be recovered
check_pc() {
	CPU_MODEL=`grep "model name" /proc/cpuinfo | head -n1 | awk -F: '{print $2}' - | sed -e 's/^[ \t]*//'`
	MEM_TOTAL=`grep "MemTotal" /proc/meminfo | awk -F: '{print $2}' - | sed -e 's/^[ \t]*//' | awk '{print $1}'`
	VGA_CTRL=`lspci | grep "VGA compatible controller" | awk -F: '{print $3}' | sed -e 's/^[ \t]*//'`
	
	echo "CPU: " "$CPU_MODEL"
	echo "MEM: " "$MEM_TOTAL"
	echo "VGA: " "$VGA_CTRL"

	# Zitan Liu's test environment
	if [ "$CPU_MODEL" == "Intel(R) Core(TM) i5-3210M CPU @ 2.50GHz" ] && [ "$MEM_TOTAL" == "2071984" ] && [ "$VGA_CTRL" == "VMware SVGA II Adapter" ]; then		
		MACHINE_TYPE="LZT-TEST-THINKPAD"
	fi
	
	if [ "$CPU_MODEL" == "Intel(R) Atom(TM) CPU N270   @ 1.60GHz" ]; then
		MACHINE_TYPE="LZT-TEST-TONGFANG"
	fi

	# SCGY Computer Room, new machine
	if [ "$CPU_MODEL" == "Intel(R) Core(TM) i7-6700 CPU @ 3.40GHz" ] && [ "$MEM_TOTAL" == "3073288" ] && [ "$VGA_CTRL" == "Advanced Micro Devices, Inc. [AMD/ATI] Oland XT [Radeon HD 8670 / R7 250/350] (rev 87)" ] ; then
		MACHINE_TYPE="SCGY-LENOVO-NEW"
	fi
}

# $1 - remote filename to be downloaded (eg. sda-1.blk)
# $2 - stored path inside TMPFS_MOUNTPOINT
download_via_ftp() {
	DOWNLOAD_RETRY_COUNT=0
	curl "$SERVER_PATH/$1" --user "$DOWNLOAD_USERNAME:$DOWNLOAD_PASSWORD" -o "$TMPFS_MOUNTPOINT/$2"
	while [ $? -ne 0 ] && [ $DOWNLOAD_RETRY_COUNT -lt $DOWNLOAD_MAX_TRIES ]; do
		echo "Error while uploading. Retry count: $(($UPLOAD_RETRY_COUNT + 1))"
		DOWNLOAD_RETRY_COUNT=$(($DOWNLOAD_RETRY_COUNT + 1))
		sleep 5
		curl "$SERVER_PATH/$1" --user "$DOWNLOAD_USERNAME:$DOWNLOAD_PASSWORD" -o "$TMPFS_MOUNTPOINT/$2"
	done
	if [ $DOWNLOAD_RETRY_COUNT -eq $DOWNLOAD_MAX_TRIES ]; then
		echo "Max retry count exceeded. Abort."
		return 1 # false
	else
		return 0 # true
	fi
}

recover_disk_once() {
	FRAGS=$(($2/$MAX_FRAGMENT))
	REMAINDER=$(( $2 - ($2/$MAX_FRAGMENT) * $MAX_FRAGMENT ))
	[ $REMAINDER -ne 0 ] && FRAGS=$(( $FRAGS + 1 ))
	COUNTER=0
	while [ $COUNTER -lt $FRAGS ]; do
		if ! download_via_ftp "$1_$COUNTER.blk" "$1_$COUNTER.blk"; then
			echo "Error while downloading.. Recover procedure terminated."
			exit
		fi
		# bs=100M for simplicity; trouble if bs has gone too large, since dd uses "bs" bytes of memory
		run_dd "$TMPFS_MOUNTPOINT/$1_$COUNTER.blk" "/dev/$1" $COUNTER 0 1 $MAX_FRAGMENT
		# delete those images
		rm "$TMPFS_MOUNTPOINT"/*.blk
		COUNTER=$(($COUNTER+1))
	done
}

recover_disk() {
	make_tmpfs
	case $MACHINE_TYPE in 
		LZT-TEST-TONGFANG)
			echo "Machine: $MACHINE_TYPE"
			if check_size sda4 2139095040; then
				echo "Size correct."
				recover_disk_once sda4 2139095040
				echo "Operation completed successfully. Congrats! Reboot in 15 seconds."
				sleep 15
				reboot
			else
				echo "Wrong size! Abort."
				exit
			fi
			;;
		*) echo "Unknown machine: $MACHINE_TYPE. Abort." ; exit
			;;
	esac
}

# $1 - disk to be checked (better with sda1/2/3, since sda will return multiple)
# FIX: | head -n1 can fix
# $2 - size in bytes
# 0 if equal, 1 if not
check_size() {
	SIZE_IN_BLK=`cat /proc/partitions | grep "$1" | head -n1 | awk '{ print $3 }'`
	SIZE_IN_BYTE=$((${SIZE_IN_BLK}*1024))
	echo "Disk $1 has $SIZE_IN_BYTE bytes. "
	[ $SIZE_IN_BYTE -eq $2 ] && return 0 || return 1
}

# cat /proc/partitions will return a #block, which is the true value when multiplied by 1024


# $1 - pid to be tested
process_exist() {
	if [ -z `ps -eo pid | grep $1` ]; then
		return 1 # non-exist
	else
		return 0 # exist
	fi
}

#Example: run_dd /dev/zero `pwd`/test.file 0 0 233 1M
#       seek=N skip N obs-sized blocks at start of output
#       skip=N skip N ibs-sized blocks at start of input
run_dd() {
	dd if="$1" of="$2" seek="$3" skip="$4" count="$5" bs="$6" &
	DD_PID=`pidof dd`
	while true; do
		process_exist $DD_PID
		if [ $? -eq 0 ]; then
			kill -USR1 "$DD_PID"
			sleep 1;
		else
			break
		fi
	done
}


# $1 - local file to be stored
upload_via_ftp() {
	UPLOAD_RETRY_COUNT=0
	curl -T "$1" "$SERVER_PATH" --user "$UPLOAD_USERNAME:$UPLOAD_PASSWORD"
	while [ $? -ne 0 ] && [ $UPLOAD_RETRY_COUNT -lt $UPLOAD_MAX_TRIES ]; do
		echo "Error while uploading. Retry count: $(($UPLOAD_RETRY_COUNT + 1))"
		UPLOAD_RETRY_COUNT=$(($UPLOAD_RETRY_COUNT + 1))
		sleep 5
		curl -T "$1" "$SERVER_PATH" --user "$UPLOAD_USERNAME:$UPLOAD_PASSWORD"
	done
	if [ $UPLOAD_RETRY_COUNT -eq $UPLOAD_MAX_TRIES ]; then
		echo "Max retry count exceeded. Abort."
		return 1 # false
	else
		return 0 # true
	fi
}


# $1 - disk to be saved
# $2 - actual bytes of the partition
save_disk_once() {
	FRAGS=$(($2/$MAX_FRAGMENT))
	REMAINDER=$(( $2 - ($2/$MAX_FRAGMENT) * $MAX_FRAGMENT ))
	[ $REMAINDER -ne 0 ] && FRAGS=$(( $FRAGS + 1 ))
	COUNTER=0
	while [ $COUNTER -lt $FRAGS ]; do
		# bs=100M for simplicity; trouble if bs has gone too large, since dd uses "bs" bytes of memory
		run_dd "/dev/$1" "$TMPFS_MOUNTPOINT/$1_$COUNTER.blk" 0 $COUNTER 1 $MAX_FRAGMENT
		if ! upload_via_ftp "$TMPFS_MOUNTPOINT/$1_$COUNTER.blk"; then
			echo "Error while uploading.. Saving procedure terminated."
			exit
		fi
		# delete those images
		rm "$TMPFS_MOUNTPOINT"/*.blk
		COUNTER=$(($COUNTER+1))
	done
}

# save_gpt sd[a-z] partitions
# http://www.techpository.com/linux-copy-gpt-partition-table-with-dd/
save_gpt() {
	echo "Size correct."
	run_dd "/dev/$1" "$TMPFS_MOUNTPOINT/LENOVO_NEW_GPT_TABLE" 0 0 1 $((128*$2+1024))
	if ! upload_via_ftp "$TMPFS_MOUNTPOINT/LENOVO_NEW_GPT_TABLE"; then
		echo "Error while uploading.. Saving procedure terminated."
		exit
	fi
	rm "$TMPFS_MOUNTPOINT/LENOVO_NEW_GPT_TABLE"
}

# large sizes will overflow under the shell
# $1 - disk to be checked (better with sda1/2/3, since sda will return multiple)
# FIX: | head -n1 can fix
# $2 - size in BLK (bytes / 1024)
# 0 if equal, 1 if not
check_size_large() {
	SIZE_IN_BLK=`cat /proc/partitions | grep "$1" | head -n1 | awk '{ print $3 }'`
	echo "Disk $1 has $SIZE_IN_BLK bytes. "
	[ $SIZE_IN_BLK == $2 ] && return 0 || return 1
}

# large sizes will overflow under the shell
# $1 - disk to be saved
# $2 - actual blocks of the partition

MAX_FRAGMENT_LARGE=$(($MAX_FRAGMENT/1024))
save_disk_once_large() {
	FRAGS=$(($2/$MAX_FRAGMENT_LARGE))
	REMAINDER=$(( $2 - ($2/$MAX_FRAGMENT_LARGE) * $MAX_FRAGMENT_LARGE ))
	[ $REMAINDER -ne 0 ] && FRAGS=$(( $FRAGS + 1 ))
	COUNTER=0
	while [ $COUNTER -lt $FRAGS ]; do
		# bs=100M for simplicity; trouble if bs has gone too large, since dd uses "bs" bytes of memory
		run_dd "/dev/$1" "$TMPFS_MOUNTPOINT/$1_$COUNTER.blk" 0 $COUNTER 1 $MAX_FRAGMENT
		if ! upload_via_ftp "$TMPFS_MOUNTPOINT/$1_$COUNTER.blk"; then
			echo "Error while uploading.. Saving procedure terminated."
			exit
		fi
		# delete those images
		rm "$TMPFS_MOUNTPOINT"/*.blk
		COUNTER=$(($COUNTER+1))
	done
}

save_disk() {
	make_tmpfs
	case $MACHINE_TYPE in 
		LZT-TEST-TONGFANG)
			echo "Machine: $MACHINE_TYPE"
			if check_size sda4 2139095040; then
				echo "Size correct."
				save_disk_once sda4 2139095040
				echo "Operation completed successfully. Congrats! Reboot in 15 seconds."
				sleep 15
				reboot
			else
				echo "Wrong size! Abort."
				exit
			fi
			;;
		SCGY-LENOVO-NEW)
			echo "Machine: $MACHINE_TYPE"
			echo "Saving GPT Partition Table..."
			if check_size_large sda 976762584; then
				save_gpt sda 5
				save_disk_once sda1 523239424
				save_disk_once sda2 104857600
				save_disk_once sda3 16777216
				save_disk_once_large sda4 41943040
				echo "Operation completed successfully. Congrats! Reboot in 15 seconds."
				sleep 15
				reboot
			else
				echo "Wrong size! Abort."
				exit
			fi
			;;
		*) echo "Unknown machine: $MACHINE_TYPE. Abort." ; exit
			;;
	esac
}

if [ "$1" == "restore" ]; then
	read -p "Please enter password:" PASS_INPUT
	if [ $PASS_INPUT == "iknowthatalldatawillbelost" ]; then
		check_pc
		recover_disk
	else
		echo "Oops, wrong password."
		echo "Password can be seen on http://ourscgy.ustc.edu.cn/comp_index.html"
		
		echo "Reboot in 15 seconds."
		sleep 15
		reboot
	fi
fi

if [ "$1" == "save" ]; then
	read -p "Please enter password:" PASS_INPUT
	if [ $PASS_INPUT == "xtxsaikou" ]; then
		check_pc
		save_disk
	else
		echo "Oops, wrong password."
		echo "Contact jauntyliu <jauntyliu@mail.ustc.edu.cn> for password."

		echo "Reboot in 15 seconds."
		sleep 15
		reboot
	fi
fi