#!/bin/busybox ash

. /etc/init.d/tc-functions
useBusybox
checkroot

# Env. Vars
export PATH="/usr/local/sbin:/usr/local/bin:/apps/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ANSI COLORS
CRE="$(echo -e '\r\033[K')"
RED="$(echo -e '\033[1;31m')"
GREEN="$(echo -e '\033[1;32m')"
YELLOW="$(echo -e '\033[1;33m')"
BLUE="$(echo -e '\033[1;34m')"
MAGENTA="$(echo -e '\033[1;35m')"
CYAN="$(echo -e '\033[1;36m')"
WHITE="$(echo -e '\033[1;37m')"
NORMAL="$(echo -e '\033[0;39m')"

# Configurations
. /opt/scgy_recover_cfg.sh



# waiting for reply in $1 seconds
# with a prompt of $2
# return 0 if (pressed enter) / (type sth and enter)
# return 1 if not
run_with_default() {
	read -t "$1" -p "$2" junk
	if [ $? -eq 0 ]; then
		return 0
	else
		echo ""
		return 1
	fi
}

# arg1 : size, eg 8M, 16G
# arg2 : mountpoint
make_tmpfs () {
	mount -o size="$1" -t tmpfs none "$2"
}

# run saving
save_choice() {
	wget "$RESTORE_BLK_PATH"/"$INFO_FILENAME"
	if [ $? -ne 0 ]; then
		echo "${RED}Error${NORMAL}: failed to fetch info file. "
		on_error
	fi
	. ./"$INFO_FILENAME" "save"
}



on_error() {
	echo "${YELLOW}Will restart in 30 seconds. ${NORMAL}"
	run_with_default 30 "Press Enter to drop into a shell.."
	[ $? -eq 0 ] && exec sh
	do_reboot
}

do_reboot() {
	echo "Will now reboot.."
	if [ ! "$DEBUGGING_MODE" == "TRUE" ]; then
		reboot
	fi
	exit
}

restore_choice() {
	[ -f "$INFO_FILENAME" ] && rm "$INFO_FILENAME"
	wget "$RESTORE_BLK_PATH"/"$INFO_FILENAME"
	if [ $? -ne 0 ]; then
		echo "${RED}Error${NORMAL}: failed to fetch info file. "
		on_error
	fi
	. ./"$INFO_FILENAME" "restore"
	
}

info_choice() {
	cat /proc/cpuinfo | less
	cat /proc/meminfo | less
	lspci | less
}

exit_choice() {
	echo "exit"
}

splash() {
	#http://www.patorjk.com/software/taag/#p=display&f=ANSI%20Shadow&t=SCGY-Tech%0A

	echo "+====================================================================+"
	echo "|${CYAN}███████╗ ██████╗ ██████╗██╗   ██╗  ████████╗███████╗ ██████╗██╗  ██╗${NORMAL}|"
	echo "|${CYAN}██╔════╝██╔════╝██╔════╝╚██╗ ██╔╝  ╚══██╔══╝██╔════╝██╔════╝██║  ██║${NORMAL}|"
	echo "|${CYAN}███████╗██║     ██║  ███╗╚████╔╝█████╗██║   █████╗  ██║     ███████║${NORMAL}|"
	echo "|${CYAN}╚════██║██║     ██║   ██║ ╚██╔╝ ╚════╝██║   ██╔══╝  ██║     ██╔══██║${NORMAL}|"
	echo "|${CYAN}███████║╚██████╗╚██████╔╝  ██║        ██║   ███████╗╚██████╗██║  ██║${NORMAL}|"
	echo "|${CYAN}╚══════╝ ╚═════╝ ╚═════╝   ╚═╝        ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝${NORMAL}|"
	echo "+====================================================================+"
	echo "${YELLOW}Computer maintenance utility for SCGY${NORMAL}"
	echo "${GREEN}Maintenance: SCGY-Tech${NORMAL}"
}

splash

run_with_default 2 "${YELLOW}Experts${NORMAL}: Press Enter to drop into a shell.."
[ $? -eq 0 ] && exec sh

if [ $UNATTENDED == "TRUE" ]; then
	echo "${RED}Notice:${NORMAL} the script is in unattended operation."
	run_with_default 2 "Press Enter to cancel unattended operation.."
	[ $? -eq 0 ] && UNATTENDED=FALSE
fi


while true; do

	MAIN_CHOICE=""

	if [ "$UNATTENDED" == "FALSE" ]; then
		read -p "What to do?[(${YELLOW}R${NORMAL})estore/(${YELLOW}S${NORMAL})ave/(${YELLOW}I${NORMAL})nfo/(${YELLOW}E${NORMAL})xit]:" MAIN_CHOICE
	else
		read -t 2 -p "What to do?[(${YELLOW}R${NORMAL})estore/(${YELLOW}S${NORMAL})ave/(${YELLOW}I${NORMAL})nfo/(${YELLOW}E${NORMAL})xit]:" MAIN_CHOICE
		if [ $? -ne 0 ]; then
			MAIN_CHOICE="R"
			echo "R"
		fi
	fi
	
	# to lower case
	MAIN_CHOICE=`echo "$MAIN_CHOICE" | tr '[:upper:]' '[:lower:]'`

	case $MAIN_CHOICE in
		r) restore_choice $UNATTENDED; break ;;
		restore) restore_choice $UNATTENDED; break ;;
		s) save_choice $UNATTENDED; break ;;
		save) save_choice $UNATTENDED; break ;;
		i) info_choice $UNATTENDED; break ;;
		info) info_choice $UNATTENDED; break ;;
		E) exit_choice $UNATTENDED; break ;;
		exit) exit_choice $UNATTENDED; break ;;
		*) echo "Illegal input $MAIN_CHOICE. Try again.";;
	esac
done
