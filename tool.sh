#!/bin/bash
########################################################################
main() {
	check_linux_distro
	check_architecture
	case "$1" in
	i | -i)
		tmoe_linux_tool_menu
		;;
	--install-gui | install-gui)
		install_gui
		;;
	--modify_remote_desktop_config)
		modify_remote_desktop_config
		;;
	--remove_gui)
		remove_gui
		;;
	--mirror-list)
		tmoe_sources_list_manager
		;;
	up | -u)
		tmoe_linux_tool_upgrade
		;;
	h | -h | --help)
		frequently_asked_questions
		;;
	file | filebrowser)
		filebrowser_restart
		;;
	tuna | -tuna | t | -t)
		SOURCE_MIRROR_STATION='mirrors.tuna.tsinghua.edu.cn'
		auto_check_distro_and_modify_sources_list
		;;
	*)
		check_root
		;;
	esac
}
################
check_root() {
	if [ "$(id -u)" != "0" ]; then
		if [ $(command -v curl) ]; then
			sudo bash -c "$(curl -LfsS https://gitee.com/mo2/linux/raw/master/debian.sh)" ||
				su -c "$(curl -LfsS https://gitee.com/mo2/linux/raw/master/debian.sh)"
		else
			sudo bash -c "$(wget -qO- https://gitee.com/mo2/linux/raw/master/debian.sh)" ||
				su -c "$(wget -qO- https://gitee.com/mo2/linux/raw/master/debian.sh)"
		fi
		exit 0
	fi
	check_linux_distro
	check_architecture
	check_dependencies
}
#####################
check_architecture() {
	case $(uname -m) in
	aarch64)
		ARCH_TYPE="arm64"
		;;
	armv7l)
		ARCH_TYPE="armhf"
		;;
	armv6l)
		ARCH_TYPE="armel"
		;;
	x86_64)
		ARCH_TYPE="amd64"
		;;
	i*86)
		ARCH_TYPE="i386"
		;;
	x86)
		ARCH_TYPE="i386"
		;;
	s390*)
		ARCH_TYPE="s390x"
		;;
	ppc*)
		ARCH_TYPE="ppc64el"
		;;
	mips*)
		ARCH_TYPE="mipsel"
		;;
	risc*)
		ARCH_TYPE="riscv"
		;;
	esac
}
#####################
check_linux_distro() {
	if grep -Eq 'debian|ubuntu' "/etc/os-release"; then
		LINUX_DISTRO='debian'
		PACKAGES_INSTALL_COMMAND='apt install -y'
		PACKAGES_REMOVE_COMMAND='apt purge -y'
		PACKAGES_UPDATE_COMMAND='apt update'
		if grep -q 'ubuntu' /etc/os-release; then
			DEBIAN_DISTRO='ubuntu'
		elif [ "$(cat /etc/issue | cut -c 1-4)" = "Kali" ]; then
			DEBIAN_DISTRO='kali'
		fi
		###################
	elif grep -Eq "opkg|entware" '/opt/etc/opkg.conf' 2>/dev/null || grep -q 'openwrt' "/etc/os-release"; then
		LINUX_DISTRO='openwrt'
		PACKAGES_UPDATE_COMMAND='opkg update'
		PACKAGES_INSTALL_COMMAND='opkg install'
		PACKAGES_REMOVE_COMMAND='opkg remove'
		##################
	elif grep -Eqi "Fedora|CentOS|Red Hat|redhat" "/etc/os-release"; then
		LINUX_DISTRO='redhat'
		PACKAGES_UPDATE_COMMAND='dnf update'
		PACKAGES_INSTALL_COMMAND='dnf install -y --skip-broken'
		PACKAGES_REMOVE_COMMAND='dnf remove -y'
		if [ "$(cat /etc/os-release | grep 'ID=' | head -n 1 | cut -d '"' -f 2)" = "centos" ]; then
			REDHAT_DISTRO='centos'
		elif grep -q 'Fedora' "/etc/os-release"; then
			REDHAT_DISTRO='fedora'
		fi
		###################
	elif grep -q "Alpine" '/etc/issue' || grep -q "Alpine" "/etc/os-release"; then
		LINUX_DISTRO='alpine'
		PACKAGES_UPDATE_COMMAND='apk update'
		PACKAGES_INSTALL_COMMAND='apk add'
		PACKAGES_REMOVE_COMMAND='apk del'
		######################
	elif grep -Eq "Arch|Manjaro" '/etc/os-release' || grep -Eq "Arch|Manjaro" '/etc/issue'; then
		LINUX_DISTRO='arch'
		PACKAGES_UPDATE_COMMAND='pacman -Syy'
		PACKAGES_INSTALL_COMMAND='pacman -Syu --noconfirm'
		PACKAGES_REMOVE_COMMAND='pacman -Rsc'
		######################
	elif grep -Eq "gentoo|funtoo" "/etc/os-release"; then
		LINUX_DISTRO='gentoo'
		PACKAGES_INSTALL_COMMAND='emerge -vk'
		PACKAGES_REMOVE_COMMAND='emerge -C'
		########################
	elif grep -qi 'suse' '/etc/os-release'; then
		LINUX_DISTRO='suse'
		PACKAGES_INSTALL_COMMAND='zypper in -y'
		PACKAGES_REMOVE_COMMAND='zypper rm'
		########################
	elif [ "$(cat /etc/issue | cut -c 1-4)" = "Void" ]; then
		LINUX_DISTRO='void'
		PACKAGES_INSTALL_COMMAND='xbps-install -S -y'
		PACKAGES_REMOVE_COMMAND='xbps-remove -R'
	fi
	###############
	RED=$(printf '\033[31m')
	GREEN=$(printf '\033[32m')
	YELLOW=$(printf '\033[33m')
	BLUE=$(printf '\033[34m')
	BOLD=$(printf '\033[1m')
	RESET=$(printf '\033[m')
}
#############################
check_dependencies() {
	DEPENDENCIES=""

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ ! -e /usr/bin/aptitude ]; then
			DEPENDENCIES="${DEPENDENCIES} aptitude"
		fi
	fi

	if [ ! $(command -v aria2c) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} net-misc/aria2"
		else
			DEPENDENCIES="${DEPENDENCIES} aria2"
		fi
	fi

	if [ ! -e /bin/bash ]; then
		DEPENDENCIES="${DEPENDENCIES} bash"
	fi

	if [ ! $(command -v busybox) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} sys-apps/busybox"
		elif [ "${LINUX_DISTRO}" = "redhat" ]; then
			if [ "${REDHAT_DISTRO}" = "fedora" ]; then
				DEPENDENCIES="${DEPENDENCIES} busybox"
			fi
		else
			DEPENDENCIES="${DEPENDENCIES} busybox"
		fi
	fi
	#####################
	if [ ! -e /usr/bin/catimg ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			if grep -q 'VERSION_ID' "/etc/os-release"; then
				DEBIANVERSION="$(grep 'VERSION_ID' "/etc/os-release" | cut -d '"' -f 2 | cut -d '.' -f 1)"
			else
				DEBIANVERSION="10"
			fi
			if ((${DEBIANVERSION} <= 9)); then
				echo "检测到您的系统版本低于debian10，跳过安装catimg"
			else
				DEPENDENCIES="${DEPENDENCIES} catimg"
			fi

		elif [ "${REDHAT_DISTRO}" = "fedora" ] || [ "${LINUX_DISTRO}" = "arch" ] || [ "${LINUX_DISTRO}" = "void" ]; then
			DEPENDENCIES="${DEPENDENCIES} catimg"
		fi
	fi

	if [ ! -e /usr/bin/curl ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} net-misc/curl"
		else
			DEPENDENCIES="${DEPENDENCIES} curl"
		fi
	fi
	######################
	if [ ! -e /usr/bin/fc-cache ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} fontconfig"
		fi
	fi
	###################
	#manjaro基础容器里无grep
	if [ ! $(command -v grep) ]; then
		if [ "${LINUX_DISTRO}" != "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} grep"
		fi
	fi
	####################
	if [ ! -e /usr/bin/git ]; then
		if [ "${LINUX_DISTRO}" = "openwrt" ]; then
			DEPENDENCIES="${DEPENDENCIES} git git-http"
		elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} dev-vcs/git"
		else
			DEPENDENCIES="${DEPENDENCIES} git"
		fi
	fi
	####################
	if [ ! -e /usr/bin/mkfontscale ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} xfonts-utils"
		elif [ "${LINUX_DISTRO}" = "arch" ]; then
			DEPENDENCIES="${DEPENDENCIES} xorg-mkfontscale"
		fi
	fi
	#####################
	if [ ! -e /usr/bin/xz ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} xz-utils"
		elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} app-arch/xz-utils"
		else
			DEPENDENCIES="${DEPENDENCIES} xz"
		fi
	fi

	if [ ! -e /usr/bin/pkill ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} sys-process/procps"
		elif [ "${LINUX_DISTRO}" != "openwrt" ]; then
			DEPENDENCIES="${DEPENDENCIES} procps"
		fi
	fi
	#####################
	if [ ! -e /usr/bin/sudo ]; then
		if [ "${LINUX_DISTRO}" != "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} sudo"
		fi
	fi
	###################
	#centos8基础容器里无tar
	if [ ! $(command -v tar) ]; then
		if [ "${LINUX_DISTRO}" != "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} tar"
		fi
	fi
	#####################
	if [ ! -e /usr/bin/whiptail ] && [ ! -e /bin/whiptail ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCIES="${DEPENDENCIES} whiptail"
		elif [ "${LINUX_DISTRO}" = "arch" ]; then
			DEPENDENCIES="${DEPENDENCIES} libnewt"
		elif [ "${LINUX_DISTRO}" = "openwrt" ]; then
			DEPENDENCIES="${DEPENDENCIES} dialog"
		elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} dev-libs/newt"
		else
			DEPENDENCIES="${DEPENDENCIES} newt"
		fi
	fi
	##############
	if [ ! -e /usr/bin/wget ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCIES="${DEPENDENCIES} net-misc/wget"
		else
			DEPENDENCIES="${DEPENDENCIES} wget"
		fi
	fi
	##############

	if [ ! -z "${DEPENDENCIES}" ]; then
		echo "正在安装相关软件包及其依赖..."

		if [ "${LINUX_DISTRO}" = "debian" ]; then
			apt update
			apt install -y ${DEPENDENCIES}
			#创建文件夹防止aptitude报错
			mkdir -p /run/lock /var/lib/aptitude
			touch /var/lib/aptitude/pkgstates

		elif [ "${LINUX_DISTRO}" = "alpine" ]; then
			apk update
			apk add ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "arch" ]; then
			pacman -Syu --noconfirm ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "redhat" ]; then
			dnf install -y --skip-broken ${DEPENDENCIES} || yum install -y --skip-broken ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "openwrt" ]; then
			#opkg update
			opkg install ${DEPENDENCIES} || opkg install whiptail

		elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
			emerge -avk ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "suse" ]; then
			zypper in -y ${DEPENDENCIES}

		elif [ "${LINUX_DISTRO}" = "void" ]; then
			xbps-install -S -y ${DEPENDENCIES}

		else
			apt update
			apt install -y ${DEPENDENCIES} || port install ${DEPENDENCIES} || zypper in ${DEPENDENCIES} || guix package -i ${DEPENDENCIES} || pkg install ${DEPENDENCIES} || pkg_add ${DEPENDENCIES} || pkgutil -i ${DEPENDENCIES}
		fi
	fi
	################
	################
	if [ ! -e /usr/bin/catimg ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			CATIMGlatestVersion="$(curl -LfsS 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/c/catimg/' | grep arm64 | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2 | cut -d '_' -f 2)"
			cd /tmp
			aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'catimg.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/c/catimg/catimg_${CATIMGlatestVersion}_${ARCH_TYPE}.deb"
			apt install -y ./catimg.deb
			rm -f catimg.deb
		fi
	fi

	if [ ! $(command -v busybox) ]; then
		cd /tmp
		wget --no-check-certificate -O "busybox" "https://gitee.com/mo2/busybox/raw/master/busybox-$(uname -m)"
		chmod +x busybox
		LatestBusyboxDEB="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/b/busybox/ | grep static | grep ${ARCH_TYPE} | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'busybox.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/b/busybox/${LatestBusyboxDEB}"
		mkdir -p busybox-static
		./busybox dpkg-deb -X busybox.deb ./busybox-static
		mv -f ./busybox-static/bin/busybox /usr/local/bin/
		chmod +x /usr/local/bin/busybox
		rm -rvf busybox busybox-static busybox.deb
	fi

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			if [ ! -e "/bin/add-apt-repository" ] && [ ! -e "/usr/bin/add-apt-repository" ]; then
				apt install -y software-properties-common
			fi
		fi

		if ! grep -q "^zh_CN" "/etc/locale.gen"; then
			if [ ! -e "/usr/sbin/locale-gen" ]; then
				apt install -y locales
			fi
			sed -i 's/^#.*zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
			locale-gen
			apt install -y language-pack-zh-hans 2>/dev/null
		fi
	fi

	if [ "$(uname -r | cut -d '-' -f 3)" = "Microsoft" ] || [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
		WINDOWSDISTRO='WSL'
	fi
	##############
	cur=$(pwd)
	tmoe_linux_tool_menu
}
####################################################
tmoe_linux_tool_menu() {
	cd ${cur}
	#窗口大小20 50 7
	TMOE_OPTION=$(
		whiptail --title "Tmoe-linux Tool输debian-i启动(20200521-18)" --menu "Type 'debian-i' to start this tool.Please use the enter and arrow keys to operate.请使用方向键和回车键操作,更新日志:0510更新文件选择功能,0511支持配置x11vnc,支持WM,0512增加新图标包，0514支持安装qq音乐,0515支持下载壁纸包,0520支持烧录iso,增加tmoe软件包安装器" 20 50 7 \
			"1" "Install GUI 安装图形界面" \
			"2" "Install browser 安装浏览器" \
			"3" "Download theme 下载主题" \
			"4" "Other software/games 其它软件/游戏" \
			"5" "Modify vnc/xsdl/rdp(远程桌面)conf" \
			"6" "Download video 解析视频链接" \
			"7" "Personal netdisk 个人云网盘/文件共享" \
			"8" "Update tmoe-linux tool 更新本工具" \
			"9" "VSCode 现代化代码编辑器" \
			"10" "Start zsh tool 启动zsh管理工具" \
			"11" "Remove GUI 卸载图形界面" \
			"12" "Remove browser 卸载浏览器" \
			"13" "FAQ 常见问题" \
			"14" "software sources软件镜像源管理" \
			"15" "download iso(Android,linux等)" \
			"16" "Beta Features 测试版功能" \
			"0" "Exit 退出" \
			3>&1 1>&2 2>&3
	)
	########
	case "${TMOE_OPTION}" in
	0 | "") exit 0 ;;
	1) install_gui ;;
	2) install_browser ;;
	3) configure_theme ;;
	4) other_software ;;
	5) modify_remote_desktop_config ;;
	6) download_videos ;;
	7) personal_netdisk ;;
	8) tmoe_linux_tool_upgrade ;;
	9) which_vscode_edition ;;
	10) bash -c "$(curl -LfsS 'https://gitee.com/mo2/zsh/raw/master/zsh.sh')" ;;
	11) remove_gui ;;
	12) remove_browser ;;
	13) frequently_asked_questions ;;
	14) tmoe_sources_list_manager ;;
	15) download_virtual_machine_iso_file ;;
	16) beta_features ;;
	esac
	#########################
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	tmoe_linux_tool_menu
}
############################
############################
arch_does_not_support() {
	echo "${RED}WARNING！${RESET}检测到${YELLOW}架构${RESET}${RED}不支持！${RESET}"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
}
##########################
do_you_want_to_continue() {
	echo "${YELLOW}Do you want to continue?[Y/n]${RESET}"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}continue${RESET},type ${YELLOW}n${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}继续${RESET}，输${YELLOW}n${RESET}${BLUE}返回${RESET}"
	read opt
	case $opt in
	y* | Y* | "") ;;

	n* | N*)
		echo "skipped."
		${RETURN_TO_WHERE}
		;;
	*)
		echo "Invalid choice. skipped."
		${RETURN_TO_WHERE}
		#beta_features
		;;
	esac
}
######################
different_distro_software_install() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		apt update
		apt install -y ${DEPENDENCY_01} || aptitude install ${DEPENDENCY_01}
		apt install -y ${DEPENDENCY_02} || aptitude install ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		apk update
		apk add ${DEPENDENCY_01}
		apk add ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		pacman -Syu --noconfirm ${DEPENDENCY_01} || yay -S ${DEPENDENCY_01} || echo "请以非root身份运行yay"
		pacman -S --noconfirm ${DEPENDENCY_02} || yay -S ${DEPENDENCY_02} || echo "请以非root身份运行yay"
		################
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		dnf install -y --skip-broken ${DEPENDENCY_01} || yum install -y --skip-broken ${DEPENDENCY_01}
		dnf install -y --skip-broken ${DEPENDENCY_02} || yum install -y --skip-broken ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "openwrt" ]; then
		#opkg update
		opkg install ${DEPENDENCY_01}
		opkg install ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		emerge -vk ${DEPENDENCY_01}
		emerge -vk ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		zypper in -y ${DEPENDENCY_01}
		zypper in -y ${DEPENDENCY_02}
		################
	elif [ "${LINUX_DISTRO}" = "void" ]; then
		xbps-install -S -y ${DEPENDENCY_01}
		xbps-install -S -y ${DEPENDENCY_02}
		################
	else
		apt update
		apt install -y ${DEPENDENCY_01} || port install ${DEPENDENCY_01} || guix package -i ${DEPENDENCY_01} || pkg install ${DEPENDENCY_01} || pkg_add ${DEPENDENCY_01} || pkgutil -i ${DEPENDENCY_01}
	fi
}
############################
############################
tmoe_linux_tool_upgrade() {
	if [ "${LINUX_DISTRO}" = "alpine" ]; then
		wget -O /usr/local/bin/debian-i 'https://gitee.com/mo2/linux/raw/master/tool.sh'
	else
		curl -Lv -o /usr/local/bin/debian-i 'https://gitee.com/mo2/linux/raw/master/tool.sh'
	fi
	echo "Update ${YELLOW}completed${RESET}, Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}更新完成，按回车键返回。${RESET}"
	chmod +x /usr/local/bin/debian-i
	read
	#bash /usr/local/bin/debian-i
	source /usr/local/bin/debian-i
}
#####################
#####################
download_videos() {
	VIDEOTOOL=$(
		whiptail --title "DOWNLOAD VIDEOS" --menu "你想要使用哪个工具来下载视频呢" 14 50 6 \
			"1" "Annie" \
			"2" "You-get" \
			"3" "Youtube-dl" \
			"4" "cookie说明" \
			"5" "upgrade更新下载工具" \
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	if [ "${VIDEOTOOL}" == '0' ]; then
		tmoe_linux_tool_menu
	fi
	##############################
	if [ "${VIDEOTOOL}" == '1' ]; then
		golang_annie
		#https://gitee.com/mo2/annie
		#AnnieVersion=$(annie -v | cut -d ':' -f 2 | cut -d ',' -f 1 | awk -F ' ' '$0=$NF')
	fi
	##############################
	if [ "${VIDEOTOOL}" == '2' ]; then
		python_you_get
	fi
	##############################
	if [ "${VIDEOTOOL}" == '3' ]; then
		python_youtube_dl
	fi
	##############################
	if [ "${VIDEOTOOL}" == '4' ]; then
		cookies_readme
	fi
	##############################
	if [ "${VIDEOTOOL}" == '5' ]; then
		upgrade_video_download_tool
	fi
	#########################
	if [ -z "${VIDEOTOOL}" ]; then
		tmoe_linux_tool_menu
	fi
	###############
	press_enter_to_return
	tmoe_linux_tool_menu
}
###########
golang_annie() {
	if [ ! -e "/usr/local/bin/annie" ]; then
		echo "检测到您尚未安装annie，将为您跳转至更新管理中心"
		upgrade_video_download_tool
		exit 0
	fi

	if [ ! -e "${HOME}/sd/Download/Videos" ]; then
		mkdir -p ${HOME}/sd/Download/Videos
	fi

	cd ${HOME}/sd/Download/Videos

	AnnieVideoURL=$(whiptail --inputbox "Please enter a url.请输入视频链接,例如https://www.bilibili.com/video/av号,或者直接输入avxxx(av号或BV号)。您可以在url前加-f参数来指定清晰度，-p来下载整个播放列表。Press Enter after the input is completed." 12 50 --title "请在地址栏内输入 视频链接" 3>&1 1>&2 2>&3)

	# echo ${AnnieVideoURL} >> ${HOME}/.video_history
	if [ "$(echo ${AnnieVideoURL} | grep 'b23.tv')" ]; then
		AnnieVideoURL="$(echo ${AnnieVideoURL} | sed 's@b23.tv@www.bilibili.com/video@')"
	elif [ "$(echo ${AnnieVideoURL} | grep '^BV')" ]; then
		AnnieVideoURL="$(echo ${AnnieVideoURL} | sed 's@^BV@https://www.bilibili.com/video/&@')"
	fi
	#当未添加http时，将自动修复。
	if [ "$(echo ${AnnieVideoURL} | grep -E 'www|com')" ] && [ ! "$(echo ${AnnieVideoURL} | grep 'http')" ]; then
		ls
		AnnieVideoURL=$(echo ${AnnieVideoURL} | sed 's@www@http://&@')
	fi
	echo ${AnnieVideoURL}
	echo "正在解析中..."
	echo "Parsing ..."
	#if [ ! $(echo ${AnnieVideoURL} | grep -E '^BV|^av|^http') ]; then
	#	AnnieVideoURL=$(echo ${AnnieVideoURL} | sed 's@^@http://&@')
	#fi

	annie -i ${AnnieVideoURL}
	if [ -e "${HOME}/.config/tmoe-linux/videos.cookiepath" ]; then
		VideoCookies=$(cat ${HOME}/.config/tmoe-linux/videos.cookiepath | head -n 1)
		annie -c ${VideoCookies} -d ${AnnieVideoURL}
	else
		annie -d ${AnnieVideoURL}
	fi
	ls -lAth ./ | head -n 3
	echo "视频文件默认下载至$(pwd)"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	download_videos
}
###########
python_you_get() {
	if [ ! $(command -v you-get) ]; then
		echo "检测到您尚未安装you-get,将为您跳转至更新管理中心"
		upgrade_video_download_tool
		exit 0
	fi

	if [ ! -e "${HOME}/sd/Download/Videos" ]; then
		mkdir -p ${HOME}/sd/Download/Videos
	fi

	cd ${HOME}/sd/Download/Videos

	AnnieVideoURL=$(whiptail --inputbox "Please enter a url.请输入视频链接,例如https://www.bilibili.com/video/av号,您可以在url前加--format参数来指定清晰度，-l来下载整个播放列表。Press Enter after the input is completed." 12 50 --title "请在地址栏内输入 视频链接" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		download_videos
	fi
	echo ${AnnieVideoURL}
	echo "正在解析中..."
	echo "Parsing ..."
	you-get -i ${AnnieVideoURL}
	if [ -e "${HOME}/.config/tmoe-linux/videos.cookiepath" ]; then
		VideoCookies=$(cat ${HOME}/.config/tmoe-linux/videos.cookiepath | head -n 1)
		you-get -c ${VideoCookies} -d ${AnnieVideoURL}
	else
		you-get -d ${AnnieVideoURL}
	fi
	ls -lAth ./ | head -n 3
	echo "视频文件默认下载至$(pwd)"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	download_videos
}
############
python_youtube_dl() {
	if [ ! $(command -v youtube-dl) ]; then
		echo "检测到您尚未安装youtube-dl,将为您跳转至更新管理中心"
		upgrade_video_download_tool
		exit 0
	fi

	if [ ! -e "${HOME}/sd/Download/Videos" ]; then
		mkdir -p ${HOME}/sd/Download/Videos
	fi

	cd ${HOME}/sd/Download/Videos

	AnnieVideoURL=$(whiptail --inputbox "Please enter a url.请输入视频链接,例如https://www.bilibili.com/video/av号,您可以在url前加--yes-playlist来下载整个播放列表。Press Enter after the input is completed." 12 50 --title "请在地址栏内输入 视频链接" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		download_videos
	fi
	echo ${AnnieVideoURL}
	echo "正在解析中..."
	echo "Parsing ..."
	youtube-dl -e --get-description --get-duration ${AnnieVideoURL}
	if [ -e "${HOME}/.config/tmoe-linux/videos.cookiepath" ]; then
		VideoCookies=$(cat ${HOME}/.config/tmoe-linux/videos.cookiepath | head -n 1)
		youtube-dl --merge-output-format mp4 --all-subs --cookies ${VideoCookies} -v ${AnnieVideoURL}
	else
		youtube-dl --merge-output-format mp4 --all-subs -v ${AnnieVideoURL}
	fi
	ls -lAth ./ | head -n 3
	echo "视频文件默认下载至$(pwd)"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	download_videos
}
#############
check_file_selection_items() {
	if [[ -d "${SELECTION}" ]]; then # 目录是否已被选择
		tmoe_file "$1" "${SELECTION}"
	elif [[ -f "${SELECTION}" ]]; then # 文件已被选择？
		if [[ ${SELECTION} == *${FILE_EXT_01} ]] || [[ ${SELECTION} == *${FILE_EXT_02} ]]; then
			# 检查文件扩展名
			if (whiptail --title "Confirm Selection" --yes-button "Confirm确认" --no-button "Back返回" --yesno "目录: $CURRENT_DIR\n文件: ${SELECTION}" 10 55 4); then
				FILE_NAME="${SELECTION}"
				FILE_PATH="${CURRENT_DIR}"
				#将文件路径作为已经选择的变量
			else
				tmoe_file "$1" "$CURRENT_DIR"
			fi
		else
			whiptail --title "WARNING: File Must have ${FILE_EXT_01} or ${FILE_EXT_02} Extension" \
				--msgbox "${SELECTION}\n您必须选择${FILE_EXT_01}或${FILE_EXT_02}格式的文件。You Must Select a ${FILE_EXT_01} or ${FILE_EXT_02} file" 0 0
			tmoe_file "$1" "$CURRENT_DIR"
		fi
	else
		whiptail --title "WARNING: Selection Error" \
			--msgbox "无法选择该文件或文件夹，请返回。Error Changing to Path ${SELECTION}" 0 0
		tmoe_file "$1" "$CURRENT_DIR"
	fi
}
#####################
tmoe_file() {
	if [ -z $2 ]; then
		DIR_LIST=$(ls -lAhp | awk -F ' ' ' { print $9 " " $5 } ')
	else
		cd "$2"
		DIR_LIST=$(ls -lAhp | awk -F ' ' ' { print $9 " " $5 } ')
	fi
	###########################
	CURRENT_DIR=$(pwd)
	# 检测是否为根目录
	if [ "$CURRENT_DIR" == "/" ]; then
		SELECTION=$(whiptail --title "$1" \
			--menu "${MENU_01}\n$CURRENT_DIR" 0 0 0 \
			--title "$TMOE_TITLE" \
			--cancel-button Cancel取消 \
			--ok-button Select选择 $DIR_LIST 3>&1 1>&2 2>&3)
	else
		SELECTION=$(whiptail --title "$1" \
			--menu "${MENU_01}\n$CURRENT_DIR" 0 0 0 \
			--title "$TMOE_TITLE" \
			--cancel-button Cancel取消 \
			--ok-button Select选择 ../ 返回 $DIR_LIST 3>&1 1>&2 2>&3)
	fi
	########################
	EXIT_STATUS=$?
	if [ ${EXIT_STATUS} = 1 ]; then # 用户是否取消操作？
		return 1
	elif [ ${EXIT_STATUS} = 0 ]; then
		check_file_selection_items
	fi
	############
}
################
tmoe_file_manager() {
	#START_DIR="/root"
	#FILE_EXT_01='tar.gz'
	#FILE_EXT_02='tar.xz'
	TMOE_TITLE="${FILE_EXT_01} & ${FILE_EXT_02} 文件选择Tmoe-linux管理器"
	MENU_01="请使用方向键和回车键进行操作"
	########################################
	#-bak_rootfs.tar.xz
	###################
	#tmoe_file
	###############
	tmoe_file "$TMOE_TITLE" "$START_DIR"

	EXIT_STATUS=$?
	if [ ${EXIT_STATUS} -eq 0 ]; then
		if [ "${SELECTION}" == "" ]; then
			echo "检测到您取消了操作,User Pressed Esc with No File Selection"
		else
			whiptail --msgbox "文件属性 :  $(ls -lh ${FILE_NAME})\n路径 : ${FILE_PATH}" 0 0
			TMOE_FILE_ABSOLUTE_PATH="${CURRENT_DIR}/${SELECTION}"
			#uncompress_tar_file
		fi
	else
		echo "检测到您${RED}取消了${RESET}${YELLOW}操作${RESET}，没有文件${BLUE}被选择${RESET},with No File ${BLUE}Selected.${RESET}"
		#press_enter_to_return
	fi
}
###########
where_is_start_dir() {
	if [ -d "/root/sd" ]; then
		START_DIR='/root/sd/Download'
	elif [ -d "/sdcard" ]; then
		START_DIR='/sdcard/'
	else
		START_DIR="$(pwd)"
	fi
	tmoe_file_manager
}
###################################
cookies_readme() {
	cat <<-'EndOFcookies'
		若您需要下载大会员视频，则需要指定cookie文件路径。
		加载cookie后，即使您不是大会员，也能提高部分网站的下载速度。
		cookie文件包含了会员身份认证凭据，请勿将该文件泄露出去！
		一个cookie文件可以包含多个网站的cookies，您只需要手动将包含cookie数据的纯文本复制至cookies.txt文件即可。
		您需要安装浏览器扩展插件来导出cookie，部分插件还需手动配置导出格式为Netscape，并将后缀名修改为txt
		对于不同平台(windows、linux和macos)导出的cookie文件，如需跨平台加载，则需要转换为相应系统的换行符。
		浏览器商店中包含多个相关扩展插件，但不同插件导出的cookie文件可能存在兼容性的差异。
		例如火狐扩展cookies-txt（适用于you-get v0.4.1432，不适用于annie v0.9.8）
		https://addons.mozilla.org/zh-CN/firefox/addon/cookies-txt/
		再次提醒，cookie非常重要!
		希望您能仔细甄别，堤防恶意插件。
		同时希望您能够了解，将cookie文件泄露出去等同于将账号泄密！
		请妥善保管好该文件及相关数据！
	EndOFcookies
	if [ -e "${HOME}/.config/tmoe-linux/videos.cookiepath" ]; then
		echo "您当前的cookie路径为$(cat ${HOME}/.config/tmoe-linux/videos.cookiepath | head -n 1)"
	fi
	RETURN_TO_WHERE='download_videos'
	do_you_want_to_continue
	if [ -e "${HOME}/.config/tmoe-linux/videos.cookiepath" ]; then
		COOKIESTATUS="检测到您已启用加载cookie功能"
		CurrentCOOKIESpath="您当前的cookie路径为$(cat ${HOME}/.config/tmoe-linux/videos.cookiepath | head -n 1)"
	else
		COOKIESTATUS="检测到cookie处于禁用状态"
	fi

	mkdir -p "${HOME}/.config/tmoe-linux"
	if (whiptail --title "modify cookie path and status" --yes-button '指定cookie file' --no-button 'disable禁用cookie' --yesno "您想要修改哪些配置信息？${COOKIESTATUS} Which configuration do you want to modify?" 9 50); then
		FILE_EXT_01='txt'
		FILE_EXT_02='sqlite'
		where_is_start_dir
		if [ -z ${SELECTION} ]; then
			echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
		else
			echo ${TMOE_FILE_ABSOLUTE_PATH} >"${HOME}/.config/tmoe-linux/videos.cookiepath"
			echo "您当前的cookie文件路径为${TMOE_FILE_ABSOLUTE_PATH}"
			ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		fi
	else
		rm -f "${HOME}/.config/tmoe-linux/videos.cookiepath"
		echo "已禁用加载cookie功能"
	fi
	press_enter_to_return
	download_videos
}
#########
check_latest_video_download_tool_version() {
	echo "正在${YELLOW}检测${RESET}${GREEN}版本信息${RESET}..."
	cat <<-ENDofnote
		如需${YELLOW}卸载${RESET}${BLUE}annie${RESET},请输${GREEN}rm /usr/local/bin/annie${RESET}
		如需${YELLOW}卸载${RESET}${BLUE}you-get${RESET},请输${GREEN}pip3 uninstall you-get${RESET}
		如需${YELLOW}卸载${RESET}${BLUE}youtube-dl${RESET},请输${GREEN}pip3 uninstall youtube-dl${RESET}
	ENDofnote

	LATEST_ANNIE_VERSION=$(curl -LfsS https://gitee.com/mo2/annie/raw/linux_amd64/annie_version.txt | head -n 1)

	####################
	if [ $(command -v you-get) ]; then
		YouGetVersion=$(you-get -V 2>&1 | head -n 1 | cut -d ':' -f 2 | cut -d ',' -f 1 | awk -F ' ' '$0=$NF')
	else
		YouGetVersion='您尚未安装you-get'
	fi
	#LATEST_YOU_GET_VERSION=$(curl -LfsS https://github.com/soimort/you-get/releases | grep 'muted-link css-truncate' | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f 5)

	#######################
	if [ $(command -v youtube-dl) ]; then
		YOTUBEdlVersion=$(youtube-dl --version 2>&1 | head -n 1)
	else
		YOTUBEdlVersion='您尚未安装youtube-dl'
	fi
	#LATEST_YOUTUBE_DL_VERSION=$(curl -LfsS https://github.com/ytdl-org/youtube-dl/releases | grep 'muted-link css-truncate' | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2 | cut -d '/' -f 5)
	LATEST_YOUTUBE_DL_VERSION=$(curl -LfsS https://pypi.tuna.tsinghua.edu.cn/simple/youtube-dl/ | grep .whl | tail -n 1 | cut -d '=' -f 3 | cut -d '>' -f 2 | cut -d '<' -f 1 | cut -d '-' -f 2)
	##################
	cat <<-ENDofTable
		╔═══╦══════════╦═══════════════════╦════════════════════
		║   ║          ║                   ║                    
		║   ║ software ║ 最新版本          ║   本地版本 🎪
		║   ║          ║latest version✨   ║  Local version     
		║---║----------║-------------------║--------------------
		║ 1 ║   annie  ║                   ║  ${AnnieVersion}
		║   ║          ║${LATEST_ANNIE_VERSION}║
		║---║----------║-------------------║--------------------
		║   ║          ║                   ║ ${YouGetVersion}                   
		║ 2 ║ you-get  ║                   ║  
		║---║----------║-------------------║--------------------
		║   ║          ║                   ║  ${YOTUBEdlVersion}                  
		║ 3 ║youtube-dl║${LATEST_YOUTUBE_DL_VERSION}           ║  

		annie: github.com/iawia002/annie
		you-get : github.com/soimort/you-get
		youtube-dl：github.com/ytdl-org/youtube-dl
	ENDofTable
	#对原开发者iawia002的代码进行自动编译
	echo "为避免加载超时，故${RED}隐藏${RESET}了部分软件的${GREEN}版本信息。${RESET}"
	echo "annie将于每月1号凌晨4点自动编译并发布最新版"
	echo "您可以按${GREEN}回车键${RESET}来${BLUE}获取更新${RESET}，亦可前往原开发者的仓库来${GREEN}手动下载${RESET}新版"
}
##################
upgrade_video_download_tool() {
	cat <<-'ENDofTable'
		╔═══╦════════════╦════════╦════════╦═════════╦
		║   ║     💻     ║    🎬  ║   🌁   ║   📚    ║
		║   ║  website   ║ Videos ║ Images ║Playlist ║
		║   ║            ║        ║        ║         ║
		║---║------------║--------║--------║---------║
		║ 1 ║  bilibili  ║  ✓     ║        ║   ✓     ║
		║   ║            ║        ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║ 2 ║  tiktok    ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║ 3 ║ youku      ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║ 4 ║ youtube    ║  ✓     ║        ║   ✓     ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║ 5 ║ iqiyi      ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║ 6 ║  weibo     ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║ netease    ║        ║        ║         ║
		║ 7 ║ 163music   ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║ tencent    ║        ║        ║         ║
		║ 8 ║ video      ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║ 9 ║ instagram  ║  ✓     ║  ✓     ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║10 ║  twitter   ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║11 ║ douyu      ║  ✓     ║        ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║12 ║pixivision  ║        ║  ✓     ║         ║
		║---║------------║--------║--------║---------║
		║   ║            ║        ║        ║         ║
		║13 ║ pornhub    ║  ✓     ║        ║         ║

	ENDofTable

	if [ -e "/usr/local/bin/annie" ]; then
		#AnnieVersion=$(annie -v | cut -d ':' -f 2 | cut -d ',' -f 1 | awk -F ' ' '$0=$NF')
		AnnieVersion=$(cat ~/.config/tmoe-linux/annie_version.txt | head -n 1)
		check_latest_video_download_tool_version

	else
		AnnieVersion='您尚未安装annie'
		echo "检测到您${RED}尚未安装${RESET}annie，跳过${GREEN}版本检测！${RESET}"
	fi

	echo "按${GREEN}回车键${RESET}将同时更新${YELLOW}annie、you-get和youtube-dl${RESET}"
	echo 'Press Enter to update'
	RETURN_TO_WHERE='download_videos'
	do_you_want_to_continue
	NON_DEBIAN=false
	DEPENDENCY_01=""
	DEPENDENCY_02=""

	if [ ! $(command -v python3) ]; then
		DEPENDENCY_01="${DEPENDENCY_01} python3"
	fi

	if [ ! $(command -v ffmpeg) ]; then
		if [ "${ARCH_TYPE}" = "amd64" ] || [ "${ARCH_TYPE}" = "arm64" ]; then
			cd /tmp
			rm -rf .FFMPEGTEMPFOLDER
			git clone -b linux_$(uname -m) --depth=1 https://gitee.com/mo2/ffmpeg.git ./.FFMPEGTEMPFOLDER
			cd /usr/local/bin
			tar -Jxvf /tmp/.FFMPEGTEMPFOLDER/ffmpeg.tar.xz ffmpeg
			chmod +x ffmpeg
			rm -rf /tmp/.FFMPEGTEMPFOLDER
		else
			DEPENDENCY_01="${DEPENDENCY_01} ffmpeg"
		fi
	fi
	#检测两次
	if [ ! $(command -v ffmpeg) ]; then
		if [ "${ARCH_TYPE}" = "amd64" ] || [ "${ARCH_TYPE}" = "arm64" ]; then
			DEPENDENCY_01="${DEPENDENCY_01} ffmpeg"
		fi
	fi

	if [ ! $(command -v pip3) ]; then
		if [ "${LINUX_DISTRO}" = 'debian' ]; then
			apt update 2>/dev/null
			apt install -y python3 python3-distutils 2>/dev/null
		else
			${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
		fi
		cd /tmp
		curl -LO https://gitee.com/mo2/get-pip/raw/master/.get-pip.tar.gz.00
		curl -LO https://gitee.com/mo2/get-pip/raw/master/.get-pip.tar.gz.01
		cat .get-pip.tar.gz.* >.get-pip.tar.gz
		tar -zxvf .get-pip.tar.gz
		python3 get-pip.py -i https://pypi.tuna.tsinghua.edu.cn/simple
		rm -f .get-pip.tar.gz* get-pip.py
	fi
	#检测两次
	if [ ! $(command -v pip3) ]; then
		if [ "${LINUX_DISTRO}" = 'debian' ]; then
			DEPENDENCY_02="${DEPENDENCY_02} python3-pip"
		else
			DEPENDENCY_02="${DEPENDENCY_02} python-pip"
		fi
	fi

	if [ ! -z "${DEPENDENCY_01}" ] && [ ! -z "${DEPENDENCY_02}" ]; then
		beta_features_quick_install
	fi

	cd /tmp
	if [ ! $(command -v pip3) ]; then
		curl -LO https://gitee.com/mo2/get-pip/raw/master/.get-pip.tar.gz.00
		curl -LO https://gitee.com/mo2/get-pip/raw/master/.get-pip.tar.gz.01
		cat .get-pip.tar.gz.* >.get-pip.tar.gz
		tar -zxvf .get-pip.tar.gz
		if [ -f "get-pip.py" ]; then
			rm -f .get-pip.tar.gz*
		else
			curl -LO https://bootstrap.pypa.io/get-pip.py
		fi
		python3 get-pip.py -i https://pypi.tuna.tsinghua.edu.cn/simple
		rm -f get-pip.py
	fi

	rm -rf ./.ANNIETEMPFOLDER
	git clone -b linux_${ARCH_TYPE} --depth=1 https://gitee.com/mo2/annie ./.ANNIETEMPFOLDER
	cd ./.ANNIETEMPFOLDER
	tar -Jxvf annie.tar.xz
	chmod +x annie
	mkdir -p ~/.config/tmoe-linux/
	mv -f annie_version.txt ~/.config/tmoe-linux/
	mv -f annie /usr/local/bin/
	annie -v
	cd ..
	rm -rf ./.ANNIETEMPFOLDER
	#mkdir -p ${HOME}/.config
	#pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
	pip3 install pip -U -i https://pypi.tuna.tsinghua.edu.cn/simple 2>/dev/null
	pip3 install you-get -U -i https://pypi.tuna.tsinghua.edu.cn/simple
	you-get -V
	pip3 install youtube-dl -U -i https://pypi.tuna.tsinghua.edu.cn/simple
	youtube-dl -v 2>&1 | grep version
	echo "更新完毕，如需${YELLOW}卸载${RESET}annie,请输${YELLOW}rm /usr/local/bin/annie${RESET}"
	echo "如需卸载you-get,请输${YELLOW}pip3 uninstall you-get${RESET}"
	echo "如需卸载youtube-dl,请输${YELLOW}pip3 uninstall youtube-dl${RESET}"
	echo "请问您是否需要将pip源切换为清华源[Y/n]?"
	echo "If you are not living in the People's Republic of China, then please type ${YELLOW}n${RESET} .[Y/n]"
	RETURN_TO_WHERE='download_videos'
	do_you_want_to_continue
	pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

	echo 'Press Enter to start annie'
	echo "${YELLOW}按回车键启动annie。${RESET}"
	read
	golang_annie
}
##################
which_vscode_edition() {
	RETURN_TO_WHERE='which_vscode_edition'
	ps -e >/dev/null 2>&1 || VSCODEtips=$(echo "检测到您无权读取/proc分区的部分内容，请选择Server版，或使用x11vnc打开VSCode本地版")
	VSCODE_EDITION=$(whiptail --title "Visual Studio Code" --menu \
		"${VSCODEtips} Which edition do you want to install" 15 60 5 \
		"1" "VS Code Server(web版)" \
		"2" "VS Codium" \
		"3" "VS Code OSS" \
		"4" "Microsoft Official(x64,官方版)" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	case "${VSCODE_EDITION}" in
	0 | "") tmoe_linux_tool_menu ;;
	1) check_vscode_server_arch ;;
	2) install_vscodium ;;
	3) install_vscode_oss ;;
	4) install_vscode_official ;;
	esac
	#########################
	press_enter_to_return
	tmoe_linux_tool_menu
}
#################################
check_vscode_server_arch() {
	if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "x86_64" ]; then
		install_vscode_server
	else
		echo "非常抱歉，Tmoe-linux的开发者未对您的架构进行适配。"
		echo "请选择其它版本"
		arch_does_not_support
		which_vscode_edition
	fi
}
###################
install_vscode_server() {
	if [ ! -e "/usr/local/bin/code-server-data/code-server" ]; then
		if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "install安装" --no-button "Configure配置" --yesno "检测到您尚未安装vscode-server\nVisual Studio Code is a lightweight but powerful source code editor which runs on your desktop and is available for Windows, macOS and Linux. It comes with built-in support for JavaScript, TypeScript and Node.js and has a rich ecosystem of extensions for other languages (such as C++, C#, Java, Python, PHP, Go) and runtimes (such as .NET and Unity).  ♪(^∇^*) " 16 50); then
			vscode_server_upgrade
		else
			configure_vscode_server
		fi
	else
		check_vscode_server_status
	fi
}
#################
check_vscode_server_status() {
	#pgrep code-server &>/dev/null
	pgrep node &>/dev/null
	if [ "$?" = "0" ]; then
		VSCODE_SERVER_STATUS='检测到code-server进程正在运行'
		VSCODE_SERVER_PROCESS='Restart重启'
	else
		VSCODE_SERVER_STATUS='检测到code-server进程未运行'
		VSCODE_SERVER_PROCESS='Start启动'
	fi

	if (whiptail --title "你想要对这个小可爱做什么" --yes-button "${VSCODE_SERVER_PROCESS}" --no-button 'Configure配置' --yesno "您是想要启动服务还是配置服务？${VSCODE_SERVER_STATUS}" 9 50); then
		vscode_server_restart
	else
		configure_vscode_server
	fi
}
###############
configure_vscode_server() {
	CODE_SERVER_OPTION=$(
		whiptail --title "CONFIGURE VSCODE_SERVER" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 14 50 5 \
			"1" "upgrade code-server更新/升级" \
			"2" "password 设定密码" \
			"3" "stop 停止" \
			"4" "remove 卸载/移除" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	if [ "${CODE_SERVER_OPTION}" == '0' ]; then
		which_vscode_edition
	fi
	##############################
	if [ "${CODE_SERVER_OPTION}" == '1' ]; then
		pkill node
		#service code-server stop 2>/dev/null
		vscode_server_upgrade
	fi
	##############################
	if [ "${CODE_SERVER_OPTION}" == '2' ]; then
		vscode_server_password
	fi
	##############################
	if [ "${CODE_SERVER_OPTION}" == '3' ]; then
		echo "正在停止服务进程..."
		echo "Stopping..."
		pkill node
		#service code-server stop 2>/dev/null
		#service vscode_server status
	fi
	##############################
	if [ "${CODE_SERVER_OPTION}" == '4' ]; then
		vscode_server_remove
	fi
	########################################
	if [ -z "${CODE_SERVER_OPTION}" ]; then
		which_vscode_edition
	fi
	##############
	press_enter_to_return
	configure_vscode_server
}
##############
vscode_server_upgrade() {
	echo "正在检测版本信息..."
	if [ -e "/usr/local/bin/code-server-data/code-server" ]; then
		LOCAL_VSCODE_VERSION=$(code-server --version | cut -d ' ' -f 1)
	else
		LOCAL_VSCODE_VERSION='您尚未安装code-server'
	fi
	LATEST_VSCODE_VERSION=$(curl -sL https://gitee.com/mo2/vscode-server/raw/aarch64/version.txt | head -n 1)

	cat <<-ENDofTable
		╔═══╦══════════╦═══════════════════╦════════════════════
		║   ║          ║                   ║                    
		║   ║ software ║    ✨最新版本     ║   本地版本 🎪
		║   ║          ║  Latest version   ║  Local version     
		║---║----------║-------------------║--------------------
		║ 1 ║ vscode   ║                      ${LOCAL_VSCODE_VERSION} 
		║   ║ server   ║${LATEST_VSCODE_VERSION} 

	ENDofTable
	RETURN_TO_WHERE='configure_vscode_server'
	do_you_want_to_continue
	if [ ! -e "/tmp/sed-vscode.tmp" ]; then
		cat >"/tmp/sed-vscode.tmp" <<-'EOF'
			if [ -e "/tmp/startcode.tmp" ]; then
				echo "正在为您启动VSCode服务(器),请复制密码，并在浏览器的密码框中粘贴。"
				echo "The VSCode service(server) is starting, please copy the password and paste it in your browser."

				rm -f /tmp/startcode.tmp
				code-server &
				echo "已为您启动VS Code Server!"
				echo "VS Code Server has been started,enjoy it !"
				echo "您可以输pkill node来停止服务(器)。"
				echo 'You can type "pkill node" to stop vscode service(server).'
			fi
		EOF
	fi
	grep '/tmp/startcode.tmp' /root/.bashrc >/dev/null || sed -i "$ r /tmp/sed-vscode.tmp" /root/.bashrc
	grep '/tmp/startcode.tmp' /root/.zshrc >/dev/null || sed -i "$ r /tmp/sed-vscode.tmp" /root/.zshrc
	if [ ! -x "/usr/local/bin/code-server-data/code-server" ]; then
		chmod +x /usr/local/bin/code-server-data/code-server 2>/dev/null
		#echo -e "检测到您未安装vscode server\nDetected that you do not have vscode server installed."
	fi

	cd /tmp
	rm -rvf .VSCODE_SERVER_TEMP_FOLDER

	if [ "${ARCH_TYPE}" = "arm64" ]; then
		git clone -b aarch64 --depth=1 https://gitee.com/mo2/vscode-server.git .VSCODE_SERVER_TEMP_FOLDER
		cd .VSCODE_SERVER_TEMP_FOLDER
		tar -PpJxvf code.tar.xz
		cd ${cur}
		rm -rf /tmp/.VSCODE_SERVER_TEMP_FOLDER
	elif [ "${ARCH_TYPE}" = "amd64" ]; then
		mkdir -p .VSCODE_SERVER_TEMP_FOLDER
		cd .VSCODE_SERVER_TEMP_FOLDER
		LATEST_VSCODE_SERVER_LINK=$(curl -Lv https://api.github.com/repos/cdr/code-server/releases | grep 'x86_64' | grep browser_download_url | grep linux | head -n 1 | awk -F ' ' '$0=$NF' | cut -d '"' -f 2)
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o .VSCODE_SERVER.tar.gz ${LATEST_VSCODE_SERVER_LINK}
		tar -zxvf .VSCODE_SERVER.tar.gz
		VSCODE_FOLDER_NAME=$(ls -l ./ | grep '^d' | awk -F ' ' '$0=$NF')
		mv ${VSCODE_FOLDER_NAME} code-server-data
		rm -rvf /usr/local/bin/code-server-data /usr/local/bin/code-server
		mv code-server-data /usr/local/bin/
		ln -sf /usr/local/bin/code-server-data/code-server /usr/local/bin/code-server
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定访问密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		press_enter_to_return
		vscode_server_password
	fi

	if [ ! -e "${HOME}/.profile" ]; then
		echo '' >>~/.profile
	fi
	sed -i '/export PASSWORD=/d' ~/.profile
	sed -i '/export PASSWORD=/d' ~/.zshrc
	sed -i "$ a\export PASSWORD=${TARGET_USERPASSWD}" ~/.profile
	sed -i "$ a\export PASSWORD=${TARGET_USERPASSWD}" ~/.zshrc
	export PASSWORD=${TARGET_USERPASSWD}
	vscode_server_restart
	########################################
	press_enter_to_return
	configure_vscode_server
	#此处的返回步骤并非多余
}
############
vscode_server_restart() {
	echo "即将为您启动code-server,请复制密码，并在浏览器中粘贴。"
	echo "The VSCode server is starting, please copy the password and paste it in your browser."
	echo "您之后可以输code-server来启动Code Server."
	echo 'You can type "code-server" to start Code Server.'
	/usr/local/bin/code-server-data/code-server &
	echo "正在为您启动code-server，本机默认访问地址为localhost:8080"
	echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):8080
	echo "您可以输${YELLOW}pkill node${RESET}来停止进程"
}
#############
vscode_server_password() {
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定访问密码\n Please enter the password.您的密码将以明文形式保存至.profile和.zshrc" 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，操作取消"
		press_enter_to_return
		configure_vscode_server
	fi
	if [ ! -e "${HOME}/.profile" ]; then
		echo '' >>~/.profile
	fi
	sed -i '/export PASSWORD=/d' ~/.profile
	sed -i '/export PASSWORD=/d' ~/.zshrc
	sed -i "$ a\export PASSWORD=${TARGET_USERPASSWD}" ~/.profile
	sed -i "$ a\export PASSWORD=${TARGET_USERPASSWD}" ~/.zshrc
	export PASSWORD=${TARGET_USERPASSWD}
}
#################
vscode_server_remove() {
	pkill node
	#service code-server stop 2>/dev/null
	echo "正在停止code-server进程..."
	echo "Stopping code-server..."
	#service vscode-server stop 2>/dev/null
	echo "按回车键确认移除"
	echo "${YELLOW}Press enter to remove VSCode Server. ${RESET}"
	RETURN_TO_WHERE='configure_vscode_server'
	do_you_want_to_continue
	sed -i '/export PASSWORD=/d' ~/.profile
	sed -i '/export PASSWORD=/d' ~/.zshrc
	rm -rvf /usr/local/bin/code-server-data/ /usr/local/bin/code-server /tmp/sed-vscode.tmp
	echo "${YELLOW}移除成功${RESET}"
	echo "Remove successfully"
}
##########################
install_vscodium() {
	cd /tmp
	if [ "${ARCH_TYPE}" = 'arm64' ]; then
		CodiumARCH=arm64
	elif [ "${ARCH_TYPE}" = 'armhf' ]; then
		CodiumARCH=arm
		#CodiumDebArch=armhf
	elif [ "${ARCH_TYPE}" = 'amd64' ]; then
		CodiumARCH=x64
	elif [ "${ARCH_TYPE}" = 'i386' ]; then
		echo "暂不支持i386 linux"
		arch_does_not_support
		which_vscode_edition
	fi

	if [ -e "/usr/bin/codium" ]; then
		echo '检测到您已安装VSCodium,请手动输以下命令启动'
		#echo 'codium --user-data-dir=${HOME}/.config/VSCodium'
		echo "codium --user-data-dir=${HOME}"
		echo "如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} codium"
	elif [ -e "/usr/local/bin/vscodium-data/codium" ]; then
		echo "检测到您已安装VSCodium,请输codium --no-sandbox启动"
		echo "如需卸载，请手动输rm -rvf /usr/local/bin/vscodium-data/ /usr/local/bin/vscodium"
	fi

	if [ $(command -v codium) ]; then
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		which_vscode_edition
	fi

	if [ "${LINUX_DISTRO}" = 'debian' ]; then
		LatestVSCodiumLink="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/ | grep ${ARCH_TYPE} | grep -v '.sha256' | grep '.deb' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCodium.deb' "https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/${LatestVSCodiumLink}"
		apt show ./VSCodium.deb
		apt install -y ./VSCodium.deb
		rm -vf VSCodium.deb
		#echo '安装完成,请输codium --user-data-dir=${HOME}/.config/VSCodium启动'
		echo "安装完成,请输codium --user-data-dir=${HOME}启动"
	else
		LatestVSCodiumLink="$(curl -L https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/ | grep ${CodiumARCH} | grep -v '.sha256' | grep '.tar' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCodium.tar.gz' "https://mirrors.tuna.tsinghua.edu.cn/github-release/VSCodium/vscodium/LatestRelease/${LatestVSCodiumLink}"
		mkdir -p /usr/local/bin/vscodium-data
		tar -zxvf VSCodium.tar.gz -C /usr/local/bin/vscodium-data
		rm -vf VSCodium.tar.gz
		ln -sf /usr/local/bin/vscodium-data/codium /usr/local/bin/codium
		echo "安装完成，输codium --no-sandbox启动"
	fi
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	which_vscode_edition
}
########################
install_vscode_oss() {
	if [ -e "/usr/bin/code-oss" ]; then
		echo "检测到您已安装VSCode OSS,请手动输以下命令启动"
		#echo 'code-oss --user-data-dir=${HOME}/.config/Code\ -\ OSS\ \(headmelted\)'
		echo "code-oss --user-data-dir=${HOME}"
		echo "如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} code-oss"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		which_vscode_edition
	fi

	if [ "${LINUX_DISTRO}" = 'debian' ]; then
		apt update
		apt install -y gpg
		bash -c "$(wget -O- https://code.headmelted.com/installers/apt.sh)"
	elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
		. <(wget -O- https://code.headmelted.com/installers/yum.sh)
	else
		echo "检测到您当前使用的可能不是deb系或红帽系发行版，跳过安装"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		which_vscode_edition
	fi
	echo "安装完成,请手动输以下命令启动"
	echo "code-oss --user-data-dir=${HOME}"
	echo "如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} code-oss"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	which_vscode_edition
}
#######################
install_vscode_official() {
	cd /tmp
	if [ "${ARCH_TYPE}" != 'amd64' ]; then
		echo "当前仅支持x86_64架构"
		arch_does_not_support
		which_vscode_edition
	fi

	if [ -e "/usr/bin/code" ]; then
		echo '检测到您已安装VSCode,请手动输以下命令启动'
		#echo 'code --user-data-dir=${HOME}/.vscode'
		echo 'code --user-data-dir=${HOME}'
		echo "如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} code"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		which_vscode_edition
	elif [ -e "/usr/local/bin/vscode-data/code" ]; then
		echo "检测到您已安装VSCode,请输code --no-sandbox启动"
		echo "如需卸载，请手动输rm -rvf /usr/local/bin/VSCode-linux-x64/ /usr/local/bin/code"
		echo "${YELLOW}按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		which_vscode_edition
	fi

	if [ "${LINUX_DISTRO}" = 'debian' ]; then
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCODE.deb' "https://go.microsoft.com/fwlink/?LinkID=760868"
		apt show ./VSCODE.deb
		apt install -y ./VSCODE.deb
		rm -vf VSCODE.deb
		echo "安装完成,请输code --user-data-dir=${HOME}启动"

	elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCODE.rpm' "https://go.microsoft.com/fwlink/?LinkID=760867"
		rpm -ivh ./VSCODE.rpm
		rm -vf VSCODE.rpm
		echo "安装完成,请输code --user-data-dir=${HOME}启动"
	else
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'VSCODE.tar.gz' "https://go.microsoft.com/fwlink/?LinkID=620884"
		#mkdir -p /usr/local/bin/vscode-data
		tar -zxvf VSCODE.tar.gz -C /usr/local/bin/

		rm -vf VSCode.tar.gz
		ln -sf /usr/local/bin/VSCode-linux-x64/code /usr/local/bin/code
		echo "安装完成，输code --no-sandbox启动"
	fi
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	which_vscode_edition
}
###############################
###############################
modify_other_vnc_conf() {
	MODIFYOTHERVNCCONF=$(whiptail --title "Modify vnc server conf" --menu "Choose your option" 15 60 5 \
		"1" "音频地址 Pulse server address" \
		"2" "VNC密码 password" \
		"3" "Edit xstartup manually 手动编辑xstartup" \
		"4" "Edit startvnc manually 手动编辑vnc启动脚本" \
		"5" "修复VNC闪退" \
		"6" "调整屏幕缩放比例(仅支持xfce)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	###########
	if [ "${MODIFYOTHERVNCCONF}" == '0' ]; then
		modify_remote_desktop_config
	fi
	###########
	if [ "${MODIFYOTHERVNCCONF}" == '1' ]; then
		modify_vnc_pulse_audio
	fi
	###########
	if [ "${MODIFYOTHERVNCCONF}" == '2' ]; then
		echo 'The password you entered is hidden.'
		echo '您需要输两遍（不可见的）密码。'
		echo "When prompted for a view-only password, it is recommended that you enter 'n'"
		echo '如果提示view-only,那么建议您输n,选择权在您自己的手上。'
		echo '请输入6至8位密码'
		/usr/bin/vncpasswd
		echo '修改完成，您之后可以输startvnc来启动vnc服务，输stopvnc停止'
		echo "正在为您停止VNC服务..."
		sleep 1
		stopvnc 2>/dev/null
		press_enter_to_return
		modify_other_vnc_conf
	fi
	###########
	if [ "${MODIFYOTHERVNCCONF}" == '3' ]; then
		nano ~/.vnc/xstartup
		stopvnc 2>/dev/null
		press_enter_to_return
		modify_other_vnc_conf
	fi
	###########
	if [ "${MODIFYOTHERVNCCONF}" == '4' ]; then
		nano_startvnc_manually
	fi
	#########################
	if [ "${MODIFYOTHERVNCCONF}" == '5' ]; then
		fix_vnc_dbus_launch
	fi
	###############
	if [ "${MODIFYOTHERVNCCONF}" == '6' ]; then
		modify_xfce_window_scaling_factor
	fi
	##########
	if [ -z "${MODIFYOTHERVNCCONF}" ]; then
		modify_remote_desktop_config
	fi
	#########
	press_enter_to_return
	modify_other_vnc_conf
	##########
}
#########################
modify_xfce_window_scaling_factor() {
	TARGET=$(whiptail --inputbox "请输入您需要缩放的比例大小(纯数字)，当前仅支持整数倍，例如1和2，不支持1.5" 10 50 --title "Window Scaling Factor" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		dbus-launch xfconf-query -c xsettings -p /Gdk/WindowScalingFactor -s ${TARGET} || dbus-launch xfconf-query -n -t int -c xsettings -p /Gdk/WindowScalingFactor -s ${TARGET}
		if ((${TARGET} > 1)); then
			dbus-launch xfconf-query -c xfwm4 -p /general/theme -s Default-xhdpi
			#dbus-launch xfconf-query -c xfwm4 -p /general/theme -s Kali-Light-xHiDPI
		fi
		echo "修改完成，请输${GREEN}startvnc${RESET}重启进程"
	else
		echo '检测到您取消了操作'
		cat ${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml | grep 'WindowScalingFactor' | grep 'value='
	fi
}
##################
modify_vnc_pulse_audio() {
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。linux默认为127.0.0.1,WSL2默认为宿主机ip,当前为$(grep 'PULSE_SERVER' ~/.vnc/xstartup | cut -d '=' -f 2 | head -n 1) \n本功能适用于局域网传输，本机操作无需任何修改。若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：您需要手动启动音频服务端,Android-Termux需输pulseaudio --start,win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat' \n至于其它第三方app,例如安卓XSDL,若其显示的PULSE_SERVER地址为192.168.1.3:4713,那么您需要输入192.168.1.3:4713" 20 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		#sed -i '/PULSE_SERVER/d' ~/.vnc/xstartup
		#sed -i "2 a\export PULSE_SERVER=$TARGET" ~/.vnc/xstartup
		if grep '^export.*PULSE_SERVER' "${HOME}/.vnc/xstartup"; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" ~/.vnc/xstartup
		else
			sed -i "4 a\export PULSE_SERVER=$TARGET" ~/.vnc/xstartup
		fi
		echo 'Your current PULSEAUDIO SERVER address has been modified.'
		echo '您当前的音频地址已修改为'
		echo $(grep 'PULSE_SERVER' ~/.vnc/xstartup | cut -d '=' -f 2 | head -n 1)
		echo "请输startvnc重启vnc服务，以使配置生效"
		press_enter_to_return
		modify_other_vnc_conf
	else
		modify_other_vnc_conf
	fi
}
##################
nano_startvnc_manually() {
	echo '您可以手动修改vnc的配置信息'
	echo 'If you want to modify the resolution, please change the 1440x720 (default resolution，landscape) to another resolution, such as 1920x1080 (vertical screen).'
	echo '若您想要修改分辨率，请将默认的1440x720（横屏）改为其它您想要的分辨率，例如720x1440（竖屏）。'
	echo "您当前分辨率为$(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)"
	echo '改完后按Ctrl+S保存，Ctrl+X退出。'
	RETURN_TO_WHERE='modify_other_vnc_conf'
	do_you_want_to_continue
	nano /usr/local/bin/startvnc || nano $(command -v startvnc)
	echo "您当前分辨率为$(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)"

	stopvnc 2>/dev/null
	press_enter_to_return
	modify_other_vnc_conf
}
#############################################
#############################################
ubuntu_install_chromium_browser() {
	if ! grep -q '^deb.*bionic-update' "/etc/apt/sources.list"; then
		if [ "${ARCH_TYPE}" = "amd64" ] || [ "${ARCH_TYPE}" = "i386" ]; then
			sed -i '$ a\deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse' "/etc/apt/sources.list"
		else
			sed -i '$ a\deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ bionic-updates main restricted universe multiverse' "/etc/apt/sources.list"
		fi
		DEPENDENCY_01="chromium-browser/bionic-updates"
		DEPENDENCY_02="chromium-browser-l10n/bionic-updates"
	fi
}
#########
fix_chromium_root_ubuntu_no_sandbox() {
	sed -i 's/chromium-browser %U/chromium-browser --no-sandbox %U/g' /usr/share/applications/chromium-browser.desktop
	grep 'chromium-browser' /etc/profile || sed -i '$ a\alias chromium="chromium-browser --no-sandbox"' /etc/profile
}
#####################
fix_chromium_root_no_sandbox() {
	sed -i 's/chromium %U/chromium --no-sandbox %U/g' /usr/share/applications/chromium.desktop
	grep 'chromium' /etc/profile || sed -i '$ a\alias chromium="chromium --no-sandbox"' /etc/profile
}
#################
install_chromium_browser() {
	echo "${YELLOW}妾身就知道你没有看走眼！${RESET}"
	echo '要是下次见不到妾身，就关掉那个小沙盒吧！"chromium --no-sandbox"'
	echo "1s后将自动开始安装"
	sleep 1
	NON_DEBIAN='false'
	DEPENDENCY_01="chromium"
	DEPENDENCY_02="chromium-l10n"

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		#新版Ubuntu是从snap商店下载chromium的，为解决这一问题，将临时换源成ubuntu 18.04LTS.
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			ubuntu_install_chromium_browser
		fi
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		dispatch-conf
		DEPENDENCY_01="www-client/chromium"
		DEPENDENCY_02=""
	#emerge -avk www-client/google-chrome-unstable
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02=""
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_02="chromium-plugin-widevinecdm chromium-ffmpeg-extra"
	fi
	beta_features_quick_install
	#####################
	if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
		sed -i '$ d' "/etc/apt/sources.list"
		apt-mark hold chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg-extra
		apt update
	fi
	####################
	do_you_want_to_close_the_sandbox_mode
	read opt
	case $opt in
	y* | Y* | "")
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			fix_chromium_root_ubuntu_no_sandbox
		else
			fix_chromium_root_no_sandbox
		fi
		;;
	n* | N*)
		echo "skipped."
		;;
	*)
		echo "Invalid choice. skipped."
		;;
	esac
}
############
do_you_want_to_close_the_sandbox_mode() {
	echo "请问您是否需要关闭沙盒模式？"
	echo "若您需要以root权限运行该应用，则需要关闭，否则请保持开启状态。"
	echo "${YELLOW}Do you need to turn off the sandbox mode?[Y/n]${RESET}"
	echo "Press enter to close this mode,type n to cancel."
	echo "按${YELLOW}回车${RESET}键${RED}关闭${RESET}该模式，输${YELLOW}n${RESET}取消"
}
#######################
install_firefox_esr_browser() {
	echo 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
	echo "${YELLOW} “谢谢您选择了我，我一定会比姐姐向您提供更好的上网服务的！”╰(*°▽°*)╯火狐ESR娘坚定地说道。 ${RESET}"
	echo "1s后将自动开始安装"
	sleep 1

	NON_DEBIAN='false'
	DEPENDENCY_01="firefox-esr"
	DEPENDENCY_02="firefox-esr-l10n-zh-cn"

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			add-apt-repository -y ppa:mozillateam/ppa
			DEPENDENCY_02="firefox-esr-locale-zh-hans"
		fi
		#################
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02="firefox-esr-i18n-zh-cn"
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		dispatch-conf
		DEPENDENCY_01='www-client/firefox'
		DEPENDENCY_02=""
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01="MozillaFirefox-esr"
		DEPENDENCY_02="MozillaFirefox-esr-translations-common"
	fi
	beta_features_quick_install
	#################
	if [ ! $(command -v firefox-esr) ]; then
		echo "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫姐姐来代替了。${RESET}"
		echo 'Press Enter to confirm.'
		RETURN_TO_WHERE='install_browser'
		do_you_want_to_continue
		install_firefox_browser
	fi
}
#####################
install_firefox_browser() {
	echo 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
	echo " ${YELLOW}“谢谢您选择了我，我一定会比妹妹向您提供更好的上网服务的！”╰(*°▽°*)╯火狐娘坚定地说道。${RESET}"
	echo "1s后将自动开始安装"
	sleep 1
	NON_DEBIAN='false'
	DEPENDENCY_01="firefox"
	DEPENDENCY_02="firefox-l10n-zh-cn"

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			DEPENDENCY_02="firefox-locale-zh-hans"
		fi
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02="firefox-i18n-zh-cn"
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_02="firefox-x11"
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		dispatch-conf
		DEPENDENCY_01="www-client/firefox-bin"
		DEPENDENCY_02=""
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01="MozillaFirefox"
		DEPENDENCY_02="MozillaFirefox-translations-common"
	fi
	beta_features_quick_install
	################
	if [ ! $(command -v firefox) ]; then
		echo "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫妹妹ESR来代替了。${RESET}"
		RETURN_TO_WHERE='install_browser'
		do_you_want_to_continue
		install_firefox_esr_browser
	fi
}
#####################
install_browser() {
	if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium" --yesno "建议在安装完图形界面后，再来选择哦！(　o=^•ェ•)o　┏━┓\n我是火狐娘，选我啦！♪(^∇^*) \n妾身是chrome娘的姐姐chromium娘，妾身和那些妖艳的货色不一样，选择妾身就没错呢！(✿◕‿◕✿)✨\n请做出您的选择！ " 15 50); then

		if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox-ESR" --no-button "Firefox" --yesno " 我是firefox，其实我还有个妹妹叫firefox-esr，您是选我还是选esr?\n “(＃°Д°)姐姐，我可是什么都没听你说啊！” 躲在姐姐背后的ESR瑟瑟发抖地说。\n✨请做出您的选择！ " 15 50); then
			#echo 'esr可怜巴巴地说道:“我也想要得到更多的爱。”  '
			#什么乱七八糟的，2333333戏份真多。
			install_firefox_esr_browser
		else
			install_firefox_browser
		fi
		echo "若无法正常加载HTML5视频，则您可能需要安装火狐扩展${YELLOW}User-Agent Switcher and Manager${RESET}，并将浏览器UA修改为windows版chrome"
	else
		install_chromium_browser
	fi
	press_enter_to_return
	tmoe_linux_tool_menu
}
######################################################
######################################################
install_gui() {
	#该字体检测两次
	if [ -f '/usr/share/fonts/Iosevka.ttf' ]; then
		standand_desktop_install
	fi
	cd /tmp
	echo 'lxde预览截图'
	#curl -LfsS 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/BUSYeSLZRqq3i3oM.png' | catimg -
	if [ ! -f 'LXDE_BUSYeSLZRqq3i3oM.png' ]; then
		curl -sLo 'LXDE_BUSYeSLZRqq3i3oM.png' 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/BUSYeSLZRqq3i3oM.png'
	fi
	catimg 'LXDE_BUSYeSLZRqq3i3oM.png'

	echo 'mate预览截图'
	#curl -LfsS 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/1frRp1lpOXLPz6mO.jpg' | catimg -
	if [ ! -f 'MATE_1frRp1lpOXLPz6mO.jpg' ]; then
		curl -sLo 'MATE_1frRp1lpOXLPz6mO.jpg' 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/1frRp1lpOXLPz6mO.jpg'
	fi
	catimg 'MATE_1frRp1lpOXLPz6mO.jpg'
	echo 'xfce预览截图'

	if [ ! -f 'XFCE_a7IQ9NnfgPckuqRt.jpg' ]; then
		curl -sLo 'XFCE_a7IQ9NnfgPckuqRt.jpg' 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/a7IQ9NnfgPckuqRt.jpg'
	fi
	catimg 'XFCE_a7IQ9NnfgPckuqRt.jpg'
	if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
		if [ ! -e "/mnt/c/Users/Public/Downloads/VcXsrv/XFCE_a7IQ9NnfgPckuqRt.jpg" ]; then
			cp -f 'XFCE_a7IQ9NnfgPckuqRt.jpg' "/mnt/c/Users/Public/Downloads/VcXsrv"
		fi
		cd "/mnt/c/Users/Public/Downloads/VcXsrv"
		/mnt/c/WINDOWS/system32/cmd.exe /c "start .\XFCE_a7IQ9NnfgPckuqRt.jpg" 2>/dev/null
	fi

	if [ ! -f '/usr/share/fonts/Iosevka.ttf' ]; then
		echo '正在刷新字体缓存...'
		mkdir -p /usr/share/fonts/
		cd /tmp
		if [ -e "font.ttf" ]; then
			mv -f font.ttf '/usr/share/fonts/Iosevka.ttf'
		else
			curl -Lo 'Iosevka.tar.xz' 'https://gitee.com/mo2/Termux-zsh/raw/p10k/Iosevka.tar.xz'
			tar -xvf 'Iosevka.tar.xz'
			rm -f 'Iosevka.tar.xz'
			mv -f font.ttf '/usr/share/fonts/Iosevka.ttf'
		fi
		cd /usr/share/fonts/
		mkfontscale 2>/dev/null
		mkfontdir 2>/dev/null
		fc-cache 2>/dev/null
	fi
	#curl -LfsS 'https://gitee.com/mo2/pic_api/raw/test/2020/03/15/a7IQ9NnfgPckuqRt.jpg' | catimg -
	#echo "建议缩小屏幕字体，并重新加载图片，以获得更优的显示效果。"
	echo "按${GREEN}回车键${RESET}${RED}选择${RESET}您需要${YELLOW}安装${RESET}的${BLUE}图形桌面环境${RESET}"
	RETURN_TO_WHERE="tmoe_linux_tool_menu"
	do_you_want_to_continue
	standand_desktop_install
}
########################
preconfigure_gui_dependecies_02() {
	DEPENDENCY_02="tigervnc"
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			NON_DBUS='true'
		fi
		DEPENDENCY_02="dbus-x11 fonts-noto-cjk tightvncserver"
		#上面的依赖摆放的位置是有讲究的。
		##############
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			NON_DBUS='true'
		fi
		DEPENDENCY_02="tigervnc-server google-noto-sans-cjk-ttc-fonts"
		##################
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02="noto-fonts-cjk tigervnc"
		##################
	elif [ "${LINUX_DISTRO}" = "void" ]; then
		DEPENDENCY_02="xorg tigervnc wqy-microhei"
		#################
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		dispatch-conf
		etc-update
		DEPENDENCY_02="media-fonts/wqy-bitmapfont net-misc/tigervnc"
		#################
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_02="tigervnc-x11vnc noto-sans-sc-fonts"
		##################
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_02="xvfb dbus-x11 font-noto-cjk x11vnc"
		#ca-certificates openssl
		##############
	fi
}
########################
standand_desktop_install() {
	NON_DEBIAN='false'
	preconfigure_gui_dependecies_02
	REMOVE_UDISK2='false'
	RETURN_TO_WHERE='standand_desktop_install'
	INSTALLDESKTOP=$(whiptail --title "单项选择题" --menu \
		"您想要安装哪个桌面？按方向键选择，回车键确认！仅xfce桌面支持在本工具内便捷下载主题。 \n Which desktop environment do you want to install? " 15 60 5 \
		"1" "xfce：兼容性高" \
		"2" "lxde：轻量化桌面" \
		"3" "mate：基于GNOME 2" \
		"4" "Other其它桌面(内测版新功能):lxqt,kde" \
		"5" "window manager窗口管理器(公测):ice,fvwm" \
		"0" "我一个都不要 =￣ω￣=" \
		3>&1 1>&2 2>&3)
	##########################
	case "${INSTALLDESKTOP}" in
	0 | "") tmoe_linux_tool_menu ;;
	1)
		REMOVE_UDISK2='true'
		install_xfce4_desktop
		;;
	2)
		REMOVE_UDISK2='true'
		install_lxde_desktop
		;;
	3) install_mate_desktop ;;
	4) other_desktop ;;
	5) windows_manager_install ;;
	esac
	##########################
	press_enter_to_return
	tmoe_linux_tool_menu
}
#######################
auto_select_keyboard_layout() {
	echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
	echo "keyboard-configuration keyboard-configuration/layout select 'English (US)'" | debconf-set-selections
	echo keyboard-configuration keyboard-configuration/layoutcode select 'us' | debconf-set-selections
}
##################
#################
will_be_installed_for_you() {
	echo "即将为您安装思源黑体(中文字体)、${REMOTE_DESKTOP_SESSION_01}、tightvncserver等软件包"
}
########################
#####################
windows_manager_install() {
	NON_DBUS='true'
	REMOTE_DESKTOP_SESSION_02='x-window-manager'
	BETA_DESKTOP=$(
		whiptail --title "WINDOW MANAGER" --menu \
			"WARNING！本功能仍处于测试阶段哟！\nwindow manager窗口管理器(简称WM)是一种比桌面环境更轻量化的图形界面.\n您想要安装哪个WM呢?您可以同时安装多个\nBeta features may not work properly.\nWhich WM do you want to install?" 0 0 0 \
			"01" "ice(意在提升感观和体验,兼顾轻量和可定制性)" \
			"02" "openbox(快速,轻巧,可扩展)" \
			"03" "fvwm(强大的、与ICCCM2兼容的WM)" \
			"04" "awesome(平铺式WM)" \
			"05" "enlightenment(X11 WM based on EFL)" \
			"06" "fluxbox(高度可配置,低资源占用)" \
			"07" "i3(改进的动态平铺WM)" \
			"08" "xmonad(基于Haskell开发的平铺式WM)" \
			"09" "9wm(X11 WM inspired by Plan 9's rio)" \
			"10" "metacity(轻量的GTK+ WM)" \
			"11" "twm(Tab WM)" \
			"12" "aewm(极简主义WM for X11)" \
			"13" "aewm++(最小的 WM written in C++)" \
			"14" "afterstep(拥有NEXTSTEP风格的WM)" \
			"15" "blackbox(WM for X)" \
			"16" "dwm(dynamic window manager)" \
			"17" "mutter(轻量的GTK+ WM)" \
			"18" "bspwm(Binary space partitioning WM)" \
			"19" "clfswm(Another Common Lisp FullScreen WM)" \
			"20" "ctwm(Claude's Tab WM)" \
			"21" "evilwm(极简主义WM for X11)" \
			"22" "flwm(Fast Light WM)" \
			"23" "herbstluftwm(manual tiling WM for X11)" \
			"24" "jwm(very small & pure轻量,纯净)" \
			"25" "kwin-x11(KDE默认WM,X11 version)" \
			"26" "lwm(轻量化WM)" \
			"27" "marco(轻量化GTK+ WM for MATE)" \
			"28" "matchbox-window-manager(WM for resource-limited systems)" \
			"29" "miwm(极简主义WM with virtual workspaces)" \
			"30" "muffin(轻量化window and compositing manager)" \
			"31" "mwm(Motif WM)" \
			"32" "oroborus(a 轻量化 themeable WM)" \
			"33" "pekwm(very light)" \
			"34" "ratpoison(keyboard-only WM)" \
			"35" "sapphire(a 最小的 but configurable X11R6 WM)" \
			"36" "sawfish" \
			"37" "spectrwm(dynamic tiling WM)" \
			"38" "stumpwm(tiling,keyboard driven Common Lisp)" \
			"39" "subtle(grid-based manual tiling)" \
			"40" "sugar-session(Sugar Learning Platform)" \
			"41" "tinywm" \
			"42" "ukwm(轻量化 GTK+ WM)" \
			"43" "vdesk(manages virtual desktops for 最小的WM)" \
			"44" "vtwm(Virtual Tab WM)" \
			"45" "w9wm(enhanced WM based on 9wm)" \
			"46" "wm2(small,unconfigurable)" \
			"47" "wmaker(NeXTSTEP-like WM for X)" \
			"48" "wmii(轻量化 tabbed and tiled WM)" \
			"49" "xfwm4(xfce4默认WM)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##################
	case "${BETA_DESKTOP}" in
	0 | "") standand_desktop_install ;;
	01)
		DEPENDENCY_01='icewm'
		REMOTE_DESKTOP_SESSION_01='icewm-session'
		REMOTE_DESKTOP_SESSION_02='icewm'
		;;
	02)
		DEPENDENCY_01='openbox'
		REMOTE_DESKTOP_SESSION_01='openbox-session'
		REMOTE_DESKTOP_SESSION_02='openbox'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='openbox obmenu openbox-menu'
		fi
		;;
	03)
		install_fvwm
		;;
	04)
		DEPENDENCY_01='awesome'
		REMOTE_DESKTOP_SESSION_01='awesome'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='awesome awesome-extra'
		fi
		;;
	05)
		DEPENDENCY_01='enlightenment'
		REMOTE_DESKTOP_SESSION_01='enlightenment'
		;;
	06)
		DEPENDENCY_01='fluxbox'
		REMOTE_DESKTOP_SESSION_01='fluxbox'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='bbmail bbpager bbtime fbpager fluxbox'
		fi
		;;
	07)
		DEPENDENCY_01='i3'
		REMOTE_DESKTOP_SESSION_01='i3'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='i3 i3-wm i3blocks'
		fi
		;;
	08)
		DEPENDENCY_01='xmonad'
		REMOTE_DESKTOP_SESSION_01='xmonad'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='xmobar dmenu xmonad'
		fi
		;;
	09)
		DEPENDENCY_01='9wm'
		REMOTE_DESKTOP_SESSION_01='9wm'
		;;
	10)
		DEPENDENCY_01='metacity'
		REMOTE_DESKTOP_SESSION_01='metacity'
		;;
	11)
		DEPENDENCY_01='twm'
		REMOTE_DESKTOP_SESSION_01='twm'
		;;
	12)
		DEPENDENCY_01='aewm'
		REMOTE_DESKTOP_SESSION_01='aewm'
		;;
	13)
		DEPENDENCY_01='aewm++'
		REMOTE_DESKTOP_SESSION_01='aewm++'
		;;
	14)
		DEPENDENCY_01='afterstep'
		REMOTE_DESKTOP_SESSION_01='afterstep'
		;;
	15)
		DEPENDENCY_01='blackbox'
		REMOTE_DESKTOP_SESSION_01='blackbox'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='bbmail bbpager bbtime blackbox'
		fi
		;;
	16)
		DEPENDENCY_01='dwm'
		REMOTE_DESKTOP_SESSION_01='dwm'
		;;
	17)
		DEPENDENCY_01='mutter'
		REMOTE_DESKTOP_SESSION_01='mutter'
		;;
	18)
		DEPENDENCY_01='bspwm'
		REMOTE_DESKTOP_SESSION_01='bspwm'
		;;
	19)
		DEPENDENCY_01='clfswm'
		REMOTE_DESKTOP_SESSION_01='clfswm'
		;;
	20)
		DEPENDENCY_01='ctwm'
		REMOTE_DESKTOP_SESSION_01='ctwm'
		;;
	21)
		DEPENDENCY_01='evilwm'
		REMOTE_DESKTOP_SESSION_01='evilwm'
		;;
	22)
		DEPENDENCY_01='flwm'
		REMOTE_DESKTOP_SESSION_01='flwm'
		;;
	23)
		DEPENDENCY_01='herbstluftwm'
		REMOTE_DESKTOP_SESSION_01='herbstluftwm'
		;;
	24)
		DEPENDENCY_01='jwm'
		REMOTE_DESKTOP_SESSION_01='jwm'
		;;
	25)
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			echo "检测到您处于proot容器环境下，kwin可能无法正常运行"
			RETURN_TO_WHERE="windows_manager_install"
			do_you_want_to_continue
		fi
		if [ "${LINUX_DISTRO}" = "alpine" ]; then
			DEPENDENCY_01='kwin'
		else
			DEPENDENCY_01='kwin-x11'
		fi
		REMOTE_DESKTOP_SESSION_01='kwin'
		;;
	26)
		DEPENDENCY_01='lwm'
		REMOTE_DESKTOP_SESSION_01='lwm'
		;;
	27)
		DEPENDENCY_01='marco'
		REMOTE_DESKTOP_SESSION_01='marco'
		;;
	28)
		DEPENDENCY_01='matchbox-window-manager'
		REMOTE_DESKTOP_SESSION_01='matchbox-window-manager'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='matchbox-themes-extra matchbox-window-manager'
		fi
		;;
	29)
		DEPENDENCY_01='miwm'
		REMOTE_DESKTOP_SESSION_01='miwm'
		;;
	30)
		DEPENDENCY_01='muffin'
		REMOTE_DESKTOP_SESSION_01='muffin'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='murrine-themes muffin'
		fi
		;;
	31)
		DEPENDENCY_01='mwm'
		REMOTE_DESKTOP_SESSION_01='mwm'
		;;
	32)
		DEPENDENCY_01='oroborus'
		REMOTE_DESKTOP_SESSION_01='oroborus'
		;;
	33)
		DEPENDENCY_01='pekwm'
		REMOTE_DESKTOP_SESSION_01='pekwm'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='pekwm-themes pekwm'
		fi
		;;
	34)
		DEPENDENCY_01='ratpoison'
		REMOTE_DESKTOP_SESSION_01='ratpoison'
		;;
	35)
		DEPENDENCY_01='sapphire'
		REMOTE_DESKTOP_SESSION_01='sapphire'
		;;
	36)
		DEPENDENCY_01='sawfish'
		REMOTE_DESKTOP_SESSION_01='sawfish'
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01='sawfish-themes sawfish'
		fi
		;;
	37)
		DEPENDENCY_01='spectrwm'
		REMOTE_DESKTOP_SESSION_01='spectrwm'
		;;
	38)
		DEPENDENCY_01='stumpwm'
		REMOTE_DESKTOP_SESSION_01='stumpwm'
		;;
	39)
		DEPENDENCY_01='subtle'
		REMOTE_DESKTOP_SESSION_01='subtle'
		;;
	40)
		DEPENDENCY_01='sugar-session'
		REMOTE_DESKTOP_SESSION_01='sugar-session'
		;;
	41)
		DEPENDENCY_01='tinywm'
		REMOTE_DESKTOP_SESSION_01='tinywm'
		;;
	42)
		DEPENDENCY_01='ukwm'
		REMOTE_DESKTOP_SESSION_01='ukwm'
		;;
	43)
		DEPENDENCY_01='vdesk'
		REMOTE_DESKTOP_SESSION_01='vdesk'
		;;
	44)
		DEPENDENCY_01='vtwm'
		REMOTE_DESKTOP_SESSION_01='vtwm'
		;;
	45)
		DEPENDENCY_01='w9wm'
		REMOTE_DESKTOP_SESSION_01='w9wm'
		;;
	46)
		DEPENDENCY_01='wm2'
		REMOTE_DESKTOP_SESSION_01='wm2'
		;;
	47)
		DEPENDENCY_01='wmaker'
		REMOTE_DESKTOP_SESSION_01='wmaker'
		;;
	48)
		DEPENDENCY_01='wmii'
		REMOTE_DESKTOP_SESSION_01='wmii'
		;;
	49)
		DEPENDENCY_01='xfwm4'
		REMOTE_DESKTOP_SESSION_01='xfwm4'
		;;
	esac
	#############
	will_be_installed_for_you
	beta_features_quick_install
	configure_vnc_xstartup
	press_enter_to_return
	tmoe_linux_tool_menu
}
##########################
install_fvwm() {
	DEPENDENCY_01='fvwm'
	REMOTE_DESKTOP_SESSION_01='fvwm'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		DEPENDENCY_01='fvwm fvwm-icons'
		REMOTE_DESKTOP_SESSION_01='fvwm-crystal'
		if grep -Eq 'buster|bullseye|bookworm' /etc/os-release; then
			DEPENDENCY_01='fvwm fvwm-icons fvwm-crystal'
		else
			REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/f/fvwm-crystal/'
			GREP_NAME='all'
			download_deb_comman_model_01
			if [ $(command -v fvwm-crystal) ]; then
				REMOTE_DESKTOP_SESSION_01='fvwm-crystal'
			fi
		fi
	fi
}
#################
download_deb_comman_model_01() {
	cd /tmp/
	THE_LATEST_DEB_VERSION="$(curl -L ${REPO_URL} | grep '.deb' | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
	THE_LATEST_DEB_LINK="${REPO_URL}${THE_LATEST_DEB_VERSION}"
	echo ${THE_LATEST_DEB_LINK}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_DEB_VERSION}" "${THE_LATEST_DEB_LINK}"
	apt show ./${THE_LATEST_DEB_VERSION}
	apt install -y ./${THE_LATEST_DEB_VERSION}
	rm -fv ${THE_LATEST_DEB_VERSION}
}
###################
other_desktop() {
	BETA_DESKTOP=$(whiptail --title "Alpha features" --menu \
		"WARNING！本功能仍处于测试阶段,可能无法正常运行。部分桌面依赖systemd,无法在chroot环境中运行\nAlpha features may not work properly." 15 60 6 \
		"1" "lxqt(lxde原作者基于QT开发的桌面)" \
		"2" "kde plasma5(风格华丽的桌面环境)" \
		"3" "gnome3(GNU项目的一部分)" \
		"4" "cinnamon(肉桂类似于GNOME2,对用户友好)" \
		"5" "dde(国产deepin系统桌面)" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##############################
	case "${BETA_DESKTOP}" in
	0 | "") standand_desktop_install ;;
	1) install_lxqt_desktop ;;
	2) install_kde_plasma5_desktop ;;
	3) install_gnome3_desktop ;;
	4) install_cinnamon_desktop ;;
	5) install_deepin_desktop ;;
	esac
	##################
	press_enter_to_return
	tmoe_linux_tool_menu
}
#####################
################
configure_vnc_xstartup() {
	mkdir -p ~/.vnc
	cd ${HOME}/.vnc
	cat >xstartup <<-EndOfFile
		#!/bin/bash
		unset SESSION_MANAGER
		unset DBUS_SESSION_BUS_ADDRESS
		xrdb \${HOME}/.Xresources
		export PULSE_SERVER=127.0.0.1
		if [ \$(command -v ${REMOTE_DESKTOP_SESSION_01}) ]; then
			dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_01} &
		else
			dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_02} &
		fi
	EndOfFile
	#dbus-launch startxfce4 &
	chmod +x ./xstartup
	first_configure_startvnc
}
####################
configure_x11vnc_remote_desktop_session() {
	cd /usr/local/bin/
	cat >startx11vnc <<-EOF
		#!/bin/bash
		stopvnc 2>/dev/null
		stopx11vnc
		export PULSE_SERVER=127.0.0.1
		export DISPLAY=:233
		/usr/bin/Xvfb :233 -screen 0 1440x720x24 -ac +extension GLX +render -noreset & 
		if [ "$(uname -r | cut -d '-' -f 3 | head -n 1)" = "Microsoft" ] || [ "$(uname -r | cut -d '-' -f 2 | head -n 1)" = "microsoft" ]; then
			echo '检测到您使用的是WSL,正在为您打开音频服务'
			cd "/mnt/c/Users/Public/Downloads/pulseaudio"
			/mnt/c/WINDOWS/system32/cmd.exe /c "start .\pulseaudio.bat"
			echo "若无法自动打开音频服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat"
			if grep -q '172..*1' "/etc/resolv.conf"; then
				echo "检测到您当前使用的可能是WSL2"
				WSL2IP=\$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
				export PULSE_SERVER=\${WSL2IP}
				echo "已将您的音频服务ip修改为\${WSL2IP}"
			fi
		fi
		if [ \$(command -v ${REMOTE_DESKTOP_SESSION_01}) ]; then
		    ${REMOTE_DESKTOP_SESSION_01} &
		else
		    ${REMOTE_DESKTOP_SESSION_02} &
		fi
		#export LANG="zh_CN.UTF8"
		x11vnc -ncache_cr -xkb -noxrecord -noxfixes -noxdamage -display :233 -forever -bg -rfbauth \${HOME}/.vnc/x11passwd -users \$(whoami) -rfbport 5901 -noshm &
		sleep 2s
		echo "正在启动x11vnc服务,本机默认vnc地址localhost:5901"
		echo The LAN VNC address 局域网地址 \$(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):5901
		echo "您可能会经历长达10多秒的黑屏"
		echo "You may experience a black screen for up to 10 seconds."
		echo "您之后可以输startx11vnc启动，输stopvnc或stopx11vnc停止"
		echo "You can type startx11vnc to start x11vnc,type stopx11vnc to stop it."
	EOF
	cat >stopx11vnc <<-'EOF'
		#!/bin/bash
		pkill dbus
		pkill Xvfb
	EOF
	#pkill pulse
	cat >x11vncpasswd <<-'EOF'
		#!/bin/bash
		echo "Configuring x11vnc..."
		echo "正在配置x11vnc server..."
		read -sp "请输入6至8位密码，Please enter the new VNC password: " PASSWORD
		mkdir -p ${HOME}/.vnc
		x11vnc -storepasswd $PASSWORD ${HOME}/.vnc/x11passwd
	EOF
	if [ "${NON_DBUS}" != "true" ]; then
		enable_dbus_launch
	fi
	chmod +x ./*
	x11vncpasswd
	startx11vnc
}
##########################
kali_xfce4_extras() {
	apt install -y kali-menu
	apt install -y kali-undercover
	apt install -y zenmap
	apt install -y kali-themes-common
	if [ "${ARCH_TYPE}" = "arm64" ] || [ "${ARCH_TYPE}" = "armhf" ]; then
		apt install -y kali-linux-arm
		if [ $(command -v chromium) ]; then
			apt install -y chromium-l10n
			fix_chromium_root_no_sandbox
		fi
		apt search kali-linux
	fi
	dbus-launch xfconf-query -c xsettings -p /Net/IconThemeName -s Flat-Remix-Blue-Light
}
###################
apt_purge_libfprint() {
	if [ "${LINUX_DISTRO}" = "debian" ] && [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		apt purge -y ^libfprint
		apt clean
		apt autoclean
	fi
}
###################
debian_xfce4_extras() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ "${DEBIAN_DISTRO}" = "kali" ]; then
			kali_xfce4_extras
		fi
	fi
	apt_purge_libfprint
}
##################
install_xfce4_desktop() {
	echo '即将为您安装思源黑体(中文字体)、xfce4、xfce4-terminal、xfce4-goodies和tightvncserver等软件包。'
	REMOTE_DESKTOP_SESSION_01='xfce4-session'
	REMOTE_DESKTOP_SESSION_02='startxfce4'
	DEPENDENCY_01="xfce4"
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		DEPENDENCY_01="xfce4 xfce4-goodies xfce4-terminal"
		dpkg --configure -a
		auto_select_keyboard_layout
		##############
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01='@xfce'
		rm -rf /etc/xdg/autostart/xfce-polkit.desktop
		##################
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="xfce4 xfce4-terminal xfce4-goodies"
		##################
	elif [ "${LINUX_DISTRO}" = "void" ]; then
		DEPENDENCY_01="xfce4"
		#################
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		dispatch-conf
		etc-update
		DEPENDENCY_01="xfce4-meta x11-terms/xfce4-terminal"
		#################
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01="patterns-xfce-xfce xfce4-terminal"
		###############
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="faenza-icon-theme xfce4 xfce4-terminal"
		##############
	fi
	##################
	beta_features_quick_install
	####################
	debian_xfce4_extras
	#################
	if [ ! -e "/usr/share/desktop-base/kali-theme" ]; then
		download_kali_themes_common
	fi
	##############
	if [ ! -e "/usr/share/icons/Papirus" ]; then
		download_papirus_icon_theme
		if [ "${DEBIAN_DISTRO}" != "kali" ]; then
			dbus-launch xfconf-query -c xsettings -p /Net/IconThemeName -s Papirus
		fi
	fi

	if [ ! -e "/usr/share/xfce4/terminal/colorschemes/Monokai Remastered.theme" ]; then
		cd /usr/share/xfce4/terminal
		echo "正在配置xfce4终端配色..."
		curl -Lo "colorschemes.tar.xz" 'https://gitee.com/mo2/xfce-themes/raw/terminal/colorschemes.tar.xz'
		tar -Jxvf "colorschemes.tar.xz"
	fi
	#########
	configure_vnc_xstartup
}
###############
install_lxde_desktop() {
	REMOTE_DESKTOP_SESSION_01='lxsession'
	REMOTE_DESKTOP_SESSION_02='startlxde'
	echo '即将为您安装思源黑体(中文字体)、lxde-core、lxterminal、tightvncserver。'
	DEPENDENCY_01='lxde'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		DEPENDENCY_01="lxde-core lxterminal"
		#############
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01='lxde-desktop'
		#############
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01='lxde'
		############
	elif [ "${LINUX_DISTRO}" = "void" ]; then
		DEPENDENCY_01='lxde'
		#############
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		DEPENDENCY_01='media-fonts/wqy-bitmapfont lxde-base/lxde-meta'
		##################
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01='patterns-lxde-lxde'
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="fvwm"
		REMOTE_DESKTOP_SESSION='fvwm'
	###################
	fi
	############
	beta_features_quick_install
	apt_purge_libfprint
	configure_vnc_xstartup
}
##########################
install_mate_desktop() {
	REMOTE_DESKTOP_SESSION_01='mate-session'
	REMOTE_DESKTOP_SESSION_02='x-window-manager'
	echo '即将为您安装思源黑体(中文字体)、tightvncserver、mate-desktop-environment和mate-terminal等软件包'
	DEPENDENCY_01='mate'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		#apt-mark hold gvfs
		apt update
		apt install -y udisks2 2>/dev/null
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			echo "" >/var/lib/dpkg/info/udisks2.postinst
		fi
		#apt-mark hold udisks2
		dpkg --configure -a
		auto_select_keyboard_layout
		DEPENDENCY_01='mate-desktop-environment mate-terminal'
		#apt autopurge -y ^libfprint
		apt clean
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01='@mate-desktop'
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		echo "${RED}WARNING！${RESET}检测到您当前使用的是${YELLOW}Arch系发行版${RESET}"
		echo "mate-session在远程桌面下可能${RED}无法正常运行${RESET}"
		echo "建议您${BLUE}更换${RESET}其他桌面！"
		echo "按${GREEN}回车键${RESET}${BLUE}继续安装${RESET}"
		echo "${YELLOW}Do you want to continue?[Y/l/x/q/n]${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}continue.${RESET},type n to return."
		echo "Type q to install lxqt,type l to install lxde,type x to install xfce."
		echo "按${GREEN}回车键${RESET}${RED}继续${RESET}，输${YELLOW}n${RESET}${BLUE}返回${RESET}"
		echo "输${YELLOW}q${RESET}安装lxqt,输${YELLOW}l${RESET}安装lxde,输${YELLOW}x${RESET}安装xfce"
		read opt
		case $opt in
		y* | Y* | "") ;;

		n* | N*)
			echo "skipped."
			standand_desktop_install
			;;
		l* | L*)
			install_lxde_desktop
			;;
		q* | Q*)
			install_lxqt_desktop
			;;
		x* | X*)
			install_xfce4_desktop
			;;
		*)
			echo "Invalid choice. skipped."
			standand_desktop_install
			#beta_features
			;;
		esac
		DEPENDENCY_01='mate mate-extra'
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		DEPENDENCY_01='mate-base/mate-desktop mate-base/mate'
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01='patterns-mate-mate'
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="mate-desktop-environment"
		REMOTE_DESKTOP_SESSION='mate-session'
	fi
	####################
	beta_features_quick_install
	apt_purge_libfprint
	configure_vnc_xstartup
}
#############
######################
#DEPENDENCY_02="dbus-x11 fonts-noto-cjk tightvncserver"
install_lxqt_desktop() {
	REMOTE_DESKTOP_SESSION_02='startlxqt'
	REMOTE_DESKTOP_SESSION_01='lxqt-session'
	DEPENDENCY_01="lxqt"
	echo '即将为您安装思源黑体(中文字体)、lxqt-core、lxqt-config、qterminal和tightvncserver等软件包。'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		DEPENDENCY_01="lxqt-core lxqt-config qterminal"
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01='@lxqt'
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="lxqt xorg"
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		DEPENDENCY_01="lxqt-base/lxqt-meta"
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01="tigervnc-x11vnc patterns-lxqt-lxqt"
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="openbox pcmfm rxvt-unicode tint2"
		REMOTE_DESKTOP_SESSION='openbox'
	fi
	####################
	beta_features_quick_install
	apt_purge_libfprint
	configure_vnc_xstartup
}
####################
install_kde_plasma5_desktop() {
	REMOTE_DESKTOP_SESSION_01='startkde'
	REMOTE_DESKTOP_SESSION_02='startplasma-x11'
	DEPENDENCY_01="plasma-desktop"
	echo '即将为您安装思源黑体(中文字体)、kde-plasma-desktop和tightvncserver等软件包。'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		DEPENDENCY_01="kde-plasma-desktop"
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		#yum groupinstall kde-desktop
		#dnf groupinstall -y "KDE" || yum groupinstall -y "KDE"
		#dnf install -y sddm || yum install -y sddm
		DEPENDENCY_01='@KDE'
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="plasma-desktop phonon-qt5-vnc xorg kdebase sddm sddm-kcm"
		#pacman -S --noconfirm sddm sddm-kcm
		#中文输入法
		#pacman -S fcitx fcitx-rime fcitx-im kcm-fcitx fcitx-sogoupinyin
	elif [ "${LINUX_DISTRO}" = "void" ]; then
		DEPENDENCY_01="kde"
	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		PLASMAnoSystemd=$(eselect profile list | grep plasma | grep -v systemd | tail -n 1 | cut -d ']' -f 1 | cut -d '[' -f 2)
		eselect profile set ${PLASMAnoSystemd}
		dispatch-conf
		etc-update
		#emerge -auvDN --with-bdeps=y @world
		DEPENDENCY_01="plasma-desktop plasma-nm plasma-pa sddm konsole"
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01="patterns-kde-kde_plasma"
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="plasma-desktop"
		REMOTE_DESKTOP_SESSION='startplasma-x11'
	fi
	####################
	beta_features_quick_install
	apt_purge_libfprint
	configure_vnc_xstartup
}
##################
gnome3_warning() {
	if [ -e "/tmp/.Chroot-Container-Detection-File" ]; then
		echo "检测到您当前可能处于chroot容器环境！"
		echo "${YELLOW}警告！GNOME3可能无法正常运行${RESET}"
	fi

	ps -e >/dev/null 2>&1
	exitstatus=$?
	if [ "${exitstatus}" != "0" ]; then
		echo "检测到您当前可能处于容器环境！"
		echo "${YELLOW}警告！GNOME3可能无法正常运行${RESET}"
		echo "WARNING! 检测到您未挂载/proc分区，请勿安装！"
	fi

	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "${RED}WARNING！${RESET}检测到您当前处于${GREEN}proot容器${RESET}环境下！"
		echo "若您的宿主机为${BOLD}Android${RESET}系统，则${RED}无法${RESET}${BLUE}保障${RESET}GNOME桌面安装后可以正常运行。"
		RETURN_TO_WHERE='other_desktop'
		do_you_want_to_continue
	fi
	#DEPENDENCY_01="plasma-desktop"
	RETURN_TO_WHERE="other_desktop"
	do_you_want_to_continue
}
###############
install_gnome3_desktop() {
	gnome3_warning
	REMOTE_DESKTOP_SESSION_01='gnome-session'
	REMOTE_DESKTOP_SESSION_02='x-window-manager'
	DEPENDENCY_01="gnome"
	echo '即将为您安装思源黑体(中文字体)、gnome-session、gnome-menus、gnome-tweak-tool、gnome-shell和tightvncserver等软件包。'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		#aptitude install -y task-gnome-desktop || apt install -y task-gnome-desktop
		#apt install --no-install-recommends xorg gnome-session gnome-menus gnome-tweak-tool gnome-shell || aptitude install -y gnome-core
		DEPENDENCY_01='--no-install-recommends xorg gnome-session gnome-menus gnome-tweak-tool gnome-shell'
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		#yum groupinstall "GNOME Desktop Environment"
		#dnf groupinstall -y "GNOME" || yum groupinstall -y "GNOME"
		DEPENDENCY_01='--skip-broken @GNOME'

	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01='gnome gnome-extra'

	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		GNOMEnoSystemd=$(eselect profile list | grep gnome | grep -v systemd | tail -n 1 | cut -d ']' -f 1 | cut -d '[' -f 2)
		eselect profile set ${GNOMEnoSystemd}
		#emerge -auvDN --with-bdeps=y @world
		dispatch-conf
		etc-update
		DEPENDENCY_01='gnome-shell gdm gnome-terminal'
	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01='patterns-gnome-gnome_x11'
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="gnome-desktop"
		REMOTE_DESKTOP_SESSION='gnome-session'
	fi
	####################
	beta_features_quick_install
	apt_purge_libfprint
	configure_vnc_xstartup
}
#################
install_cinnamon_desktop() {
	REMOTE_DESKTOP_SESSION_01='cinnamon-launcher'
	REMOTE_DESKTOP_SESSION_02='cinnamon-session'
	DEPENDENCY_01="cinnamon"
	echo '即将为您安装思源黑体(中文字体)、cinnamon和tightvncserver等软件包。'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		auto_select_keyboard_layout
		DEPENDENCY_01="cinnamon cinnamon-desktop-environment"

	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01='--skip-broken @Cinnamon Desktop'

	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="sddm cinnamon xorg"

	elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
		DEPENDENCY_01="gnome-extra/cinnamon gnome-extra/cinnamon-desktop gnome-extra/cinnamon-translations"

	elif [ "${LINUX_DISTRO}" = "suse" ]; then
		DEPENDENCY_01="cinnamon cinnamon-control-center"
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01="adapta-cinnamon"
	fi
	##############
	beta_features_quick_install
	apt_purge_libfprint
	configure_vnc_xstartup
}
####################
deepin_desktop_warning() {
	if [ "${ARCH_TYPE}" != "i386" ] && [ "${ARCH_TYPE}" != "amd64" ]; then
		echo "非常抱歉，深度桌面不支持您当前的架构。"
		echo "建议您在换用x86_64或i386架构的设备后，再来尝试。"
		echo "${YELLOW}警告！deepin桌面可能无法正常运行${RESET}"
		arch_does_not_support
		other_desktop
	fi
}
#################
deepin_desktop_debian() {
	if [ ! -e "/usr/bin/gpg" ]; then
		DEPENDENCY_01="gpg"
		DEPENDENCY_01=""
		echo "${GREEN} ${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
		echo "即将为您安装gpg..."
		${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01}
	fi
	DEPENDENCY_01="deepin-desktop"

	if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
		add-apt-repository ppa:leaeasy/dde
	else
		cd /etc/apt/
		if ! grep -q '^deb.*deepin' sources.list.d/deepin.list 2>/dev/null; then
			cat >/etc/apt/sources.list.d/deepin.list <<-'EOF'
				   #如需使用apt upgrade命令，请禁用deepin软件源,否则将有可能导致系统崩溃。
					deb [by-hash=force] https://mirrors.tuna.tsinghua.edu.cn/deepin unstable main contrib non-free
			EOF
		fi
	fi
	wget https://mirrors.tuna.tsinghua.edu.cn/deepin/project/deepin-keyring.gpg
	gpg --import deepin-keyring.gpg
	gpg --export --armor 209088E7 | apt-key add -
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 425956BB3E31DF51
	echo '即将为您安装思源黑体(中文字体)、dde和tightvncserver等软件包。'
	dpkg --configure -a
	apt update
	auto_select_keyboard_layout
	aptitude install -y dde
	sed -i 's/^deb/#&/g' /etc/apt/sources.list.d/deepin.list
	apt update
}
###############
################
install_deepin_desktop() {
	deepin_desktop_warning
	REMOTE_DESKTOP_SESSION_01='startdde'
	REMOTE_DESKTOP_SESSION_02='x-window-manager'
	DEPENDENCY_01="deepin-desktop"
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		deepin_desktop_debian
		DEPENDENCY_01="dde"

	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01='--skip-broken deepin-desktop'

	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		#pacman -S --noconfirm deepin-kwin
		#pacman -S --noconfirm file-roller evince
		#rm -v ~/.pam_environment 2>/dev/null
		DEPENDENCY_01="deepin deepin-extra lightdm lightdm-deepin-greeter xorg"
	fi
	####################
	beta_features_quick_install
	apt_purge_libfprint
	configure_vnc_xstartup
}
############################
############################
remove_gui() {
	DEPENDENCY_01="xfce lxde mate lxqt cinnamon gnome dde deepin-desktop kde-plasma"
	echo '"xfce" "呜呜，(≧﹏ ≦)您真的要离开我么"  '
	echo '"lxde" "很庆幸能与阁下相遇（；´д｀）ゞ "  '
	echo '"mate" "喔...喔呜...我不舍得你走/(ㄒoㄒ)/~~"  '
	#新功能预告：即将适配非deb系linux的gui卸载功能
	echo "${YELLOW}按回车键确认卸载${RESET}"
	echo 'Press enter to remove,press Ctrl + C to cancel'
	RETURN_TO_WHERE='tmoe_linux_tool_menu'
	do_you_want_to_continue
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		apt purge -y xfce4 xfce4-terminal tightvncserver xfce4-goodies
		apt purge -y dbus-x11
		apt purge -y ^xfce
		#apt purge -y xcursor-themes
		apt purge -y lxde-core lxterminal
		apt purge -y ^lxde
		apt purge -y mate-desktop-environment-core mate-terminal || aptitude purge -y mate-desktop-environment-core 2>/dev/null
		umount .gvfs
		apt purge -y ^gvfs ^udisks
		apt purge -y ^mate
		apt purge -y -y kde-plasma-desktop
		apt purge -y ^kde-plasma
		apt purge -y ^gnome
		apt purge -y ^cinnamon
		apt purge -y dde
		apt autopurge || apt autoremove
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		pacman -Rsc xfce4 xfce4-goodies
		pacman -Rsc mate mate-extra
		pacman -Rsc lxde lxqt
		pacman -Rsc plasma-desktop
		pacman -Rsc gnome gnome-extra
		pacman -Rsc cinnamon
		pacman -Rsc deepin deepin-extra
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		dnf groupremove -y xfce
		dnf groupremove -y mate-desktop
		dnf groupremove -y lxde-desktop
		dnf groupremove -y lxqt
		dnf groupremove -y "KDE" "GNOME" "Cinnamon Desktop"
		dnf remove -y deepin-desktop
	else
		${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
	fi
}
##########################
remove_browser() {
	if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "chromium" --yesno '火狐娘:“虽然知道总有离别时，但我没想到这一天竟然会这么早。虽然很不舍，但还是很感激您曾选择了我。希望我们下次还会再相遇，呜呜...(;´༎ຶД༎ຶ`)”chromium娘：“哼(￢︿̫̿￢☆)，负心人，走了之后就别回来了！o(TヘTo) 。”  ✨请做出您的选择！' 10 60); then
		echo '呜呜...我...我才...才不会为了这点小事而流泪呢！ヽ(*。>Д<)o゜'
		echo "${YELLOW}按回车键确认卸载firefox${RESET}"
		echo 'Press enter to remove firefox,press Ctrl + C to cancel'
		RETURN_TO_WHERE='tmoe_linux_tool_menu'
		do_you_want_to_continue
		${PACKAGES_REMOVE_COMMAND} firefox-esr firefox-esr-l10n-zh-cn
		${PACKAGES_REMOVE_COMMAND} firefox firefox-l10n-zh-cn
		${PACKAGES_REMOVE_COMMAND} firefox-locale-zh-hans
		apt autopurge 2>/dev/null
		#dnf remove -y firefox 2>/dev/null
		#pacman -Rsc firefox 2>/dev/null
		emerge -C firefox-bin firefox 2>/dev/null

	else
		echo '小声嘀咕：“妾身不在的时候，你一定要好好照顾好自己。” '
		echo "${YELLOW}按回车键确认卸载chromium${RESET}"
		echo 'Press enter to confirm uninstall chromium,press Ctrl + C to cancel'
		RETURN_TO_WHERE='tmoe_linux_tool_menu'
		do_you_want_to_continue
		${PACKAGES_REMOVE_COMMAND} chromium chromium-l10n
		apt-mark unhold chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg-extra
		${PACKAGES_REMOVE_COMMAND} chromium-browser chromium-browser-l10n
		apt autopurge
		dnf remove -y chromium 2>/dev/null
		pacman -Rsc chromium 2>/dev/null
		emerge -C chromium 2>/dev/null

	fi
	tmoe_linux_tool_menu
}
#############################################
#############################################
set_default_xfce_icon_theme() {
	dbus-launch xfconf-query -c xsettings -p /Net/IconThemeName -s ${XFCE_ICRO_NAME} 2>/dev/null
}
###############
configure_theme() {
	RETURN_TO_WHERE='configure_theme'
	INSTALL_THEME=$(whiptail --title "桌面环境主题" --menu \
		"您想要下载哪个主题？按方向键选择！下载完成后，您需要手动修改外观设置中的样式和图标。注：您需修改窗口管理器样式才能解决标题栏丢失的问题。\n Which theme do you want to download? " 17 55 7 \
		"1" "ukui:国产优麒麟ukui桌面主题" \
		"2" "win10:kali卧底模式主题" \
		"3" "MacOS:Mojave" \
		"4" "win10x:更新颖的UI设计" \
		"5" "UOS:国产统一操作系统图标包" \
		"6" "breeze:plasma桌面微风gtk+版主题" \
		"7" "Kali:Flat-Remix-Blue主题" \
		"8" "pixel:raspberrypi树莓派" \
		"9" "deepin:深度系统壁纸包" \
		"10" "paper:简约、灵动、现代化的图标包" \
		"11" "papirus:优雅的图标包,基于paper" \
		"12" "arch/elementary/manjaro系统壁纸包" \
		"13" "chameleon:现代化鼠标指针主题" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	########################
	case "${INSTALL_THEME}" in
	0 | "") tmoe_linux_tool_menu ;;
	1) download_ukui_theme ;;
	2) install_kali_undercover ;;
	3) download_macos_mojave_theme ;;
	4) download_win10x_theme ;;
	5) download_uos_icon_theme ;;
	6) install_breeze_theme ;;
	7) download_kali_theme ;;
	8) download_raspbian_pixel_icon_theme ;;
	9) download_deepin_wallpaper ;;
	10) download_paper_icon_theme ;;
	11) download_papirus_icon_theme ;;
	12) download_manjaro_wallpaper ;;
	13) download_chameleon_cursor_theme ;;
	esac
	######################################
	press_enter_to_return
	configure_theme
}
################################
#下载deb包
download_theme_model_01() {
	mkdir -p /tmp/.${THEME_NAME}
	cd /tmp/.${THEME_NAME}
	THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL} | grep '.deb' | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
	THE_LATEST_THEME_LINK="${THEME_URL}${THE_LATEST_THEME_VERSION}"
	echo ${THE_LATEST_THEME_LINK}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_THEME_VERSION}" "${THE_LATEST_THEME_LINK}"
	busybox ar xv ${THE_LATEST_THEME_VERSION}
}
############################
update_icon_caches_model_01() {
	cd /
	tar -Jxvf /tmp/.${THEME_NAME}/data.tar.xz ./usr
	rm -rf /tmp/.${THEME_NAME}
	echo "updating icon caches..."
	echo "正在刷新图标缓存..."
	gtk-update-icon-cache /usr/share/icons/${ICON_NAME} 2>/dev/null &
	tips_of_delete_icon_theme
}
############
download_paper_icon_theme() {
	THEME_NAME='paper_icon_theme'
	ICON_NAME='Paper /usr/share/icons/Paper-Mono-Dark'
	GREP_NAME='paper-icon-theme'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/manjaro/pool/overlay/'
	download_theme_model_02
	update_icon_caches_model_02
	XFCE_ICRO_NAME='Paper'
	set_default_xfce_icon_theme
}
#############
download_papirus_icon_theme() {
	THEME_NAME='papirus_icon_theme'
	ICON_NAME='Papirus /usr/share/icons/Papirus-Dark /usr/share/icons/Papirus-Light /usr/share/icons/ePapirus'
	GREP_NAME='papirus-icon-theme'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/p/papirus-icon-theme/'
	download_theme_model_01
	update_icon_caches_model_01
	XFCE_ICRO_NAME='Papirus'
	set_default_xfce_icon_theme
}
############################
tips_of_delete_icon_theme() {
	echo "解压${BLUE}完成${RESET}，如需${RED}删除${RESET}，请手动输${YELLOW}rm -rf /usr/share/icons/${ICON_NAME} ${RESET}"
}
###################
update_icon_caches_model_02() {
	tar -Jxvf /tmp/.${THEME_NAME}/${THE_LATEST_THEME_VERSION} 2>/dev/null
	cp -rf usr /
	cd /
	rm -rf /tmp/.${THEME_NAME}
	echo "updating icon caches..."
	echo "正在刷新图标缓存..."
	gtk-update-icon-cache /usr/share/icons/${ICON_NAME} 2>/dev/null &
	tips_of_delete_icon_theme
}
###############
#tar.xz
download_theme_model_02() {
	mkdir -p /tmp/.${THEME_NAME}
	cd /tmp/.${THEME_NAME}
	THE_LATEST_THEME_VERSION="$(curl -L ${THEME_URL} | grep -v '.xz.sig' | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
	THE_LATEST_THEME_LINK="${THEME_URL}${THE_LATEST_THEME_VERSION}"
	echo ${THE_LATEST_THEME_LINK}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_THEME_VERSION}" "${THE_LATEST_THEME_LINK}"
}
####################
download_raspbian_pixel_icon_theme() {
	THEME_NAME='raspbian_pixel_icon_theme'
	ICON_NAME='PiX'
	GREP_NAME='all.deb'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/raspberrypi/pool/ui/p/pix-icons/'
	download_theme_model_01
	update_icon_caches_model_01
	download_raspbian_pixel_wallpaper
}
################
move_wallpaper_model_01() {
	tar -Jxvf data.tar.xz 2>/dev/null
	if [ -d "${HOME}/图片" ]; then
		mv ./usr/share/${WALLPAPER_NAME} ${HOME}/图片/${CUSTOM_WALLPAPER_NAME}
	else
		mkdir -p ${HOME}/Pictures
		mv ./usr/share/${WALLPAPER_NAME} ${HOME}/Pictures/${CUSTOM_WALLPAPER_NAME}
	fi
	rm -rf /tmp/.${THEME_NAME}
	echo "壁纸包已经保存至${HOME}/图片/${CUSTOM_WALLPAPER_NAME}"
}
#################
download_raspbian_pixel_wallpaper() {
	THEME_NAME='raspberrypi_pixel_wallpaper'
	WALLPAPER_NAME='pixel-wallpaper'
	CUSTOM_WALLPAPER_NAME='raspberrypi-pixel-wallpapers'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/raspberrypi/pool/ui/p/pixel-wallpaper/'
	download_theme_model_01
	move_wallpaper_model_01
	XFCE_ICRO_NAME='PiX'
	set_default_xfce_icon_theme
}
########
download_deepin_wallpaper() {
	THEME_NAME='deepin-wallpapers'
	WALLPAPER_NAME='wallpapers/deepin'
	GREP_NAME='deepin-community-wallpapers'
	CUSTOM_WALLPAPER_NAME='deepin-community-wallpapers'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/deepin/pool/main/d/deepin-wallpapers/'
	download_theme_model_01
	move_wallpaper_model_01
	GREP_NAME='deepin-wallpapers_'
	CUSTOM_WALLPAPER_NAME='deepin-wallpapers'
	download_theme_model_01
	move_wallpaper_model_01
}
##########
download_manjaro_pkg() {
	mkdir -p /tmp/.${THEME_NAME}
	cd /tmp/.${THEME_NAME}
	echo "${THEME_URL}"
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'data.tar.xz' "${THEME_URL}"
}
############
link_to_debian_wallpaper() {
	if [ -e "/usr/share/backgrounds/kali/" ]; then
		if [ -d "${HOME}/图片" ]; then
			ln -sf /usr/share/backgrounds/kali/ ${HOME}/图片/kali
		else
			mkdir -p ${HOME}/Pictures
			ln -sf /usr/share/backgrounds/kali/ ${HOME}/Pictures/kali
		fi
	fi
	#########
	DEBIAN_MOONLIGHT='/usr/share/desktop-base/moonlight-theme/wallpaper/contents/images/'
	if [ -e "${DEBIAN_MOONLIGHT}" ]; then
		if [ -d "${HOME}/图片" ]; then
			ln -sf ${DEBIAN_MOONLIGHT} ${HOME}/图片/debian-moonlight
		else
			ln -sf ${DEBIAN_MOONLIGHT} ${HOME}/Pictures/debian-moonlight
		fi
	fi
	DEBIAN_LOCK_SCREEN='/usr/share/desktop-base/lines-theme/lockscreen/contents/images/'
	if [ -e "${DEBIAN_LOCK_SCREEN}" ]; then
		if [ -d "${HOME}/图片" ]; then
			ln -sf ${DEBIAN_LOCK_SCREEN} ${HOME}/图片/debian-lockscreen
		else
			ln -sf ${DEBIAN_LOCK_SCREEN} ${HOME}/Pictures/debian-lockscreen
		fi
	fi
}
#########
download_manjaro_wallpaper() {
	THEME_NAME='manjaro-2018'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/manjaro/pool/overlay/wallpapers-2018-1.2-1-any.pkg.tar.xz'
	download_manjaro_pkg
	WALLPAPER_NAME='backgrounds/wallpapers-2018'
	CUSTOM_WALLPAPER_NAME='manjaro-2018'
	move_wallpaper_model_01
	##############
	THEME_NAME='manjaro-2017'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/manjaro/pool/overlay/manjaro-sx-wallpapers-20171023-1-any.pkg.tar.xz'
	download_manjaro_pkg
	WALLPAPER_NAME='backgrounds'
	CUSTOM_WALLPAPER_NAME='manjaro-2017'
	move_wallpaper_model_01
	##################
	link_to_debian_wallpaper
	download_arch_wallpaper
}
#########
grep_arch_linux_pkg() {
	ARCH_WALLPAPER_VERSION=$(cat index.html | grep -v '.xz.sig' | egrep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	ARCH_WALLPAPER_URL="${THEME_URL}${ARCH_WALLPAPER_VERSION}"
	echo "${ARCH_WALLPAPER_URL}"
	aria2c --allow-overwrite=true -o data.tar.xz -x 5 -s 5 -k 1M ${ARCH_WALLPAPER_URL}
}
download_arch_wallpaper() {
	mkdir -p /tmp/.arch_and_elementary
	cd /tmp/.arch_and_elementary
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/archlinux/pool/community/'
	aria2c --allow-overwrite=true -o index.html "${THEME_URL}"
	#https://mirrors.tuna.tsinghua.edu.cn/archlinux/pool/community/archlinux-wallpaper-1.4-6-any.pkg.tar.xz
	GREP_NAME='archlinux-wallpaper'
	grep_arch_linux_pkg
	THEME_NAME=${GREP_NAME}
	WALLPAPER_NAME='backgrounds/archlinux'
	CUSTOM_WALLPAPER_NAME='archlinux'
	move_wallpaper_model_01
	#https://mirrors.tuna.tsinghua.edu.cn/archlinux/pool/community/elementary-wallpapers-5.5.0-1-any.pkg.tar.xz
	GREP_NAME='elementary-wallpapers'
	grep_arch_linux_pkg
	THEME_NAME='arch_and_elementary'
	WALLPAPER_NAME='wallpapers/elementary'
	CUSTOM_WALLPAPER_NAME='elementary'
	move_wallpaper_model_01
	#elementary-wallpapers-5.5.0-1-any.pkg.tar.xz
}
################
download_kali_themes_common() {
	THEME_NAME='kali-themes-common'
	GREP_NAME='kali-themes-common'
	ICON_NAME='Flat-Remix-Blue-Dark /usr/share/icons/Flat-Remix-Blue-Light /usr/share/icons/desktop-base'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-themes/'
	download_theme_model_01
	update_icon_caches_model_01
}
####################
download_kali_theme() {
	if [ ! -e "/usr/share/desktop-base/kali-theme" ]; then
		download_kali_themes_common
	else
		echo "检测到kali_themes_common已下载，是否重新下载？"
		do_you_want_to_continue
		download_kali_themes_common
	fi
	echo "Download completed.如需删除，请手动输rm -rf /usr/share/desktop-base/kali-theme /usr/share/icons/desktop-base /usr/share/icons/Flat-Remix-Blue-Light /usr/share/icons/Flat-Remix-Blue-Dark"
	XFCE_ICRO_NAME='Flat-Remix-Blue-Light'
	set_default_xfce_icon_theme
}
##################
download_win10x_theme() {
	if [ -d "/usr/share/icons/We10X-dark" ]; then
		echo "检测到图标包已下载，是否重新下载？"
		RETURN_TO_WHERE='configure_theme'
		do_you_want_to_continue
	fi

	if [ -d "/tmp/.WINDOWS_10X_ICON_THEME" ]; then
		rm -rf /tmp/.WINDOWS_10X_ICON_THEME
	fi

	git clone -b win10x --depth=1 https://gitee.com/mo2/xfce-themes.git /tmp/.WINDOWS_10X_ICON_THEME
	cd /tmp/.WINDOWS_10X_ICON_THEME
	GITHUB_URL=$(cat url.txt)
	tar -Jxvf We10X.tar.xz -C /usr/share/icons 2>/dev/null
	gtk-update-icon-cache /usr/share/icons/We10X-dark /usr/share/icons/We10X 2>/dev/null &
	echo ${GITHUB_URL}
	rm -rf /tmp/McWe10X
	echo "Download completed.如需删除，请手动输rm -rf /usr/share/icons/We10X-dark /usr/share/icons/We10X"
	XFCE_ICRO_NAME='We10X'
	set_default_xfce_icon_theme
}
###################
download_uos_icon_theme() {
	DEPENDENCY_01="deepin-icon-theme"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install

	if [ -d "/usr/share/icons/Uos" ]; then
		echo "检测到Uos图标包已下载，是否继续。"
		RETURN_TO_WHERE='configure_theme'
		do_you_want_to_continue
	fi

	if [ -d "/tmp/UosICONS" ]; then
		rm -rf /tmp/UosICONS
	fi

	git clone -b Uos --depth=1 https://gitee.com/mo2/xfce-themes.git /tmp/UosICONS
	cd /tmp/UosICONS
	GITHUB_URL=$(cat url.txt)
	tar -Jxvf Uos.tar.xz -C /usr/share/icons 2>/dev/null
	gtk-update-icon-cache /usr/share/icons/Uos 2>/dev/null &
	echo ${GITHUB_URL}
	rm -rf /tmp/UosICONS
	echo "Download completed.如需删除，请手动输rm -rf /usr/share/icons/Uos ; ${PACKAGES_REMOVE_COMMAND} deepin-icon-theme"
	XFCE_ICRO_NAME='Uos'
	set_default_xfce_icon_theme
}
#####################
download_macos_mojave_theme() {
	if [ -d "/usr/share/themes/Mojave-dark" ]; then
		echo "检测到主题已下载，是否重新下载？"
		RETURN_TO_WHERE='configure_theme'
		do_you_want_to_continue
	fi

	if [ -d "/tmp/McMojave" ]; then
		rm -rf /tmp/McMojave
	fi

	git clone -b McMojave --depth=1 https://gitee.com/mo2/xfce-themes.git /tmp/McMojave
	cd /tmp/McMojave
	GITHUB_URL=$(cat url.txt)
	tar -Jxvf 01-Mojave-dark.tar.xz -C /usr/share/themes 2>/dev/null
	tar -Jxvf 01-McMojave-circle.tar.xz -C /usr/share/icons 2>/dev/null
	gtk-update-icon-cache /usr/share/icons/McMojave-circle-dark /usr/share/icons/McMojave-circle 2>/dev/null &
	echo ${GITHUB_URL}
	rm -rf /tmp/McMojave
	echo "Download completed.如需删除，请手动输rm -rf /usr/share/themes/Mojave-dark /usr/share/icons/McMojave-circle-dark /usr/share/icons/McMojave-circle"
	XFCE_ICRO_NAME='McMojave-circle'
	set_default_xfce_icon_theme
}
#######################
download_ukui_theme() {
	DEPENDENCY_01="ukui-themes"
	DEPENDENCY_02="ukui-greeter"
	NON_DEBIAN='false'
	beta_features_quick_install

	if [ ! -e '/usr/share/icons/ukui-icon-theme-default' ] && [ ! -e '/usr/share/icons/ukui-icon-theme' ]; then
		mkdir -p /tmp/.ukui-gtk-themes
		cd /tmp/.ukui-gtk-themes
		UKUITHEME="$(curl -LfsS 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/u/ukui-themes/' | grep all.deb | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'ukui-themes.deb' "https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/u/ukui-themes/${UKUITHEME}"
		busybox ar xv 'ukui-themes.deb'
		cd /
		tar -Jxvf /tmp/.ukui-gtk-themes/data.tar.xz ./usr
		#if which gtk-update-icon-cache >/dev/null 2>&1; then
		gtk-update-icon-cache /usr/share/icons/ukui-icon-theme-basic /usr/share/icons/ukui-icon-theme-classical /usr/share/icons/ukui-icon-theme-default 2>/dev/null &
		gtk-update-icon-cache /usr/share/icons/ukui-icon-theme 2>/dev/null &
		#fi
		rm -rf /tmp/.ukui-gtk-themes
		#apt install -y ./ukui-themes.deb
		#rm -f ukui-themes.deb
		#apt install -y ukui-greeter
	else
		echo '请前往外观设置手动修改图标'
	fi
	XFCE_ICRO_NAME='ukui-icon-theme'
	set_default_xfce_icon_theme
	#gtk-update-icon-cache /usr/share/icons/ukui-icon-theme/ 2>/dev/null
	#echo "安装完成，如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} ukui-themes"
}
#################################
install_breeze_theme() {
	DEPENDENCY_01="breeze-icon-theme"
	DEPENDENCY_02="breeze-cursor-theme breeze-gtk-theme xfwm4-theme-breeze"
	NON_DEBIAN='false'
	mkdir -p /tmp/.breeze_theme
	cd /tmp/.breeze_theme
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/any/'
	curl -Lo index.html ${THEME_URL}
	GREP_NAME='breeze-adapta-cursor-theme-git'
	grep_arch_linux_pkg
	tar -Jxvf data.tar.xz 2>/dev/null
	cp -rf usr /
	rm -rf /tmp/.breeze_theme
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="breeze-icons breeze-gtk"
		DEPENDENCY_02="xfwm4-theme-breeze capitaine-cursors"
		if [ $(command -v grub-install) ]; then
			DEPENDENCY_02="${DEPENDENCY_02} breeze-grub"
		fi
	fi
	beta_features_quick_install
}
#################
download_chameleon_cursor_theme() {
	THEME_NAME='breeze-cursor-theme'
	GREP_NAME="${THEME_NAME}"
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/b/breeze/'
	download_theme_model_01
	upcompress_deb_file
	#############
	GREP_NAME='all'
	THEME_NAME='chameleon-cursor-theme'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/c/chameleon-cursor-theme/'
	download_theme_model_01
	upcompress_deb_file
	##############
	THEME_NAME='moblin-cursor-theme'
	THEME_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/m/moblin-cursor-theme/'
	download_theme_model_01
	upcompress_deb_file
	##########
}
##########
upcompress_deb_file() {
	if [ -e "data.tar.xz" ]; then
		cd /
		tar -Jxvf /tmp/.${THEME_NAME}/data.tar.xz ./usr
	elif [ -e "data.tar.gz" ]; then
		cd /
		tar -zxvf /tmp/.${THEME_NAME}/data.tar.gz ./usr
	fi
	rm -rf /tmp/.${THEME_NAME}
}
####################
install_kali_undercover() {
	if [ -e "/usr/share/icons/Windows-10-Icons" ]; then
		echo "检测到您已安装win10主题"
		echo "如需移除，请手动输${PACKAGES_REMOVE_COMMAND} kali-undercover;rm -rf /usr/share/icons/Windows-10-Icons"
		echo "是否重新下载？"
		RETURN_TO_WHERE='configure_theme'
		do_you_want_to_continue
	fi
	DEPENDENCY_01="kali-undercover"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		beta_features_quick_install
	fi
	#此处需做两次判断
	if [ "${DEBIAN_DISTRO}" = "kali" ]; then
		beta_features_quick_install
	else
		mkdir -p /tmp/.kali-undercover-win10-theme
		cd /tmp/.kali-undercover-win10-theme
		UNDERCOVERlatestLINK="$(curl -LfsS 'https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-undercover/' | grep all.deb | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o kali-undercover.deb "https://mirrors.tuna.tsinghua.edu.cn/kali/pool/main/k/kali-undercover/${UNDERCOVERlatestLINK}"
		apt show ./kali-undercover.deb
		apt install -y ./kali-undercover.deb
		if [ ! -e "/usr/share/icons/Windows-10-Icons" ]; then
			busybox ar xv kali-undercover.deb
			cd /
			tar -Jxvf /tmp/.kali-undercover-win10-theme/data.tar.xz ./usr
			#if which gtk-update-icon-cache >/dev/null 2>&1; then
			gtk-update-icon-cache /usr/share/icons/Windows-10-Icons 2>/dev/null &
			#fi
		fi
		rm -rf /tmp/.kali-undercover-win10-theme
		#rm -f ./kali-undercover.deb
	fi
	#XFCE_ICRO_NAME='Windows 10'
}
#################
check_tmoe_sources_list_backup_file() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		SOURCES_LIST_PATH="/etc/apt/"
		SOURCES_LIST_FILE="/etc/apt/sources.list"
		SOURCES_LIST_FILE_NAME="sources.list"
		SOURCES_LIST_BACKUP_FILE="${HOME}/.config/tmoe-linux/sources.list.bak"
		SOURCES_LIST_BACKUP_FILE_NAME="sources.list.bak"
		EXTRA_SOURCE='debian更换为kali源'
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		SOURCES_LIST_PATH="/etc/pacman.d/"
		SOURCES_LIST_FILE="/etc/pacman.d/mirrorlist"
		SOURCES_LIST_FILE_NAME="mirrorlist"
		SOURCES_LIST_BACKUP_FILE="${HOME}/.config/tmoe-linux/pacman.d_mirrorlist.bak"
		SOURCES_LIST_BACKUP_FILE_NAME="pacman.d_mirrorlist.bak"
		EXTRA_SOURCE='archlinux_cn源'
		SOURCES_LIST_FILE_02="/etc/pacman.conf"
		SOURCES_LIST_BACKUP_FILE_02="${HOME}/.config/tmoe-linux/pacman.conf.bak"
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		SOURCES_LIST_PATH="/etc/apk/"
		SOURCES_LIST_FILE="/etc/apk/repositories"
		SOURCES_LIST_FILE_NAME="repositories"
		SOURCES_LIST_BACKUP_FILE="${HOME}/.config/tmoe-linux/alpine_repositories.bak"
		SOURCES_LIST_BACKUP_FILE_NAME="alpine_repositories.bak"
		EXTRA_SOURCE='alpine额外源'
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		SOURCES_LIST_PATH="/etc/yum.repos.d"
		SOURCES_LIST_BACKUP_FILE="${HOME}/.config/tmoe-linux/yum.repos.d-backup.tar.gz"
		SOURCES_LIST_BACKUP_FILE_NAME="yum.repos.d-backup.tar.gz"
		EXTRA_SOURCE='epel源'
	else
		EXTRA_SOURCE='不支持修改${LINUX_DISTRO}源'
	fi

	if [ ! -e "${SOURCES_LIST_BACKUP_FILE}" ]; then
		mkdir -p "${HOME}/.config/tmoe-linux"
		if [ "${LINUX_DISTRO}" = "redhat" ]; then
			tar -Ppzcvf ${SOURCES_LIST_BACKUP_FILE} ${SOURCES_LIST_PATH}
		else
			cp -pf "${SOURCES_LIST_FILE}" "${SOURCES_LIST_BACKUP_FILE}"
		fi
	fi

	if [ "${LINUX_DISTRO}" = "arch" ]; then
		if [ ! -e "${SOURCES_LIST_BACKUP_FILE_02}" ]; then
			cp -pf "${SOURCES_LIST_FILE_02}" "${SOURCES_LIST_BACKUP_FILE_02}"
		fi
	fi
}
##########
modify_alpine_mirror_repositories() {
	ALPINE_VERSION=$(cat /etc/os-release | grep 'PRETTY_NAME=' | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2 | awk -F ' ' '$0=$NF')
	cd /etc/apk/
	if [ ! -z ${ALPINE_VERSION} ]; then
		sed -i 's@http@#&@g' repositories
		cat >>repositories <<-ENDofRepositories
			http://${SOURCE_MIRROR_STATION}/alpine/${ALPINE_VERSION}/main
			http://${SOURCE_MIRROR_STATION}/alpine/${ALPINE_VERSION}/community
		ENDofRepositories
	else
		sed -i "s@^http.*/alpine/@http://${SOURCE_MIRROR_STATION}/alpine/@g" repositories
	fi
	${PACKAGES_UPDATE_COMMAND}
	apk upgrade
}
############################################
auto_check_distro_and_modify_sources_list() {
	if [ ! -z "${SOURCE_MIRROR_STATION}" ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			check_debian_distro_and_modify_sources_list
		elif [ "${LINUX_DISTRO}" = "arch" ]; then
			check_arch_distro_and_modify_mirror_list
		elif [ "${LINUX_DISTRO}" = "alpine" ]; then
			modify_alpine_mirror_repositories
		elif [ "${REDHAT_DISTRO}" = "fedora" ]; then
			check_fedora_version
		else
			echo "Sorry,本功能不支持${LINUX_DISTRO}"
		fi
	fi
	################
	press_enter_to_return
}
##############################
china_university_mirror_station() {
	SOURCE_MIRROR_STATION=""
	RETURN_TO_WHERE='china_university_mirror_station'
	SOURCES_LIST=$(
		whiptail --title "软件源列表" --menu \
			"您想要切换为哪个镜像源呢？目前仅支持debian,ubuntu,kali,arch,manjaro,fedora和alpine" 17 55 7 \
			"1" "清华大学mirrors.tuna.tsinghua.edu.cn" \
			"2" "中国科学技术大学mirrors.ustc.edu.cn" \
			"3" "浙江大学mirrors.zju.edu.cn" \
			"4" "上海交通大学mirrors.zju.edu.cn" \
			"5" "北京外国语大学mirrors.bfsu.edu.cn" \
			"6" "华中科技大学mirrors.hust.edu.cn" \
			"7" "北京理工大学mirror.bit.edu.cn" \
			"8" "北京交通大学mirror.bjtu.edu.cn" \
			"9" "兰州大学mirror.lzu.edu.cn" \
			"10" "大连东软信息学院mirrors.neusoft.edu.cn" \
			"11" "南京大学mirrors.nju.edu.cn" \
			"12" "南京邮电大学mirrors.njupt.edu.cn" \
			"13" "西北农林科技大学mirrors.nwafu.edu.cn" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	########################
	case "${SOURCES_LIST}" in
	0 | "") tmoe_sources_list_manager ;;
	1) SOURCE_MIRROR_STATION='mirrors.tuna.tsinghua.edu.cn' ;;
	2) SOURCE_MIRROR_STATION='mirrors.ustc.edu.cn' ;;
	3) SOURCE_MIRROR_STATION='mirrors.zju.edu.cn' ;;
	4) SOURCE_MIRROR_STATION='mirror.sjtu.edu.cn' ;;
	5) SOURCE_MIRROR_STATION='mirrors.bfsu.edu.cn' ;;
	6) SOURCE_MIRROR_STATION='mirrors.hust.edu.cn' ;;
	7) SOURCE_MIRROR_STATION='mirror.bit.edu.cn' ;;
	8) SOURCE_MIRROR_STATION='mirror.bjtu.edu.cn' ;;
	9) SOURCE_MIRROR_STATION='mirror.lzu.edu.cn' ;;
	10) SOURCE_MIRROR_STATION='mirrors.neusoft.edu.cn' ;;
	11) SOURCE_MIRROR_STATION='mirrors.nju.edu.cn' ;;
	12) SOURCE_MIRROR_STATION='mirrors.njupt.edu.cn' ;;
	13) SOURCE_MIRROR_STATION='mirrors.nwafu.edu.cn' ;;
	esac
	######################################
	auto_check_distro_and_modify_sources_list
	##########
	china_university_mirror_station
}
#############
china_bussiness_mirror_station() {
	SOURCE_MIRROR_STATION=""
	RETURN_TO_WHERE='china_bussiness_mirror_station'
	SOURCES_LIST=$(
		whiptail --title "软件源列表" --menu \
			"您想要切换为哪个镜像源呢？目前仅支持debian,ubuntu,kali,arch,manjaro,fedora和alpine" 15 55 5 \
			"1" "华为云mirrors.huaweicloud.com" \
			"2" "阿里云mirrors.aliyun.com" \
			"3" "网易mirrors.163.com" \
			"4" "中国互联网络信息中心mirrors.cnnic.cn" \
			"5" "搜狐mirrors.sohu.com" \
			"6" "首都在线mirrors.yun-idc.com" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	########################
	case "${SOURCES_LIST}" in
	0 | "") tmoe_sources_list_manager ;;
	1) SOURCE_MIRROR_STATION='mirrors.huaweicloud.com' ;;
	2) SOURCE_MIRROR_STATION='mirrors.aliyun.com' ;;
	3) SOURCE_MIRROR_STATION='mirrors.163.com' ;;
	4) SOURCE_MIRROR_STATION='mirrors.cnnic.cn' ;;
	5) SOURCE_MIRROR_STATION='mirrors.sohu.com' ;;
	6) SOURCE_MIRROR_STATION='mirrors.yun-idc.com' ;;
	esac
	######################################
	auto_check_distro_and_modify_sources_list
	china_bussiness_mirror_station
}
###########
tmoe_sources_list_manager() {
	check_tmoe_sources_list_backup_file
	SOURCE_MIRROR_STATION=""
	RETURN_TO_WHERE='tmoe_sources_list_manager'
	SOURCES_LIST=$(
		whiptail --title "software-sources tmoe-manager" --menu \
			"您想要对软件源进行何种管理呢？" 17 55 7 \
			"1" "国内高校镜像源" \
			"2" "国内商业镜像源" \
			"3" "镜像站延迟测试" \
			"4" "镜像站下载速度测试" \
			"5" "restore to default还原默认源" \
			"6" "edit list manually手动编辑" \
			"7" "${EXTRA_SOURCE}" \
			"8" "FAQ常见问题" \
			"9" "切换http与https" \
			"10" "去除无效行" \
			"11" "强制信任软件源" \
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	########################
	case "${SOURCES_LIST}" in
	0 | "") tmoe_linux_tool_menu ;;
	1) china_university_mirror_station ;;
	2) china_bussiness_mirror_station ;;
	3) ping_mirror_sources_list ;;
	4) mirror_sources_station_download_speed_test ;;
	5) restore_default_sources_list ;;
	6) edit_sources_list_manually ;;
	7) add_extra_source_list ;;
	8) sources_list_faq ;;
	9) switch_sources_http_and_https ;;
	10) delete_sources_list_invalid_rows ;;
	11) mandatory_trust_software_sources ;;
	esac
	##########
	press_enter_to_return
	tmoe_sources_list_manager
}
######################
mandatory_trust_software_sources() {
	if (whiptail --title "您想要对这个小可爱做什么 " --yes-button "trust" --no-button "untrust" --yesno "您是想要强制信任还是取消信任呢？♪(^∇^*) " 10 50); then
		trust_sources_list
	else
		untrust_sources_list
	fi
	${PACKAGES_UPDATE_COMMAND}
}
##############
untrust_sources_list() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		sed -i 's@^deb.*http@deb http@g' /etc/apt/sources.list
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		sed -i 's@SigLevel = Never@#SigLevel = Optional TrustAll@' "/etc/pacman.conf"
	else
		EXTRA_SOURCE='不支持修改${LINUX_DISTRO}源'
	fi
}
#######################
trust_sources_list() {
	echo "执行此操作可能会有未知风险"
	do_you_want_to_continue
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		sed -i 's@^deb.*http@deb [trusted=yes] http@g' /etc/apt/sources.list
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		sed -i 's@^#SigLevel.*@SigLevel = Never@' "/etc/pacman.conf"
	else
		EXTRA_SOURCE='不支持修改${LINUX_DISTRO}源'
	fi
}
#####################
delete_sources_list_invalid_rows() {
	echo "执行此操作将删除软件源列表内的所有注释行,并自动去除重复行"
	do_you_want_to_continue
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		sed -i '/^#/d' ${SOURCES_LIST_FILE}
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		sed -i '/^#Server.*=/d' ${SOURCES_LIST_FILE}
	elif [ "${LINUX_DISTRO}" = "alpine" ]; then
		sed -i '/^#.*http/d' ${SOURCES_LIST_FILE}
	else
		EXTRA_SOURCE='不支持修改${LINUX_DISTRO}源'
	fi
	sort -u ${SOURCES_LIST_FILE} -o ${SOURCES_LIST_FILE}
	${PACKAGES_UPDATE_COMMAND}
}
###################
sources_list_faq() {
	echo "若换源后更新软件数据库失败，则请切换为http源"
	if [ "${LINUX_DISTRO}" = "debian" ] || [ "${LINUX_DISTRO}" = "arch" ]; then
		echo "然后选择强制信任软件源的功能。"
	fi
	echo "若再次出错，则请更换为其它镜像源。"
}
################
switch_sources_list_to_http() {
	if [ "${LINUX_DISTRO}" = "redhat" ]; then
		sed -i 's@https://@http://@g' ${SOURCES_LIST_PATH}/*repo
	else
		sed -i 's@https://@http://@g' ${SOURCES_LIST_FILE}
	fi
}
######################
switch_sources_list_to_http_tls() {
	if [ "${LINUX_DISTRO}" = "redhat" ]; then
		sed -i 's@http://@https://@g' ${SOURCES_LIST_PATH}/*repo
	else
		sed -i 's@http://@https://@g' ${SOURCES_LIST_FILE}
	fi
}
#################
switch_sources_http_and_https() {
	if (whiptail --title "您想要对这个小可爱做什么 " --yes-button "http" --no-button "https" --yesno "您是想要将软件源切换为http还是https呢？♪(^∇^*) " 10 50); then
		switch_sources_list_to_http
	else
		switch_sources_list_to_http_tls
	fi
	${PACKAGES_UPDATE_COMMAND}
}
###################
check_fedora_version() {
	FEDORA_VERSION="$(cat /etc/os-release | grep 'VERSION_ID' | cut -d '=' -f 2)"
	if ((${FEDORA_VERSION} >= 30)); then
		if ((${FEDORA_VERSION} >= 32)); then
			fedora_32_repos
		else
			fedora_31_repos
		fi
		fedora_3x_repos
		#${PACKAGES_UPDATE_COMMAND}
		dnf makecache
	else
		echo "Sorry,不支持fedora29及其以下的版本"
	fi
}
######################
add_extra_source_list() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		modify_to_kali_sources_list
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		add_arch_linux_cn_mirror_list
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		add_fedora_epel_yum_repo
	else
		non_debian_function
	fi
}
################
add_fedora_epel_yum_repo() {
	dnf install -y epel-release || yum install -y epel-release
	cp -pvf /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
	cp -pvf /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup
	sed -e 's!^metalink=!#metalink=!g' \
		-e 's!^#baseurl=!baseurl=!g' \
		-e 's!//download\.fedoraproject\.org/pub!//mirrors.tuna.tsinghua.edu.cn!g' \
		-e 's!http://mirrors\.tuna!https://mirrors.tuna!g' \
		-i /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel-testing.repo
}
###############
add_arch_linux_cn_mirror_list() {
	if ! grep -q 'archlinuxcn' /etc/pacman.conf; then
		cat >>/etc/pacman.conf <<-'Endofpacman'
			[archlinuxcn]
			Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
		Endofpacman
		pacman -Syu --noconfirm archlinux-keyring
		pacman -Sy --noconfirm archlinuxcn-keyring
	else
		echo "检测到您已添加archlinux_cn源"
	fi

	if [ ! $(command -v yay) ]; then
		pacman -S --noconfirm yay
		yay --aururl "https://aur.tuna.tsinghua.edu.cn" --save
	fi
}
###############
check_debian_distro_and_modify_sources_list() {
	if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
		modify_ubuntu_mirror_sources_list
	elif [ "${DEBIAN_DISTRO}" = "kali" ]; then
		modify_kali_mirror_sources_list
	else
		modify_debian_mirror_sources_list
	fi
	check_ca_certificates_and_apt_update
}
##############
check_arch_distro_and_modify_mirror_list() {
	sed -i 's/^Server/#&/g' /etc/pacman.d/mirrorlist
	if [ "$(cat /etc/issue | cut -c 1-4)" = "Arch" ]; then
		modify_archlinux_mirror_list
	elif [ "$(cat /etc/issue | cut -c 1-7)" = "Manjaro" ]; then
		modify_manjaro_mirror_list
	fi
	#${PACKAGES_UPDATE_COMMAND}
	pacman -Syyu
}
##############
modify_manjaro_mirror_list() {
	if [ "${ARCH_TYPE}" = "arm64" ] || [ "${ARCH_TYPE}" = "armhf" ]; then
		cat >>/etc/pacman.d/mirrorlist <<-EndOfArchMirrors
			#Server = https://${SOURCE_MIRROR_STATION}/archlinuxarm/\$arch/\$repo
			Server = https://${SOURCE_MIRROR_STATION}/manjaro/arm-stable/\$repo/\$arch
		EndOfArchMirrors
	else
		cat >>/etc/pacman.d/mirrorlist <<-EndOfArchMirrors
			#Server = https://${SOURCE_MIRROR_STATION}/archlinux/\$repo/os/\$arch
			Server = https://${SOURCE_MIRROR_STATION}/manjaro/stable/\$repo/\$arch
		EndOfArchMirrors
	fi
}
###############
modify_archlinux_mirror_list() {
	if [ "${ARCH_TYPE}" = "arm64" ] || [ "${ARCH_TYPE}" = "armhf" ]; then
		cat >>/etc/pacman.d/mirrorlist <<-EndOfArchMirrors
			#Server = https://mirror.archlinuxarm.org/\$arch/\$repo
			Server = https://${SOURCE_MIRROR_STATION}/archlinuxarm/\$arch/\$repo
		EndOfArchMirrors
	else
		cat >>/etc/pacman.d/mirrorlist <<-EndOfArchMirrors
			#Server = http://mirrors.kernel.org/archlinux/\$repo/os/\$arch
			Server = https://${SOURCE_MIRROR_STATION}/archlinux/\$repo/os/\$arch
		EndOfArchMirrors
	fi
}
###############
edit_sources_list_manually() {
	if [ ! $(command -v nano) ]; then
		DEPENDENCY_01='nano'
		DEPENDENCY_02=""
		NON_DEBIAN='false'
		beta_features_quick_install
	fi
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		apt edit-sources || nano ${SOURCES_LIST_FILE}
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		nano ${SOURCES_LIST_PATH}/*repo
	else
		nano ${SOURCES_LIST_FILE}
	fi
}
##########
download_debian_ls_lr() {
	echo ${BLUE}${SOURCE_MIRROR_STATION_NAME}${RESET}
	DOWNLOAD_FILE_URL="https://${SOURCE_MIRROR_STATION}/debian/ls-lR.gz"
	echo "${YELLOW}${DOWNLOAD_FILE_URL}${RESET}"
	aria2c --allow-overwrite=true -o ".tmoe_netspeed_test_${SOURCE_MIRROR_STATION_NAME}_temp_file" "${DOWNLOAD_FILE_URL}"
	rm -f ".tmoe_netspeed_test_${SOURCE_MIRROR_STATION_NAME}_temp_file"
	echo "---------------------------"
}
################
mirror_sources_station_download_speed_test() {
	echo "此操作可能会消耗您数十至上百兆的流量"
	press_enter_to_continue
	cd /tmp
	echo "---------------------------"
	SOURCE_MIRROR_STATION_NAME='清华镜像站'
	SOURCE_MIRROR_STATION='mirrors.tuna.tsinghua.edu.cn'
	download_debian_ls_lr
	SOURCE_MIRROR_STATION_NAME='中科大镜像站'
	SOURCE_MIRROR_STATION='mirrors.ustc.edu.cn'
	download_debian_ls_lr
	SOURCE_MIRROR_STATION_NAME='上海交大镜像站'
	SOURCE_MIRROR_STATION='mirror.sjtu.edu.cn'
	download_debian_ls_lr
	SOURCE_MIRROR_STATION_NAME='北外镜像站'
	SOURCE_MIRROR_STATION='mirrors.bfsu.edu.cn'
	download_debian_ls_lr
	SOURCE_MIRROR_STATION_NAME='华为云镜像站'
	SOURCE_MIRROR_STATION='mirrors.huaweicloud.com'
	download_debian_ls_lr
	SOURCE_MIRROR_STATION_NAME='阿里云镜像站'
	SOURCE_MIRROR_STATION='mirrors.aliyun.com'
	download_debian_ls_lr
	SOURCE_MIRROR_STATION_NAME='网易镜像站'
	SOURCE_MIRROR_STATION='mirrors.163.com'
	download_debian_ls_lr
	###此处一定要将SOURCE_MIRROR_STATION赋值为空
	SOURCE_MIRROR_STATION=""
	rm -f .tmoe_netspeed_test_*_temp_file
	echo "测试${YELLOW}完成${RESET}，已自动${RED}清除${RESET}${BLUE}临时文件。${RESET}"
	echo "下载${GREEN}速度快${RESET}并不意味着${BLUE}更新频率高。${RESET}"
	echo "请${YELLOW}自行${RESET}${BLUE}选择${RESET}"
}
######################
ping_mirror_sources_list_count_3() {
	echo ${YELLOW}${SOURCE_MIRROR_STATION}${RESET}
	echo ${BLUE}${SOURCE_MIRROR_STATION_NAME}${RESET}
	ping ${SOURCE_MIRROR_STATION} -c 3 | grep -E 'avg|time.*ms' --color=auto
	echo "---------------------------"
}
##############
ping_mirror_sources_list() {
	echo "时间越短，延迟越低"
	echo "---------------------------"
	SOURCE_MIRROR_STATION_NAME='清华镜像站'
	SOURCE_MIRROR_STATION='mirrors.tuna.tsinghua.edu.cn'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='中科大镜像站'
	SOURCE_MIRROR_STATION='mirrors.ustc.edu.cn'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='上海交大镜像站'
	SOURCE_MIRROR_STATION='mirror.sjtu.edu.cn'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='华为云镜像站'
	SOURCE_MIRROR_STATION='mirrors.huaweicloud.com'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='阿里云镜像站'
	SOURCE_MIRROR_STATION='mirrors.aliyun.com'
	ping_mirror_sources_list_count_3
	SOURCE_MIRROR_STATION_NAME='网易镜像站'
	SOURCE_MIRROR_STATION='mirrors.163.com'
	ping_mirror_sources_list_count_3
	###此处一定要将SOURCE_MIRROR_STATION赋值为空
	SOURCE_MIRROR_STATION=""
	echo "测试${YELLOW}完成${RESET}"
	echo "延迟${GREEN}时间低${RESET}并不意味着${BLUE}下载速度快。${RESET}"
	echo "请${YELLOW}自行${RESET}${BLUE}选择${RESET}"
}
##############
modify_kali_mirror_sources_list() {
	echo "检测到您使用的是Kali系统"
	sed -i 's/^deb/# &/g' /etc/apt/sources.list
	cat >>/etc/apt/sources.list <<-EndOfSourcesList
		deb http://${SOURCE_MIRROR_STATION}/kali/ kali-rolling main contrib non-free
		deb http://${SOURCE_MIRROR_STATION}/debian/ stable main contrib non-free
		# deb http://${SOURCE_MIRROR_STATION}/kali/ kali-last-snapshot main contrib non-free
	EndOfSourcesList
	#注意：kali-rolling添加debian testing源后，可能会破坏系统依赖关系，可以添加stable源（暂未发现严重影响）
}
#############
check_ca_certificates_and_apt_update() {
	if [ -e "/usr/sbin/update-ca-certificates" ]; then
		echo "检测到您已安装ca-certificates"
		echo "Replacing http software source list with https."
		echo "正在将http源替换为https..."
		#update-ca-certificates
		sed -i 's@http:@https:@g' /etc/apt/sources.list
	fi
	apt update
	apt dist-upgrade
	echo "修改完成，您当前的${BLUE}软件源列表${RESET}如下所示。"
	cat /etc/apt/sources.list
	cat /etc/apt/sources.list.d/* 2>/dev/null
	echo "您可以输${YELLOW}apt edit-sources${RESET}来手动编辑软件源列表"
}
#############
modify_ubuntu_mirror_sources_list() {
	if grep -q 'Bionic Beaver' "/etc/os-release"; then
		SOURCELISTCODE='bionic'
		echo '18.04 LTS'
	elif grep -q 'Focal Fossa' "/etc/os-release"; then
		SOURCELISTCODE='focal'
		echo '20.04 LTS'
	elif grep -q 'Xenial' "/etc/os-release"; then
		SOURCELISTCODE='xenial'
		echo '16.04 LTS'
	elif grep -q 'Cosmic' "/etc/os-release"; then
		SOURCELISTCODE='cosmic'
		echo '18.10'
	elif grep -q 'Disco' "/etc/os-release"; then
		SOURCELISTCODE='disco'
		echo '19.04'
	elif grep -q 'Eoan' "/etc/os-release"; then
		SOURCELISTCODE='eoan'
		echo '19.10'
	else
		SOURCELISTCODE=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d '=' -f 2 | head -n 1)
		echo $(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f 2 | cut -d '"' -f 2 | head -n 1)
	fi
	echo "检测到您使用的是Ubuntu ${SOURCELISTCODE}系统"
	sed -i 's/^deb/# &/g' /etc/apt/sources.list
	#下面那行EndOfSourcesList不能有单引号
	cat >>/etc/apt/sources.list <<-EndOfSourcesList
		deb http://${SOURCE_MIRROR_STATION}/ubuntu/ ${SOURCELISTCODE} main restricted universe multiverse
		deb http://${SOURCE_MIRROR_STATION}/ubuntu/ ${SOURCELISTCODE}-updates main restricted universe multiverse
		deb http://${SOURCE_MIRROR_STATION}/ubuntu/ ${SOURCELISTCODE}-backports main restricted universe multiverse
		deb http://${SOURCE_MIRROR_STATION}/ubuntu/ ${SOURCELISTCODE}-security main restricted universe multiverse
		# proposed为预发布软件源，不建议启用
		# deb https://${SOURCE_MIRROR_STATION}/ubuntu/ ${SOURCELISTCODE}-proposed main restricted universe multiverse
	EndOfSourcesList
	if [ "${ARCH_TYPE}" != 'amd64' ] && [ "${ARCH_TYPE}" != 'i386' ]; then
		sed -i 's:/ubuntu:/ubuntu-ports:g' /etc/apt/sources.list
	fi
}
#############
modify_debian_mirror_sources_list() {
	NEW_DEBIAN_SOURCES_LIST='false'
	if grep -q '^PRETTY_NAME.*sid' "/etc/os-release"; then
		SOURCELISTCODE='sid'

	elif grep -q '^PRETTY_NAME.*testing' "/etc/os-release"; then
		NEW_DEBIAN_SOURCES_LIST='true'
		SOURCELISTCODE='testing'
		BACKPORTCODE=$(cat /etc/os-release | grep PRETTY_NAME | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2 | awk -F ' ' '$0=$NF' | cut -d '/' -f 1)
		#echo "Debian testing"

	elif ! grep -Eq 'buster|stretch|jessie' "/etc/os-release"; then
		NEW_DEBIAN_SOURCES_LIST='true'
		SOURCELISTCODE=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d '=' -f 2 | head -n 1)
		BACKPORTCODE=${SOURCELISTCODE}

	elif grep -q 'buster' "/etc/os-release"; then
		SOURCELISTCODE='buster'
		BACKPORTCODE='buster'
		#echo "Debian 10 buster"

	elif grep -q 'stretch' "/etc/os-release"; then
		SOURCELISTCODE='stretch'
		BACKPORTCODE='stretch'
		#echo "Debian 9 stretch"

	elif grep -q 'jessie' "/etc/os-release"; then
		SOURCELISTCODE='jessie'
		BACKPORTCODE='jessie'
		#echo "Debian 8 jessie"
	fi
	echo $(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f 2 | cut -d '"' -f 2 | head -n 1)
	echo "检测到您使用的是Debian ${SOURCELISTCODE}系统"
	sed -i 's/^deb/# &/g' /etc/apt/sources.list
	if [ "${SOURCELISTCODE}" = "sid" ]; then
		cat >>/etc/apt/sources.list <<-EndOfSourcesList
			deb http://${SOURCE_MIRROR_STATION}/debian/ sid main contrib non-free
			deb http://${SOURCE_MIRROR_STATION}/debian/ experimental main contrib non-free
		EndOfSourcesList
	else
		if [ "${NEW_DEBIAN_SOURCES_LIST}" = "true" ]; then
			cat >>/etc/apt/sources.list <<-EndOfSourcesList
				deb http://${SOURCE_MIRROR_STATION}/debian/ ${SOURCELISTCODE} main contrib non-free
				deb http://${SOURCE_MIRROR_STATION}/debian/ ${SOURCELISTCODE}-updates main contrib non-free
				deb http://${SOURCE_MIRROR_STATION}/debian/ ${BACKPORTCODE}-backports main contrib non-free
				deb http://${SOURCE_MIRROR_STATION}/debian-security ${SOURCELISTCODE}-security main contrib non-free
			EndOfSourcesList
		else
			#下面那行EndOfSourcesList不能加单引号
			cat >>/etc/apt/sources.list <<-EndOfSourcesList
				deb http://${SOURCE_MIRROR_STATION}/debian/ ${SOURCELISTCODE} main contrib non-free
				deb http://${SOURCE_MIRROR_STATION}/debian/ ${SOURCELISTCODE}-updates main contrib non-free
				deb http://${SOURCE_MIRROR_STATION}/debian/ ${BACKPORTCODE}-backports main contrib non-free
				deb http://${SOURCE_MIRROR_STATION}/debian-security ${SOURCELISTCODE}/updates main contrib non-free
			EndOfSourcesList
		fi
	fi
}
##############
restore_normal_default_sources_list() {
	if [ -e "${SOURCES_LIST_BACKUP_FILE}" ]; then
		cd ${SOURCES_LIST_PATH}
		cp -pvf ${SOURCES_LIST_FILE_NAME} ${SOURCES_LIST_BACKUP_FILE_NAME}
		cp -pf ${SOURCES_LIST_BACKUP_FILE} ${SOURCES_LIST_FILE}
		${PACKAGES_UPDATE_COMMAND}
		echo "您当前的软件源列表已经备份至${YELLOW}$(pwd)/${SOURCES_LIST_BACKUP_FILE_NAME}${RESET}"
		diff ${SOURCES_LIST_BACKUP_FILE_NAME} ${SOURCES_LIST_FILE_NAME} -y --color
		echo "${YELLOW}左侧${RESET}显示的是${RED}旧源${RESET}，${YELLOW}右侧${RESET}为${GREEN}当前的${RESET}${BLUE}软件源${RESET}"
	else
		echo "检测到备份文件不存在，还原失败。"
	fi
	###################
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		if [ -e "${SOURCES_LIST_BACKUP_FILE_02}" ]; then
			cp -pf "${SOURCES_LIST_BACKUP_FILE_02}" "${SOURCES_LIST_FILE_02}"
		fi
	fi
}
########
restore_default_sources_list() {
	if [ ! $(command -v diff) ]; then
		NON_DEBIAN='false'
		DEPENDENCY_01=""
		DEPENDENCY_02="diffutils"
		beta_features_quick_install
	fi

	if [ "${LINUX_DISTRO}" = "redhat" ]; then
		tar -Ppzxvf ${SOURCES_LIST_BACKUP_FILE}
	else
		restore_normal_default_sources_list
	fi
}
#############
fedora_31_repos() {
	curl -o /etc/yum.repos.d/fedora.repo http://${SOURCE_MIRROR_STATION}/repo/fedora.repo
	curl -o /etc/yum.repos.d/fedora-updates.repo http://${SOURCE_MIRROR_STATION}/repo/fedora-updates.repo
}
###########
#fedora清华源mirrors.tuna.tsinghua.edu.cn/fedora/releases/
fedora_32_repos() {
	cat >/etc/yum.repos.d/fedora.repo <<-EndOfYumRepo
		[fedora]
		name=Fedora \$releasever - \$basearch
		failovermethod=priority
		baseurl=https://${SOURCE_MIRROR_STATION}/fedora/releases/\$releasever/Everything/\$basearch/os/
		metadata_expire=28d
		gpgcheck=1
		gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch
		skip_if_unavailable=False
	EndOfYumRepo

	cat >/etc/yum.repos.d/fedora-updates.repo <<-EndOfYumRepo
		[updates]
		name=Fedora \$releasever - \$basearch - Updates
		failovermethod=priority
		baseurl=https://${SOURCE_MIRROR_STATION}/fedora/updates/\$releasever/Everything/\$basearch/
		enabled=1
		gpgcheck=1
		metadata_expire=6h
		gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch
		skip_if_unavailable=False
	EndOfYumRepo
}
#########################
fedora_3x_repos() {
	cat >/etc/yum.repos.d/fedora-modular.repo <<-EndOfYumRepo
		[fedora-modular]
		name=Fedora Modular \$releasever - \$basearch
		failovermethod=priority
		baseurl=https://${SOURCE_MIRROR_STATION}/fedora/releases/\$releasever/Modular/\$basearch/os/
		enabled=1
		metadata_expire=7d
		gpgcheck=1
		gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch
		skip_if_unavailable=False
	EndOfYumRepo

	cat >/etc/yum.repos.d/fedora-updates-modular.repo <<-EndOfYumRepo
		[updates-modular]
		name=Fedora Modular \$releasever - \$basearch - Updates
		failovermethod=priority
		baseurl=https://${SOURCE_MIRROR_STATION}/fedora/updates/\$releasever/Modular/\$basearch/
		enabled=1
		gpgcheck=1
		metadata_expire=6h
		gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch
		skip_if_unavailable=False
	EndOfYumRepo
}
###############
modify_to_kali_sources_list() {
	if [ "${LINUX_DISTRO}" != "debian" ]; then
		echo "${YELLOW}非常抱歉，检测到您使用的不是deb系linux，按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		tmoe_linux_tool_menu
	fi

	if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
		echo "${YELLOW}非常抱歉，暂不支持Ubuntu，按回车键返回。${RESET}"
		echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
		read
		tmoe_linux_tool_menu
	fi

	if ! grep -q "^deb.*kali" /etc/apt/sources.list; then
		echo "检测到您当前为debian源，是否修改为kali源？"
		echo "Detected that your current software sources list is debian, do you need to modify it to kali source?"
		RETURN_TO_WHERE='tmoe_linux_tool_menu'
		do_you_want_to_continue
		kali_sources_list
	else
		echo "检测到您当前为kali源，是否修改为debian源？"
		echo "Detected that your current software sources list is kali, do you need to modify it to debian source?"
		RETURN_TO_WHERE='tmoe_linux_tool_menu'
		do_you_want_to_continue
		debian_sources_list
	fi
}
################################
kali_sources_list() {
	if [ ! -e "/usr/bin/gpg" ]; then
		apt update
		apt install gpg -y
	fi
	#添加公钥
	apt-key adv --keyserver keyserver.ubuntu.com --recv ED444FF07D8D0BF6
	cd /etc/apt/
	cp -f sources.list sources.list.bak

	sed -i 's/^deb/#&/g' /etc/apt/sources.list
	cat >>/etc/apt/sources.list <<-'EOF'
		deb http://mirrors.tuna.tsinghua.edu.cn/kali/ kali-rolling main contrib non-free
		deb http://mirrors.tuna.tsinghua.edu.cn/debian/ stable main contrib non-free
		# deb https://mirrors.ustc.edu.cn/kali kali-rolling main non-free contrib
		# deb http://mirrors.tuna.tsinghua.edu.cn/kali/ kali-last-snapshot main contrib non-free
	EOF
	apt update
	apt list --upgradable
	apt dist-upgrade -y
	apt search kali-linux
	echo 'You have successfully replaced your debian source with a kali source.'
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	tmoe_linux_tool_menu
}
#######################
debian_sources_list() {
	sed -i 's/^deb/#&/g' /etc/apt/sources.list
	cat >>/etc/apt/sources.list <<-'EOF'
		deb https://mirrors.tuna.tsinghua.edu.cn/debian/ sid main contrib non-free
	EOF
	apt update
	apt list --upgradable
	echo '您已换回debian源'
	apt dist-upgrade -y
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
	tmoe_linux_tool_menu
}
############################################
add_debian_opt_repo() {
	echo "检测到您未添加debian_opt软件源，是否添加？"
	echo "debian_opt_repo列表的所有软件均来自于开源项目"
	echo "感谢https://github.com/coslyk/debianopt-repo 仓库的维护者，以及各个项目的原开发者。"
	RETURN_TO_WHERE='other_software'
	do_you_want_to_continue
	cd /tmp
	curl -o bintray-public.key.asc 'https://bintray.com/user/downloadSubjectPublicKey?username=bintray'
	apt-key add bintray-public.key.asc
	echo "deb https://bintray.proxy.ustclug.org/debianopt/debianopt/ buster main" >>/etc/apt/sources.list.d/debianopt.list
	apt update
}
#######################
explore_debian_opt_repo() {
	if [ ! $(command -v gpg) ]; then
		DEPENDENCY_01=""
		DEPENDENCY_02="gpg"
		beta_features_quick_install
	else
		DEPENDENCY_02=""
	fi

	if [ ! -e "/etc/apt/sources.list.d/debianopt.list" ]; then
		add_debian_opt_repo
	fi

	NON_DEBIAN='true'
	DEPENDENCY_02=''
	cd /usr/share/applications/
	INSTALL_APP=$(whiptail --title "DEBIAN OPT REPO" --menu \
		"您想要安装哪个软件？按方向键选择，回车键确认！\n Which software do you want to install? " 16 50 7 \
		"1" "cocomusic:第三方QQ音乐客户端" \
		"2" "iease-music:界面华丽的云音乐客户端" \
		"3" "electron-netease-cloud-music:云音乐客户端" \
		"4" "listen1:免费音乐聚合" \
		"5" "lx-music-desktop:音乐下载助手" \
		"6" "feeluown(x64):支持网易云、虾米" \
		"7" "netease-cloud-music-gtk(x64):云音乐" \
		"8" "picgo:图床上传工具" \
		"9" "other其他软件" \
		"10" "remove移除本仓库" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##############
	case "${INSTALL_APP}" in
	0 | "") other_software ;;
	1) install_coco_music ;;
	2) install_iease_music ;;
	3) install_electron_netease_cloud_music ;;
	4) install_listen1 ;;
	5) install_lx_music_desktop ;;
	6) install_feeluown ;;
	7) install_netease_cloud_music_gtk ;;
	8) install_pic_go ;;
	9) apt_list_debian_opt ;;
	10) remove_debian_opt_repo ;;
	esac
	##########################
	press_enter_to_return
	explore_debian_opt_repo
}
################
debian_opt_quick_install() {
	beta_features_quick_install
	do_you_want_to_close_the_sandbox_mode
	RETURN_TO_WHERE='explore_debian_opt_repo'
	do_you_want_to_continue
}
############
with_no_sandbox_model_01() {
	sed -i "s+${DEPENDENCY_01} %U+${DEPENDENCY_01} --no-sandbox %U+" ${DEPENDENCY_01}.desktop
}
########
with_no_sandbox_model_02() {
	if ! grep 'sandbox' "${DEPENDENCY_01}.desktop"; then
		sed -i "s@/usr/bin/${DEPENDENCY_01}@& --no-sandbox@" ${DEPENDENCY_01}.desktop
	fi
}
##################
remove_debian_opt_repo() {
	rm -vf /etc/apt/sources.list.d/debianopt.list
	apt update
}
##########
apt_list_debian_opt() {
	apt list | grep '~buster'
	echo "请使用apt install 软件包名称 来安装"
}
#############
install_coco_music() {
	DEPENDENCY_01='cocomusic'
	echo "github url：https://github.com/xtuJSer/CoCoMusic"
	debian_opt_quick_install
	#sed -i 's+cocomusic %U+electron /opt/CocoMusic --no-sandbox "$@"+' /usr/share/applications/cocomusic.desktop
	with_no_sandbox_model_01
}
#####################
install_iease_music() {
	DEPENDENCY_01='iease-music'
	echo "github url：https://github.com/trazyn/ieaseMusic"
	debian_opt_quick_install
	with_no_sandbox_model_02
}
######################
install_electron_netease_cloud_music() {
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "${RED}WARNING！${RESET}检测到您当前处于${GREEN}proot容器${RESET}环境下！"
		echo "在当前环境下，安装后可能无法正常运行。"
		RETURN_TO_WHERE='explore_debian_opt_repo'
		do_you_want_to_continue
	fi
	DEPENDENCY_01='electron-netease-cloud-music'
	echo "github url：https://github.com/Rocket1184/electron-netease-cloud-music"
	debian_opt_quick_install
	#with_no_sandbox_model_02
	if ! grep -q 'sandbox' "$(command -v electron-netease-cloud-music)"; then
		sed -i 's@exec electron /opt/electron-netease-cloud-music/app.asar@& --no-sandbox@' $(command -v electron-netease-cloud-music)
	fi
}
########################
install_listen1() {
	DEPENDENCY_01='listen1'
	echo "github url：http://listen1.github.io/listen1/"
	debian_opt_quick_install
	#sed -i 's+listen1 %U+listen1 --no-sandbox %U+' listen1.desktop
	with_no_sandbox_model_01
}
################
install_lx_music_desktop() {
	DEPENDENCY_01='lx-music-desktop'
	echo "github url：https://github.com/lyswhut/lx-music-desktop"
	debian_opt_quick_install
	#sed -i 's+lx-music-desktop %U+lx-music-desktop --no-sandbox %U+' lx-music-desktop.desktop
	with_no_sandbox_model_01
}
####################
install_feeluown() {
	DEPENDENCY_01='feeluown'
	echo "url：https://feeluown.readthedocs.io/en/latest/"
	beta_features_quick_install
	if [ ! $(command -v feeluown) ]; then
		arch_does_not_support
	fi
}
###########
install_netease_cloud_music_gtk() {
	DEPENDENCY_01='netease-cloud-music-gtk'
	echo "github url：https://github.com/gmg137/netease-cloud-music-gtk"
	beta_features_quick_install
	if [ ! $(command -v netease-cloud-music-gtk) ]; then
		arch_does_not_support
	fi
}
###############
install_pic_go() {
	DEPENDENCY_01='picgo'
	echo "github url：https://github.com/Molunerfinn/PicGo"
	debian_opt_quick_install
	#sed -i 's+picgo %U+picgo --no-sandbox %U+' picgo.desktop
	with_no_sandbox_model_01
}
############################################
############################################
other_software() {
	RETURN_TO_WHERE='other_software'
	SOFTWARE=$(
		whiptail --title "其它软件" --menu \
			"您想要安装哪个软件？\n Which software do you want to install? 您需要使用方向键或pgdown来翻页。 部分软件需要在安装gui后才能使用！" 17 60 7 \
			"1" "MPV：开源、跨平台的音视频播放器" \
			"2" "LinuxQQ：在线聊天软件" \
			"3" "Debian-opt仓库(第三方QQ音乐,云音乐)" \
			"4" "Tmoe-deb软件包安装器" \
			"5" "大灾变-劫后余生：末日幻想背景的探索生存游戏" \
			"6" "Synaptic：新立得软件包管理器/软件商店" \
			"7" "GIMP：GNU 图像处理程序" \
			"8" "LibreOffice:开源、自由的办公文档软件" \
			"9" "Parole：xfce默认媒体播放器，风格简洁" \
			"10" "百度网盘(x86_64):提供文件的网络备份、同步和分享服务" \
			"11" "网易云音乐(x86_64):专注于发现与分享的音乐产品" \
			"12" "ADB:Android Debug Bridge" \
			"13" "BleachBit:垃圾清理" \
			"14" "Install Chinese manual 安装中文手册" \
			"15" "斯隆与马克贝尔的谜之物语：nds解谜游戏" \
			"16" "韦诺之战：奇幻背景的回合制策略战棋游戏" \
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	#(已移除)"12" "Tasksel:轻松,快速地安装组软件" \
	case "${SOFTWARE}" in
	0 | "") tmoe_linux_tool_menu ;;
	1) install_mpv ;;
	2) install_linux_qq ;;
	3)
		non_debian_function
		explore_debian_opt_repo
		;;
	4) tmoe_deb_file_installer ;;
	5) install_game_cataclysm ;;
	6) install_package_manager_gui ;;
	7) install_gimp ;;
	8) install_libre_office ;;
	9) install_parole ;;
	10) install_baidu_netdisk ;;
	11) install_netease_163_cloud_music ;;
	12) install_android_debug_bridge ;;
	13) install_bleachbit_cleaner ;;
	14) install_chinese_manpages ;;
	15) install_nds_game_mayomonogatari ;;
	16) install_wesnoth_game ;;
	esac
	############################################
	press_enter_to_return
	other_software
	#tmoe_linux_tool_menu
}
###########
remove_deb_package() {
	if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "Back返回" --no-button "Remove移除" --yesno "${PACKAGE_NAME}\n您是想要返回还是卸载这个软件包？Do you want to return,or remove this package?♪(^∇^*) " 10 50); then
		other_software
	else
		apt purge ${PACKAGE_NAME}
		delete_tmoe_deb_file
		other_software
	fi
}
#############
deb_file_installer() {
	#进入deb文件目录
	cd ${CURRENT_DIR}
	#./${SELECTION}
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		file ./${SELECTION} 2>/dev/null
		apt show ./${SELECTION}
		PACKAGE_NAME=$(apt show ./${SELECTION} 2>&1 | grep Package | head -n 1 | awk -F ' ' '$0=$NF')
		echo "您是否需要安装此软件包？"
		echo "Do you want to install it?"
		RETURN_TO_WHERE='remove_deb_package'
		do_you_want_to_continue
		RETURN_TO_WHERE='other_software'
		apt install -y ./${SELECTION}
		DEPENDENCY_01=${PACKAGE_NAME}
		DEPENDENCY_02=""
		beta_features_install_completed
	else
		mkdir -p .DEB_TEMP_FOLDER
		mv ${SELECTION} .DEB_TEMP_FOLDER
		cd ./.DEB_TEMP_FOLDER
		busybox ar xv ${SELECTION}
		mv ${SELECTION} ../
		if [ -e "data.tar.xz" ]; then
			cd /
			tar -Jxvf ${CURRENT_DIR}/.DEB_TEMP_FOLDER/data.tar.xz ./usr
		elif [ -e "data.tar.gz" ]; then
			cd /
			tar -zxvf ${CURRENT_DIR}/.DEB_TEMP_FOLDER/data.tar.gz ./usr
		fi
		rm -rf ${CURRENT_DIR}/.DEB_TEMP_FOLDER
	fi
	delete_tmoe_deb_file
}
######################
delete_tmoe_deb_file() {
	echo "请问是否需要${RED}删除${RESET}安装包文件"
	ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
	echo "Do you want to ${RED}delete${RESET} it?"
	do_you_want_to_continue
	rm -fv ${TMOE_FILE_ABSOLUTE_PATH}
}
#################
tmoe_deb_file_installer() {
	FILE_EXT_01='deb'
	FILE_EXT_02='DEB'
	START_DIR="${HOME}"
	tmoe_file_manager
	if [ -z ${SELECTION} ]; then
		echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		echo "您选择的deb文件为${TMOE_FILE_ABSOLUTE_PATH}"
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		deb_file_installer
	fi
}
##################
install_wesnoth_game() {
	DEPENDENCY_01="wesnoth"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
###########
install_mpv() {
	if [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01="kmplayer"
	else
		DEPENDENCY_01="mpv"
	fi
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
#############
install_linux_qq() {
	DEPENDENCY_01="linuxqq"
	DEPENDENCY_02=""
	if [ -e "/usr/share/applications/qq.desktop" ]; then
		press_enter_to_reinstall
	fi
	cd /tmp
	if [ "${ARCH_TYPE}" = "arm64" ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o LINUXQQ.deb "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.deb"
			apt show ./LINUXQQ.deb
			apt install -y ./LINUXQQ.deb
		else
			aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o LINUXQQ.sh http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.sh
			chmod +x LINUXQQ.sh
			sudo ./LINUXQQ.sh
			#即使是root用户也需要加sudo
		fi
	elif [ "${ARCH_TYPE}" = "amd64" ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o LINUXQQ.deb "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_amd64.deb"
			apt show ./LINUXQQ.deb
			apt install -y ./LINUXQQ.deb
			#http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_arm64.deb
		else
			aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o LINUXQQ.sh "http://down.qq.com/qqweb/LinuxQQ_1/linuxqq_2.0.0-b2-1082_x86_64.sh"
			chmod +x LINUXQQ.sh
			sudo ./LINUXQQ.sh
		fi
	fi
	echo "若安装失败，则请前往官网手动下载安装。"
	echo "url: https://im.qq.com/linuxqq/download.html"
	rm -fv ./LINUXQQ.deb ./LINUXQQ.sh 2>/dev/null
	beta_features_install_completed
}
###################
install_nds_game_mayomonogatari() {
	DEPENDENCY_01="desmume"
	DEPENDENCY_02="p7zip-full"
	NON_DEBIAN='false'
	beta_features_quick_install
	if [ -e "斯隆与马克贝尔的谜之物语/3782.nds" ]; then
		echo "检测到您已下载游戏文件，路径为/root/斯隆与马克贝尔的谜之物语"
		press_enter_to_reinstall
	fi
	cd ${HOME}
	mkdir -p '斯隆与马克贝尔的谜之物语'
	cd '斯隆与马克贝尔的谜之物语'
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o slymkbr1.zip http://k73dx1.zxclqw.com/slymkbr1.zip
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o mayomonogatari2.zip http://k73dx1.zxclqw.com/mayomonogatari2.zip
	7za x slymkbr1.zip
	7za x mayomonogatari2.zip
	mv -f 斯隆与马克贝尔的谜之物语k73/* ./
	mv -f 迷之物语/* ./
	rm -f *url *txt
	rm -rf 迷之物语 斯隆与马克贝尔的谜之物语k73
	rm -f slymkbr1.zip* mayomonogatari2.zip*

	echo "安装完成，您需要手动进入'/root/斯隆与马克贝尔的谜之物语'目录加载游戏"
	echo "如需卸载，请手动输${PACKAGES_REMOVE_COMMAND} desmume ; rm -rf ~/斯隆与马克贝尔的谜之物语"
	echo 'Press enter to start the nds emulator.'
	echo "${YELLOW}按回车键启动游戏。${RESET}"
	read
	desmume "${HOME}/斯隆与马克贝尔的谜之物语/3782.nds" 2>/dev/null &
}
##################
install_game_cataclysm() {
	DEPENDENCY_01="cataclysm-dda-curses"
	DEPENDENCY_02="cataclysm-dda-sdl"
	NON_DEBIAN='false'
	beta_features_quick_install
	echo "在终端环境下，您需要缩小显示比例，并输入cataclysm来启动字符版游戏。"
	echo "在gui下，您需要输cataclysm-tiles来启动画面更为华丽的图形界面版游戏。"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "${YELLOW}按回车键启动。${RESET}"
	read
	cataclysm
}
##############################################################
install_package_manager_gui() {
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		install_synaptic
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		echo "检测到您使用的是arch系发行版，将为您安装pamac"
		install_pamac_gtk
	else
		echo "检测到您使用的不是deb系发行版，将为您安装gnome_software"
		install_gnome_software
	fi
}
######################
install_gimp() {
	DEPENDENCY_01="gimp"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
##############
install_parole() {
	DEPENDENCY_01="parole"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
###############
install_pamac_gtk() {
	DEPENDENCY_01="pamac"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
#####################
install_synaptic() {
	if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "Install安装" --no-button "Remove移除" --yesno "新立德是一款使用apt的图形化软件包管理工具，您也可以把它理解为软件商店。Synaptic is a graphical package management program for apt. It provides the same features as the apt-get command line utility with a GUI front-end based on Gtk+.它提供与apt-get命令行相同的功能，并带有基于Gtk+的GUI前端。功能：1.安装、删除、升级和降级单个或多个软件包。 2.升级整个系统。 3.管理软件源列表。  4.自定义过滤器选择(搜索)软件包。 5.按名称、状态、大小或版本对软件包进行排序。 6.浏览与所选软件包相关的所有可用在线文档。♪(^∇^*) " 19 50); then
		DEPENDENCY_01="synaptic"
		DEPENDENCY_02="gdebi"
		NON_DEBIAN='true'
		beta_features_quick_install
		sed -i 's/synaptic-pkexec/synaptic/g' /usr/share/applications/synaptic.desktop
		echo "synaptic和gdebi安装完成，您可以将deb文件的默认打开程序修改为gdebi"
	else
		echo "${YELLOW}您真的要离开我么？哦呜。。。${RESET}"
		echo "Do you really want to remove synaptic?"
		RETURN_TO_WHERE='other_software'
		do_you_want_to_continue
		${PACKAGES_REMOVE_COMMAND} synaptic
		${PACKAGES_REMOVE_COMMAND} gdebi
	fi
}
##########################################
install_chinese_manpages() {
	echo '即将为您安装 debian-reference-zh-cn、manpages、manpages-zh和man-db'

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		DEPENDENCY_01="manpages manpages-zh man-db"

	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="man-pages-zh_cn"

	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_01="man-pages-zh-CN"
	else
		DEPENDENCY_01="man-pages-zh-CN"
	fi
	DEPENDENCY_02="debian-reference-zh-cn"
	NON_DEBIAN='false'
	beta_features_quick_install
	if [ ! -e "${HOME}/文档/debian-handbook/usr/share/doc/debian-handbook/html" ]; then
		mkdir -p ${HOME}/文档/debian-handbook
		cd ${HOME}/文档/debian-handbook
		GREP_NAME='debian-handbook'
		LATEST_DEB_REPO='https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/d/debian-handbook/'
		download_tuna_repo_deb_file_all_arch
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'debian-handbook.deb' 'https://mirrors.tuna.tsinghua.edu.cn/debian/pool/main/d/debian-handbook/debian-handbook_8.20180830_all.deb'
		busybox ar xv ${LATEST_DEB_VERSION}
		tar -Jxvf data.tar.xz ./usr/share/doc/debian-handbook/html
		ls | grep -v usr | xargs rm -rf
		ln -sf ./usr/share/doc/debian-handbook/html/zh-CN/index.html ./
	fi
	echo "man一款帮助手册软件，它可以帮助您了解关于命令的详细用法。"
	echo "man a help manual software, which can help you understand the detailed usage of the command."
	echo "您可以输${YELLOW}man 软件或命令名称${RESET}来获取帮助信息，例如${YELLOW}man bash${RESET}或${YELLOW}man zsh${RESET}"
}
#####################
install_libre_office() {
	#ps -e >/dev/null || echo "/proc分区未挂载，请勿安装libreoffice,赋予proot容器真实root权限可解决相关问题，但强烈不推荐！"
	ps -e >/dev/null || echo "${RED}WARNING！${RESET}检测到您无权读取${GREEN}/proc${RESET}分区的某些数据！"
	RETURN_TO_WHERE='other_software'
	do_you_want_to_continue
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		DEPENDENCY_01='--no-install-recommends libreoffice'
	else
		DEPENDENCY_01="libreoffice"
	fi
	DEPENDENCY_02="libreoffice-l10n-zh-cn libreoffice-gtk3"
	NON_DEBIAN='false'
	beta_features_quick_install
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ] && [ "${ARCH_TYPE}" = "arm64" ]; then
		mkdir -p /prod/version
		cd /usr/lib/libreoffice/program
		rm -f oosplash
		curl -Lo 'oosplash' https://gitee.com/mo2/patch/raw/libreoffice/oosplash
		chmod +x oosplash
	fi
	beta_features_install_completed
}
###################
install_baidu_netdisk() {
	DEPENDENCY_01="baidunetdisk"
	DEPENDENCY_02=""
	if [ "${ARCH_TYPE}" != "amd64" ]; then
		arch_does_not_support
		other_software
	fi

	if [ -e "/usr/share/applications/baidunetdisk.desktop" ]; then
		press_enter_to_reinstall
	fi
	cd /tmp
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="baidunetdisk-bin"
		beta_features_quick_install
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'baidunetdisk.rpm' "http://wppkg.baidupcs.com/issue/netdisk/LinuxGuanjia/3.0.1/baidunetdisk_linux_3.0.1.2.rpm"
		rpm -ivh 'baidunetdisk.rpm'
	elif [ "${LINUX_DISTRO}" = "debian" ]; then
		GREP_NAME='baidunetdisk'
		LATEST_DEB_REPO='http://archive.ubuntukylin.com/software/pool/'
		download_ubuntu_kylin_deb_file_model_02
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o baidunetdisk.deb "http://wppkg.baidupcs.com/issue/netdisk/LinuxGuanjia/3.0.1/baidunetdisk_linux_3.0.1.2.deb"
		#apt show ./baidunetdisk.deb
		#apt install -y ./baidunetdisk.deb
	fi
	echo "若安装失败，则请前往官网手动下载安装"
	echo "url：https://pan.baidu.com/download"
	#rm -fv ./baidunetdisk.deb
	beta_features_install_completed
}
######################
#####################
install_deb_file_common_model_01() {
	cd /tmp
	LATEST_DEB_URL="${LATEST_DEB_REPO}${LATEST_DEB_VERSION}"
	echo ${LATEST_DEB_URL}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${LATEST_DEB_VERSION}" "${LATEST_DEB_URL}"
	apt show ./${LATEST_DEB_VERSION}
	apt install -y ./${LATEST_DEB_VERSION}
	rm -fv ./${LATEST_DEB_VERSION}
}
###################
download_ubuntu_kylin_deb_file_model_02() {
	LATEST_DEB_VERSION=$(curl -L "${LATEST_DEB_REPO}" | grep '.deb' | grep "${ARCH_TYPE}" | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 5 | cut -d '"' -f 2)
	install_deb_file_common_model_01
}
################
download_debian_cn_repo_deb_file_model_01() {
	LATEST_DEB_VERSION=$(curl -L "${LATEST_DEB_REPO}" | grep '.deb' | grep "${ARCH_TYPE}" | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
	install_deb_file_common_model_01
}
######################
download_tuna_repo_deb_file_model_03() {
	LATEST_DEB_VERSION=$(curl -L "${LATEST_DEB_REPO}" | grep '.deb' | grep "${ARCH_TYPE}" | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	install_deb_file_common_model_01
}
################
download_tuna_repo_deb_file_all_arch() {
	LATEST_DEB_VERSION=$(curl -L "${LATEST_DEB_REPO}" | grep '.deb' | grep "all" | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	LATEST_DEB_URL="${LATEST_DEB_REPO}${LATEST_DEB_VERSION}"
	echo ${LATEST_DEB_URL}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${LATEST_DEB_VERSION}" "${LATEST_DEB_URL}"
	apt show ./${LATEST_DEB_VERSION} 2>/dev/null
}
##此处不要自动安装deb包
######################
install_netease_163_cloud_music() {
	DEPENDENCY_01="netease-cloud-music"
	DEPENDENCY_02=""

	if [ "${ARCH_TYPE}" != "amd64" ] && [ "${ARCH_TYPE}" != "i386" ]; then
		arch_does_not_support
		other_software
	fi
	if [ -e "/usr/share/applications/netease-cloud-music.desktop" ]; then
		press_enter_to_reinstall
	fi
	cd /tmp
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="netease-cloud-music"
		beta_features_quick_install
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		curl -Lv https://dl.senorsen.com/pub/package/linux/add_repo.sh | sh -
		dnf install http://dl-http.senorsen.com/pub/package/linux/rpm/senorsen-repo-0.0.1-1.noarch.rpm
		dnf install -y netease-cloud-music
		#https://github.com/ZetaoYang/netease-cloud-music-appimage/releases
		#appimage格式
	else
		non_debian_function
		GREP_NAME='netease-cloud-music'
		if [ "${ARCH_TYPE}" = "amd64" ]; then
			LATEST_DEB_REPO='http://archive.ubuntukylin.com/software/pool/'
			download_ubuntu_kylin_deb_file_model_02
			#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o netease-cloud-music.deb "http://d1.music.126.net/dmusic/netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb"
		else
			LATEST_DEB_REPO='http://mirrors.ustc.edu.cn/debiancn/pool/main/n/netease-cloud-music/'
			download_debian_cn_repo_deb_file_model_01
			#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o netease-cloud-music.deb "http://mirrors.ustc.edu.cn/debiancn/pool/main/n/netease-cloud-music/netease-cloud-music_1.0.0%2Brepack.debiancn-1_i386.deb"
		fi
		echo "若安装失败，则请前往官网手动下载安装。"
		echo 'url: https://music.163.com/st/download'
		beta_features_install_completed
	fi
	press_enter_to_return
	tmoe_linux_tool_menu
}
############################
install_android_debug_bridge() {
	if [ ! $(command -v adb) ]; then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			DEPENDENCY_01="adb"
		else
			DEPENDENCY_01="android-tools"
		fi
	fi

	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
	adb --help
	echo "正在重启进程,您也可以手动输adb devices来获取设备列表"
	adb kill-server
	adb devices -l
	echo "即将为您自动进入adb shell模式，您也可以手动输adb shell来进入该模式"
	adb shell
}
####################
install_bleachbit_cleaner() {
	DEPENDENCY_01="bleachbit"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
##########################
##########################
modify_remote_desktop_config() {
	RETURN_TO_WHERE='modify_remote_desktop_config'
	if [ ! $(command -v nano) ]; then
		DEPENDENCY_01='nano'
		DEPENDENCY_02=""
		NON_DEBIAN='false'
		beta_features_quick_install
	fi
	##################
	REMOTE_DESKTOP=$(whiptail --title "远程桌面" --menu \
		"您想要修改哪个远程桌面的配置？\nWhich remote desktop configuration do you want to modify?" 15 60 4 \
		"1" "tightvnc/tigervnc" \
		"2" "x11vnc" \
		"3" "XSDL" \
		"4" "XRDP" \
		"5" "Xwayland(测试版)" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	case "${REMOTE_DESKTOP}" in
	0 | "") tmoe_linux_tool_menu ;;
	1) modify_vnc_conf ;;
	2) configure_x11vnc ;;
	3) modify_xsdl_conf ;;
	4) modify_xrdp_conf ;;
	5) modify_xwayland_conf ;;
	esac
	#######################
	press_enter_to_return
	modify_remote_desktop_config
}
#########################
configure_x11vnc() {
	TMOE_OPTION=$(
		whiptail --title "CONFIGURE x11vnc" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 14 50 5 \
			"1" "one-key configure初始化一键配置" \
			"2" "pulse_server音频服务" \
			"3" "resolution分辨率" \
			"4" "修改startx11vnc启动脚本" \
			"5" "修改stopx11vnc停止脚本" \
			"6" "remove 卸载/移除" \
			"7" "readme 进程管理说明" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	case "${TMOE_OPTION}" in
	0 | "") modify_remote_desktop_config ;;
	1) x11vnc_onekey ;;
	2) x11vnc_pulse_server ;;
	3) x11vnc_resolution ;;
	4) nano /usr/local/bin/startx11vnc ;;
	5) nano /usr/local/bin/stopx11vnc ;;
	6) remove_X11vnc ;;
	7) x11vnc_process_readme ;;
	esac
	########################################
	press_enter_to_return
	configure_x11vnc
	####################
}
############
x11vnc_process_readme() {
	echo "输startx11vnc启动x11vnc"
	echo "输stopvnc或stopx11vnc停止x11vnc"
	echo "若您的宿主机为Android系统，且发现音频服务无法启动,请在启动完成后，新建一个termux窗口，然后手动在termux原系统里输${GREEN}pulseaudio -D${RESET}来启动音频服务后台进程"
	echo "您亦可输${GREEN}pulseaudio --start${RESET}"
}
###################
x11vnc_warning() {
	echo "注：x11vnc和tightvnc是有${RED}区别${RESET}的！"
	echo "x11vnc可以打开tightvnc无法打开的某些应用"
	echo "配置完x11vnc后，输${GREEN}startx11vnc${RESET}${BLUE}启动${RESET},输${GREEN}stopvnc${RESET}${BLUE}停止${RESET}"
	echo "若超过一分钟黑屏，则请输${GREEN}startx11vnc${RESET}重启该服务"
	echo "若您的宿主机为Android系统，且发现音频服务无法启动,请在启动完成后，新建一个termux窗口，然后手动在termux原系统里输${GREEN}pulseaudio -D${RESET}来启动音频服务后台进程"
	RETURN_TO_WHERE='configure_x11vnc'
	do_you_want_to_continue
	stopvnc 2>/dev/null
	NON_DEBIAN='false'
	DEPENDENCY_01=''
	DEPENDENCY_02=''
	if [ ! $(command -v x11vnc) ]; then
		if [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCY_01='x11-misc/x11vnc'
		else
			DEPENDENCY_01="${DEPENDENCY_01} x11vnc"
		fi
	fi
	#注意下面那处的大小写
	if [ ! $(command -v xvfb) ] && [ ! $(command -v Xvfb) ]; then
		if [ "${LINUX_DISTRO}" = "arch" ]; then
			DEPENDENCY_02='xorg-server-xvfb'
		elif [ "${LINUX_DISTRO}" = "redhat" ]; then
			DEPENDENCY_02='xorg-x11-server-Xvfb'
		elif [ "${LINUX_DISTRO}" = "suse" ]; then
			DEPENDENCY_02='xorg-x11-server-Xvfb'
		elif [ "${LINUX_DISTRO}" = "gentoo" ]; then
			DEPENDENCY_02='x11-misc/xvfb-run'
		else
			DEPENDENCY_02='xvfb'
		fi
	fi

	if [ ! -z "${DEPENDENCY_01}" ] || [ ! -z "${DEPENDENCY_02}" ]; then
		beta_features_quick_install
	fi
	#音频控制器单独检测
	if [ ! $(command -v pavucontrol) ]; then
		${PACKAGES_INSTALL_COMMAND} pavucontrol
	fi
}
############
x11vnc_onekey() {
	x11vnc_warning
	################
	X11_OR_WAYLAND_DESKTOP='x11vnc'
	configure_remote_desktop_enviroment
}
#############
remove_X11vnc() {
	echo "正在停止x11vnc进程..."
	echo "Stopping x11vnc..."
	stopx11vnc
	echo "${YELLOW}This is a dangerous operation, you must press Enter to confirm${RESET}"
	RETURN_TO_WHERE='configure_x11vnc'
	do_you_want_to_continue
	rm -rfv /usr/local/bin/startx11vnc /usr/local/bin/stopx11vnc
	echo "即将为您卸载..."
	${PACKAGES_REMOVE_COMMAND} x11vnc
}
################
x11vnc_pulse_server() {
	cd /usr/local/bin/
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。当前为$(grep 'PULSE_SERVER' startx11vnc | grep -v '^#' | cut -d '=' -f 2 | head -n 1) \n若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'" 15 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		if grep -q '^export.*PULSE_SERVER' startx11vnc; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startx11vnc
		else
			sed -i "3 a\export PULSE_SERVER=$TARGET" startx11vnc
		fi
		echo 'Your current PULSEAUDIO SERVER address has been modified.'
		echo '您当前的音频地址已修改为'
		echo $(grep 'PULSE_SERVER' startx11vnc | grep -v '^#' | cut -d '=' -f 2 | head -n 1)
	else
		configure_x11vnc
	fi
}
##################
x11vnc_resolution() {
	TARGET=$(whiptail --inputbox "Please enter a resolution,请输入分辨率,例如2880x1440,2400x1200,1920x1080,1920x960,720x1140,1280x1024,1280x960,1280x720,1024x768,800x680等等,默认为1440x720,当前为$(cat $(command -v startx11vnc) | grep '/usr/bin/Xvfb' | head -n 1 | cut -d ':' -f 2 | cut -d '+' -f 1 | cut -d '-' -f 2 | cut -d 'x' -f -2 | awk -F ' ' '$0=$NF')。分辨率可自定义，但建议您根据屏幕比例来调整，输入完成后按回车键确认，修改完成后将自动停止VNC服务。注意：x为英文小写，不是乘号。Press Enter after the input is completed." 16 50 --title "请在方框内输入 水平像素x垂直像素 (数字x数字) " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		#/usr/bin/Xvfb :1 -screen 0 1440x720x24 -ac +extension GLX +render -noreset &
		sed -i "s@^/usr/bin/Xvfb.*@/usr/bin/Xvfb :233 -screen 0 ${TARGET}x24 -ac +extension GLX +render -noreset \&@" "$(command -v startx11vnc)"
		echo 'Your current resolution has been modified.'
		echo '您当前的分辨率已经修改为'
		echo $(cat $(command -v startx11vnc) | grep '/usr/bin/Xvfb' | head -n 1 | cut -d ':' -f 2 | cut -d '+' -f 1 | cut -d '-' -f 2 | cut -d 'x' -f -2 | awk -F ' ' '$0=$NF')
		#echo $(sed -n \$p "$(command -v startx11vnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
		#$p表示最后一行，必须用反斜杠转义。
		stopx11vnc
	else
		echo "您当前的分辨率为$(cat $(command -v startx11vnc) | grep '/usr/bin/Xvfb' | head -n 1 | cut -d ':' -f 2 | cut -d '+' -f 1 | cut -d '-' -f 2 | cut -d 'x' -f -2 | awk -F ' ' '$0=$NF')"
	fi
}
############################
######################
modify_vnc_conf() {
	if [ ! -e /usr/local/bin/startvnc ]; then
		echo "/usr/local/bin/startvnc is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
		echo '未检测到startvnc,您可能尚未安装图形桌面，是否继续编辑?'
		echo "${YELLOW}按回车键确认编辑。${RESET}"
		RETURN_TO_WHERE='modify_remote_desktop_config'
		do_you_want_to_continue
	fi

	if (whiptail --title "modify vnc configuration" --yes-button '分辨率resolution' --no-button '其它other' --yesno "您想要修改哪项配置信息？Which configuration do you want to modify?" 9 50); then
		TARGET=$(whiptail --inputbox "Please enter a resolution,请输入分辨率,例如2880x1440,2400x1200,1920x1080,1920x960,720x1140,1280x1024,1280x960,1280x720,1024x768,800x680等等,默认为1440x720,当前为$(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1) 。分辨率可自定义，但建议您根据屏幕比例来调整，输入完成后按回车键确认，修改完成后将自动停止VNC服务。注意：x为英文小写，不是乘号。Press Enter after the input is completed." 16 50 --title "请在方框内输入 水平像素x垂直像素 (数字x数字) " 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			sed -i '/vncserver -geometry/d' "$(command -v startvnc)"
			sed -i "$ a\vncserver -geometry $TARGET -depth 24 -name tmoe-linux :1" "$(command -v startvnc)"
			echo 'Your current resolution has been modified.'
			echo '您当前的分辨率已经修改为'
			echo $(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
			#echo $(sed -n \$p "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
			#$p表示最后一行，必须用反斜杠转义。
			stopvnc 2>/dev/null
			echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
			echo "${YELLOW}按回车键返回。${RESET}"
			read
			tmoe_linux_tool_menu
		else
			echo '您当前的分辨率为'
			echo $(grep '\-geometry' "$(command -v startvnc)" | cut -d 'y' -f 2 | cut -d '-' -f 1)
		fi
	else
		modify_other_vnc_conf
	fi
}

############################
modify_xsdl_conf() {
	if [ ! -f /usr/local/bin/startxsdl ]; then
		echo "/usr/local/bin/startxsdl is not detected, maybe you have not installed the graphical desktop environment, do you want to continue editing?"
		echo '未检测到startxsdl,您可能尚未安装图形桌面，是否继续编辑。'
		RETURN_TO_WHERE='modify_remote_desktop_config'
		do_you_want_to_continue
	fi
	XSDL_XSERVER=$(whiptail --title "Modify x server conf" --menu "Choose your option" 15 60 5 \
		"1" "音频端口 Pulse server port " \
		"2" "显示编号 Display number" \
		"3" "ip address" \
		"4" "手动编辑 Edit manually" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	###########
	case "${XSDL_XSERVER}" in
	0 | "") modify_remote_desktop_config ;;
	1) modify_pulse_server_port ;;
	2) modify_display_port ;;
	3) modify_xsdl_ip_address ;;
	4) modify_startxsdl_manually ;;
	esac
	########################################
	press_enter_to_return
	modify_xsdl_conf
}
#################
modify_startxsdl_manually() {
	nano /usr/local/bin/startxsdl || nano $(command -v startxsdl)
	echo 'See your current xsdl configuration information below.'
	echo '您当前的ip地址为'
	echo $(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 1)

	echo '您当前的显示端口为'
	echo $(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 2)

	echo '您当前的音频端口为'
	echo $(sed -n 4p $(command -v startxsdl) | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2)
	press_enter_to_return
	modify_xsdl_conf
}

######################
modify_pulse_server_port() {

	TARGET=$(whiptail --inputbox "若xsdl app显示的端口非4713，则您可在此处修改。默认为4713，当前为$(sed -n 4p $(command -v startxsdl) | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2) \n请以xsdl app显示的pulse server地址的最后几位数字为准，输入完成后按回车键确认。" 20 50 --title "MODIFY PULSE SERVER PORT " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i "4 c export PULSE_SERVER=tcp:127.0.0.1:$TARGET" "$(command -v startxsdl)"
		echo 'Your current PULSE SERVER port has been modified.'
		echo '您当前的音频端口已修改为'
		echo $(sed -n 4p $(command -v startxsdl) | cut -d 'c' -f 2 | cut -c 1-2 --complement | cut -d ':' -f 2)
		press_enter_to_return
		modify_xsdl_conf
	else
		modify_xsdl_conf
	fi
}

########################################################
modify_display_port() {

	TARGET=$(whiptail --inputbox "若xsdl app显示的Display number(输出显示的端口数字) 非0，则您可在此处修改。默认为0，当前为$(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 2) \n请以xsdl app显示的DISPLAY=:的数字为准，输入完成后按回车键确认。" 20 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i "3 c export DISPLAY=127.0.0.1:$TARGET" "$(command -v startxsdl)"
		echo 'Your current DISPLAY port has been modified.'
		echo '您当前的显示端口已修改为'
		echo $(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 2)
		press_enter_to_return
		modify_xsdl_conf
	else
		modify_xsdl_conf
	fi
}
###############################################
modify_xsdl_ip_address() {
	XSDLIP=$(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 1)
	TARGET=$(whiptail --inputbox "若您需要用局域网其它设备来连接，则您可在下方输入该设备的IP地址。本机连接请勿修改，默认为127.0.0.1 ,当前为${XSDLIP} \n 请在修改完其它信息后，再来修改此项，否则将被重置为127.0.0.1。windows设备输 ipconfig，linux设备输ip -4 -br -c addr获取ip address，获取到的地址格式类似于192.168.123.234，输入获取到的地址后按回车键确认。" 20 50 --title "MODIFY DISPLAY PORT " 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i "s/${XSDLIP}/${TARGET}/g" "$(command -v startxsdl)"
		echo 'Your current ip address has been modified.'
		echo '您当前的ip地址已修改为'
		echo $(sed -n 3p $(command -v startxsdl) | cut -d '=' -f 2 | cut -d ':' -f 1)
		press_enter_to_return
		modify_xsdl_conf
	else
		modify_xsdl_conf
	fi
}
#################
press_enter_to_continue() {
	echo "Press ${GREEN}enter${RESET} to ${BLUE}continue.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}继续${RESET}"
	read
}
#############################################
press_enter_to_return() {
	echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
	echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
	read
}
#############################################
press_enter_to_return_configure_xrdp() {
	press_enter_to_return
	configure_xrdp
}
##############
modify_xwayland_conf() {
	if [ ! -e "/etc/xwayland" ] && [ ! -L "/etc/xwayland" ]; then
		echo "${RED}WARNING！${RESET}检测到wayland目录${YELLOW}不存在${RESET}"
		echo "请先在termux里进行配置，再返回此处选择您需要配置的桌面环境"
		echo "若您无root权限，则有可能配置失败！"
		press_enter_to_return
		modify_remote_desktop_config
	fi
	if (whiptail --title "你想要对这个小可爱做什么" --yes-button "启动" --no-button 'Configure配置' --yesno "您是想要启动桌面还是配置wayland？" 9 50); then
		if [ ! -e "/usr/local/bin/startw" ] || [ ! $(command -v weston) ]; then
			echo "未检测到启动脚本，请重新配置"
			echo "Please reconfigure xwayland"
			sleep 2s
			xwayland_onekey
		fi
		/usr/local/bin/startw
	else
		configure_xwayland
	fi
}
##################
#############
press_enter_to_return_configure_xwayland() {
	press_enter_to_return
	configure_xwayland
}
#######################
xwayland_desktop_enviroment() {
	X11_OR_WAYLAND_DESKTOP='xwayland'
	configure_remote_desktop_enviroment
}
#############
configure_xwayland() {
	RETURN_TO_WHERE='configure_xwayland'
	#进入xwayland配置文件目录
	cd /etc/xwayland/
	TMOE_OPTION=$(
		whiptail --title "CONFIGURE xwayland" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 14 50 5 \
			"1" "One-key conf 初始化一键配置" \
			"2" "指定xwayland桌面环境" \
			"3" "pulse_server音频服务" \
			"4" "remove 卸载/移除" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	case "${TMOE_OPTION}" in
	0 | "") modify_remote_desktop_config ;;
	1) xwayland_onekey ;;
	2) xwayland_desktop_enviroment ;;
	3) xwayland_pulse_server ;;
	4) remove_xwayland ;;
	esac
	##############################
	press_enter_to_return_configure_xwayland
}
#####################
remove_xwayland() {
	echo "${YELLOW}This is a dangerous operation, you must press Enter to confirm${RESET}"
	#service xwayland restart
	RETURN_TO_WHERE='configure_xwayland'
	do_you_want_to_continue
	DEPENDENCY_01='weston'
	DEPENDENCY_02='xwayland'
	NON_DEBIAN='false'
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02='xorg-server-xwayland'
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		DEPENDENCY_02='xorg-x11-server-Xwayland'
	fi
	rm -fv /etc/xwayland/startw
	echo "${YELLOW}已删除xwayland启动脚本${RESET}"
	echo "即将为您卸载..."
	${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
}
##############
xwayland_pulse_server() {
	cd /usr/local/bin/
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可以在此处修改。当前为$(grep 'PULSE_SERVER' startw | grep -v '^#' | cut -d '=' -f 2 | head -n 1) \n若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'" 15 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		if grep '^export.*PULSE_SERVER' startw; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startw
		else
			sed -i "3 a\export PULSE_SERVER=$TARGET" startw
		fi
		echo 'Your current PULSEAUDIO SERVER address has been modified.'
		echo '您当前的音频地址已修改为'
		echo $(grep 'PULSE_SERVER' startw | grep -v '^#' | cut -d '=' -f 2 | head -n 1)
		press_enter_to_return_configure_xwayland
	else
		configure_xwayland
	fi
}
##############
xwayland_onekey() {
	RETURN_TO_WHERE='configure_xwayland'
	do_you_want_to_continue

	DEPENDENCY_01='weston'
	DEPENDENCY_02='xwayland'
	NON_DEBIAN='false'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ $(command -v startplasma-x11) ]; then
			DEPENDENCY_02='xwayland plasma-workspace-wayland'
		fi
	fi
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_02='xorg-server-xwayland'
	fi
	beta_features_quick_install
	###################
	cat >${HOME}/.config/weston.ini <<-'EndOFweston'
		[core]
		### uncomment this line for xwayland support ###
		modules=xwayland.so

		[shell]
		background-image=/usr/share/backgrounds/gnome/Aqua.jpg
		background-color=0xff002244
		panel-color=0x90ff0000
		locking=true
		animation=zoom
		#binding-modifier=ctrl
		#num-workspaces=6
		### for cursor themes install xcursor-themes pkg from Extra. ###
		#cursor-theme=whiteglass
		#cursor-size=24

		### tablet options ###
		#lockscreen-icon=/usr/share/icons/gnome/256x256/actions/lock.png
		#lockscreen=/usr/share/backgrounds/gnome/Garden.jpg
		#homescreen=/usr/share/backgrounds/gnome/Blinds.jpg
		#animation=fade

		[keyboard]
		keymap_rules=evdev
		#keymap_layout=gb
		#keymap_options=caps:ctrl_modifier,shift:both_capslock_cancel
		### keymap_options from /usr/share/X11/xkb/rules/base.lst ###

		[terminal]
		#font=DroidSansMono
		#font-size=14

		[screensaver]
		# Uncomment path to disable screensaver
		path=/usr/libexec/weston-screensaver
		duration=600

		[input-method]
		path=/usr/libexec/weston-keyboard

		###  for Laptop displays  ###
		#[output]
		#name=LVDS1
		#mode=1680x1050
		#transform=90

		#[output]
		#name=VGA1
		# The following sets the mode with a modeline, you can get modelines for your preffered resolutions using the cvt utility
		#mode=173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync
		#transform=flipped

		#[output]
		#name=X1
		mode=1440x720
		#transform=flipped-270
	EndOFweston
	cd /usr/local/bin
	cat >startw <<-'EndOFwayland'
		#!/bin/bash
		chmod +x -R /etc/xwayland
		XDG_RUNTIME_DIR=/etc/xwayland Xwayland &
		export PULSE_SERVER=127.0.0.1:0
		export DISPLAY=:0
		xfce4-session
	EndOFwayland
	chmod +x startw
	xwayland_desktop_enviroment
	###########################
	press_enter_to_return_configure_xwayland
	#此处的返回步骤并非多余
}
###########
##################
modify_xrdp_conf() {
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "${RED}WARNING！${RESET}检测到您当前处于${GREEN}proot容器${RESET}环境下！"
		echo "若您的宿主机为${BOLD}Android${RESET}系统，则${RED}无法${RESET}${BLUE}保障${RESET}xrdp可以正常连接！"
		RETURN_TO_WHERE='modify_remote_desktop_config'
		do_you_want_to_continue
	fi

	pgrep xrdp &>/dev/null
	if [ "$?" = "0" ]; then
		FILEBROWSER_STATUS='检测到xrdp进程正在运行'
		FILEBROWSER_PROCESS='Restart重启'
	else
		FILEBROWSER_STATUS='检测到xrdp进程未运行'
		FILEBROWSER_PROCESS='Start启动'
	fi

	if (whiptail --title "你想要对这个小可爱做什么" --yes-button "${FILEBROWSER_PROCESS}" --no-button 'Configure配置' --yesno "您是想要启动服务还是配置服务？${FILEBROWSER_STATUS}" 9 50); then
		if [ ! -e "${HOME}/.config/tmoe-linux/xrdp.ini" ]; then
			echo "未检测到已备份的xrdp配置文件，请重新配置"
			echo "Please reconfigure xrdp"
			sleep 2s
			xrdp_onekey
		fi
		xrdp_restart
	else
		configure_xrdp
	fi
}
#############
xrdp_desktop_enviroment() {
	X11_OR_WAYLAND_DESKTOP='xrdp'
	configure_remote_desktop_enviroment
}
#############
configure_xrdp() {
	#进入xrdp配置文件目录
	cd /etc/xrdp/
	TMOE_OPTION=$(
		whiptail --title "CONFIGURE XRDP" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 14 50 5 \
			"1" "One-key conf 初始化一键配置" \
			"2" "指定xrdp桌面环境" \
			"3" "xrdp port 修改xrdp端口" \
			"4" "xrdp.ini修改配置文件" \
			"5" "startwm.sh修改启动脚本" \
			"6" "stop 停止" \
			"7" "status 进程状态" \
			"8" "pulse_server音频服务" \
			"9" "reset 重置" \
			"10" "remove 卸载/移除" \
			"11" "进程管理说明" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	case "${TMOE_OPTION}" in
	0 | "") modify_remote_desktop_config ;;
	1)
		service xrdp stop 2>/dev/null
		xrdp_onekey
		;;
	2)
		X11_OR_WAYLAND_DESKTOP='xrdp'
		#xrdp_desktop_enviroment
		configure_remote_desktop_enviroment
		;;
	3) xrdp_port ;;
	4) nano /etc/xrdp/xrdp.ini ;;
	5) nano /etc/xrdp/startwm.sh ;;
	6)
		service xrdp stop 2>/dev/null
		service xrdp status | head -n 24
		;;
	7)
		echo "Type ${GREEN}q${RESET} to ${BLUE}return.${RESET}"
		service xrdp status
		;;
	8) xrdp_pulse_server ;;
	9) xrdp_reset ;;
	10) remove_xrdp ;;
	11) xrdp_systemd ;;
	esac
	##############################
	press_enter_to_return_configure_xrdp
}
#############
remove_xrdp() {
	pkill xrdp
	echo "正在停止xrdp进程..."
	echo "Stopping xrdp..."
	service xrdp stop 2>/dev/null
	echo "${YELLOW}This is a dangerous operation, you must press Enter to confirm${RESET}"
	#service xrdp restart
	RETURN_TO_WHERE='configure_xrdp'
	do_you_want_to_continue
	rm -fv /etc/xrdp/xrdp.ini /etc/xrdp/startwm.sh
	echo "${YELLOW}已删除xrdp配置文件${RESET}"
	echo "即将为您卸载..."
	${PACKAGES_REMOVE_COMMAND} xrdp
}
################
configure_remote_desktop_enviroment() {
	BETA_DESKTOP=$(whiptail --title "REMOTE_DESKTOP" --menu \
		"您想要配置哪个桌面？按方向键选择，回车键确认！\n Which desktop environment do you want to configure? " 15 60 5 \
		"1" "xfce：兼容性高" \
		"2" "lxde：轻量化桌面" \
		"3" "mate：基于GNOME 2" \
		"4" "lxqt" \
		"5" "kde plasma 5" \
		"6" "gnome 3" \
		"7" "cinnamon" \
		"8" "dde (deepin desktop)" \
		"0" "我一个都不选 =￣ω￣=" \
		3>&1 1>&2 2>&3)
	##########################
	if [ "${BETA_DESKTOP}" == '1' ]; then
		REMOTE_DESKTOP_SESSION_01='xfce4-session'
		REMOTE_DESKTOP_SESSION_02='startxfce4'
		#configure_remote_xfce4_desktop
	fi
	##########################
	if [ "${BETA_DESKTOP}" == '2' ]; then
		REMOTE_DESKTOP_SESSION_01='lxsession'
		REMOTE_DESKTOP_SESSION_02='startlxde'
		#configure_remote_lxde_desktop
	fi
	##########################
	if [ "${BETA_DESKTOP}" == '3' ]; then
		REMOTE_DESKTOP_SESSION_01='mate-session'
		REMOTE_DESKTOP_SESSION_02='x-windows-manager'
		#configure_remote_mate_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '4' ]; then
		REMOTE_DESKTOP_SESSION_01='lxqt-session'
		REMOTE_DESKTOP_SESSION_02='startlxqt'
		#configure_remote_lxqt_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '5' ]; then
		#REMOTE_DESKTOP_SESSION='plasma-x11-session'
		#configure_remote_kde_plasma5_desktop
		REMOTE_DESKTOP_SESSION_01='startkde'
		REMOTE_DESKTOP_SESSION_02='startplasma-x11'
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '6' ]; then
		REMOTE_DESKTOP_SESSION_01='gnome-session'
		REMOTE_DESKTOP_SESSION_02='x-window-manager'
		#configure_remote_gnome3_desktop
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '7' ]; then
		#configure_remote_cinnamon_desktop
		REMOTE_DESKTOP_SESSION_01='cinnamon-launcher'
		REMOTE_DESKTOP_SESSION_02='cinnamon-session'
	fi
	##############################
	if [ "${BETA_DESKTOP}" == '8' ]; then
		REMOTE_DESKTOP_SESSION_01='startdde'
		REMOTE_DESKTOP_SESSION_02='x-window-manager'
		#configure_remote_deepin_desktop
	fi
	##########################
	if [ "${BETA_DESKTOP}" == '0' ] || [ -z ${BETA_DESKTOP} ]; then
		modify_remote_desktop_config
	fi
	##########################
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		if [ "${LINUX_DISTRO}" = "debian" ] || [ "${LINUX_DISTRO}" = "redhat" ]; then
			NON_DBUS='true'
		fi
	fi
	if [ $(command -v ${REMOTE_DESKTOP_SESSION_01}) ]; then
		REMOTE_DESKTOP_SESSION="${REMOTE_DESKTOP_SESSION_01}"
	else
		REMOTE_DESKTOP_SESSION="${REMOTE_DESKTOP_SESSION_02}"
	fi
	configure_remote_desktop_session
	press_enter_to_return
	modify_remote_desktop_config
}
##############
configure_xrdp_remote_desktop_session() {
	echo "${REMOTE_DESKTOP_SESSION}" >~/.xsession
	#touch ~/.session
	cd /etc/xrdp
	sed -i '/session/d' startwm.sh
	sed -i '/start/d' startwm.sh
	if grep 'exec' startwm.sh; then
		sed -i '$ d' startwm.sh
		sed -i '$ d' startwm.sh
	fi
	#sed -i '/X11\/Xsession/d' startwm.sh
	cat >>startwm.sh <<-'EnfOfStartWM'
		test -x /etc/X11/Xsession && exec /etc/X11/Xsession
		exec /bin/sh /etc/X11/Xsession
	EnfOfStartWM
	sed -i "s@exec /etc/X11/Xsession@exec ${REMOTE_DESKTOP_SESSION}@g" /etc/xrdp/startwm.sh
	sed -i "s@exec /bin/sh /etc/X11/Xsession@exec /bin/sh ${REMOTE_DESKTOP_SESSION}@g" /etc/xrdp/startwm.sh
	echo "修改完成，若无法生效，则请使用强制配置功能[Y/f]"
	echo "输f启用，一般情况下无需启用，因为这可能会造成一些问题。"
	echo "若root用户无法连接，则请使用${GREEN}adduser${RESET}命令新建一个普通用户"
	echo 'If the configuration fails, please use the mandatory configuration function！'
	echo "Press enter to return,type f to force congigure."
	echo "按${GREEN}回车键${RESET}${RED}返回${RESET}，输${YELLOW}f${RESET}启用${BLUE}强制配置功能${RESET}"
	read opt
	case $opt in
	y* | Y* | "") ;;
	f* | F*)
		sed -i "s@/etc/X11/Xsession@${REMOTE_DESKTOP_SESSION}@g" startwm.sh
		;;
	*)
		echo "Invalid choice. skipped."
		${RETURN_TO_WHERE}
		#beta_features
		;;
	esac
	service xrdp restart
	service xrdp status
}
##############
configure_xwayland_remote_desktop_session() {
	cd /usr/local/bin
	cat >startw <<-EndOFwayland
		#!/bin/bash
		chmod +x -R /etc/xwayland
		XDG_RUNTIME_DIR=/etc/xwayland Xwayland &
		export PULSE_SERVER=127.0.0.1:0
		export DISPLAY=:0
		${REMOTE_DESKTOP_SESSION}
	EndOFwayland
	echo ${REMOTE_DESKTOP_SESSION}
	chmod +x startw
	echo "配置完成，请先打开sparkle app，点击Start"
	echo "然后在GNU/Linux容器里输startw启动xwayland"
	echo "在使用过程中，您可以按音量+调出键盘"
	echo "执行完startw后,您可能需要经历长达30s的黑屏"
	echo "Press ${GREEN}enter${RESET} to ${BLUE}continue${RESET}"
	echo "按${GREEN}回车键${RESET}执行${BLUE}startw${RESET}"
	read
	startw
}
#################
configure_remote_desktop_session() {
	if [ "${X11_OR_WAYLAND_DESKTOP}" == 'xrdp' ]; then
		configure_xrdp_remote_desktop_session
	elif [ "${X11_OR_WAYLAND_DESKTOP}" == 'xwayland' ]; then
		configure_xwayland_remote_desktop_session
	elif [ "${X11_OR_WAYLAND_DESKTOP}" == 'x11vnc' ]; then
		configure_x11vnc_remote_desktop_session
	fi
}
#####################
xrdp_pulse_server() {
	cd /etc/xrdp
	TARGET=$(whiptail --inputbox "若您需要转发音频到其它设备,那么您可在此处修改。linux默认为127.0.0.1,WSL2默认为宿主机ip,当前为$(grep 'PULSE_SERVER' startwm.sh | grep -v '^#' | cut -d '=' -f 2 | head -n 1) \n若您曾在音频服务端（接收音频的设备）上运行过Tmoe-linux(仅限Android和win10),并配置允许局域网连接,则只需输入该设备ip,无需加端口号。注：win10需手动打开'C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat'" 15 50 --title "MODIFY PULSE SERVER ADDRESS" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then

		if grep ! '^export.*PULSE_SERVER' startwm.sh; then
			sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startwm.sh
			#sed -i "4 a\export PULSE_SERVER=$TARGET" startwm.sh
		fi
		sed -i "s@export.*PULSE_SERVER=.*@export PULSE_SERVER=$TARGET@" startwm.sh
		echo 'Your current PULSEAUDIO SERVER address has been modified.'
		echo '您当前的音频地址已修改为'
		echo $(grep 'PULSE_SERVER' startwm.sh | grep -v '^#' | cut -d '=' -f 2 | head -n 1)
		press_enter_to_return_configure_xrdp
	else
		configure_xrdp
	fi
}
##############
xrdp_onekey() {
	RETURN_TO_WHERE='configure_xrdp'
	do_you_want_to_continue

	DEPENDENCY_01='xrdp'
	DEPENDENCY_02='nano'
	NON_DEBIAN='false'
	if [ "${LINUX_DISTRO}" = "gentoo" ]; then
		emerge -avk layman
		layman -a bleeding-edge
		layman -S
		#ACCEPT_KEYWORDS="~amd64" USE="server" emerge -a xrdp
	fi
	beta_features_quick_install
	##############
	mkdir -p /etc/polkit-1/localauthority.conf.d /etc/polkit-1/localauthority/50-local.d/
	cat >/etc/polkit-1/localauthority.conf.d/02-allow-colord.conf <<-'EndOfxrdp'
		polkit.addRule(function(action, subject) {
		if ((action.id == “org.freedesktop.color-manager.create-device” || action.id == “org.freedesktop.color-manager.create-profile” || action.id == “org.freedesktop.color-manager.delete-device” || action.id == “org.freedesktop.color-manager.delete-profile” || action.id == “org.freedesktop.color-manager.modify-device” || action.id == “org.freedesktop.color-manager.modify-profile”) && subject.isInGroup(“{group}”))
		{
		return polkit.Result.YES;
		}
		});
	EndOfxrdp
	#############
	cat >/etc/polkit-1/localauthority/50-local.d/45-allow.colord.pkla <<-'ENDofpolkit'
		[Allow Colord all Users]
		Identity=unix-user:*
		Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
		ResultAny=no
		ResultInactive=no
		ResultActive=yes

		[Allow Package Management all Users]
		Identity=unix-user:*
		Action=org.debian.apt.*;io.snapcraft.*;org.freedesktop.packagekit.*;com.ubuntu.update-notifier.*
		ResultAny=no
		ResultInactive=no
		ResultActive=yes
	ENDofpolkit
	###################

	if [ ! -e "${HOME}/.config/tmoe-linux/xrdp.ini" ]; then
		mkdir -p ${HOME}/.config/tmoe-linux/
		cd /etc/xrdp/
		cp -p startwm.sh xrdp.ini ${HOME}/.config/tmoe-linux/
	fi
	####################
	if [ -e "/usr/bin/xfce4-session" ]; then
		if [ ! -e " ~/.xsession" ]; then
			echo 'xfce4-session' >~/.xsession
			touch ~/.session
			sed -i 's:exec /bin/sh /etc/X11/Xsession:exec /bin/sh xfce4-session /etc/X11/Xsession:g' /etc/xrdp/startwm.sh
		fi
	fi

	if ! grep -q '^export PULSE_SERVER' /etc/xrdp/startwm.sh; then
		sed -i '/test -x \/etc\/X11/i\export PULSE_SERVER=127.0.0.1' /etc/xrdp/startwm.sh
	fi
	###########################
	if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
		if grep -q '172..*1' "/etc/resolv.conf"; then
			echo "检测到您当前使用的可能是WSL2"
			WSL2IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
			sed -i "s/^export PULSE_SERVER=.*/export PULSE_SERVER=${WSL2IP}/g" /etc/xrdp/startwm.sh
			echo "已将您的音频服务ip修改为${WSL2IP}"
		fi
		echo '检测到您使用的是WSL,为防止与windows自带的远程桌面的3389端口冲突，请您设定一个新的端口'
		sleep 2s
	fi
	xrdp_port
	xrdp_restart
	################
	press_enter_to_return_configure_xrdp
	#此处的返回步骤并非多余
}
############
xrdp_restart() {
	cd /etc/xrdp/
	RDP_PORT=$(cat xrdp.ini | grep 'port=' | head -n 1 | cut -d '=' -f 2)
	service xrdp restart 2>/dev/null
	if [ "$?" != "0" ]; then
		/etc/init.d/xrdp restart
	fi
	service xrdp status | head -n 24
	echo "您可以输${YELLOW}service xrdp stop${RESET}来停止进程"
	echo "您当前的IP地址为"
	ip -4 -br -c a | cut -d '/' -f 1
	echo "端口号为${RDP_PORT}"
	echo "正在为您启动xrdp服务，本机默认访问地址为localhost:${RDP_PORT}"
	echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${RDP_PORT}
	echo "如需停止xrdp服务，请输service xrdp stop或systemctl stop xrdp"
	echo "如需修改当前用户密码，请输passwd"
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		echo "检测到您使用的是arch系发行版，您之后可以输xrdp来启动xrdp服务"
		xrdp
	fi
	if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
		echo '检测到您使用的是WSL，正在为您打开音频服务'
		export PULSE_SERVER=tcp:127.0.0.1
		if grep -q '172..*1' "/etc/resolv.conf"; then
			echo "检测到您当前使用的可能是WSL2"
			WSL2IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
			export PULSE_SERVER=tcp:${WSL2IP}
			echo "已将您的音频服务ip修改为${WSL2IP}"
		fi
		cd "/mnt/c/Users/Public/Downloads/pulseaudio/bin"
		/mnt/c/WINDOWS/system32/cmd.exe /c "start .\pulseaudio.bat" 2>/dev/null
		echo "若无法自动打开音频服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat"
	fi
}
#################
xrdp_port() {
	cd /etc/xrdp/
	RDP_PORT=$(cat xrdp.ini | grep 'port=' | head -n 1 | cut -d '=' -f 2)
	TARGET_PORT=$(whiptail --inputbox "请输入新的端口号(纯数字)，范围在1-65525之间,不建议您将其设置为22、80、443或3389,检测到您当前的端口为${RDP_PORT}\n Please enter the port number." 12 50 --title "PORT" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		press_enter_to_return_configure_xrdp
	fi
	sed -i "s@port=${RDP_PORT}@port=${TARGET_PORT}@" xrdp.ini
	ls -l $(pwd)/xrdp.ini
	cat xrdp.ini | grep 'port=' | head -n 1
	/etc/init.d/xrdp restart
}
#################
xrdp_systemd() {
	if [ -e "/tmp/.Chroot-Container-Detection-File" ]; then
		echo "检测到您当前处于chroot容器环境下，无法使用systemctl命令"
	elif [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您当前处于${BLUE}proot容器${RESET}环境下，无法使用systemctl命令"
	fi

	cat <<-'EOF'
		    systemd管理
			输systemctl start xrdp启动
			输systemctl stop xrdp停止
			输systemctl status xrdp查看进程状态
			输systemctl enable xrdp开机自启
			输systemctl disable xrdp禁用开机自启

			service命令
			输service xrdp start启动
			输service xrdp stop停止
			输service xrdp status查看进程状态

		    init.d管理
			/etc/init.d/xrdp start启动
			/etc/init.d/xrdp restart重启
			/etc/init.d/xrdp stop停止
			/etc/init.d/xrdp statuss查看进程状态
			/etc/init.d/xrdp force-reload重新加载
	EOF
}
###############
xrdp_reset() {
	echo "正在停止xrdp进程..."
	echo "Stopping xrdp..."
	pkill xrdp
	service xrdp stop 2>/dev/null
	echo "${YELLOW}WARNING！继续执行此操作将丢失xrdp配置信息！${RESET}"
	RETURN_TO_WHERE='configure_xrdp'
	do_you_want_to_continue
	rm -f /etc/polkit-1/localauthority/50-local.d/45-allow.colord.pkla /etc/polkit-1/localauthority.conf.d/02-allow-colord.conf
	cd ${HOME}/.config/tmoe-linux
	cp -pf xrdp.ini startwm.sh /etc/xrdp/
}
#################################
#################################
configure_startxsdl() {
	cd /usr/local/bin
	cat >startxsdl <<-'EndOfFile'
		#!/bin/bash
		stopvnc >/dev/null 2>&1
		export DISPLAY=127.0.0.1:0
		export PULSE_SERVER=tcp:127.0.0.1:4713
		echo '正在为您启动xsdl,请将display number改为0'
		echo 'Starting xsdl, please change display number to 0'
		echo '默认为前台运行，您可以按Ctrl+C终止，或者在termux原系统内输stopvnc'
		echo 'The default is to run in the foreground, you can press Ctrl + C to terminate, or type "stopvnc" in the original termux system.'
		if [ "$(uname -r | cut -d '-' -f 3)" = "Microsoft" ] || [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
			echo '检测到您使用的是WSL,正在为您打开音频服务'
			export PULSE_SERVER=tcp:127.0.0.1
			cd "/mnt/c/Users/Public/Downloads/pulseaudio"
			/mnt/c/WINDOWS/system32/cmd.exe /c "start .\pulseaudio.bat"
			echo "若无法自动打开音频服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat"
			cd "/mnt/c/Users/Public/Downloads/VcXsrv/"
			#/mnt/c/WINDOWS/system32/cmd.exe /c "start .\config.xlaunch"
			/mnt/c/WINDOWS/system32/taskkill.exe /f /im vcxsrv.exe 2>/dev/null
			/mnt/c/WINDOWS/system32/cmd.exe /c "start .\vcxsrv.exe :0 -multiwindow -clipboard -wgl -ac"
			echo "若无法自动打开X服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\VcXsrv\vcxsrv.exe"
			if grep -q '172..*1' "/etc/resolv.conf"; then
				echo "检测到您当前使用的可能是WSL2，如需手动启动，请在xlaunch.exe中勾选Disable access control"
				WSL2IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
				export PULSE_SERVER=${WSL2IP}
				export DISPLAY=${WSL2IP}:0
				echo "已将您的显示和音频服务ip修改为${WSL2IP}"
			fi
			sleep 2
		fi
		#不要将上面uname -r的检测修改为WINDOWSDISTRO
		#sudo下无法用whoami检测用户
		CURRENTuser=$(ls -lt /home | grep ^d | head -n 1 | awk -F ' ' '$0=$NF')
		if [ ! -z "${CURRENTuser}" ] && [ "${HOME}" != "/root" ]; then
			if [ -e "${HOME}/.profile" ]; then
				CURRENTuser=$(ls -l ${HOME}/.profile | cut -d ' ' -f 3)
				CURRENTgroup=$(ls -l ${HOME}/.profile | cut -d ' ' -f 4)
			elif [ -e "${HOME}/.bashrc" ]; then
				CURRENTuser=$(ls -l ${HOME}/.bashrc | cut -d ' ' -f 3)
				CURRENTgroup=$(ls -l ${HOME}/.bashrc | cut -d ' ' -f 4)
			elif [ -e "${HOME}/.zshrc" ]; then
				CURRENTuser=$(ls -l ${HOME}/.zshrc | cut -d ' ' -f 3)
				CURRENTgroup=$(ls -l ${HOME}/.zshrc | cut -d ' ' -f 4)
			fi
			echo "检测到/home目录不为空，为避免权限问题，正在将${HOME}目录下的.ICEauthority、.Xauthority以及.vnc 的权限归属修改为${CURRENTuser}用户和${CURRENTgroup}用户组"
			cd ${HOME}
			chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null || sudo chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null
		fi
		export LANG="zh_CN.UTF-8"
	EndOfFile
	cat >>startxsdl <<-ENDofStartxsdl
		if [ \$(command -v ${REMOTE_DESKTOP_SESSION_01}) ]; then
			dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_01}
		else
			dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_02}
		fi
	ENDofStartxsdl
	#启动命令结尾无&
	###############################
	#debian禁用dbus分两次，并非重复
	if [ "${NON_DBUS}" = "true" ]; then
		if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
			sed -i 's:dbus-launch --exit-with-session::' startxsdl ~/.vnc/xstartup
		fi
	fi
}
#################
configure_startvnc() {
	cd /usr/local/bin
	cat >startvnc <<-'EndOfFile'
		#!/bin/bash
		stopvnc >/dev/null 2>&1
		export USER="$(whoami)"
		export HOME="${HOME}"
		if [ ! -e "${HOME}/.vnc/xstartup" ]; then
			sudo cp -rvf "/root/.vnc" "${HOME}" || su -c "cp -rvf /root/.vnc ${HOME}"
		fi
		if [ "$(uname -r | cut -d '-' -f 3)" = "Microsoft" ] || [ "$(uname -r | cut -d '-' -f 2)" = "microsoft" ]; then
			echo '检测到您使用的是WSL,正在为您打开音频服务'
			export PULSE_SERVER=tcp:127.0.0.1
			cd "/mnt/c/Users/Public/Downloads/pulseaudio"
			/mnt/c/WINDOWS/system32/cmd.exe /c "start .\pulseaudio.bat"
			echo "若无法自动打开音频服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\pulseaudio\pulseaudio.bat"
			if grep -q '172..*1' "/etc/resolv.conf"; then
				echo "检测到您当前使用的可能是WSL2"
				WSL2IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
				sed -i "s/^export PULSE_SERVER=.*/export PULSE_SERVER=${WSL2IP}/g" ~/.vnc/xstartup
				echo "已将您的音频服务ip修改为${WSL2IP}"
			fi
			#grep 无法从"~/.vnc"中读取文件，去掉双引号就可以了。
			sleep 2
		fi
		CURRENTuser=$(ls -lt /home | grep ^d | head -n 1 | awk -F ' ' '$0=$NF')
		if [ ! -z "${CURRENTuser}" ] && [ "${HOME}" != "/root" ]; then
		if [ -e "${HOME}/.profile" ]; then
			CURRENTuser=$(ls -l ${HOME}/.profile | cut -d ' ' -f 3)
			CURRENTgroup=$(ls -l ${HOME}/.profile | cut -d ' ' -f 4)
		elif [ -e "${HOME}/.bashrc" ]; then
			CURRENTuser=$(ls -l ${HOME}/.bashrc | cut -d ' ' -f 3)
			CURRENTgroup=$(ls -l ${HOME}/.bashrc | cut -d ' ' -f 4)
		elif [ -e "${HOME}/.zshrc" ]; then
			CURRENTuser=$(ls -l ${HOME}/.zshrc | cut -d ' ' -f 3)
			CURRENTgroup=$(ls -l ${HOME}/.zshrc | cut -d ' ' -f 4)
		fi
		echo "检测到/home目录不为空，为避免权限问题，正在将${HOME}目录下的.ICEauthority、.Xauthority以及.vnc 的权限归属修改为${CURRENTuser}用户和${CURRENTgroup}用户组"
			cd ${HOME}
		chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null || sudo chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null
		fi
		echo "正在启动vnc服务,本机默认vnc地址localhost:5901"
		echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):5901
		export LANG="zh_CN.UTF8"
		#启动VNC服务的命令为最后一行
		vncserver -geometry 1440x720 -depth 24 -name tmoe-linux :1
	EndOfFile
	##############
	cat >stopvnc <<-'EndOfFile'
		#!/bin/bash
		export USER="$(whoami)"
		export HOME="${HOME}"
		vncserver -kill :1
		rm -rf /tmp/.X1-lock
		rm -rf /tmp/.X11-unix/X1
		pkill Xtightvnc
		stopx11vnc 2>/dev/null
	EndOfFile
}
###############
first_configure_startvnc() {
	#卸载udisks2，会破坏mate和plasma的依赖关系。
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ] && [ ${REMOVE_UDISK2} = 'true' ]; then
		if [ "${LINUX_DISTRO}" = 'debian' ]; then
			echo "检测到您处于${BLUE}proot容器${RESET}环境下，即将为您${RED}卸载${RESET}${YELLOW}udisk2${RESET}和${GREEN}gvfs${RESET}"
			#umount .gvfs
			apt purge -y --allow-change-held-packages ^udisks2 ^gvfs
		fi
	fi
	configure_startvnc
	configure_startxsdl
	if [ "${LINUX_DISTRO}" != "debian" ]; then
		sed -i 's@--exit-with-session@@' ~/.vnc/xstartup /usr/local/bin/startxsdl
	fi
	######################
	chmod +x startvnc stopvnc startxsdl
	dpkg --configure -a 2>/dev/null

	CURRENTuser=$(ls -lt /home | grep ^d | head -n 1 | awk -F ' ' '$0=$NF')
	if [ ! -z "${CURRENTuser}" ]; then
		if [ -e "${HOME}/.profile" ]; then
			CURRENTuser=$(ls -l ${HOME}/.profile | cut -d ' ' -f 3)
			CURRENTgroup=$(ls -l ${HOME}/.profile | cut -d ' ' -f 4)
		elif [ -e "${HOME}/.bashrc" ]; then
			CURRENTuser=$(ls -l ${HOME}/.bashrc | cut -d ' ' -f 3)
			CURRENTgroup=$(ls -l ${HOME}/.bashrc | cut -d ' ' -f 4)
		elif [ -e "${HOME}/.zshrc" ]; then
			CURRENTuser=$(ls -l ${HOME}/.zshrc | cut -d ' ' -f 3)
			CURRENTgroup=$(ls -l ${HOME}/.zshrc | cut -d ' ' -f 4)
		fi
		echo "检测到/home目录不为空，为避免权限问题，正在将${HOME}目录下的.ICEauthority、.Xauthority以及.vnc 的权限归属修改为${CURRENTuser}用户和${CURRENTgroup}用户组"
		cd ${HOME}
		chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null || sudo chown -R ${CURRENTuser}:${CURRENTgroup} ".ICEauthority" ".ICEauthority" ".vnc" 2>/dev/null
	fi
	#仅针对WSL修改语言设定
	if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
		if [ "${LANG}" != 'zh_CN.UTF8' ]; then
			grep -q 'LANG=\"zh_CN' "/etc/profile" || sed -i '$ a\export LANG="zh_CN.UTF-8"' "/etc/profile"
			grep -q 'LANG=\"zh_CN' "${HOME}/.zlogin" || echo 'export LANG="zh_CN.UTF-8"' >>"${HOME}/.zlogin"
		fi
	fi
	echo "The vnc service is about to start for you. The password you entered is hidden."
	echo "即将为您启动vnc服务，您需要输两遍${RED}（不可见的）${RESET}密码。"
	echo "When prompted for a view-only password, it is recommended that you enter${YELLOW} 'n'${RESET}"
	echo "如果提示${BLUE}view-only${RESET},那么建议您输${YELLOW}n${RESET},选择权在您自己的手上。"
	echo "请输入${RED}6至8位${RESET}${BLUE}密码${RESET}"
	startvnc
	echo "您之后可以输${GREEN}startvnc${RESET}来${BLUE}启动${RESET}vnc服务，输${GREEN}stopvnc${RESET}${RED}停止${RESET}"
	echo "您还可以在termux原系统或windows的linux子系统里输${GREEN}startxsdl${RESET}来启动xsdl，按${YELLOW}Ctrl+C${RESET}或在termux原系统里输${GREEN}stopvnc${RESET}来${RED}停止${RESET}进程"
	xfce4_tightvnc_hidpi_settings
	if [ "${HOME}" != "/root" ]; then
		cp -rpf ~/.vnc /root/ &
		chown -R root:root /root/.vnc &
	fi

	if [ "${WINDOWSDISTRO}" = 'WSL' ]; then
		echo "若无法自动打开X服务，则请手动在资源管理器中打开C:\Users\Public\Downloads\VcXsrv\vcxsrv.exe"
		cd "/mnt/c/Users/Public/Downloads"
		if grep -q '172..*1' "/etc/resolv.conf"; then
			echo "检测到您当前使用的可能是WSL2，如需手动启动，请在xlaunch.exe中勾选Disable access control"
			WSL2IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -n 1)
			export PULSE_SERVER=${WSL2IP}
			export DISPLAY=${WSL2IP}:0
			echo "已将您的X和音频服务ip修改为${WSL2IP}"
		else
			echo "${YELLOW}检测到您使用的是WSL1(第一代win10的Linux子系统)${RESET}"
			echo "${YELLOW}若无法启动x服务，则请在退出脚本后，以非root身份手动输startxsdl来启动windows的x服务${RESET}"
			echo "您也可以手动输startvnc来启动vnc服务"
		fi
		cd ./VcXsrv
		echo "请在启动音频服务前，确保您已经允许pulseaudio.exe通过Windows Defender防火墙"
		if [ ! -e "Firewall-pulseaudio.png" ]; then
			aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "Firewall-pulseaudio.png" 'https://gitee.com/mo2/pic_api/raw/test/2020/03/31/rXLbHDxfj1Vy9HnH.png'
		fi
		/mnt/c/WINDOWS/system32/cmd.exe /c "start Firewall.cpl"
		/mnt/c/WINDOWS/system32/cmd.exe /c "start .\Firewall-pulseaudio.png" 2>/dev/null
		############
		if [ ! -e 'XserverHightDPI.png' ]; then
			aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'XserverHightDPI.png' https://gitee.com/mo2/pic_api/raw/test/2020/03/27/jvNs2JUIbsSQQInO.png
		fi
		/mnt/c/WINDOWS/system32/cmd.exe /c "start .\XserverHightDPI.png" 2>/dev/null
		echo "若X服务的画面过于模糊，则您需要右击vcxsrv.exe，并手动修改兼容性设定中的高Dpi选项。"
		echo "vcxsrv文件位置为C:\Users\Public\Downloads\VcXsrv\vcxsrv.exe"
		echo "${YELLOW}按回车键启动X${RESET}"
		echo "${YELLOW}Press enter to startx${RESET}"
		echo '运行过程中，您可以按Ctrl+C终止前台进程，输pkill -u $(whoami)终止当前用户所有进程'
		#上面那行必须要单引号
		read
		cd "/mnt/c/Users/Public/Downloads"
		/mnt/c/WINDOWS/system32/cmd.exe /c "start ."
		startxsdl &
	fi
	echo "${GREEN}tightvnc/tigervnc & xserver${RESET}配置${BLUE}完成${RESET},将为您配置${GREEN}x11vnc${RESET}"
	x11vnc_warning
	configure_x11vnc_remote_desktop_session
	xfce4_x11vnc_hidpi_settings
}
########################
########################
xfce4_tightvnc_hidpi_settings() {
	if [ "${REMOTE_DESKTOP_SESSION_01}" = 'xfce4-session' ]; then
		echo "检测到您当前的桌面环境为xfce4，将为您自动调整高分屏设定"
		echo "若分辨率不合，则请在脚本执行完成后，手动输${GREEN}debian-i${RESET}，然后在${BLUE}vnc${RESET}选项里进行修改。"
		stopvnc >/dev/null 2>&1
		sed -i '/vncserver -geometry/d' "$(command -v startvnc)"
		sed -i "$ a\vncserver -geometry 2880x1440 -depth 24 -name tmoe-linux :1" "$(command -v startvnc)"
		sed -i "s@^/usr/bin/Xvfb.*@/usr/bin/Xvfb :233 -screen 0 2880x1440x24 -ac +extension GLX +render -noreset \&@" "$(command -v startx11vnc)" 2>/dev/null
		echo "已将默认分辨率修改为2880x1440，窗口缩放大小调整为2x"
		dbus-launch xfconf-query -c xsettings -p /Gdk/WindowScalingFactor -s 2 || dbus-launch xfconf-query -n -t int -c xsettings -p /Gdk/WindowScalingFactor -s 2
		#-n创建一个新属性，类型为int
		dbus-launch xfconf-query -c xfwm4 -p /general/theme -s Default-xhdpi 2>/dev/null
		#dbus-launch xfconf-query -c xfwm4 -p /general/theme -s Kali-Light-xHiDPI 2>/dev/null
		startvnc >/dev/null 2>&1
	fi
	#Default-xhdpi默认处于未激活状态
}
################
xfce4_x11vnc_hidpi_settings() {
	if [ "${REMOTE_DESKTOP_SESSION_01}" = 'xfce4-session' ]; then
		stopx11vnc >/dev/null 2>&1
		sed -i "s@^/usr/bin/Xvfb.*@/usr/bin/Xvfb :233 -screen 0 2880x1440x24 -ac +extension GLX +render -noreset \&@" "$(command -v startx11vnc)"
		startx11vnc >/dev/null 2>&1
	fi
}
####################
frequently_asked_questions() {
	TMOE_FAQ=$(whiptail --title "FAQ(よくある質問)" --menu \
		"您有哪些疑问？\nWhat questions do you have?" 15 60 5 \
		"1" "Cannot open Baidu Netdisk" \
		"2" "udisks2/gvfs配置失败" \
		"3" "linuxQQ闪退" \
		"4" "VNC/X11闪退" \
		"5" "软件禁止以root权限运行" \
		"6" "初始化mlocate数据库失败" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	if [ "${TMOE_FAQ}" == '0' ]; then
		tmoe_linux_tool_menu
	fi
	############################
	if [ "${TMOE_FAQ}" == '1' ]; then
		#echo "若无法打开，则请手动输rm -f ~/baidunetdisk/baidunetdiskdata.db"
		echo "若无法打开，则请手动输rm -rf ~/baidunetdisk"
		echo "按回车键自动执行${YELLOW}rm -vf ~/baidunetdisk/baidunetdiskdata.db${RESET}"
		RETURN_TO_WHERE='frequently_asked_questions'
		do_you_want_to_continue
		rm -vf ~/baidunetdisk/baidunetdiskdata.db
	fi
	#######################
	if [ "${TMOE_FAQ}" == '2' ]; then
		echo "${YELLOW}按回车键卸载gvfs和udisks2${RESET}"
		RETURN_TO_WHERE='frequently_asked_questions'
		do_you_want_to_continue
		${PACKAGES_REMOVE_COMMAND} --allow-change-held-packages ^udisks2 ^gvfs
	fi
	############################
	if [ "${TMOE_FAQ}" == '3' ]; then
		echo "如果版本更新后登录出现闪退的情况，那么您可以输rm -rf ~/.config/tencent-qq/ 后重新登录。"
		echo "${YELLOW}按回车键自动执行上述命令${RESET}"
		RETURN_TO_WHERE='frequently_asked_questions'
		do_you_want_to_continue
		rm -rvf ~/.config/tencent-qq/
	fi
	#######################
	if [ "${TMOE_FAQ}" == '4' ]; then
		fix_vnc_dbus_launch
	fi
	#######################
	if [ "${TMOE_FAQ}" == '5' ]; then
		echo "部分软件出于安全性考虑，禁止以root权限运行。权限越大，责任越大。若root用户不慎操作，将有可能破坏系统。"
		echo "您可以使用以下命令来新建普通用户"
		echo "#创建一个用户名为mo2的新用户"
		echo "${YELLOW}adduser mo2${RESET}"
		echo "#输入的密码是隐藏的，根据提示创建完成后，接着输以下命令"
		echo "#将mo2加入到sudo用户组"
		echo "${YELLOW}adduser mo2 sudo${RESET}"
		echo "之后，若需要提权，则只需输sudo 命令"
		echo "例如${YELLOW}sudo apt update${RESET}"
		echo ""
		echo "切换用户的说明"
		echo "您可以输${YELLOW}sudo su - ${RESET}或${YELLOW}sudo -i ${RESET}切换至root用户"
		echo "亦可输${YELLOW}sudo su - mo2${RESET}或${YELLOW}sudo -iu mo2${RESET}切换回mo2用户"
		echo "若需要以普通用户身份启动VNC，请先切换至普通用户，再输${YELLOW}startvnc${RESET}"
	fi
	###################
	if [ "${TMOE_FAQ}" == '6' ]; then
		echo "您是否需要卸载mlocate和catfish"
		echo "Do you want to remove mlocate and catfish?"
		do_you_want_to_continue
		${PACKAGES_REMOVE_COMMAND} mlocate catfish
		apt autopurge 2>/dev/null
	fi
	##################
	if [ -z "${TMOE_FAQ}" ]; then
		tmoe_linux_tool_menu
	fi
	###########
	press_enter_to_return
	frequently_asked_questions
}
##############
enable_dbus_launch() {
	XSTARTUP_LINE=$(cat -n ~/.vnc/xstartup | grep -v 'command' | grep ${REMOTE_DESKTOP_SESSION_01} | awk -F ' ' '{print $1}')
	sed -i "${XSTARTUP_LINE} c\ dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_01} \&" ~/.vnc/xstartup
	#################
	START_X11VNC_LINE=$(cat -n /usr/local/bin/startx11vnc | grep -v 'command' | grep ${REMOTE_DESKTOP_SESSION_01} | awk -F ' ' '{print $1}')
	sed -i "${START_X11VNC_LINE} c\ dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_01} \&" /usr/local/bin/startx11vnc
	##################
	START_XSDL_LINE=$(cat -n /usr/local/bin/startxsdl | grep -v 'command' | grep ${REMOTE_DESKTOP_SESSION_01} | awk -F ' ' '{print $1}')
	sed -i "${START_XSDL_LINE} c\ dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_01}" /usr/local/bin/startxsdl
	#################
	sed -i "s/.*${REMOTE_DESKTOP_SESSION_02}.*/ dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_02} \&/" ~/.vnc/xstartup "/usr/local/bin/startx11vnc"
	sed -i "s/.*${REMOTE_DESKTOP_SESSION_02}.*/ dbus-launch --exit-with-session ${REMOTE_DESKTOP_SESSION_02}/" "/usr/local/bin/startxsdl"
	if [ "${LINUX_DISTRO}" != "debian" ]; then
		sed -i 's@--exit-with-session@@' ~/.vnc/xstartup /usr/local/bin/startxsdl /usr/local/bin/startx11vnc
	fi
}
#################
fix_vnc_dbus_launch() {
	echo "由于在2020-0410至0411的更新中给所有系统的桌面都加入了dbus-launch，故在部分安卓设备的${BLUE}proot容器${RESET}上出现了兼容性问题。"
	echo "注1：该操作在linux虚拟机及win10子系统上没有任何问题"
	echo "注2：2020-0412更新的版本已加入检测功能，理论上不会再出现此问题。"
	if [ ! -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您当前可能处于非proot环境下，是否继续修复？"
		echo "如需重新配置vnc启动脚本，请更新debian-i后再覆盖安装gui"
	fi
	RETURN_TO_WHERE='frequently_asked_questions'
	do_you_want_to_continue

	if grep 'dbus-launch' ~/.vnc/xstartup; then
		DBUSstatus="$(echo 检测到dbus-launch当前在VNC脚本中处于启用状态)"
	else
		DBUSstatus="$(echo 检测到dbus-launch当前在vnc脚本中处于禁用状态)"
	fi

	if (whiptail --title "您想要对这个小可爱中做什么 " --yes-button "Disable" --no-button "Enable" --yesno "您是想要禁用dbus-launch，还是启用呢？${DBUSstatus} \n请做出您的选择！✨" 10 50); then
		if [ "${LINUX_DISTRO}" = "debian" ]; then
			sed -i 's:dbus-launch --exit-with-session::' "/usr/local/bin/startxsdl" "${HOME}/.vnc/xstartup" "/usr/local/bin/startx11vnc"
		else
			sed -i 's@--exit-with-session@@' ~/.vnc/xstartup /usr/local/bin/startxsdl /usr/local/bin/startx11vnc
		fi
	else
		if grep 'startxfce4' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为xfce4，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_02='startxfce4'
			REMOTE_DESKTOP_SESSION_01='xfce4-session'
		elif grep 'startlxde' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为lxde，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_02='startlxde'
			REMOTE_DESKTOP_SESSION_01='lxsession'
		elif grep 'startlxqt' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为lxqt，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_02='startlxqt'
			REMOTE_DESKTOP_SESSION_01='lxqt-session'
		elif grep 'mate-session' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为mate，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_01='mate-session'
			REMOTE_DESKTOP_SESSION_02='x-windows-manager'
		elif grep 'startplasma' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为KDE Plasma5，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_01='startkde'
			REMOTE_DESKTOP_SESSION_02='startplasma-x11'
		elif grep 'gnome-session' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为GNOME3，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_01='gnome-session'
			REMOTE_DESKTOP_SESSION_02='x-windows-manager'
		elif grep 'cinnamon' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为cinnamon，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_01='cinnamon-launcher'
			REMOTE_DESKTOP_SESSION_02='cinnamon-session'
		elif grep 'startdde' ~/.vnc/xstartup; then
			echo "检测您当前的VNC配置为deepin desktop，正在将dbus-launch加入至启动脚本中..."
			REMOTE_DESKTOP_SESSION_01='startdde'
			REMOTE_DESKTOP_SESSION_02='x-windows-manager'
		else
			echo "未检测到vnc相关配置或您安装的桌面环境不被支持，请更新debian-i后再覆盖安装gui"
		fi
		enable_dbus_launch
	fi

	echo "${YELLOW}修改完成，按回车键返回${RESET}"
	echo "若无法修复，则请前往gitee.com/mo2/linux提交issue，并附上报错截图和详细说明。"
	echo "还建议您附上cat /usr/local/bin/startxsdl 和 cat ~/.vnc/xstartup 的启动脚本截图"
	press_enter_to_return
	tmoe_linux_tool_menu
}
###################
###################
beta_features_management_menu() {
	if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "reinstall重装" --no-button "remove移除" --yesno "检测到您已安装${DEPENDENCY_01} ${DEPENDENCY_02} \nDo you want to reinstall or remove it? ♪(^∇^*) " 10 50); then
		echo "${GREEN} ${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
		echo "即将为您重装..."
	else
		${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02}
		press_enter_to_return
		tmoe_linux_tool_menu
	fi
}
##############
non_debian_function() {
	if [ "${LINUX_DISTRO}" != 'debian' ]; then
		echo "非常抱歉，本功能仅适配deb系发行版"
		echo "Sorry, this feature is only suitable for debian based distributions"
		press_enter_to_return
		if [ ! -z ${RETURN_TO_WHERE} ]; then
			${RETURN_TO_WHERE}
		else
			beta_features
		fi
	fi
}
############
press_enter_to_reinstall() {
	echo "检测到${YELLOW}您已安装${RESET} ${GREEN} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
	echo "如需${RED}卸载${RESET}，请手动输${BLUE} ${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
	press_enter_to_reinstall_yes_or_no
}
################
if_return_to_where_no_empty() {
	if [ ! -z ${RETURN_TO_WHERE} ]; then
		${RETURN_TO_WHERE}
	else
		beta_features
	fi
}
##########
press_enter_to_reinstall_yes_or_no() {
	echo "按${GREEN}回车键${RESET}${RED}重新安装${RESET},输${YELLOW}n${RESET}${BLUE}返回${RESET}"
	echo "输${YELLOW}m${RESET}打开${BLUE}管理菜单${RESET}"
	echo "${YELLOW}Do you want to reinstall it?[Y/m/n]${RESET}"
	echo "Press enter to reinstall,type n to return,type m to open management menu"
	read opt
	case $opt in
	y* | Y* | "") ;;
	n* | N*)
		echo "skipped."
		if_return_to_where_no_empty
		;;
	m* | M*)
		beta_features_management_menu
		;;
	*)
		echo "Invalid choice. skipped."
		if_return_to_where_no_empty
		;;
	esac
}
#######################
beta_features_install_completed() {
	echo "安装${GREEN}完成${RESET}，如需${RED}卸载${RESET}，请手动输${BLUE} ${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
	echo "The installation is complete. If you want to remove, please enter the above highlighted command."
}
####################
beta_features_quick_install() {
	if [ "${NON_DEBIAN}" = 'true' ]; then
		non_debian_function
	fi
	#############
	if [ ! -z "${DEPENDENCY_01}" ]; then
		DEPENDENCY_01_COMMAND=$(echo ${DEPENDENCY_01} | awk -F ' ' '$0=$NF')
		if [ $(command -v ${DEPENDENCY_01_COMMAND}) ]; then
			echo "检测到${YELLOW}您已安装${RESET} ${GREEN} ${DEPENDENCY_01} ${RESET}"
			echo "如需${RED}卸载${RESET}，请手动输${BLUE} ${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_01} ${RESET}"
			EXISTS_COMMAND='true'
		fi
	fi
	#############
	if [ ! -z "${DEPENDENCY_02}" ]; then
		DEPENDENCY_02_COMMAND=$(echo ${DEPENDENCY_02} | awk -F ' ' '$0=$NF')
		if [ $(command -v ${DEPENDENCY_02_COMMAND}) ]; then
			echo "检测到${YELLOW}您已安装${RESET} ${GREEN} ${DEPENDENCY_02} ${RESET}"
			echo "如需${RED}卸载${RESET}，请手动输${BLUE} ${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_02} ${RESET}"
			EXISTS_COMMAND='true'
		fi
	fi
	###############
	echo "即将为您安装相关软件包及其依赖..."
	echo "${GREEN} ${PACKAGES_INSTALL_COMMAND} ${DEPENDENCY_01} ${DEPENDENCY_02} ${RESET}"
	echo "Tmoe-linux tool will install relevant dependencies for you."
	############
	if [ "${EXISTS_COMMAND}" = "true" ]; then
		EXISTS_COMMAND='false'
		press_enter_to_reinstall_yes_or_no
	fi

	############
	different_distro_software_install
	#############
	beta_features_install_completed
}
####################
beta_features() {
	RETURN_TO_WHERE='beta_features'
	NON_DEBIAN='false'
	TMOE_BETA=$(
		whiptail --title "Beta features" --menu "测试版功能可能无法正常运行\nBeta features may not work properly." 17 55 8 \
			"1" "input method输入法(搜狗,讯飞,百度)" \
			"2" "WPS office(办公软件)" \
			"3" "container/VM(docker容器,qemu,vbox虚拟机)" \
			"4" "geogebra+kalzium(数学+化学)" \
			"5" "gparted:磁盘分区工具" \
			"6" "OBS-Studio(录屏软件)" \
			"7" "typora(markdown编辑器)" \
			"8" "electronic-wechat(第三方微信客户端)" \
			"9" "qbittorrent(P2P下载工具)" \
			"10" "plasma-discover:KDE发现(软件中心)" \
			"11" "gnome-software软件商店" \
			"12" "calibre:电子书转换器和库管理" \
			"13" "文件管理器:thunar/nautilus/dolphin" \
			"14" "krita(数字绘画)" \
			"15" "openshot(视频剪辑)" \
			"16" "fbreader(epub阅读器)" \
			"17" "gnome-system-monitor(资源监视器)" \
			"18" "telegram(注重保护隐私的社交app)" \
			"19" "Grub Customizer(图形化开机引导编辑器)" \
			"20" "catfish(文件搜索)" \
			"0" "Back to the main menu 返回主菜单" \
			3>&1 1>&2 2>&3
	)
	##########
	case ${TMOE_BETA} in
	0 | "") tmoe_linux_tool_menu ;;
	1) install_pinyin_input_method ;;
	2) install_wps_office ;;
	3) install_container_and_virtual_machine ;;
	4) install_geogebra_and_kalzium ;;
	5) install_gparted ;;
	6) install_obs_studio ;;
	7) install_typora ;;
	8) install_electronic_wechat ;;
	9) install_qbitorrent ;;
	10) install_plasma_discover ;;
	11) install_gnome_software ;;
	12) install_calibre ;;
	13) thunar_nautilus_dolphion ;;
	14) install_krita ;;
	15) install_openshot ;;
	16) install_fbreader ;;
	17) install_gnome_system_monitor ;;
	18) install_telegram ;;
	19) install_grub_customizer ;;
	20) install_catfish ;;
	esac
	##############################
	########################################
	# Blender在WSL2（Xserver）下测试失败，Kdenlive在VNC远程下测试成功。
	press_enter_to_return
	beta_features
}
####################
install_container_and_virtual_machine() {
	RETURN_TO_WHERE='install_container_and_virtual_machine'
	NON_DEBIAN='false'
	VIRTUAL_TECH=$(
		whiptail --title "虚拟化与api的转换" --menu "您想要选择哪一项呢？" 16 55 6 \
			"1" "qemu" \
			"2" "download iso(Android,linux等)" \
			"3" "docker-ce:开源的应用容器引擎" \
			"4" "VirtualBox:甲骨文开源虚拟机(x64)" \
			"5" "wine(调用win api并即时转换)" \
			"6" "anbox:Android in a box(测试)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") beta_features ;;
	1) install_aqemu ;;
	2) download_virtual_machine_iso_file ;;
	3) install_docker_ce ;;
	4) install_virtual_box ;;
	5) install_wine64 ;;
	6) install_anbox ;;
	esac
	###############
	press_enter_to_return
	beta_features
}
###########
download_virtual_machine_iso_file() {
	RETURN_TO_WHERE='download_virtual_machine_iso_file'
	NON_DEBIAN='false'
	cd ~
	VIRTUAL_TECH=$(
		whiptail --title "ISO IMAGE FILE" --menu "Which iso file do you want to download?" 16 55 6 \
			"1" "Android x86_64(latest)" \
			"2" "debian(每周自动构建,包含non-free)" \
			"3" "ubuntu" \
			"4" "flash iso烧录镜像文件至U盘" \
			"5" "windows10" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	#############
	case ${VIRTUAL_TECH} in
	0 | "") install_container_and_virtual_machine ;;
	1) download_android_x86_file ;;
	2) download_debian_iso_file ;;
	3) download_ubuntu_iso_file ;;
	4) flash_iso_to_udisk ;;
	5) download_windows_10_iso ;;
	esac
	###############
	press_enter_to_return
	download_virtual_machine_iso_file
}
###########
flash_iso_to_udisk() {
	FILE_EXT_01='iso'
	FILE_EXT_02='ISO'
	START_DIR="${HOME}"
	tmoe_file_manager
	if [ -z ${SELECTION} ]; then
		echo "没有指定${YELLOW}有效${RESET}的${BLUE}文件${GREEN}，请${GREEN}重新${RESET}选择"
	else
		echo "您选择的iso文件为${TMOE_FILE_ABSOLUTE_PATH}"
		ls -lah ${TMOE_FILE_ABSOLUTE_PATH}
		check_fdisk
	fi
}
################
check_fdisk() {
	if [ ! $(command -v fdisk) ]; then
		DEPENDENCY_01='fdisk'
		DEPENDENCY_02=''
		beta_features_quick_install
	fi
	lsblk
	df -h
	fdisk -l
	echo "${RED}WARNING！${RESET}您接下来需要选择一个${YELLOW}磁盘分区${RESET}，请复制指定磁盘的${RED}完整路径${RESET}（包含/dev）"
	echo "若选错磁盘，将会导致该磁盘数据${RED}完全丢失！${RESET}"
	echo "此操作${RED}不可逆${RESET}！请${GREEN}谨慎${RESET}选择！"
	echo "建议您在执行本操作前，对指定磁盘进行${BLUE}备份${RESET}"
	echo "若您因选错了磁盘而${YELLOW}丢失数据${RESET}，开发者${RED}概不负责！！！${RESET}"
	do_you_want_to_continue
	dd_flash_iso_to_udisk
}
################
dd_flash_iso_to_udisk() {
	DD_OF_TARGET=$(whiptail --inputbox "请输入磁盘路径，例如/dev/nvme0n1px或/dev/sdax,请以实际路径为准" 12 50 --title "DEVICES" 3>&1 1>&2 2>&3)
	if [ "$?" != "0" ]; then
		echo "检测到您取消了操作"
		download_virtual_machine_iso_file
	fi
	echo "${DD_OF_TARGET}即将被格式化，所有文件都将丢失"
	do_you_want_to_continue
	echo "正在烧录中，这可能需要数分钟的时间..."
	dd <${TMOE_FILE_ABSOLUTE_PATH} >${DD_OF_TARGET}
}
############
download_win10_19041_iso() {
	if [ ! -e "19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.iso" ]; then
		echo "即将为您下载10.0.19041.172 iso镜像文件..."
		aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.iso" 'https://cdn.tmoe.me/windows/20H1/19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.ISO' || aria2c -x 16 -k 1M --split=16 --allow-overwrite=true -o "19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.iso" 'https://m.tmoe.me/down/share/windows/20H1/19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.ISO'
	fi
	#下面那处需要再次if,而不是else
	if [ -e "19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.iso" ]; then
		echo "正在校验sha256sum..."
		echo 'Verifying sha256sum ...'
		SHA256SUMDEBIAN="$(sha256sum '19041.172.200320-0621.VB_RELEASE_SVC_PROD3_CLIENTMULTI_X64FRE_ZH-CN.iso' | cut -c 1-64)"
		CORRENTSHA256SUM='f8972cf8e3d6e7ff1abff5f7f4e3e7deeef05422c33299d911253b21e6ee2b49'
		if [ "${SHA256SUMDEBIAN}" != "${CORRENTSHA256SUM}" ]; then
			echo "当前文件的sha256校验值为${SHA256SUMDEBIAN}"
			echo "远程文件的sha256校验值为${CORRENTSHA256SUM}"
			echo 'sha256校验值不一致，请重新下载！'
			echo 'sha256sum value is inconsistent, please download again.'
		else
			echo 'Congratulations,检测到sha256sum一致'
			echo 'Detected that sha256sum is the same as the source code, and your download is correct.'
		fi
	fi
}
############
download_windows_10_iso() {
	if (whiptail --title "请选择版本" --yes-button "19041" --no-button "other" --yesno "您想要下载哪个版本呢？♪(^∇^*) " 10 50); then
		download_win10_19041_iso
	else
		cat <<-'EOF'
			如需下载arm64架构的版本，那么您可以前往uupdump.ml
			如需下载其他版本，请前往microsoft官网
			https://www.microsoft.com/zh-cn/software-download/windows10ISO
		EOF
	fi
}
####################
download_ubuntu_iso_file() {
	if (whiptail --title "请选择版本" --yes-button "20.04" --no-button "自定义版本" --yesno "您是想要下载20.04还是自定义版本呢？♪(^∇^*) " 10 50); then
		UBUNTU_VERSION='20.04'
		download_ubuntu_latest_iso_file
	else
		TARGET=$(whiptail --inputbox "请输入版本号，例如18.04\n Please enter the version." 12 50 --title "UBUNTU VERSION" 3>&1 1>&2 2>&3)
		if [ "$?" != "0" ]; then
			echo "检测到您取消了操作"
			UBUNTU_VERSION='20.04'
		else
			UBUNTU_VERSION="$(echo ${TARGET} | head -n 1 | cut -d ' ' -f 1)"
		fi
	fi
	download_ubuntu_latest_iso_file
}
#############
download_ubuntu_latest_iso_file() {
	UBUNTU_MIRROR='tuna'
	UBUNTU_EDITION=$(
		whiptail --title "UBUNTU EDITION" --menu "请选择您需要下载的版本？Which edition do you want to install?" 16 55 6 \
			"1" "ubuntu-server(自动识别架构)" \
			"2" "ubuntu(gnome)" \
			"3" "xubuntu(xfce)" \
			"4" "kubuntu(kde plasma)" \
			"5" "lubuntu(lxqt)" \
			"6" "ubuntu-mate" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${UBUNTU_EDITION} in
	0 | "") download_virtual_machine_iso_file ;;
	1) UBUNTU_DISTRO='ubuntu-legacy-server' ;;
	2) UBUNTU_DISTRO='ubuntu-gnome' ;;
	3) UBUNTU_DISTRO='xubuntu' ;;
	4) UBUNTU_DISTRO='kubuntu' ;;
	5) UBUNTU_DISTRO='lubuntu' ;;
	6) UBUNTU_DISTRO='ubuntu-mate' ;;
	esac
	###############
	if [ ${UBUNTU_DISTRO} = 'ubuntu-gnome' ]; then
		download_ubuntu_huawei_mirror_iso
	else
		download_ubuntu_tuna_mirror_iso
	fi
	press_enter_to_return
	download_virtual_machine_iso_file
}
###############
ubuntu_arm_warning() {
	echo "请选择Server版"
	arch_does_not_support
	download_ubuntu_latest_iso_file
}
################
aria2c_download_file() {
	echo ${THE_LATEST_ISO_LINK}
	cd ~
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M "${THE_LATEST_ISO_LINK}"
}
############
download_ubuntu_huawei_mirror_iso() {
	if [ "${ARCH_TYPE}" = "amd64" ]; then
		THE_LATEST_ISO_LINK="https://mirrors.huaweicloud.com/ubuntu-releases/${UBUNTU_VERSION}/ubuntu-${UBUNTU_VERSION}-desktop-amd64.iso"
	elif [ "${ARCH_TYPE}" = "i386" ]; then
		THE_LATEST_ISO_LINK="https://mirrors.huaweicloud.com/ubuntu-releases/16.04.6/ubuntu-16.04.6-desktop-i386.iso"
	else
		ubuntu_arm_warning
	fi
	aria2c_download_file
}
####################
get_ubuntu_server_iso_url() {
	if [ "${ARCH_TYPE}" = "amd64" ]; then
		THE_LATEST_ISO_LINK="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/${UBUNTU_DISTRO}/releases/${UBUNTU_VERSION}/release/ubuntu-${UBUNTU_VERSION}-legacy-server-${ARCH_TYPE}.iso"
	elif [ "${ARCH_TYPE}" = "i386" ]; then
		THE_LATEST_ISO_LINK="https://mirrors.huaweicloud.com/ubuntu-releases/16.04.6/ubuntu-16.04.6-server-i386.iso"
	else
		THE_LATEST_ISO_LINK="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/ubuntu/releases/${UBUNTU_VERSION}/release/ubuntu-${UBUNTU_VERSION}-live-server-${ARCH_TYPE}.iso"
	fi
}
##############
get_other_ubuntu_distros_url() {
	if [ "${ARCH_TYPE}" = "amd64" ]; then
		THE_LATEST_ISO_LINK="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/${UBUNTU_DISTRO}/releases/${UBUNTU_VERSION}/release/${UBUNTU_DISTRO}-${UBUNTU_VERSION}-desktop-amd64.iso"
	elif [ "${ARCH_TYPE}" = "i386" ]; then
		THE_LATEST_ISO_LINK="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cdimage/${UBUNTU_DISTRO}/releases/18.04.4/release/${UBUNTU_DISTRO}-18.04.4-desktop-i386.iso"
	else
		ubuntu_arm_warning
	fi
}
################
download_ubuntu_tuna_mirror_iso() {
	if [ ${UBUNTU_DISTRO} = 'ubuntu-legacy-server' ]; then
		get_ubuntu_server_iso_url
	else
		get_other_ubuntu_distros_url
	fi
	aria2c_download_file
}
#######################
download_android_x86_file() {
	REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/osdn/android-x86/'
	REPO_FOLDER=$(curl -L ${REPO_URL} | grep -v incoming | grep date | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	if [ "${ARCH_TYPE}" = 'i386' ]; then
		THE_LATEST_ISO_VERSION=$(curl -L ${REPO_URL}${REPO_FOLDER} | grep -v 'x86_64' | grep date | grep '.iso' | tail -n 1 | head -n 1 | cut -d '=' -f 4 | cut -d '"' -f 2)
	else
		THE_LATEST_ISO_VERSION=$(curl -L ${REPO_URL}${REPO_FOLDER} | grep date | grep '.iso' | tail -n 2 | head -n 1 | cut -d '=' -f 4 | cut -d '"' -f 2)
	fi
	THE_LATEST_ISO_LINK="${REPO_URL}${REPO_FOLDER}${THE_LATEST_ISO_VERSION}"
	echo ${THE_LATEST_ISO_LINK}
	cd ~
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_ISO_VERSION}" "${THE_LATEST_ISO_LINK}"
}
################
download_debian_iso_file() {
	DEBIAN_FREE='unkown'
	DEBIAN_ARCH=$(
		whiptail --title "architecture" --menu "请选择您需要下载的架构版本，non-free版包含了非自由固件(例如闭源无线网卡驱动等)" 18 55 9 \
			"1" "x64(non-free,unofficial)" \
			"2" "x86(non-free,unofficial)" \
			"3" "x64(free)" \
			"4" "x86(free)" \
			"5" "arm64" \
			"6" "armhf" \
			"7" "mips" \
			"8" "mipsel" \
			"9" "mips64el" \
			"10" "ppc64el" \
			"11" "s390x" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${DEBIAN_ARCH} in
	0 | "") download_virtual_machine_iso_file ;;
	1)
		GREP_ARCH='amd64'
		DEBIAN_FREE='false'
		download_debian_nonfree_iso
		;;
	2)
		GREP_ARCH='i386'
		DEBIAN_FREE='false'
		download_debian_nonfree_iso
		;;
	3)
		GREP_ARCH='amd64'
		DEBIAN_FREE='true'
		download_debian_nonfree_iso
		;;
	4)
		GREP_ARCH='i386'
		DEBIAN_FREE='true'
		download_debian_nonfree_iso
		;;
	5) GREP_ARCH='arm64' ;;
	6) GREP_ARCH='armhf' ;;
	7) GREP_ARCH='mips' ;;
	8) GREP_ARCH='mipsel' ;;
	9) GREP_ARCH='mips64el' ;;
	10) GREP_ARCH='ppc64el' ;;
	11) GREP_ARCH='s390x' ;;
	esac
	###############
	if [ ${DEBIAN_FREE} = 'unkown' ]; then
		download_debian_weekly_builds_iso
	fi
	press_enter_to_return
	download_virtual_machine_iso_file
}
##################
download_debian_nonfree_iso() {
	DEBIAN_LIVE=$(
		whiptail --title "architecture" --menu "您下载的镜像中需要包含何种桌面环境？" 16 55 8 \
			"1" "cinnamon" \
			"2" "gnome" \
			"3" "kde plasma" \
			"4" "lxde" \
			"5" "lxqt" \
			"6" "mate" \
			"7" "standard(默认无桌面)" \
			"8" "xfce" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	####################
	case ${DEBIAN_LIVE} in
	0 | "") download_debian_iso_file ;;
	1) DEBIAN_DE='cinnamon' ;;
	2) DEBIAN_DE='gnome' ;;
	3) DEBIAN_DE='kde' ;;
	4) DEBIAN_DE='lxde' ;;
	5) DEBIAN_DE='lxqt' ;;
	6) DEBIAN_DE='mate' ;;
	7) DEBIAN_DE='standard' ;;
	8) DEBIAN_DE='xfce' ;;
	esac
	##############
	if [ ${DEBIAN_FREE} = 'false' ]; then
		download_debian_nonfree_live_iso
	else
		download_debian_free_live_iso
	fi
}
###############
download_debian_weekly_builds_iso() {
	THE_LATEST_ISO_LINK="https://mirrors.ustc.edu.cn/debian-cdimage/weekly-builds/${GREP_ARCH}/iso-cd/debian-testing-${GREP_ARCH}-xfce-CD-1.iso"
	echo ${THE_LATEST_ISO_LINK}
	cd ~
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "debian-testing-${GREP_ARCH}-xfce-CD-1.iso" "${THE_LATEST_ISO_LINK}"
}
##################
download_debian_free_live_iso() {
	THE_LATEST_ISO_LINK="https://mirrors.ustc.edu.cn/debian-cdimage/weekly-live-builds/${GREP_ARCH}/iso-hybrid/debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}.iso"
	echo ${THE_LATEST_ISO_LINK}
	cd ~
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}.iso" "${THE_LATEST_ISO_LINK}"
}
############
download_debian_nonfree_live_iso() {
	THE_LATEST_ISO_LINK="https://mirrors.ustc.edu.cn/debian-cdimage/unofficial/non-free/cd-including-firmware/weekly-live-builds/${GREP_ARCH}/iso-hybrid/debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}%2Bnonfree.iso"
	echo ${THE_LATEST_ISO_LINK}
	cd ~
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "debian-live-testing-${GREP_ARCH}-${DEBIAN_DE}-nonfree.iso" "${THE_LATEST_ISO_LINK}"
}
#####################
install_wine64() {
	DEPENDENCY_01='wine winetricks-zh q4wine'
	DEPENDENCY_02='playonlinux wine32'
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			DEPENDENCY_01='wine winetricks q4wine'
		fi
		dpkg --add-architecture i386
		apt update
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01='winetricks-zh'
		DEPENDENCY_02='playonlinux5-git q4wine'
	fi
	beta_features_quick_install
	if [ "${ARCH_TYPE}" != "i386" ]; then
		cat <<-'EOF'
			如需完全卸载wine，那么您还需要移除i386架构的软件包。
			apt purge "*:i386"
			dpkg  --remove-architecture i386
			apt update
		EOF
	fi
}
#########################
install_aqemu() {
	DEPENDENCY_01='qemu'
	DEPENDENCY_02='qemu-system-x86 qemu-system-arm qemu-system-gui qemu-utils qemu-block-extra aqemu'
	beta_features_quick_install
}
#########
download_ubuntu_ppa_deb_model_01() {
	cd /tmp/
	THE_LATEST_DEB_VERSION="$(curl -L ${REPO_URL} | grep '.deb' | grep "${GREP_NAME}" | head -n 1 | cut -d '=' -f 5 | cut -d '"' -f 2)"
	THE_LATEST_DEB_LINK="${REPO_URL}${THE_LATEST_DEB_VERSION}"
	echo ${THE_LATEST_DEB_LINK}
	aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_DEB_VERSION}" "${THE_LATEST_DEB_LINK}"
	apt install ./${THE_LATEST_DEB_VERSION}
	rm -fv ${THE_LATEST_DEB_VERSION}
}
##############
install_anbox() {
	cat <<-'EndOfFile'
		WARNING!本软件需要安装内核模块补丁,且无法保证可以正常运行!
		您亦可使用以下补丁，并将它们构建为模块。
		https://salsa.debian.org/kernel-team/linux/blob/master/debian/patches/debian/android-enable-building-ashmem-and-binder-as-modules.patch
		https://salsa.debian.org/kernel-team/linux/blob/master/debian/patches/debian/export-symbols-needed-by-android-drivers.patch
		若模块安装失败，则请前往官网阅读说明https://docs.anbox.io/userguide/install_kernel_modules.html
		如需卸载该模块，请手动输apt purge -y anbox-modules-dkms
	EndOfFile
	do_you_want_to_continue
	DEPENDENCY_01=''
	if [ "${LINUX_DISTRO}" = "debian" ]; then
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			add-apt-repository ppa:morphis/anbox-support
			apt update
			apt install anbox-modules-dkms
			apt install linux-headers-generic
		else
			REPO_URL='http://ppa.launchpad.net/morphis/anbox-support/ubuntu/pool/main/a/anbox-modules/'
			GREP_NAME='all'
			download_ubuntu_ppa_deb_model_01
		fi
		modprobe ashmem_linux
		modprobe binder_linux
		ls -1 /dev/{ashmem,binder}
		DEPENDENCY_02='anbox'
		beta_features_quick_install
	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01='anbox-modules-dkms-git'
		DEPENDENCY_02='anbox-git'
		beta_features_quick_install
	else
		non_debian_function
	fi
}
###########
install_catfish() {
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您处于proot环境下，可能无法成功创建索引数据库"
		echo "若安装时卡在mlocalte，请按Ctrl+C并强制重启终端，最后输${PACKAGES_REMOVE_COMMAND} mlocate catfish"
		do_you_want_to_continue
		if [ "${DEBIAN_DISTRO}" = "ubuntu" ]; then
			echo "检测到您使用的ubuntu，无法为您自动安装"
			read
			beta_features
		fi
	fi
	DEPENDENCY_01=''
	DEPENDENCY_02='catfish'
	beta_features_quick_install
}
###########
install_geogebra_and_kalzium() {
	DEPENDENCY_01='geogebra'
	DEPENDENCY_02='kalzium'
	beta_features_quick_install
}
##################
install_pinyin_input_method() {
	RETURN_TO_WHERE='install_pinyin_input_method'
	NON_DEBIAN='false'
	DEPENDENCY_01="fcitx"
	INPUT_METHOD=$(
		whiptail --title "输入法" --menu "您想要安装哪个输入法呢？\nWhich input method do you want to install?" 17 55 8 \
			"1" "sogou搜狗拼音" \
			"2" "iflyime讯飞语音+拼音+五笔" \
			"3" "rime中州韻(擊響中文之韻)" \
			"4" "baidu百度输入法" \
			"5" "libpinyin(提供智能整句输入算法核心)" \
			"6" "sunpinyin(基于统计学语言模型)" \
			"7" "google谷歌拼音(引擎fork自Android版)" \
			"8" "uim(Universal Input Method)" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	case ${INPUT_METHOD} in
	0 | "") beta_features ;;
	1) install_sogou_pinyin ;;
	2) install_iflyime_pinyin ;;
	3) install_rime_pinyin ;;
	4) install_baidu_pinyin ;;
	5) install_lib_pinyin ;;
	6) install_sun_pinyin ;;
	7) install_google_pinyin ;;
	8) install_uim_pinyin ;;
	esac
	###############
	press_enter_to_return
	beta_features
}
########################
install_uim_pinyin() {
	DEPENDENCY_01='uim uim-mozc'
	DEPENDENCY_02='uim-pinyin'
	beta_features_quick_install
}
###########
install_rime_pinyin() {
	DEPENDENCY_02='fcitx-rime'
	beta_features_quick_install
}
#############
install_lib_pinyin() {
	DEPENDENCY_02='fcitx-libpinyin'
	beta_features_quick_install
}
######################
install_sun_pinyin() {
	DEPENDENCY_02='fcitx-sunpinyin'
	beta_features_quick_install
}
###########
install_google_pinyin() {
	DEPENDENCY_02='fcitx-googlepinyin'
	beta_features_quick_install
}
###########
install_debian_baidu_pinyin() {
	DEPENDENCY_02="fcitx-baidupinyin"
	if [ ! $(command -v unzip) ]; then
		${PACKAGES_INSTALL_COMMAND} unzip
	fi
	###################
	if [ "${ARCH_TYPE}" = "amd64" ]; then
		mkdir /tmp/.BAIDU_IME
		cd /tmp/.BAIDU_IME
		THE_Latest_Link='https://imeres.baidu.com/imeres/ime-res/guanwang/img/Ubuntu_Deepin-fcitx-baidupinyin-64.zip'
		echo ${THE_Latest_Link}
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'fcitx-baidupinyin.zip' "${THE_Latest_Link}"
		unzip 'fcitx-baidupinyin.zip'
		DEB_FILE_NAME="$(ls -l ./*deb | grep ^- | head -n 1 | awk -F ' ' '$0=$NF')"
		apt install ${DEB_FILE_NAME}
	else
		echo "架构不支持，跳过安装百度输入法。"
		arch_does_not_support
		beta_features
	fi
	apt show ./fcitx-baidupinyin.deb
	apt install -y ./fcitx-baidupinyin.deb
	echo "若安装失败，则请前往官网手动下载安装。"
	echo 'url: https://srf.baidu.com/site/guanwang_linux/index.html'
	cd /tmp
	rm -rfv /tmp/.BAIDU_IME
	beta_features_install_completed
}
########
install_pkg_warning() {
	echo "检测到${YELLOW}您已安装${RESET} ${GREEN} ${DEPENDENCY_02} ${RESET}"
	echo "如需${RED}卸载${RESET}，请手动输${BLUE} ${PACKAGES_REMOVE_COMMAND} ${DEPENDENCY_02} ${RESET}"
	press_enter_to_reinstall_yes_or_no
}
#############
install_baidu_pinyin() {
	DEPENDENCY_02="fcitx-baidupinyin"
	if [ -e "/opt/apps/com.baidu.fcitx-baidupinyin/" ]; then
		install_pkg_warning
	fi

	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01='fcitx-im fcitx-cofigtool'
		DEPENDENCY_02="fcitx-baidupinyin"
		beta_features_quick_install
		configure_arch_fcitx
	elif [ "${LINUX_DISTRO}" = "debian" ]; then
		install_debian_baidu_pinyin
	else
		non_debian_function
	fi
}
##########
#已废弃！
sougou_pinyin_amd64() {
	if [ "${ARCH_TYPE}" = "amd64" ] || [ "${ARCH_TYPE}" = "i386" ]; then
		LatestSogouPinyinLink=$(curl -L 'https://pinyin.sogou.com/linux' | grep ${ARCH_TYPE} | grep 'deb' | head -n 1 | cut -d '=' -f 3 | cut -d '?' -f 1 | cut -d '"' -f 2)
		echo ${LatestSogouPinyinLink}
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'sogou_pinyin.deb' "${LatestSogouPinyinLink}"
	else
		echo "架构不支持，跳过安装搜狗输入法。"
		arch_does_not_support
		beta_features
	fi
}
###################
install_debian_sogou_pinyin() {
	DEPENDENCY_02="sogouimebs"
	###################
	if [ -e "/usr/share/fcitx-sogoupinyin" ] || [ -e "/usr/share/sogouimebs/" ]; then
		install_pkg_warning
	fi
	if [ "${ARCH_TYPE}" = "i386" ]; then
		GREP_NAME='sogoupinyin'
		LATEST_DEB_REPO='http://archive.kylinos.cn/kylin/KYLIN-ALL/pool/main/s/sogoupinyin/'
	else
		GREP_NAME='sogouimebs'
		LATEST_DEB_REPO='http://archive.ubuntukylin.com/ukui/pool/main/s/sogouimebs/'
	fi
	download_ubuntu_kylin_deb_file_model_02
	#download_ubuntu_kylin_deb_file
	echo "若安装失败，则请前往官网手动下载安装。"
	echo 'url: https://pinyin.sogou.com/linux/'
	#rm -fv sogou_pinyin.deb
	beta_features_install_completed
}
########
install_sogou_pinyin() {
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01='fcitx-im fcitx-cofigtool'
		DEPENDENCY_02="fcitx-sogouimebs"
		beta_features_quick_install
		configure_arch_fcitx
	elif [ "${LINUX_DISTRO}" = "debian" ]; then
		install_debian_sogou_pinyin
	else
		non_debian_function
	fi
}
############
configure_arch_fcitx() {
	if [ ! -e "${HOME}/.xprofile" ]; then
		echo '' >${HOME}/.xprofile
	fi

	sed -i 's/^export GTK_IM_MODULE.*/#&/' ${HOME}/.xprofile
	sed -i 's/^export QT_IM_MODULE=.*/#&/' ${HOME}/.xprofile
	sed -i 's/^export XMODIFIERS=.*/#&/' ${HOME}/.xprofile
	cat >>${HOME}/.xprofile <<-'EOF'
		export GTK_IM_MODULE=fcitx
		export QT_IM_MODULE=fcitx
		export XMODIFIERS="@im=fcitx"
	EOF
}
##############
install_debian_iflyime_pinyin() {
	DEPENDENCY_02="iflyime"
	beta_features_quick_install
	if [ "${ARCH_TYPE}" = "amd64" ]; then
		REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/deepin/pool/non-free/i/iflyime/'
		GREP_NAME="${ARCH_TYPE}"
		download_deb_comman_model_01
	else
		arch_does_not_support
		echo "请在更换x64架构的设备后，再来尝试"
	fi
}
#############
install_iflyime_pinyin() {
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01='fcitx-im fcitx-cofigtool'
		DEPENDENCY_02="iflyime"
		beta_features_quick_install
		configure_arch_fcitx
	elif [ "${LINUX_DISTRO}" = "debian" ]; then
		install_debian_iflyime_pinyin
	else
		non_debian_function
	fi
}
################
install_gnome_system_monitor() {
	DEPENDENCY_01="gnome-system-monitor"
	DEPENDENCY_02="gnome-nettool"
	NON_DEBIAN='false'
	beta_features_quick_install
}
###############
debian_add_docker_gpg() {
	if [ "${DEBIAN_DISTRO}" = 'ubuntu' ]; then
		DOCKER_RELEASE='ubuntu'
	else
		DOCKER_RELEASE='debian'
	fi

	curl -Lv https://download.docker.com/linux/${DOCKER_RELEASE}/gpg | apt-key add -
	cd /etc/apt/sources.list.d/
	sed -i 's/^deb/# &/g' docker.list
	DOCKER_CODE="$(lsb_release -cs)"

	if [ ! $(command -v lsb_release) ]; then
		DOCKER_CODE="buster"
	fi

	if [ "$(lsb_release -cs)" = "focal" ]; then
		DOCKER_CODE="eoan"
	#2020-05-05：暂没有focal的仓库
	elif [ "$(lsb_release -cs)" = "bullseye" ]; then
		DOCKER_CODE="buster"
	elif [ "$(lsb_release -cs)" = "bookworm" ]; then
		DOCKER_CODE="bullseye"
	fi
	echo "deb https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/${DOCKER_RELEASE} ${DOCKER_CODE} stable" >>docker.list
	#$(#lsb_release -cs)
}
#################
install_docker_ce() {
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "${RED}WARNING！${RESET}检测到您当前处于${GREEN}proot容器${RESET}环境下！"
		echo "若您使用的是${BOLD}Android${RESET}系统，则请在安装前${BLUE}确保${RESET}您的Linux内核支持docker"
		echo "否则请直接退出安装！！！"
		RETURN_TO_WHERE='beta_features'
		do_you_want_to_continue
	fi

	NON_DEBIAN='false'
	if [ ! $(command -v gpg) ]; then
		DEPENDENCY_01=""
		DEPENDENCY_02="gpg"
		beta_features_quick_install
	else
		DEPENDENCY_02=""
	fi
	DEPENDENCY_01="docker-ce"
	#apt remove docker docker-engine docker.io
	if [ "${LINUX_DISTRO}" = 'debian' ]; then
		debian_add_docker_gpg
	elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
		curl -Lv -o /etc/yum.repos.d/docker-ce.repo "https://download.docker.com/linux/${REDHAT_DISTRO}/docker-ce.repo"
		sed -i 's@download.docker.com@mirrors.tuna.tsinghua.edu.cn/docker-ce@g' /etc/yum.repos.d/docker-ce.repo
	elif [ "${LINUX_DISTRO}" = 'arch' ]; then
		DEPENDENCY_01="docker"
	fi
	beta_features_quick_install
	if [ ! $(command -v docker) ]; then
		echo "安装失败，请执行${PACKAGES_INSTALL_COMMAND} docker.io"
	fi

}
#################
debian_add_virtual_box_gpg() {
	if [ "${DEBIAN_DISTRO}" = 'ubuntu' ]; then
		VBOX_RELEASE='bionic'
	else
		VBOX_RELEASE='buster'
	fi
	curl -Lv https://www.virtualbox.org/download/oracle_vbox_2016.asc | apt-key add -
	cd /etc/apt/sources.list.d/
	sed -i 's/^deb/# &/g' virtualbox.list
	echo "deb http://mirrors.tuna.tsinghua.edu.cn/virtualbox/apt/ ${VBOX_RELEASE} contrib" >>virtualbox.list
}
###############
get_debian_vbox_latest_url() {
	TUNA_VBOX_LINK='https://mirrors.tuna.tsinghua.edu.cn/virtualbox/apt/pool/contrib/v/'
	LATEST_VBOX_VERSION=$(curl -L ${TUNA_VBOX_LINK} | grep 'virtualbox-' | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	if [ "${DEBIAN_DISTRO}" = 'ubuntu' ]; then
		LATEST_VBOX_FILE=$(curl -L ${TUNA_VBOX_LINK}${LATEST_VBOX_VERSION} | grep -E "Ubuntu" | head -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)
	else
		LATEST_VBOX_FILE=$(curl -L ${TUNA_VBOX_LINK}${LATEST_VBOX_VERSION} | grep -E "Debian" | head -n 1 | cut -d '=' -f 7 | cut -d '"' -f 2)
	fi
	VBOX_DEB_FILE_URL="${TUNA_VBOX_LINK}${LATEST_VBOX_VERSION}${LATEST_VBOX_FILE}"
	echo "获取到vbox的最新链接为${VBOX_DEB_FILE_URL},是否下载并安装？"
	RETURN_TO_WHERE='beta_features'
	do_you_want_to_continue
	cd /tmp
	curl -Lo .Oracle_VIRTUAL_BOX.deb "${VBOX_DEB_FILE_URL}"
	apt show ./.Oracle_VIRTUAL_BOX.deb
	apt install -y ./.Oracle_VIRTUAL_BOX.deb
	rm -fv ./.Oracle_VIRTUAL_BOX.deb
}
################
debian_download_latest_vbox_deb() {
	if [ ! $(command -v virtualbox) ]; then
		get_debian_vbox_latest_url
	else
		echo "检测到您已安装virtual box，是否将其添加到软件源？"
		RETURN_TO_WHERE='beta_features'
		do_you_want_to_continue
		debian_add_virtual_box_gpg
	fi
}
#############
redhat_add_virtual_box_repo() {
	cat >/etc/yum.repos.d/virtualbox.repo <<-'EndOFrepo'
		[virtualbox]
		name=Virtualbox Repository
		baseurl=https://mirrors.tuna.tsinghua.edu.cn/virtualbox/rpm/el$releasever/
		gpgcheck=0
		enabled=1
	EndOFrepo
}
###############
install_virtual_box() {
	if [ "${ARCH_TYPE}" != "amd64" ]; then
		arch_does_not_support
		beta_features
	fi

	NON_DEBIAN='false'
	if [ ! $(command -v gpg) ]; then
		DEPENDENCY_01=""
		DEPENDENCY_02="gpg"
		beta_features_quick_install
	else
		DEPENDENCY_02=""
		#linux-headers
	fi
	DEPENDENCY_01="virtualbox"
	#apt remove docker docker-engine docker.io
	if [ "${LINUX_DISTRO}" = 'debian' ]; then
		debian_download_latest_vbox_deb
	#$(#lsb_release -cs)
	elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
		redhat_add_virtual_box_repo
	elif [ "${LINUX_DISTRO}" = 'arch' ]; then
		DEPENDENCY_01="virtualbox virtualbox-guest-iso"
		DEPENDENCY_02="virtualbox-ext-oracle"
		echo "您可以在安装完成后，输usermod -G vboxusers -a 当前用户名称"
		echo "将当前用户添加至vboxusers用户组"
		#
	fi
	echo "您可以输modprobe vboxdrv vboxnetadp vboxnetflt来加载内核模块"
	beta_features_quick_install
	####################
	if [ ! $(command -v virtualbox) ]; then
		echo "检测到virtual box安装失败，是否将其添加到软件源？"
		RETURN_TO_WHERE='beta_features'
		do_you_want_to_continue
		debian_add_virtual_box_gpg
		beta_features_quick_install
	fi
}
################
install_gparted() {
	DEPENDENCY_01="gparted"
	DEPENDENCY_02="baobab"
	NON_DEBIAN='false'
	beta_features_quick_install
}
################
install_typora() {
	DEPENDENCY_01="typora"
	DEPENDENCY_02=""
	NON_DEBIAN='true'
	beta_features_quick_install
	cd /tmp
	GREP_NAME='typora'
	if [ "${ARCH_TYPE}" = "amd64" ]; then
		LATEST_DEB_REPO='http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/t/typora/'
		download_debian_cn_repo_deb_file_model_01
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'typora.deb' 'http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/t/typora/typora_0.9.67-1_amd64.deb'
	elif [ "${ARCH_TYPE}" = "i386" ]; then
		LATEST_DEB_REPO='https://mirrors.tuna.tsinghua.edu.cn/deepin/pool/non-free/t/typora/'
		download_tuna_repo_deb_file_model_03
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'typora.deb' 'https://mirrors.tuna.tsinghua.edu.cn/deepin/pool/non-free/t/typora/typora_0.9.22-1_i386.deb'
	else
		arch_does_not_support
	fi
	#apt show ./typora.deb
	#apt install -y ./typora.deb
	#rm -vf ./typora.deb
	beta_features_install_completed
}
####################
install_wps_office() {
	DEPENDENCY_01="wps-office"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	cd /tmp
	if [ -e "/usr/share/applications/wps-office-wps.desktop" ]; then
		press_enter_to_reinstall
	fi

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		dpkg --configure -a
		LatestWPSLink=$(curl -L https://linux.wps.cn/ | grep '\.deb' | grep -i "${ARCH_TYPE}" | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o WPSoffice.deb "${LatestWPSLink}"
		apt show ./WPSoffice.deb
		apt install -y ./WPSoffice.deb

	elif [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="wps-office-cn"
		beta_features_quick_install
	elif [ "${LINUX_DISTRO}" = "redhat" ]; then
		LatestWPSLink=$(curl -L https://linux.wps.cn/ | grep '\.rpm' | grep -i "$(uname -m)" | head -n 1 | cut -d '=' -f 2 | cut -d '"' -f 2)
		aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o WPSoffice.rpm "https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/9505/wps-office-11.1.0.9505-1.x86_64.rpm"
		rpm -ivh ./WPSoffice.rpm
	fi

	echo "若安装失败，则请前往官网手动下载安装。"
	echo "url: https://linux.wps.cn"
	rm -fv ./WPSoffice.deb ./WPSoffice.rpm 2>/dev/null
	beta_features_install_completed
}
###################
thunar_nautilus_dolphion() {
	if [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您当前使用的是${BLUE}proot容器${RESET}，请勿安装${RED}dolphion${RESET}"
		echo "安装后将有可能导致VNC黑屏"
		echo "请选择${GREEN}thunar${RESET}或${GREEN}nautilus${RESET}"
	fi
	DEPENDENCY_02=""
	echo "${YELLOW}Which file manager do you want to install?[t/n/d/r]${RESET}"
	echo "请选择您需要安装的${BLUE}文件管理器${RESET}，输${YELLOW}t${RESET}安装${GREEN}thunar${RESET},输${YELLOW}n${RESET}安装${GREEN}nautilus${RESET}，输${YELLOW}d${RESET}安装${GREEN}dolphion${RESET}，输${YELLOW}r${RESET}${BLUE}返回${RESET}。"
	echo "Type t to install thunar,type n to install nautils,type d to install dolphin,type r to return."
	read opt
	case $opt in
	t* | T* | "")
		DEPENDENCY_01="thunar"
		;;
	n* | N*)
		DEPENDENCY_01="nautilus"
		;;
	d* | D*)
		DEPENDENCY_02="dolphin"
		;;
	r* | R*)
		beta_features
		;;
	*)
		echo "Invalid choice. skipped."
		beta_features
		#beta_features
		;;
	esac
	NON_DEBIAN='false'
	beta_features_quick_install
}
##################
install_electronic_wechat() {
	DEPENDENCY_01="electronic-wechat"
	DEPENDENCY_02=""
	NON_DEBIAN='true'
	if [ "${LINUX_DISTRO}" = "arch" ]; then
		DEPENDENCY_01="electron-wechat"
		NON_DEBIAN='false'
		beta_features_quick_install
	fi
	################
	if [ -e "/opt/wechat/electronic-wechat" ] || [ "$(command -v electronic-wechat)" ]; then
		beta_features_install_completed
		echo "按回车键重新安装"
		echo "Press enter to reinstall it?"
		do_you_want_to_continue
	fi

	non_debian_function
	cd /tmp
	GREP_NAME='electronic-wechat'
	if [ "${ARCH_TYPE}" = "amd64" ]; then
		LATEST_DEB_REPO='http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/e/electronic-wechat/'
		download_debian_cn_repo_deb_file_model_01
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'electronic-wechat.deb' 'http://mirrors.ustc.edu.cn/debiancn/debiancn/pool/main/e/electronic-wechat/electronic-wechat_2.0~repack0~debiancn0_amd64.deb'
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'electronic-wechat.deb' 'http://archive.ubuntukylin.com:10006/ubuntukylin/pool/main/e/electronic-wechat/electronic-wechat_2.0.1_amd64.deb'
	elif [ "${ARCH_TYPE}" = "i386" ]; then
		LATEST_DEB_REPO='http://archive.ubuntukylin.com:10006/ubuntukylin/pool/main/e/electronic-wechat/'
		download_ubuntu_kylin_deb_file_model_02
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'electronic-wechat.deb' 'http://archive.ubuntukylin.com:10006/ubuntukylin/pool/main/e/electronic-wechat/electronic-wechat_2.0.1_i386.deb'
	elif [ "${ARCH_TYPE}" = "arm64" ]; then
		LATEST_DEB_REPO='http://archive.kylinos.cn/kylin/KYLIN-ALL/pool/main/e/electronic-wechat/'
		download_ubuntu_kylin_deb_file_model_02
		#LATEST_VERSION=$(curl -L "${REPO_URL}" | grep 'arm64.deb' | tail -n 1 | cut -d '=' -f 5 | cut -d '"' -f 2)
		#LATEST_URL="${REPO_URL}${LATEST_VERSION}"
		#echo ${LATEST_URL}
		#aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o 'electronic-wechat.deb' "${LATEST_URL}"
	else
		arch_does_not_support
	fi
	#apt show ./electronic-wechat.deb
	#apt install -y ./electronic-wechat.deb
	#rm -vf ./electronic-wechat.deb
	beta_features_install_completed
}
#############
install_gnome_software() {
	DEPENDENCY_01="gnome-software"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
#############
install_obs_studio() {
	if [ ! $(command -v ffmpeg) ]; then
		DEPENDENCY_01="ffmpeg"
	else
		DEPENDENCY_01=""
	fi

	if [ "${LINUX_DISTRO}" = "gentoo" ]; then
		DEPENDENCY_02="media-video/obs-studio"
	else
		DEPENDENCY_02="obs-studio"
	fi

	NON_DEBIAN='false'
	beta_features_quick_install

	if [ "${LINUX_DISTRO}" = "redhat" ]; then
		if [ $(command -v dnf) ]; then
			dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
			dnf install -y obs-studio
		else
			yum install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
			yum install -y obs-studio
		fi
		#dnf install xorg-x11-drv-nvidia-cuda
	fi
	echo "若安装失败，则请前往官网阅读安装说明。"
	echo "url: https://obsproject.com/wiki/install-instructions#linux"
}
################
install_openshot() {
	DEPENDENCY_01="openshot"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	echo "您亦可选择其他视频剪辑软件，Blender在Xserver下测试失败，Kdenlive在VNC远程下测试成功。"
	beta_features_quick_install
}
############################
install_telegram() {
	DEPENDENCY_01="telegram-desktop"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
######################
install_grub_customizer() {
	DEPENDENCY_01="grub-customizer"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
############################
install_qbitorrent() {
	DEPENDENCY_01="qbittorrent"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}

############################
install_plasma_discover() {
	DEPENDENCY_01="plasma-discover"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}

############################
install_calibre() {
	DEPENDENCY_01="calibre"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}

############################
install_krita() {
	DEPENDENCY_01="krita"
	DEPENDENCY_02="krita-l10n"
	NON_DEBIAN='false'
	beta_features_quick_install
}
############################
install_fbreader() {
	DEPENDENCY_01="fbreader"
	DEPENDENCY_02=""
	NON_DEBIAN='false'
	beta_features_quick_install
}
################
################
personal_netdisk() {
	WHICH_NETDISK=$(whiptail --title "FILE SHARE SERVER" --menu "你想要使用哪个软件来共享文件呢" 14 50 6 \
		"1" "Filebrowser:简单轻量的个人网盘" \
		"2" "Nginx WebDAV:比ftp更适合用于传输流媒体" \
		"0" "Back to the main menu 返回主菜单" \
		3>&1 1>&2 2>&3)
	##############################
	case "${WHICH_NETDISK}" in
	0 | "") tmoe_linux_tool_menu ;;
	1) install_filebrowser ;;
	2) install_nginx_webdav ;;
	esac
	##################
	press_enter_to_return
	tmoe_linux_tool_menu
}
################################
################################
install_nginx_webdav() {

	pgrep nginx &>/dev/null
	if [ "$?" = "0" ]; then
		FILEBROWSER_STATUS='检测到nginx进程正在运行'
		FILEBROWSER_PROCESS='Restart重启'
	else
		FILEBROWSER_STATUS='检测到nginx进程未运行'
		FILEBROWSER_PROCESS='Start启动'
	fi

	if (whiptail --title "你想要对这个小可爱做什么" --yes-button "${FILEBROWSER_PROCESS}" --no-button 'Configure配置' --yesno "您是想要启动服务还是配置服务？${FILEBROWSER_STATUS}" 9 50); then
		if [ ! -e "/etc/nginx/conf.d/webdav.conf" ]; then
			echo "检测到配置文件不存在，2s后将为您自动配置服务。"
			sleep 2s
			nginx_onekey
		fi
		nginx_restart
	else
		configure_nginx_webdav
	fi
}

#############
configure_nginx_webdav() {
	#进入nginx webdav配置文件目录
	cd /etc/nginx/conf.d/
	TMOE_OPTION=$(whiptail --title "CONFIGURE WEBDAV" --menu "您想要修改哪项配置？Which configuration do you want to modify?" 14 50 5 \
		"1" "One-key conf 初始化一键配置" \
		"2" "管理访问账号" \
		"3" "view logs 查看日志" \
		"4" "WebDAV port 修改webdav端口" \
		"5" "Nginx port 修改nginx端口" \
		"6" "进程管理说明" \
		"7" "stop 停止" \
		"8" "Root dir修改根目录" \
		"9" "reset nginx重置nginx" \
		"10" "remove 卸载/移除" \
		"0" "Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##############################
	if [ "${TMOE_OPTION}" == '0' ]; then
		#tmoe_linux_tool_menu
		personal_netdisk
	fi
	##############################
	if [ "${TMOE_OPTION}" == '1' ]; then
		pkill nginx
		service nginx stop 2>/dev/null
		nginx_onekey
	fi
	##############################
	if [ "${TMOE_OPTION}" == '2' ]; then
		nginx_add_admin
	fi
	##############################
	if [ "${TMOE_OPTION}" == '3' ]; then
		nginx_logs
	fi
	##############################
	if [ "${TMOE_OPTION}" == '4' ]; then
		nginx_webdav_port
	fi
	##############################
	if [ "${TMOE_OPTION}" == '5' ]; then
		nginx_port
	fi
	##############################
	if [ "${TMOE_OPTION}" == '6' ]; then
		nginx_systemd
	fi
	##############################
	if [ "${TMOE_OPTION}" == '7' ]; then
		echo "正在停止服务进程..."
		echo "Stopping..."
		pkill nginx
		service nginx stop 2>/dev/null
		service nginx status
	fi
	##############################
	if [ "${TMOE_OPTION}" == '8' ]; then
		nginx_webdav_root_dir
	fi
	##############################
	if [ "${TMOE_OPTION}" == '9' ]; then
		echo "正在停止nginx进程..."
		echo "Stopping nginx..."
		pkill nginx
		service nginx stop 2>/dev/null
		nginx_reset
	fi
	##############################
	if [ "${TMOE_OPTION}" == '10' ]; then
		pkill nginx
		echo "正在停止nginx进程..."
		echo "Stopping nginx..."
		service nginx stop 2>/dev/null
		rm -fv /etc/nginx/conf.d/webdav.conf
		echo "${YELLOW}已删除webdav配置文件,${RESET}"
		echo "是否继续卸载nginx?"
		echo "您正在执行危险操作，卸载nginx将导致您部署的所有网站无法访问！！！"
		echo "${YELLOW}This is a dangerous operation, you must press Enter to confirm${RESET}"
		service nginx restart
		RETURN_TO_WHERE='configure_nginx_webdav'
		do_you_want_to_continue
		service nginx stop
		${PACKAGES_REMOVE_COMMAND} nginx nginx-extras
	fi
	########################################
	if [ -z "${TMOE_OPTION}" ]; then
		personal_netdisk
	fi
	###########
	press_enter_to_return
	configure_nginx_webdav
}
##############
nginx_onekey() {
	if [ -e "/tmp/.Chroot-Container-Detection-File" ] || [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您处于${BLUE}chroot/proot容器${RESET}环境下，部分功能可能出现异常。"
		echo "部分系统可能会出现failed，但仍能正常连接。"
		CHROOT_STATUS='1'
	fi
	echo "本服务依赖于软件源仓库的nginx,可能无法与宝塔等第三方面板的nginx相互兼容"
	echo "若80和443端口被占用，则有可能导致nginx启动失败，请修改nginx为1000以上的高位端口。"
	echo "安装完成后，若浏览器测试连接成功，则您可以换用文件管理器进行管理。"
	echo "例如Android端的Solid Explorer,windows端的RaiDrive"
	echo 'Press Enter to confirm.'
	echo "默认webdav根目录为/media，您可以在安装完成后自行修改。"
	RETURN_TO_WHERE='configure_nginx_webdav'
	do_you_want_to_continue

	DEPENDENCY_01='nginx'
	DEPENDENCY_02='apache2-utils'
	NON_DEBIAN='false'

	if [ "${LINUX_DISTRO}" = "debian" ]; then
		DEPENDENCY_01="${DEPENDENCY_01} nginx-extras"
	fi
	beta_features_quick_install
	##############
	mkdir -p /media
	touch "/media/欢迎使用tmoe-linux-webdav_你可以将文件复制至根目录下的media文件夹"
	if [ -e "/root/sd" ]; then
		ln -sf /root/sd /media/
	fi

	if [ -e "/root/tf" ]; then
		ln -sf /root/tf /media/
	fi

	if [ -e "/root/termux" ]; then
		ln -sf /root/sd /media/
	fi

	if [ "${CHROOT_STATUS}" = "1" ]; then
		echo "检测到您处于容器环境下"
		cd /etc/nginx/sites-available
		if [ ! -f "default.tar.gz" ]; then
			tar -zcvf default.tar.gz default
		fi
		tar -zxvf default.tar.gz default
		ls -lh /etc/nginx/sites-available/default
		sed -i 's@80 default_server@2086 default_server@g' default
		sed -i 's@443 ssl default_server@8443 ssl default_server@g' default
		echo "已将您的nginx的http端口从80修改为2086，https端口从443修改为8443"
	fi

	cd /etc/nginx/conf.d/
	cat >webdav.conf <<-'EndOFnginx'
		server {
		    listen       28080;
		    server_name  webdav;
		    error_log /var/log/nginx/webdav.error.log error;
		    access_log  /var/log/nginx/webdav.access.log combined;
		    location / {
		        root /media;
		        charset utf-8;
		        autoindex on;
		        dav_methods PUT DELETE MKCOL COPY MOVE;
		        dav_ext_methods PROPFIND OPTIONS;
		        create_full_put_path  on;
		        dav_access user:rw group:r all:r;
		        auth_basic "Not currently available";
		        auth_basic_user_file /etc/nginx/conf.d/.htpasswd.webdav;
		    }
		    error_page   500 502 503 504  /50x.html;
		    location = /50x.html {
		        root   /usr/share/nginx/html;
		    }
		}
	EndOFnginx
	#############
	TARGET_USERNAME=$(whiptail --inputbox "请自定义webdav用户名,例如root,admin,kawaii,moe,neko等 \n Please enter the username.Press Enter after the input is completed." 15 50 --title "USERNAME" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "用户名无效，请返回重试。"
		press_enter_to_return
		nginx_onekey
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定访问密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		press_enter_to_return
		nginx_onekey
	fi
	htpasswd -mbc /etc/nginx/conf.d/.htpasswd.webdav ${TARGET_USERNAME} ${TARGET_USERPASSWD}
	nginx -t
	if [ "$?" != "0" ]; then
		sed -i 's@dav_methods@# &@' webdav.conf
		sed -i 's@dav_ext_methods@# &@' webdav.conf
		nginx -t
	fi
	nginx_restart
	########################################
	press_enter_to_return
	configure_nginx_webdav
	#此处的返回步骤并非多余
}
############
nginx_restart() {
	cd /etc/nginx/conf.d/
	NGINX_WEBDAV_PORT=$(cat webdav.conf | grep listen | head -n 1 | cut -d ';' -f 1 | awk -F ' ' '$0=$NF')
	service nginx restart 2>/dev/null
	if [ "$?" != "0" ]; then
		/etc/init.d/nginx reload
	fi
	service nginx status 2>/dev/null
	if [ "$?" = "0" ]; then
		echo "您可以输${YELLOW}service nginx stop${RESET}来停止进程"
	else
		echo "您可以输${YELLOW}/etc/init.d/nginx stop${RESET}来停止进程"
	fi
	cat /var/log/nginx/webdav.error.log | tail -n 10
	cat /var/log/nginx/webdav.access.log | tail -n 10
	echo "正在为您启动nginx服务，本机默认访问地址为localhost:${NGINX_WEBDAV_PORT}"
	echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${NGINX_WEBDAV_PORT}
	echo The WAN VNC address 外网地址 $(curl -sL ip.sb | head -n 1):${NGINX_WEBDAV_PORT}
	echo "${YELLOW}您可以使用文件管理器或浏览器来打开WebDAV访问地址${RESET}"
	echo "Please use your browser to open the access address"
}
#############
nginx_add_admin() {
	TARGET_USERNAME=$(whiptail --inputbox "您正在重置webdav访问用户,请输入新用户名,例如root,admin,kawaii,moe,neko等 \n Please enter the username.Press Enter after the input is completed." 15 50 --title "USERNAME" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "用户名无效，操作取消"
		press_enter_to_return
		configure_nginx_webdav
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定访问密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		press_enter_to_return
		nginx_add_admin
	fi
	htpasswd -mbc /etc/nginx/conf.d/.htpasswd.webdav ${TARGET_USERNAME} ${TARGET_USERPASSWD}
	nginx_restart
}
#################
nginx_webdav_port() {
	NGINX_WEBDAV_PORT=$(cat webdav.conf | grep listen | head -n 1 | cut -d ';' -f 1 | awk -F ' ' '$0=$NF')
	TARGET_PORT=$(whiptail --inputbox "请输入新的端口号(纯数字)，范围在1-65525之间,检测到您当前的端口为${NGINX_WEBDAV_PORT}\n Please enter the port number." 12 50 --title "PORT" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		press_enter_to_return
		configure_nginx_webdav
	fi
	sed -i "s@${NGINX_WEBDAV_PORT}\;@${TARGET_PORT}\;@" webdav.conf
	ls -l $(pwd)/webdav.conf
	cat webdav.conf | grep listen
	/etc/init.d/nginx reload
}
#################
nginx_port() {
	cd /etc/nginx/sites-available
	NGINX_PORT=$(cat default | grep -E 'listen|default' | head -n 1 | cut -d ';' -f 1 | cut -d 'd' -f 1 | awk -F ' ' '$0=$NF')
	TARGET_PORT=$(whiptail --inputbox "请输入新的端口号(纯数字)，范围在1-65525之间,检测到您当前的Nginx端口为${NGINX_PORT}\n Please enter the port number." 12 50 --title "PORT" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		press_enter_to_return
		configure_nginx_webdav
	fi
	cp -pvf default default.bak
	tar -zxvf default.tar.gz default
	sed -i "s@80 default_server@${TARGET_PORT} default_server@g" default
	ls -l $(pwd)/default
	cat default | grep -E 'listen|default' | grep -v '#'
	/etc/init.d/nginx reload
}
############
nginx_logs() {
	cat /var/log/nginx/webdav.error.log | tail -n 10
	if [ $(command -v less) ]; then
		cat /var/log/nginx/webdav.access.log | less -meQ
	else
		cat /var/log/nginx/webdav.access.log | tail -n 10
	fi
	ls -lh /var/log/nginx/webdav.error.log
	ls -lh /var/log/nginx/webdav.access.log
}
#############
nginx_webdav_root_dir() {
	NGINX_WEBDAV_ROOT_DIR=$(cat webdav.conf | grep root | head -n 1 | cut -d ';' -f 1 | awk -F ' ' '$0=$NF')
	TARGET_PATH=$(whiptail --inputbox "请输入新的路径,例如/media/root,检测到您当前的webDAV根目录为${NGINX_WEBDAV_ROOT_DIR}\n Please enter the port number." 12 50 --title "PATH" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		press_enter_to_return
		configure_nginx_webdav
	fi
	sed -i "s@${NGINX_WEBDAV_ROOT_DIR}\;@${TARGET_PATH}\;@" webdav.conf
	ls -l $(pwd)/webdav.conf
	echo "您当前的webdav根目录已修改为$(cat webdav.conf | grep root | head -n 1 | cut -d ';' -f 1 | awk -F ' ' '$0=$NF')"
	/etc/init.d/nginx reload
}
#################
nginx_systemd() {
	if [ -e "/tmp/.Chroot-Container-Detection-File" ]; then
		echo "检测到您当前处于chroot容器环境下，无法使用systemctl命令"
	elif [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您当前处于${BLUE}proot容器${RESET}环境下，无法使用systemctl命令"
	fi

	cat <<-'EOF'
		    systemd管理
			输systemctl start nginx启动
			输systemctl stop nginx停止
			输systemctl status nginx查看进程状态
			输systemctl enable nginx开机自启
			输systemctl disable nginx禁用开机自启

			service命令
			输service nginx start启动
			输service nginx stop停止
			输service nginx status查看进程状态

		    init.d管理
			/etc/init.d/nginx start启动
			/etc/init.d/nginx restart重启
			/etc/init.d/nginx stop停止
			/etc/init.d/nginx statuss查看进程状态
			/etc/init.d/nginx reload重新加载

	EOF
}
###############
nginx_reset() {
	echo "${YELLOW}WARNING！继续执行此操作将丢失nginx配置信息！${RESET}"
	RETURN_TO_WHERE='configure_nginx_webdav'
	do_you_want_to_continue
	cd /etc/nginx/sites-available
	tar zcvf default.tar.gz default
}
###############
install_filebrowser() {
	if [ ! $(command -v filebrowser) ]; then
		cd /tmp
		if [ "${ARCH_TYPE}" = "amd64" ] || [ "${ARCH_TYPE}" = "arm64" ]; then
			rm -rf .FileBrowserTEMPFOLDER
			git clone -b linux_${ARCH_TYPE} --depth=1 https://gitee.com/mo2/filebrowser.git ./.FileBrowserTEMPFOLDER
			cd /usr/local/bin
			tar -Jxvf /tmp/.FileBrowserTEMPFOLDER/filebrowser.tar.xz filebrowser
			chmod +x filebrowser
			rm -rf /tmp/.FileBrowserTEMPFOLDER
		else
			#https://github.com/filebrowser/filebrowser/releases
			#curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
			if [ "${ARCH_TYPE}" = "armhf" ]; then
				aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o .filebrowser.tar.gz 'https://github.com/filebrowser/filebrowser/releases/download/v2.1.0/linux-armv7-filebrowser.tar.gz'
			elif [ "${ARCH_TYPE}" = "i386" ]; then
				aria2c --allow-overwrite=true -s 5 -x 5 -k 1M -o .filebrowser.tar.gz 'https://github.com/filebrowser/filebrowser/releases/download/v2.1.0/linux-386-filebrowser.tar.gz'
			fi
			cd /usr/local/bin
			tar -zxvf /tmp/.filebrowser.tar.gz filebrowser
			chmod +x filebrowser
			rm -rf /tmp/.filebrowser.tar.gz
		fi
	fi
	pgrep filebrowser &>/dev/null
	if [ "$?" = "0" ]; then
		FILEBROWSER_STATUS='检测到filebrowser进程正在运行'
		FILEBROWSER_PROCESS='Restart重启'
	else
		FILEBROWSER_STATUS='检测到filebrowser进程未运行'
		FILEBROWSER_PROCESS='Start启动'
	fi

	if (whiptail --title "你想要对这个小可爱做什么" --yes-button "${FILEBROWSER_PROCESS}" --no-button 'Configure配置' --yesno "您是想要启动服务还是配置服务？${FILEBROWSER_STATUS}" 9 50); then
		if [ ! -e "/etc/filebrowser.db" ]; then
			echo "检测到数据库文件不存在，2s后将为您自动配置服务。"
			sleep 2s
			filebrowser_onekey
		fi
		filebrowser_restart
	else
		configure_filebrowser
	fi
}
############
configure_filebrowser() {
	#先进入etc目录，防止database加载失败
	cd /etc
	TMOE_OPTION=$(
		whiptail --title "CONFIGURE FILEBROWSER" --menu "您想要修改哪项配置？修改配置前将自动停止服务。" 14 50 5 \
			"1" "One-key conf 初始化一键配置" \
			"2" "add admin 新建管理员" \
			"3" "port 修改端口" \
			"4" "view logs 查看日志" \
			"5" "language语言环境" \
			"6" "listen addr/ip 监听ip" \
			"7" "进程管理说明" \
			"8" "stop 停止" \
			"9" "reset 重置所有配置信息" \
			"10" "remove 卸载/移除" \
			"0" "Return to previous menu 返回上级菜单" \
			3>&1 1>&2 2>&3
	)
	##############################
	if [ "${TMOE_OPTION}" == '0' ]; then
		#tmoe_linux_tool_menu
		personal_netdisk
	fi
	##############################
	if [ "${TMOE_OPTION}" == '1' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		filebrowser_onekey
	fi
	##############################
	if [ "${TMOE_OPTION}" == '2' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		filebrowser_add_admin
	fi
	##############################
	if [ "${TMOE_OPTION}" == '3' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		filebrowser_port
	fi
	##############################
	if [ "${TMOE_OPTION}" == '4' ]; then
		filebrowser_logs
	fi
	##############################
	if [ "${TMOE_OPTION}" == '5' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		filebrowser_language
	fi
	##############################
	if [ "${TMOE_OPTION}" == '6' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		filebrowser_listen_ip
	fi
	##############################
	if [ "${TMOE_OPTION}" == '7' ]; then
		filebrowser_systemd
	fi
	##############################
	if [ "${TMOE_OPTION}" == '8' ]; then
		echo "正在停止服务进程..."
		echo "Stopping..."
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		service filebrowser status 2>/dev/null
	fi
	##############################
	if [ "${TMOE_OPTION}" == '9' ]; then
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		filebrowser_reset
	fi
	##############################
	if [ "${TMOE_OPTION}" == '10' ]; then
		RETURN_TO_WHERE='configure_filebrowser'
		do_you_want_to_continue
		pkill filebrowser
		service filebrowser stop 2>/dev/null
		rm -fv /usr/local/bin/filebrowser
		rm -fv /etc/systemd/system/filebrowser.service
		rm -fv /etc/filebrowser.db
	fi
	########################################
	if [ -z "${TMOE_OPTION}" ]; then
		personal_netdisk
	fi
	###########
	press_enter_to_return
	configure_filebrowser
}
##############
filebrowser_onekey() {
	cd /etc
	#初始化数据库文件
	filebrowser -d filebrowser.db config init
	#监听0.0.0.0
	filebrowser config set --address 0.0.0.0
	#设定根目录为当前主目录
	filebrowser config set --root ${HOME}
	filebrowser config set --port 38080
	#设置语言环境为中文简体
	filebrowser config set --locale zh-cn
	#修改日志文件路径
	#filebrowser config set --log /var/log/filebrowser.log
	TARGET_USERNAME=$(whiptail --inputbox "请输入自定义用户名,例如root,admin,kawaii,moe,neko等 \n Please enter the username.Press Enter after the input is completed." 15 50 --title "USERNAME" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "用户名无效，请返回重试。"
		press_enter_to_return
		filebrowser_onekey
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定管理员密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		press_enter_to_return
		filebrowser_onekey
	fi
	filebrowser users add ${TARGET_USERNAME} ${TARGET_USERPASSWD} --perm.admin
	#filebrowser users update ${TARGET_USERNAME} ${TARGET_USERPASSWD}

	cat >/etc/systemd/system/filebrowser.service <<-'EndOFsystemd'
		[Unit]
		Description=FileBrowser
		After=network.target
		Wants=network.target

		[Service]
		Type=simple
		PIDFile=/var/run/filebrowser.pid
		ExecStart=/usr/local/bin/filebrowser -d /etc/filebrowser.db
		Restart=on-failure

		[Install]
		WantedBy=multi-user.target
	EndOFsystemd
	chmod +x /etc/systemd/system/filebrowser.service
	systemctl daemon-reload 2>/dev/null
	#systemctl start filebrowser
	#service filebrowser start
	if (whiptail --title "systemctl enable filebrowser？" --yes-button 'Yes' --no-button 'No！' --yesno "是否需要将此服务设置为开机自启？" 9 50); then
		systemctl enable filebrowser
	fi
	filebrowser_restart
	########################################
	press_enter_to_return
	configure_filebrowser
	#此处的返回步骤并非多余
}
############
filebrowser_restart() {
	FILEBROWSER_PORT=$(cat /etc/filebrowser.db | grep -a port | sed 's@,@\n@g' | grep -a port | head -n 1 | cut -d ':' -f 2 | cut -d '"' -f 2)
	service filebrowser restart 2>/dev/null
	if [ "$?" != "0" ]; then
		pkill filebrowser
		nohup /usr/local/bin/filebrowser -d /etc/filebrowser.db 2>&1 >/var/log/filebrowser.log &
		cat /var/log/filebrowser.log | tail -n 20
	fi
	service filebrowser status 2>/dev/null
	if [ "$?" = "0" ]; then
		echo "您可以输${YELLOW}service filebrowser stop${RESET}来停止进程"
	else
		echo "您可以输${YELLOW}pkill filebrowser${RESET}来停止进程"
	fi
	echo "正在为您启动filebrowser服务，本机默认访问地址为localhost:${FILEBROWSER_PORT}"
	echo The LAN VNC address 局域网地址 $(ip -4 -br -c a | tail -n 1 | cut -d '/' -f 1 | cut -d 'P' -f 2):${FILEBROWSER_PORT}
	echo The WAN VNC address 外网地址 $(curl -sL ip.sb | head -n 1):${FILEBROWSER_PORT}
	echo "${YELLOW}请使用浏览器打开上述地址${RESET}"
	echo "Please use your browser to open the access address"
}
#############
filebrowser_add_admin() {
	pkill filebrowser
	service filebrowser stop 2>/dev/null
	echo "Stopping filebrowser..."
	echo "正在停止filebrowser进程..."
	echo "正在检测您当前已创建的用户..."
	filebrowser -d /etc/filebrowser.db users ls
	echo 'Press Enter to continue.'
	echo "${YELLOW}按回车键继续。${RESET}"
	read
	TARGET_USERNAME=$(whiptail --inputbox "请输入自定义用户名,例如root,admin,kawaii,moe,neko等 \n Please enter the username.Press Enter after the input is completed." 15 50 --title "USERNAME" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "用户名无效，操作取消"
		press_enter_to_return
		configure_filebrowser
	fi
	TARGET_USERPASSWD=$(whiptail --inputbox "请设定管理员密码\n Please enter the password." 12 50 --title "PASSWORD" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "密码包含无效字符，请返回重试。"
		press_enter_to_return
		filebrowser_add_admin
	fi
	cd /etc
	filebrowser users add ${TARGET_USERNAME} ${TARGET_USERPASSWD} --perm.admin
	#filebrowser users update ${TARGET_USERNAME} ${TARGET_USERPASSWD} --perm.admin
}
#################
filebrowser_port() {
	FILEBROWSER_PORT=$(cat /etc/filebrowser.db | grep -a port | sed 's@,@\n@g' | grep -a port | head -n 1 | cut -d ':' -f 2 | cut -d '"' -f 2)
	TARGET_PORT=$(whiptail --inputbox "请输入新的端口号(纯数字)，范围在1-65525之间,检测到您当前的端口为${FILEBROWSER_PORT}\n Please enter the port number." 12 50 --title "PORT" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		press_enter_to_return
		configure_filebrowser
	fi
	filebrowser config set --port ${TARGET_PORT}
}
############
filebrowser_logs() {
	if [ ! -f "/var/log/filebrowser.log" ]; then
		echo "日志文件不存在，您可能没有启用记录日志的功能"
		echo "${YELLOW}按回车键启用。${RESET}"
		read
		filebrowser -d /etc/filebrowser.db config set --log /var/log/filebrowser.log
	fi
	ls -lh /var/log/filebrowser.log
	echo "按Ctrl+C退出日志追踪，press Ctrl+C to exit."
	tail -Fvn 35 /var/log/filebrowser.log
	#if [ $(command -v less) ]; then
	# cat /var/log/filebrowser.log | less -meQ
	#else
	# cat /var/log/filebrowser.log
	#fi

}
#################
filebrowser_language() {
	TARGET_LANG=$(whiptail --inputbox "Please enter the language format, for example en,zh-cn" 12 50 --title "LANGUAGE" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		press_enter_to_return
		configure_filebrowser
	fi
	filebrowser config set --port ${TARGET_LANG}
}
###############
filebrowser_listen_ip() {
	TARGET_IP=$(whiptail --inputbox "Please enter the listen address, for example 0.0.0.0\n默认情况下无需修改。" 12 50 --title "listen" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus != 0 ]; then
		echo "检测到您取消了操作，请返回重试。"
		press_enter_to_return
		configure_filebrowser
	fi
	filebrowser config set --address ${TARGET_IP}
}
##################
filebrowser_systemd() {
	if [ -e "/tmp/.Chroot-Container-Detection-File" ]; then
		echo "检测到您当前处于chroot容器环境下，无法使用systemctl命令"
	elif [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
		echo "检测到您当前处于${BLUE}proot容器${RESET}环境下，无法使用systemctl命令"
	fi

	cat <<-'EOF'
		systemd管理
			输systemctl start filebrowser启动
			输systemctl stop filebrowser停止
			输systemctl status filebrowser查看进程状态
			输systemctl enable filebrowser开机自启
			输systemctl disable filebrowser禁用开机自启

			service命令
			输service filebrowser start启动
			输service filebrowser stop停止
			输service filebrowser status查看进程状态
		        
		    其它命令(适用于service和systemctl都无法使用的情况)
			输debian-i file启动
			pkill filebrowser停止
	EOF
}
###############
filebrowser_reset() {
	echo "${YELLOW}WARNING！继续执行此操作将丢失所有配置信息！${RESET}"
	RETURN_TO_WHERE='configure_filebrowser'
	do_you_want_to_continue
	rm -vf filebrowser.db
	filebrowser -d filebrowser.db config init
}

###########################################
main "$@"
########################################################################
