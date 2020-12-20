#!/usr/bin/env bash
#############################################
manager_main() {
	set_terminal_color
	case "$1" in
	i* | -i* | -I*)
		debian-i
		exit 0
		;;
	h* | -h* | --h*)
		cat <<-'EOF'
			-m      --更换为tuna镜像源(仅debian,ubuntu,kali,alpine和arch)
			-n      --启动novnc
			-v      --启动VNC
			-s      --停止vnc
			-x      --启动xsdl
			-h      --获取帮助信息
		EOF
		;;
	-m* | m* | -tuna*)
		gnu_linux_sources_list
		;;
	-novnc | novnc* | -n*)
		start_web_novnc
		;;
	-v | -vnc)
		startvnc
		;;
	-s | -stop*)
		stopvnc
		;;
	-x | -xsdl)
		startxsdl
		;;
	*)
		auto_check
		check_tmoe_menu_locale_file
		tmoe_manager_main_menu
		;;
	esac
}
check_tmoe_command() {
	if [ $(command -v zsh) ]; then
		if egrep -q '^[^#]*alias t=tmoe' ~/.zshrc 2>/dev//null; then
			TMOE_TIPS_01="t"
		else
			TMOE_TIPS_01="tmoe"
		fi
	else
		TMOE_TIPS_01="tmoe"
	fi
	TMOE_TIPS_00="Welcome to tmoe linux manager v1.3660,type ${TMOE_TIPS_01} to start it."
}
#########################
tmoe_manager_env() {
	check_release_version
	check_tmoe_command
	CONFIG_FOLDER="${HOME}/.config/tmoe-linux"
	TMOE_LOCALE_FILE=${CONFIG_FOLDER}/locale.txt
	TMOE_GIT_DIR="${TMOE_LINUX_DIR}/git"
	TMOE_CONTAINER_DIR="${TMOE_LINUX_DIR}/containers"
	TMOE_TOOL_DIR="${TMOE_GIT_DIR}/tools"
	TMOE_SHARE_DIR="${TMOE_GIT_DIR}/share"
	TMOE_GIT_URL="gitee.com/mo2/linux"
	AK2_GIT_URL="https://gitee.com/ak2"
	TMOE_LINUX_ISSUE_URL="https://${TMOE_GIT_URL}/issues"
	if [[ -e ${TMOE_GIT_DIR}/.git ]]; then
		source ${TMOE_SHARE_DIR}/environment/manager_environment
		#check_dependencies_03
	fi
	DEBIAN_CHROOT=${TMOE_CONTAINER_DIR}/chroot/${DEBIAN_FOLDER}
}
#############
tmoe_manager_android_env() {
	if [ ! -h "${HOME}/storage/shared" ]; then
		if [ $(command -v termux-setup-storage) ]; then
			termux-setup-storage
		else
			TERMUX_STORAGE='false'
		fi
	fi
	[[ -z ${TMPDIR} ]] || export TMPDIR=${PREFIX}/tmp
	TMOE_INSTALLATION_COMMAND='apt install -y'
	TMOE_REMOVAL_COMMAND='apt purge -y'
	SWITCH_MIRROR='true'
	TMOE_LINUX_DIR="${HOME}/.local/share/tmoe-linux"
	ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null | cut -d '.' -f 1) || ANDROID_VERSION=6
	tmoe_manager_env
}
#######
tmoe_manager_gnu_linux_env() {
	check_current_user_name_and_group
	TMPDIR=/tmp
	TMOE_LINUX_DIR='/usr/local/etc/tmoe-linux'
	tmoe_manager_env
}
######
set_terminal_color() {
	RED=$(printf '\033[31m')
	GREEN=$(printf '\033[32m')
	YELLOW=$(printf '\033[33m')
	BLUE=$(printf '\033[34m')
	BOLD=$(printf '\033[1m')
	PURPLE=$(printf '\033[0;35m')
	RESET=$(printf '\033[m')
}
#######
check_current_user_name_and_group() {
	CURRENT_USER_NAME=$(sed -n p /etc/passwd | grep "${HOME}" | awk -F ':' '{print $1}' | head -n 1)
	CURRENT_USER_GROUP=$(sed -n p /etc/passwd | grep "${HOME}" | awk -F ':' '{print $5}' | cut -d ',' -f 1 | head -n 1)
	if [ -z "${CURRENT_USER_GROUP}" ]; then
		CURRENT_USER_GROUP=${CURRENT_USER_NAME}
	fi
}
##############
press_enter_to_return() {
	printf "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}\n"
	printf "按${GREEN}回车键${RESET}${BLUE}返回${RESET}\n"
	read
}
#####################
press_enter_to_continue() {
	printf "Press ${GREEN}enter${RESET} to ${BLUE}continue.${RESET}\n"
	printf "按${GREEN}回车键${RESET}${BLUE}继续${RESET}\n"
	read
}
###################################
auto_check() {
	case "$(uname -o)" in
	Android)
		LINUX_DISTRO='Android'
		TERMUX_STORAGE='true'
		tmoe_manager_android_env
		check_android_termux_whiptail
		;;
	*)
		tmoe_manager_gnu_linux_env
		check_gnu_linux_distro
		;;
	esac
}
################
install_android_whiptail() {
	RETURN_TO_WHERE='exit'
	printf "${YELLOW}%s${RESET} ${PURPLE}%s${RESET}\n" "Do you want to install" "whiptail(dialog)?"
	printf "${GREEN}%s${RESET} ${BLUE}%s${RESET}\n" "apt install -y" "dialog"
	do_you_want_to_continue
	apt update
	apt install -y dialog
	[[ -e ${PREFIX}/bin/whiptail ]] || apt install -y whiptail
}
check_android_termux_whiptail() {
	[[ -e ${PREFIX}/bin/whiptail ]] || install_android_whiptail
}
############
check_gnu_linux_git_and_whiptail() {
	DEPENDENCIES=""
	[[ $(command -v bash) ]] || DEPENDENCIES="${DEPENDENCIES} bash"
	if [ ! $(command -v sudo) ]; then
		case "${LINUX_DISTRO}" in
		gentoo) DEPENDENCIES="${DEPENDENCIES} app-admin/sudo" ;;
		*) DEPENDENCIES="${DEPENDENCIES} sudo" ;;
		esac
	fi
	if [ ! $(command -v whiptail) ]; then
		case "${LINUX_DISTRO}" in
		debian) DEPENDENCIES="${DEPENDENCIES} whiptail" ;;
		arch) DEPENDENCIES="${DEPENDENCIES} libnewt" ;;
		gentoo) DEPENDENCIES="${DEPENDENCIES} dev-libs/newt" ;;
		openwrt) DEPENDENCIES="${DEPENDENCIES} whiptail dialog" ;;
		*) DEPENDENCIES="${DEPENDENCIES} newt" ;;
		esac
	fi
	if [ "$(uname -r | cut -d '-' -f 3)" = "Microsoft" ] || [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
		export PATH="${PATH}:/mnt/c/WINDOWS/system32/:/mnt/c/WINDOWS/system32/WindowsPowerShell/v1.0/"
		#此处必须设定环境变量，因为sudo的环境变量会发生改变。
		#不能使用这条alias：alias sudo='sudo env PATH=$PATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH'
		#printf "%s\n" "检测到您使用的是WSL"
		WSL="[WSL(win10的linux子系统)]"
		WINDOWS_DISTRO='WSL'
	else
		WSL=""
	fi
	tmoe_install_depenencies() {
		${TMOE_UPDATE_COMMAND}
		${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES}
		return 0
	}
	case ${DEPENDENCIES} in
	"") ;;
	*)
		notes_of_tmoe_package_installation
		case "${LINUX_DISTRO}" in
		debian | openwrt | slackware) tmoe_install_depenencies ;;
		alpine)
			if [ "$(uname -v | cut -c 1-3)" = "iSH" ]; then
				printf "${RED}%s${RESET}" "WARNING！不支持APPLE iOS系统"
				press_enter_to_continue
			fi
			if ! egrep -q '^[^#]*http.*community' "/etc/apk/repositories"; then
				sed -i '$ a\http://mirrors.bfsu.edu.cn/alpine/latest-stable/community' "/etc/apk/repositories"
			fi
			tmoe_install_depenencies
			;;
		void)
			export LANG='en_US.UTF-8'
			${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES}
			;;
		arch | gentoo | suse) ${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES} ;;
		redhat)
			if [ $(command -v dnf) ]; then
				${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES}
			else
				yum install -y --skip-broken ${DEPENDENCIES}
			fi
			;;
		*)
			apt update 2>/dev/null
			${TMOE_INSTALLATION_COMMAND} ${DEPENDENCIES}
			apt install -y ${DEPENDENCIES} || port install ${DEPENDENCIES} || guix package -i ${DEPENDENCIES} || pkg install ${DEPENDENCIES} || pkg_add ${DEPENDENCIES} || pkgutil -i ${DEPENDENCIES} || pacman -Syu ${DEPENDENCIES}
			;;
		esac
		;;
	esac
}
#######################
check_gnu_linux_distro() {
	case "$(id -u)" in
	0) ;;
	*)
		export PATH=${PATH}:/usr/sbin:/sbin
		[[ -e ${CONFIG_FOLDER} ]] || mkdir -p ${CONFIG_FOLDER}
		if [ -e "${TMOE_GIT_DIR}/manager.sh" ]; then
			if [ $(command -v fortune) ]; then
				fortune 2>/dev/null
			elif [ -e /usr/games/fortune ]; then
				/usr/games/fortune 2>/dev/null
			fi
			if [ $(command -v sudo) ]; then
				sudo -E bash ${TMOE_GIT_DIR}/manager.sh
			else
				su -c "bash manager.sh"
			fi
		else
			if [ -e "/usr/bin/curl" ]; then
				sudo -E bash -c "$(curl -LfsS https://${TMOE_GIT_URL}/raw/master/debian.sh)" ||
					su -c "$(curl -LfsS https://${TMOE_GIT_URL}/raw/master/debian.sh)"
			else
				sudo -E bash -c "$(wget -qO- https://${TMOE_GIT_URL}/raw/master/debian.sh)" ||
					su -c "$(wget -qO- https://${TMOE_GIT_URL}/raw/master/debian.sh)"
			fi
			#此处一定为debian.sh，而非manager.sh
		fi
		exit 0
		;;
	esac
	##############
	SWITCH_MIRROR='false'
	if egrep -q 'debian|ubuntu|deepin|uos\.com' "/etc/os-release"; then
		SWITCH_MIRROR='true'
		LINUX_DISTRO='debian'
		TMOE_UPDATE_COMMAND='apt update'
		TMOE_INSTALLATION_COMMAND='apt install -y'
		TMOE_REMOVAL_COMMAND='apt purge -y'
		if grep -q 'ubuntu' /etc/os-release; then
			DEBIAN_DISTRO='ubuntu'
		elif [ "$(sed -n p /etc/issue | cut -c 1-4)" = "Kali" ]; then
			DEBIAN_DISTRO='kali'
		elif egrep -q 'deepin|uos' /etc/os-release; then
			SWITCH_MIRROR='false'
			DEBIAN_DISTRO='deepin'
		fi

	elif egrep -qi "Fedora|CentOS|Red Hat|redhat" '/etc/os-release'; then
		LINUX_DISTRO='redhat'
		if [ $(command -v dnf) ]; then
			TMOE_REMOVAL_COMMAND='dnf remove -y'
			TMOE_INSTALLATION_COMMAND='dnf install -y --skip-broken'
		else
			TMOE_REMOVAL_COMMAND='yum remove -y'
			TMOE_INSTALLATION_COMMAND='yum install -y --skip-broken'
		fi
		if [ "$(sed -n p /etc/os-release | grep 'ID=' | head -n 1 | cut -d '"' -f 2)" = "centos" ]; then
			REDHAT_DISTRO='centos'
		elif grep -q 'Sliverblue' "/etc/os-release"; then
			printf "%s\n" "Sorry,不支持Fedora SliverBlue"
		elif grep -q 'Fedora' "/etc/os-release"; then
			REDHAT_DISTRO='fedora'
		fi

	elif grep -q "Alpine" '/etc/issue' || grep -q "Alpine" '/etc/os-release'; then
		SWITCH_MIRROR='true'
		LINUX_DISTRO='alpine'
		TMOE_UPDATE_COMMAND='apk update'
		TMOE_INSTALLATION_COMMAND='apk add'
		TMOE_REMOVAL_COMMAND='apk del'

	elif egrep -q "Arch|Manjaro" '/etc/os-release' || egrep -q "Arch|Manjaro" '/etc/issue'; then
		LINUX_DISTRO='arch'
		TMOE_REMOVAL_COMMAND='pacman -Rsc'
		TMOE_INSTALLATION_COMMAND='pacman -Syu --noconfirm'

	elif egrep -q "gentoo|funtoo" '/etc/os-release'; then
		LINUX_DISTRO='gentoo'
		TMOE_INSTALLATION_COMMAND='emerge -avk'
		TMOE_REMOVAL_COMMAND='emerge -C'

	elif grep -qi 'suse' '/etc/os-release'; then
		LINUX_DISTRO='suse'
		TMOE_INSTALLATION_COMMAND='zypper in -y'
		TMOE_REMOVAL_COMMAND='zypper rm'

	elif [ "$(sed -n p /etc/issue | cut -c 1-4)" = "Void" ]; then
		LINUX_DISTRO='void'
		TMOE_INSTALLATION_COMMAND='xbps-install -Sy'
		TMOE_REMOVAL_COMMAND='xbps-remove -R'

	elif egrep -q "opkg|entware" '/opt/etc/opkg.conf' 2>/dev/null || grep -q 'openwrt' "/etc/os-release"; then
		printf "${RED}%s${RESET}\n" "本工具已不再支持OpenWRT"
		do_you_want_to_continue
		LINUX_DISTRO='openwrt'
		TMOE_INSTALLATION_COMMAND='opkg install'
		TMOE_REMOVAL_COMMAND='opkg remove'
		cd /tmp
		wget --no-check-certificate -qO "router-debian.bash" https://${TMOE_GIT_URL}/raw/master/manager.sh
		chmod +x 'router-debian.bash'
		sed -i 's@/usr/bin@/opt/bin@g;s@-e /bin@-e /opt/bin;@wget --no-check-certificate -qO "router-debian.bash"@#&@;s@bash router-debian.bash@#&@' 'router-debian.bash'
		bash router-debian.bash
	fi
	######################################
	check_gnu_linux_git_and_whiptail
	#############
	CurrentLANG=${LANG}
	if [ ! $(printf '%s\n' "${LANG}" | egrep 'UTF-8|UTF8') ]; then
		export LANG=C.UTF-8
	fi
	########################
	case ${LINUX_DISTRO} in
	openwrt)
		if [ -d "/opt/bin" ]; then
			PREFIX="/opt"
		else
			PREFIX=/usr
		fi
		;;
	*) PREFIX='/usr/local' ;;
	esac
	################
	check_tmoe_menu_locale_file
	############
	curl_tmoe_linux_tool_sh() {
		if [ -e "${TMOE_GIT_DIR}/tool.sh" ]; then
			if [ $(command -v sudo) ]; then
				sudo -E bash ${TMOE_GIT_DIR}/tool.sh
			else
				su -c "bash ${TMOE_GIT_DIR}/tool.sh"
			fi
		else
			if [ ! $(command -v curl) ]; then
				wget -O /tmp/.tmoe-linux-tool.sh "https://${TMOE_GIT_URL}/raw/master/tool.sh"
			else
				curl -Lv -o /tmp/.tmoe-linux-tool.sh "https://${TMOE_GIT_URL}/raw/master/tool.sh"
			fi
			source /tmp/.tmoe-linux-tool.sh
		fi
	}
	##########
	choose_manager_or_tool_zh() {
		if (whiptail --title "您想要对这个小可爱做什么" --yes-button "Tool" --no-button "Manager" --yesno "检测到您使用的是${OSRELEASE} ${WSL}\n您是想要启动software安装工具，\n还是system管理器？\nDo you want to start the software installation tool\nor the system manager? ♪(^∇^*) " 0 50); then
			curl_tmoe_linux_tool_sh
			exit 0
		fi
	}
	choose_manager_or_tool_ja() {
		if (whiptail --title "どちらを選びますか" --yes-button "Tool" --no-button "Manager" --yesno "${OSRELEASE}を使用しています ${WSL}\nツールまたはマネージャーを起動しますか？♪(^∇^*) " 0 50); then
			curl_tmoe_linux_tool_sh
			exit 0
		fi
	}
	choose_manager_or_tool_en() {
		if (whiptail --title "Which do you want to choose?" --yes-button "Tool" --no-button "Manager" --yesno "You are using ${OSRELEASE} ${WSL}\nDo you want to start the software installation tool\nor the system manager? ♪(^∇^*) " 0 50); then
			curl_tmoe_linux_tool_sh
			exit 0
		fi
	}
	###########
	choose_manager_or_tool() {
		case ${TMOE_MENU_LANG} in
		zh_*UTF-8) choose_manager_or_tool_zh ;;
		ja_JP.UTF-8) choose_manager_or_tool_ja ;;
		*) choose_manager_or_tool_en ;;
		esac
	}
	if [ ! -z "${LINUX_DISTRO}" ]; then
		if grep -q 'PRETTY_NAME=' /etc/os-release; then
			OSRELEASE="$(sed -n p /etc/os-release | grep 'PRETTY_NAME=' | head -n 1 | cut -d '=' -f 2)"
		else
			OSRELEASE="$(sed -n p /etc/os-release | grep -v 'VERSION' | grep 'ID=' | head -n 1 | cut -d '=' -f 2)"
		fi
		choose_manager_or_tool
	fi
}
########################################
notes_of_tmoe_package_installation() {
	printf "正在${YELLOW}安装${RESET}相关${GREEN}软件包${RESET}及其${BLUE}依赖...${RESET}\n"
	printf "${GREEN}${TMOE_INSTALLATION_COMMAND}${BLUE}${DEPENDENCIES}${RESET}\n"
	printf "如需${BOLD}${RED}卸载${RESET}${RESET}，请${YELLOW}手动${RESET}输${RED}${TMOE_REMOVAL_COMMAND}${RESET}${BLUE}${DEPENDENCIES}${RESET}\n"
}
#####################
check_release_version() {
	CHROOT_NOTE=''
	case "${LINUX_DISTRO}" in
	"Android")
		OSRELEASE="Android"
		CHROOT_NOTE='(已向Android开放)'
		;;
	*)
		if grep -q 'NAME=' /etc/os-release; then
			OSRELEASE=$(sed -n p /etc/os-release | grep -v 'PRETTY' | grep 'NAME=' | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
		elif grep -q 'ID=' /etc/os-release; then
			OSRELEASE=$(sed -n p /etc/os-release | grep -v 'VERSION' | grep 'ID=' | head -n 1 | cut -d '=' -f 2)
		else
			OSRELEASE='GNU/Linux'
		fi
		;;
	esac
}
##################
choose_tmoe_locale_env() {
	SET_TMOE_LOCALE='true'
	CONTAINER_LOCALE=$(whiptail --title "LOCALE SETTING" \
		--menu "Please choose your \$LANG\n言語を選択してください" 0 0 0 \
		"1" "Chinese traditional 中文(繁體)" \
		"2" "${LANG}" \
		"3" "Chinese simplified 中文(简体)" \
		"4" "English" \
		"5" "nihongo/Japanese 日本語" \
		"6" "Deutsche" \
		"7" "français" \
		"8" "other" \
		3>&1 1>&2 2>&3)
	##########################
	case "${CONTAINER_LOCALE}" in
	1) TMOE_LANG="zh_TW.UTF-8" ;;
	2) TMOE_LANG="${LANG}" ;;
	3) TMOE_LANG="$(printf '%s\n' emhfQ04uVVRGLTgK | base64 -d)" ;;
	4) TMOE_LANG="en_US.UTF-8" ;;
	5) TMOE_LANG="ja_JP.UTF-8" ;;
	6) TMOE_LANG="de_DE.UTF-8" ;;
	7) TMOE_LANG="fr_FR.UTF-8" ;;
	8)
		TMOE_LOCALE_URL="https://${TMOE_GIT_URL}/raw/master/share/environment/locale"
		source_locale_setting
		;;
	esac
	##############
	case ${TMOE_LANG} in
	"") ;;
	*)
		mkdir -p ${CONFIG_FOLDER} "${TMOE_LINUX_DIR}"
		printf "%s\n" "${TMOE_LANG}" >${TMOE_LOCALE_FILE}
		chmod 666 "${TMOE_LINUX_DIR}/locale.txt" 2>/dev/null
		printf "%s\n" "${TMOE_LANG}" >"${TMOE_LINUX_DIR}/locale.txt"
		case ${LINUX_DISTRO} in
		Android) ;;
		*) sudo cp -fv ${TMOE_LOCALE_FILE} "${TMOE_LINUX_DIR}/locale.txt" ;;
		esac
		;;
	esac
}
###############
source_locale_setting() {
	TMOE_LOCALE_TMP_FILE=${TMPDIR}/.tmoe-locale
	[[ ! -e ${TMOE_LOCALE_TMP_FILE} ]] || rm ${TMOE_LOCALE_TMP_FILE}
	if [ $(command -v curl) ]; then
		curl -Lo ${TMOE_LOCALE_TMP_FILE} "${TMOE_LOCALE_URL}"
	elif [ $(command -v wget) ]; then
		wget -O ${TMOE_LOCALE_TMP_FILE} "${TMOE_LOCALE_URL}"
	fi
	source "${TMOE_LOCALE_TMP_FILE}"
}
##########
check_tmoe_menu_locale_file() {
	[[ -s ${TMOE_LOCALE_FILE} ]] || choose_tmoe_locale_env
	TMOE_LANG=$(head -n 1 ${TMOE_LOCALE_FILE})
	TMOE_MENU_LANG=${TMOE_LANG}
}
#################
install_dependencies_02() {
	unset DEPENDENCIES
	case ${LINUX_DISTRO} in
	Android) TMOE_LOCALE_URL="https://${TMOE_GIT_URL}/raw/master/share/termux/termux" ;;
	*) TMOE_LOCALE_URL="https://${TMOE_GIT_URL}/raw/master/share/environment/dependencies" ;;
	esac
	source_locale_setting
	git_clone_tmoe_manager
}
##############
check_dependencies_03() {
	unset DEPENDENCIES
	case ${LINUX_DISTRO} in
	Android) source ${TMOE_SHARE_DIR}/termux/termux ;;
	*) source ${TMOE_SHARE_DIR}/environment/dependencies ;;
	esac
}
##############
choose_your_mirror() {
	case ${SWITCH_MIRROR} in
	true)
		printf "%s\n" "您尚未安装相关依赖"
		case ${LINUX_DISTRO} in
		Android) install_dependencies_02 ;;
		*)
			case ${SWITCH_MIRROR} in
			true)
				if [ -s "${TMOE_TOOL_DIR}/sources/mirror.sh" ]; then
					source "${TMOE_TOOL_DIR}/sources/mirror.sh"
				else
					TMOE_LOCALE_URL="https://${TMOE_GIT_URL}/raw/master/tools/sources/mirror.sh"
					source_locale_setting
				fi
				;;
			*) install_dependencies_02 ;;
			esac
			;;
		esac
		;;
	*) install_dependencies_02 ;;
	esac
}
check_tmoe_manager_git() {
	RETURN_TO_WHERE='exit'
	printf "%s\n" "Do you want to ${GREEN}git clone${RESET} this repo to ${BLUE}${TMOE_GIT_DIR}${RESET}?"
	printf "%s\n" "您需要克隆本項目倉庫方能繼續使用"
	do_you_want_to_continue
	rm -rv ${TMOE_GIT_DIR} 2>/dev/null
	RETURN_TO_MENU=install_dependencies_02
	case ${TMOE_LANG} in
	zh_*UTF-8)
		if [[ ! $(command -v git) ]]; then
			choose_your_mirror
		else
			${RETURN_TO_MENU}
		fi
		;;
	*) ${RETURN_TO_MENU} ;;
	esac
}
git_clone_tmoe_manager() {
	[[ -e ${TMOE_LINUX_DIR} ]] || mkdir -p ${TMOE_LINUX_DIR}
	git clone --depth=1 https://${TMOE_GIT_URL} ${TMOE_GIT_DIR}
	source ${TMOE_SHARE_DIR}/environment/manager_environment
	tmoe_manager_main_menu
}
choose_termux_color_scheme() {
	mkdir -p ${HOME}/.termux
	cd ${HOME}/.termux
	#[[ ! -s colors.properties ]] || cp -fv colors.properties $(pwd)/colors.properties.bak

	if [[ ! -s colors.properties ]]; then
		if (whiptail --title "colors.properties" --yes-button "neon" --no-button "monokai" --yesno "Your colors.properties is empty,please choose color scheme of termux.\n请选择终端配色。" 9 50); then
			aria2c --no-conf -d "${HOME}/.termux" --allow-overwrite=true -o "colors.properties" 'https://gitee.com/mo2/zsh/raw/master/share/colors/neon'
		else
			aria2c --no-conf -d "${HOME}/.termux" --allow-overwrite=true -o "colors.properties" 'https://gitee.com/mo2/zsh/raw/master/share/colors/monokai.dark'
		fi
	fi

	if [ ! -s "${HOME}/.termux/font.ttf" ]; then
		if (whiptail --title "FONT" --yes-button "MesloLGS-NF-Bold(粗)" --no-button "Iosevka(细)" --yesno "Your font file does not exist,please choose termux font.\n请选择终端字体。" 9 50); then
			aria2c --no-conf -d "${HOME}/.termux" --allow-overwrite=true -o "font.tar.xz" 'https://gitee.com/ak2/iosevka_and_meslo-lgs-nf/raw/main/meslo-lgs-nf.tar.xz'
		else
			aria2c --no-conf -d "${HOME}/.termux" --allow-overwrite=true -o "font.tar.xz" 'https://gitee.com/ak2/iosevka_and_meslo-lgs-nf/raw/main/iosevka.tar.xz'
		fi
		tar -Jxvf font.tar.xz
	fi
	printf "%s\n" "set-default-termux-color-scheme-and-font" >${CONFIG_FOLDER}/v1.1beta
	if [ ! -s "termux.properties" ]; then
		if (whiptail --title "termux.properties" --yes-button "yes" --no-button "no" --yesno "Your termux.properties is empty,do you want to creat it? It will modify the keyboard layout.\n是否需要创建termux.properties？这将会修改小键盘布局。" 10 50); then
			aria2c --no-conf --allow-overwrite=true -o "termux.properties" 'https://gitee.com/mo2/zsh/raw/master/share/termux.properties'
		fi
	fi
	termux-reload-settings
}
###########
tmoe_manager_main_menu() {
	RETURN_TO_WHERE='tmoe_manager_main_menu'
	RETURN_TO_MENU="${RETURN_TO_WHERE}"
	tmoe_manager_main_menu_ja() {
		TMOE_MANAGER_MAIN_OPTION=$(
			whiptail --title "Tmoe manager running on ${OSRELEASE}" \
				--backtitle "Type tmoe m to start the manager" \
				--menu "${TMOE_TIPS_00}\nエンターキーと矢印キーを使用して操作してください" 0 50 0 \
				"1" "🍀 proot コンテナ(๑•̀ㅂ•́)و✧" \
				"2" "🌸 chroot コンテナ" \
				"3" "💔 削除する 天萌マネージャー" \
				"4" "🌏 ロケール locale/\$LANG" \
				"5" "📱 アンドロイド-termux 追加オプション" \
				"6" "🌈 設定 zsh" \
				"7" "🍧 *°▽°*更新" \
				"8" "🍩 よくある質問" \
				"9" "🐞 問題を報告します" \
				"0" "🌚 exit" \
				3>&1 1>&2 2>&3
		)
	}
	tmoe_manager_main_menu_en() {
		TMOE_MANAGER_MAIN_OPTION=$(
			whiptail --title "Tmoe manager running on ${OSRELEASE}" \
				--backtitle "Type tmoe m to start the manager" \
				--menu "${TMOE_TIPS_00}\nPlease use the touch screen or enter + arrow keys to operate." 0 50 0 \
				"1" "🍀 proot container(๑•̀ㅂ•́)و✧" \
				"2" "🌸 chroot container" \
				"3" "💔 remove tmoe-manager" \
				"4" "🌏 locale/\$LANG" \
				"5" "📱 Android-termux extra options" \
				"6" "🌈 Configure zsh" \
				"7" "🍧 *°▽°*update" \
				"8" "🍩 FAQ" \
				"9" "🐞 Report a problem" \
				"0" "🌚 exit" \
				3>&1 1>&2 2>&3
		)
	}
	tmoe_manager_main_menu_zh() {
		TMOE_MANAGER_MAIN_OPTION=$(
			whiptail --title "Tmoe manager running on ${OSRELEASE}" \
				--backtitle "Type tmoe m to start the manager" \
				--menu "${TMOE_TIPS_00}\n请使用触摸屏或方向键+回车键进行操作" 0 50 0 \
				"1" "🍀 proot容器(๑•̀ㅂ•́)و✧" \
				"2" "🌸 chroot容器${CHROOT_NOTE}" \
				"3" "💔 remove 移除" \
				"4" "🌏 区域 locale/\$LANG" \
				"5" "📱 Android-termux额外选项" \
				"6" "🌈 Configure zsh美化终端" \
				"7" "🍧 *°▽°*update更新" \
				"8" "🍩 FAQ常见问题" \
				"9" "🐞 Report a problem(反馈问题/bug)" \
				"0" "🌚 exit 退出" \
				3>&1 1>&2 2>&3
		)
	}
	case ${TMOE_MENU_LANG} in
	zh_*UTF-8) tmoe_manager_main_menu_zh ;;
	ja_JP.UTF-8) tmoe_manager_main_menu_ja ;;
	*) tmoe_manager_main_menu_en ;;
	esac
	[[ -e ${TMOE_GIT_DIR}/.git ]] || check_tmoe_manager_git
	check_dependencies_03
	##########################
	case "${TMOE_MANAGER_MAIN_OPTION}" in
	0 | "") exit 0 ;;
	1) install_proot_container ;;
	2) install_chroot_container ;;
	3) tmoe_linux_remove_function ;;
	4) tmoe_locale_settings ;;
	5) android_termux_tmoe_area ;;
	6) start_tmoe_zsh_manager ;;
	7) update_tmoe_linux_manager ;;
	8) frequently_asked_questions ;;
	9) report_tmoe_linux_problem ;;
	esac
}
#"10" "🍒 赋予proot容器真实root权限" \
#10) enable_root_mode ;;
##########################
check_termux_color_scheme_file() {
	case ${LINUX_DISTRO} in
	Android) [[ -s ${CONFIG_FOLDER}/v1.1beta ]] || choose_termux_color_scheme ;;
	esac
	source ${TMOE_SHARE_DIR}/configuration/menu
	[[ -e ${CONFIG_FOLDER}/default-dns.conf ]] || tmoe_container_dns
	[[ -e ${CONFIG_FOLDER}/hitokoto.conf ]] || do_you_want_to_enable_hitokoto
}
###################
install_proot_container() {
	RETURN_TO_MENU="install_proot_container"
	check_termux_color_scheme_file
	TMOE_CHROOT='false'
	check_tmoe_container_chroot
	source ${TMOE_SHARE_DIR}/container/common
}
install_chroot_container() {
	RETURN_TO_MENU="install_chroot_container"
	check_termux_color_scheme_file
	source ${TMOE_SHARE_DIR}/container/chroot/notes
	check_root_permissions
	[[ -e "${CONFIG_FOLDER}/chroot-prompt" ]] || notes_of_chroot
	TMOE_CHROOT="true"
	check_tmoe_container_chroot
	source ${TMOE_SHARE_DIR}/container/common
}
tmoe_locale_settings() {
	source ${TMOE_SHARE_DIR}/environment/locale
}
android_termux_tmoe_area() {
	source ${TMOE_SHARE_DIR}/termux/menu
}
normally_start_zsh() {
	if [ $(command -v zsh-i) ]; then
		zsh-i
	elif [ -e "${TMOE_ZSH_SCRIPT}" ]; then
		bash ${TMOE_ZSH_SCRIPT}
	else
		bash -c "$(curl -LfsS ${ZSH_TOOL_URL})"
	fi
}
start_zsh_tool_as_current_user() {
	if [ $(command -v zsh-i) ]; then
		su - ${CURRENT_USER_NAME} -c zsh-i
	elif [ -e "${TMOE_ZSH_SCRIPT}" ]; then
		su - ${CURRENT_USER_NAME} -c "bash ${TMOE_ZSH_SCRIPT}"
	else
		curl -Lo /tmp/.zsh-i.sh ${ZSH_TOOL_URL}
		su - ${CURRENT_USER_NAME} -c "bash /tmp/.zsh-i.sh"
	fi
}
start_tmoe_zsh_manager() {
	TMOE_ZSH_SCRIPT="${HOME}/.config/tmoe-zsh/git/zsh.sh"
	ZSH_TOOL_URL="https://gitee.com/mo2/zsh/raw/master/zsh.sh"
	case $(id -u) in
	0) normally_start_zsh ;;
	*)
		case ${LINUX_DISTRO} in
		Android) normally_start_zsh ;;
		*) start_zsh_tool_as_current_user ;;
		esac
		;;
	esac
}
update_tmoe_linux_manager() {
	source ${TMOE_SHARE_DIR}/termux/update
}
frequently_asked_questions() {
	source ${TMOE_SHARE_DIR}/frequently_asked_questions/faq
}
tmoe_linux_remove_function() {
	source ${TMOE_SHARE_DIR}/removal/menu
}
report_tmoe_linux_problem() {
	printf "${BLUE}%s\n${RESET}" "${TMOE_LINUX_ISSUE_URL}"
	case ${LINUX_DISTRO} in
	Android) am start -a android.intent.action.VIEW -d "${TMOE_LINUX_ISSUE_URL}" ;;
	*) su "${CURRENT_USER_NAME}" -c "xdg-open ${TMOE_LINUX_ISSUE_URL}" ;;
	esac
	press_enter_to_return
	tmoe_manager_main_menu
}
##################
if_return_to_where_no_empty() {
	case ${RETURN_TO_WHERE} in
	"") tmoe_manager_main_menu ;;
	*) ${RETURN_TO_WHERE} ;;
	esac
}
do_you_want_to_continue() {
	printf "%s\n" "${YELLOW}Do you want to continue?[Y/n]${RESET}"
	printf "%s\n" "Press ${GREEN}enter${RESET} to ${BLUE}continue${RESET},type ${YELLOW}n${RESET} to ${BLUE}return.${RESET}"
	printf "%s\n" "按${GREEN}回车键${RESET}${BLUE}继续${RESET}，输${YELLOW}n${RESET}${BLUE}返回${RESET}"
	read opt
	case $opt in
	y* | Y* | "") ;;
	n* | N*)
		printf "%s\n" "skipped."
		if_return_to_where_no_empty
		;;
	*)
		printf "%s\n" "Invalid choice. skipped."
		if_return_to_where_no_empty
		;;
	esac
}
#######################
manager_main "$@"
