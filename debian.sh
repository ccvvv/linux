#!/usr/bin/env bash
#############
# set -x
show_package_info() {
	# Architecture: amd64, i386, arm64, armhf, mipsel, riscv64, ppc64el, s390x
	if [ $(uname -o) = Android ]; then EXTRA_DEPS=", debianutils, dialog, termux-api, termux-tools"; fi
	cat <<-EndOfShow
		Package: tmoe-linux-manager
		Version: 1.4678
		Priority: optional
		Section: admin
		Maintainer: 2moe <25324935+2moe@users.noreply.github.com>
		Depends: aria2 (>= 1.30.0), coreutils, curl, findutils, git, grep, lsof (>= 4.89), whiptail (>= 0.52.19), xz-utils (>= 5.2.2), proot (>= 5.1.0), procps (>= 2:3.3.12), sed, tar (>= 1.29b-1.1), util-linux, zstd (>= 1.1.2)${EXTRA_DEPS}
		Recommends: bat, debootstrap, gzip, less, lz4, pulseaudio, pv
		Suggests: lolcat, zsh
		Tag: interface::TODO, interface::text-mode, system::cloud, system::virtual, role::program, works-with::archive, works-with::software:package, works-with::text
		Description: Easily manage containers and system.
	EndOfShow
}
#############
set_env() {
	TMOE_URL="https://gitee.com/mo2/linux/raw/master/manager.sh"
	TMOE_URL_02="https://cdn.jsdelivr.net/gh/2moe/tmoe-linux@master/.mirror/manager"
	TMOE_GIT_DIR="${HOME}/.local/share/tmoe-linux/git"
	TMOE_GIT_DIR_02="/usr/local/etc/tmoe-linux/git"
	if [ -z ${TMPDIR} ]; then
		TMPDIR=/tmp
		mkdir -pv ${TMPDIR}
	fi
	TEMP_FILE=".tmoe-linux.sh"
	unset EXTRA_DEPS MANAGER_FILE
	RED=$(printf '\033[31m')
	GREEN=$(printf '\033[32m')
	YELLOW=$(printf '\033[33m')
	BLUE=$(printf '\033[34m')
	PURPLE=$(printf '\033[35m')
	CYAN=$(printf '\033[36m')
	RESET=$(printf '\033[m')
}
show_info_and_run_the_temp_file() {
	show_package_info
	do_you_want_to_continue
	check_downloader
	download_temp_file
	exec_temp_file
}
do_you_want_to_continue() {
	printf "%s\n" "${YELLOW}Do you want to ${BLUE}continue?${PURPLE}[Y/n]${RESET}"
	printf "%s\n" "Press ${GREEN}enter${RESET} to ${BLUE}continue${RESET}, type ${YELLOW}n${RESET} to ${PURPLE}exit.${RESET}"
	printf "%s\n" "按${GREEN}回车键${RESET}${BLUE}继续${RESET}，输${YELLOW}n${RESET}${PURPLE}退出${RESET}"
	read opt
	case $opt in
	y* | Y* | "") ;;
	n* | N*)
		printf "%s\n" "${PURPLE}skipped${RESET}."
		exit 1
		;;
	*)
		printf "%s\n" "${RED}Invalid ${CYAN}choice${RESET}. skipped."
		exit 1
		;;
	esac
}
check_manager_file() {
	unset MANAGER_FILE
	for i in "${TMOE_GIT_DIR}/manager.sh" "${TMOE_GIT_DIR_02}/manager.sh"; do
		if [ -s "${i}" ]; then
			MANAGER_FILE="${i}"
			break
		fi
	done
	case ${MANAGER_FILE} in
	"") show_info_and_run_the_temp_file ;;
	*) bash "${MANAGER_FILE}" ;;
	esac
}
check_downloader() {
	for i in aria2c curl wget; do
		if [ $(command -v ${i}) ]; then
			DOWNLOADER=${i}
			break
		fi
	done
}
#############
download_temp_file() {
	cd ${TMPDIR}
	case ${DOWNLOADER} in
	aria2c) aria2c --connect-timeout=7 --console-log-level=info --no-conf --allow-overwrite=true -o ${TEMP_FILE} ${TMOE_URL} || aria2c --connect-timeout=20 --console-log-level=debug --no-conf --allow-overwrite=true -o ${TEMP_FILE} ${TMOE_URL_02} ;;
	curl) curl --connect-timeout 7 -Lvo ${TEMP_FILE} ${TMOE_URL} || curl --connect-timeout 20 -Lvo ${TEMP_FILE} ${TMOE_URL_02} ;;
	wget) wget --connect-timeout=7 -O ${TEMP_FILE} ${TMOE_URL} || wget --connect-timeout=20 -O ${TEMP_FILE} ${TMOE_URL_02} ;;
	"")
		printf "%s\n" "${RED}${BOLD}ERROR${RESET}, ${CYAN}please install ${GREEN}curl${RESET} first"
		sleep 2
		exit 127
		;;
	*)
		printf "%s\n" "${RED}${BOLD}ERROR${RESET}"
		sleep 2
		exit 1
		;;
	esac
}
exec_temp_file() {
	if [ $(command -v bash) ] && [ -s .tmoe-linux.sh ]; then
		bash .tmoe-linux.sh
	else
		printf "%s\n" "${RED}${BOLD}ERROR${RESET}, ${CYAN}please install ${GREEN}bash${RESET} first"
		sleep 2
		exit 127
	fi
}
set_env
check_manager_file
