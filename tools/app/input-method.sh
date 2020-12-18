#!/usr/bin/env bash
##################################
tmoe_pinyin_input_method_main() {
    case "$1" in
    --auto-install-fcitx4)
        case_fcitx4_depends_01
        DEPENDENCY_02='fcitx-googlepinyin'
        DEPENDENCY_03='fcitx-libpinyin'
        beta_features_quick_install
        configure_tmoe_input_method
        ;;
    *) install_pinyin_input_method ;;
    esac
}
#################
set_input_method_env() {
    LNK_NAME_FCITX4='fcitx'
    LNK_NAME_FCITX5='org.fcitx.Fcitx5 fcitx5'
    LNK_NAME_IBUS='ibus-setup'
}
install_pinyin_input_method() {
    RETURN_TO_WHERE='install_pinyin_input_method'
    set_input_method_env
    INPUT_METHOD=$(
        whiptail --title "键盘与输入法" --menu "arch & debian-sid等新版系统可用fcitx5\nubuntu18.04 & debian10等旧版系统可用fcitx4\n为避免冲突,不建议同时安装fcitx和ibus\n若您使用的是容器,则推荐fcitx4;若为虚拟机,则推荐fcitx5" 0 0 0 \
            "1" "🍁 fcitx4 小企鹅输入法框架" \
            "2" "🍀 fcitx5(软件与词库)" \
            "3" "ibus 输入法框架" \
            "4" "onboard(屏幕虚拟键盘)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    case ${INPUT_METHOD} in
    0 | "") beta_features ;;
    1) fcitx4_input_method_menu ;;
    2) tmoe_fcitx5_menu ;;
    3) ibus_input_method_menu ;;
    4) install_onboard ;;
    esac
    ###############
    press_enter_to_return
    install_pinyin_input_method
}
########################
ibus_input_method_menu() {
    DEPENDENCY_01="ibus"
    TMOE_INPUT_METHOD_FRAMEWORK="ibus"
    DEPENDENCY_02=""
    #17 55 8
    INPUT_METHOD=$(
        whiptail --title "FCITX4" --menu "IBus输入法框架的功能与 SCIM 和 Uim 类似" 0 0 0 \
            "1" "libpinyin(提供智能整句输入算法核心)" \
            "2" "rime中州韻(擊響中文之韻)" \
            "3" "🍁 FAQ:常见问题与疑难诊断" \
            "4" "sunpinyin(基于统计学语言模型)" \
            "5" "chewing(注音)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    case ${INPUT_METHOD} in
    0 | "") install_pinyin_input_method ;;
    1) DEPENDENCY_02='ibus-libpinyin' ;;
    2) DEPENDENCY_02='ibus-rime' ;;
    3) tmoe_fcitx_faq ;;
    4) DEPENDENCY_02='ibus-sunpinyin' ;;
    5) DEPENDENCY_02='ibus-chewing' ;;
    esac
    ###############
    case ${INPUT_METHOD} in
    3) ;;
    *) [[ -z ${DEPENDENCY_02} ]] || beta_features_quick_install ;;
    esac
    configure_tmoe_input_method
    press_enter_to_return
    ibus_input_method_menu
}
#################
kde_config_module_for_fcitx() {
    DEPENDENCY_01=""
    DEPENDENCY_02='kcm-fcitx'
    case "${LINUX_DISTRO}" in
    "debian") DEPENDENCY_02='kde-config-fcitx' ;;
    "arch") DEPENDENCY_02='kcm-fcitx' ;;
    esac
    beta_features_quick_install
}
#################
case_fcitx4_depends_01() {
    TMOE_INPUT_METHOD_FRAMEWORK="fcitx"
    DEPENDENCY_01="fcitx"
    case "${LINUX_DISTRO}" in
    "debian")
        DEPENDENCY_01='fcitx fcitx-tools fcitx-config-gtk' #kde-config-fcitx
        ;;
    "arch")
        DEPENDENCY_01='fcitx-im fcitx-configtool' #kcm-fcitx
        ;;
    esac
}
###########
fcitx4_input_method_menu() {
    case_fcitx4_depends_01
    DEPENDENCY_02=""
    #17 55 8
    INPUT_METHOD=$(
        whiptail --title "FCITX4" --menu "fcitx可以通过安装引擎来支持多种输入法\n在桌面环境下按Ctrl+空格切换输入法" 0 0 0 \
            "1" "google谷歌拼音(引擎fork自Android版)" \
            "2" "rime中州韻(擊響中文之韻)" \
            "3" "🍁 FAQ:常见问题与疑难诊断" \
            "4" "libpinyin(提供智能整句输入算法核心)" \
            "5" "sunpinyin(基于统计学语言模型)" \
            "6" "sogou(搜狗拼音,x64)" \
            "7" "iflyime(讯飞语音+拼音+五笔,x64)" \
            "8" "baidu(百度输入法,x64)" \
            "9" "fcitx4-云拼音模块" \
            "10" "KDE-fcitx4-配置模块" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    case ${INPUT_METHOD} in
    0 | "") install_pinyin_input_method ;;
    1) install_google_pinyin ;;
    2) install_rime_pinyin ;;
    3) tmoe_fcitx_faq ;;
    4) install_lib_pinyin ;;
    5) install_sun_pinyin ;;
    6) install_sogou_pinyin ;;
    7) install_iflyime_pinyin ;;
    8) install_baidu_pinyin ;;
    9) install_fcitx_module_cloud_pinyin ;;
    10) kde_config_module_for_fcitx ;;
    esac
    ###############
    configure_tmoe_input_method
    press_enter_to_return
    fcitx4_input_method_menu
}
#################
configure_tmoe_input_method() {
    #[[ -s /etc/environment ]] || printf "\n" >>/etc/environment
    [[ -d ${XDG_AUTOSTART_DIR} ]] || mkdir -pv ${XDG_AUTOSTART_DIR}
    if ! egrep -q "^[^#]*export SDL_IM_MODULE=" /etc/environment; then
        cat >>/etc/environment <<-'EOF'
			export GTK_IM_MODULE=fcitx
			export QT_IM_MODULE=fcitx
			export XMODIFIERS="@im=fcitx"
			export SDL_IM_MODULE=fcitx
		EOF
    fi
    chmod a+r /etc/environment
    if [[ -n ${TMOE_INPUT_METHOD_FRAMEWORK} ]]; then
        sed -E -e "s%(export GTK_IM_MODULE=).*%\1${TMOE_INPUT_METHOD_FRAMEWORK}%g" \
            -e "s%(export QT_IM_MODULE=).*%\1${TMOE_INPUT_METHOD_FRAMEWORK}%g" \
            -e "s%(export XMODIFIERS=).*%\1\"@im=${TMOE_INPUT_METHOD_FRAMEWORK}\"%g" \
            -e "s%(export SDL_IM_MODULE=).*%\1${TMOE_INPUT_METHOD_FRAMEWORK}%g" \
            -i /etc/environment
    fi
    egrep --color=auto 'GTK_IM_MODULE=|QT_IM_MODULE=|XMODIFIERS=|SDL_IM_MODULE=' /etc/environment

    case ${TMOE_INPUT_METHOD_FRAMEWORK} in
    fcitx5)
        LNK_NAME=${LNK_NAME_FCITX5}
        NON_AUTO_STARTUP="${LNK_NAME_IBUS} ${LNK_NAME_FCITX4}"
        ;;
    ibus)
        LNK_NAME=${LNK_NAME_IBUS}
        NON_AUTO_STARTUP="${LNK_NAME_FCITX4} ${LNK_NAME_FCITX5}"
        ;;
    fcitx | *)
        LNK_NAME=${LNK_NAME_FCITX4}
        NON_AUTO_STARTUP="${LNK_NAME_IBUS} ${LNK_NAME_FCITX5}"
        ;;
    esac
    #case ${ENABLE_IM_AUTOSTART} in
    #true)
    for i in ${NON_AUTO_STARTUP}; do
        [[ ! -e ${XDG_AUTOSTART_DIR}/${i}.desktop ]] || rm -vf ${XDG_AUTOSTART_DIR}/${i}.desktop
    done

    for i in ${LNK_NAME}; do
        if [[ -e ${APPS_LNK_DIR}/${i}.desktop ]]; then
            ln -svf ${APPS_LNK_DIR}/${i}.desktop ${XDG_AUTOSTART_DIR}
            break
        fi
    done
    #   ;;
    #esac
}
##############
tmoe_fcitx5_menu() {
    check_zstd
    TMOE_INPUT_METHOD_FRAMEWORK="fcitx5"
    RETURN_TO_WHERE='tmoe_fcitx5_menu'
    DEPENDENCY_01="fcitx5-chinese-addons fcitx5"
    DEPENDENCY_02=""
    case "${LINUX_DISTRO}" in
    "debian") DEPENDENCY_02='kde-config-fcitx5' ;;
    "arch") DEPENDENCY_02='fcitx5-qt fcitx5-gtk kcm-fcitx5' ;;
    esac
    INPUT_METHOD=$(
        whiptail --title "Fcitx5" --menu "Fcitx5 是继 Fcitx 后的新一代输入法框架。\n词库是输入法保存的一些流行词语、常用词语或专业术语等的信息,\n添加流行词库能增加流行候选词的命中率" 0 55 0 \
            "1" "fcitx5安装与卸载" \
            "2" "🍁 FAQ:常见问题与疑难诊断" \
            "3" "肥猫百万大词库@felixonmars" \
            "4" "萌娘百科词库@outloudvi" \
            "5" "beautification输入法美化主题" \
            "6" "fcitx5-rime" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    case ${INPUT_METHOD} in
    0 | "") install_pinyin_input_method ;;
    1) install_fcitx5 ;;
    2) tmoe_fcitx_faq ;;
    3) felixonmars_fcitx5_wiki_dict ;;
    4) outloudvi_fcitx5_moegirl_dict ;;
    5) input_method_beautification ;;
    6) install_fcitx5_rime ;;
    esac
    #"5" "Material Design质感主题@hosxy" \
    ###############
    case ${INPUT_METHOD} in
    1 | 6) configure_tmoe_input_method ;;
    esac
    press_enter_to_return
    tmoe_fcitx5_menu
}
############
install_fcitx5() {
    beta_features_quick_install
    case "${LINUX_DISTRO}" in
    "debian")
        if [ ! $(command -v fcitx5-config-qt) ]; then
            DEPENDENCY_01=""
            printf '%s\n' '检测到您的软件源中不包含kde-config-fcitx5,您可以添加第三方ppa源来安装'
            printf "%s\n" "${GREEN}add-apt-repository ppa:hosxy/test${RESET}"
            printf '%s\n' '若ppa源添加失败，则请使用本工具内置的ppa源添加器'
            add-apt-repository ppa:hosxy/test
            beta_features_quick_install
        fi
        ;;
    esac
}
##############
install_fcitx5_rime() {
    DEPENDENCY_01="fcitx5-rime"
    DEPENDENCY_02="fcitx5-pinyin-moegirl-rime"
    case "${LINUX_DISTRO}" in
    debian | arch) ;;
    *) printf '%s\n' '截至2020年末，本功能暂仅适配Arch系和Debian系发行版' ;;
    esac
    beta_features_quick_install
}
#############
input_method_beautification() {
    RETURN_TO_WHERE='input_method_beautification'
    DEPENDENCY_01=''
    FCITX5_CLASSUI_CONF_PATH="${HOME}/.config/fcitx5/conf"
    FCITX5_CLASSUI_CONF_FILE="${FCITX5_CLASSUI_CONF_PATH}/classicui.conf"
    INPUT_METHOD=$(
        whiptail --title "Fcitx5" --menu "fcitx主题" 0 55 0 \
            "1" "Material Design(微软拼音风格)@hosxy" \
            "2" "kimpanel(支持kde-wayland)" \
            "3" "gnome-shell-extension-kimpanel(支持gnome-wayland)" \
            "4" "edit config编辑主题配置" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    case ${INPUT_METHOD} in
    0 | "") tmoe_fcitx5_menu ;;
    1) configure_fcitx5_material_color_theme ;;
    2) install_kimpanel ;;
    3) install_gnome_shell_extension_kimpanel ;;
    4) edit_fcitx_theme_config_file ;;
    esac
    ###############
    press_enter_to_return
    input_method_beautification
}
##############
edit_fcitx_theme_config_file() {
    if [ $(command -v editor) ]; then
        editor ${FCITX5_CLASSUI_CONF_FILE}
    else
        nano ${FCITX5_CLASSUI_CONF_FILE}
    fi
    chown -v ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${FCITX5_CLASSUI_CONF_FILE}
}
#############
configure_fcitx5_material_color_theme() {
    RETURN_TO_WHERE='configure_fcitx5_material_color_theme'
    MATERIAL_COLOR_FOLDER="${HOME}/.local/share/fcitx5/themes/Material-Color"
    unset CURRENT_FCITX5_COLOR
    [[ ! -e ${MATERIAL_COLOR_FOLDER}/panel.png ]] || CURRENT_FCITX5_COLOR="$(ls -l ${MATERIAL_COLOR_FOLDER}/panel.png | awk -F ' ' '{print $NF}' | cut -d '-' -f 2 | cut -d '.' -f 1)"
    if [ ! -z "${CURRENT_FCITX5_COLOR}" ]; then
        FCITX_THEME_STATUS="检测到当前fcitx5-material主题配色为${CURRENT_FCITX5_COLOR}"
    else
        FCITX_THEME_STATUS="检测到您未指定fcitx5-material主题的配色"
    fi
    if [ ! -e "${MATERIAL_COLOR_FOLDER}" ]; then
        FCITX_THEME_STATUS="检测您尚未下载fcitx5-material主题"
    fi
    PANEL_COLOR_PNG=''
    INPUT_METHOD=$(
        whiptail --title "Fcitx5 Material Design" --menu "https://github.com/hosxy/Fcitx5-Material-Color\n您可以在下载完成后，自由修改主题配色。\n${FCITX_THEME_STATUS}" 0 55 0 \
            "1" "download下载/更新" \
            "2" "delete删除" \
            "3" "Pink粉" \
            "4" "Blue蓝" \
            "5" "Brown棕" \
            "6" "DeepPurple深紫" \
            "7" "Indigo靛青" \
            "8" "Red红" \
            "9" "Teal水鸭绿" \
            "10" "origin原始" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    case ${INPUT_METHOD} in
    0 | "") input_method_beautification ;;
    1) install_fcitx5_material_color_theme ;;
    2) delete_fcitx5_material_color_theme ;;
    3)
        PANEL_COLOR_PNG='panel-pink.png'
        HIGH_LIGHT_COLOR_PNG='highlight-pink.png'
        ;;
    4)
        PANEL_COLOR_PNG='panel-blue.png'
        HIGH_LIGHT_COLOR_PNG='highlight-blue.png'
        ;;
    5)
        PANEL_COLOR_PNG='panel-brown.png'
        HIGH_LIGHT_COLOR_PNG='highlight-brown.png'
        ;;
    6)
        PANEL_COLOR_PNG='panel-deepPurple.png'
        HIGH_LIGHT_COLOR_PNG='highlight-deepPurple.png'
        ;;
    7)
        PANEL_COLOR_PNG='panel-indigo.png'
        HIGH_LIGHT_COLOR_PNG='highlight-indigo.png'
        ;;
    8)
        PANEL_COLOR_PNG='panel-red.png'
        HIGH_LIGHT_COLOR_PNG='highlight-red.png'
        ;;
    9)
        PANEL_COLOR_PNG='panel-teal.png'
        HIGH_LIGHT_COLOR_PNG='highlight-teal.png'
        ;;
    10)
        PANEL_COLOR_PNG='panel-origin.png'
        HIGH_LIGHT_COLOR_PNG='highlight-origin.png'
        ;;
    esac
    ###############
    if [ ! -z "${PANEL_COLOR_PNG}" ]; then
        switch_fcitx5_material_color
    fi
    press_enter_to_return
    configure_fcitx5_material_color_theme
}
##############
switch_fcitx5_material_color() {
    if [ ! -e "${MATERIAL_COLOR_FOLDER}" ]; then
        install_fcitx5_material_color_theme
    fi
    cd ${MATERIAL_COLOR_FOLDER}
    if [ "$(command -v catimg)" ]; then
        for i in "{PANEL_COLOR_PNG}" "${HIGH_LIGHT_COLOR_PNG}"; do
            [[ ! -e "${i}" ]] || catimg "${i}" 2>/dev/null
        done
    fi
    ln -svf ${PANEL_COLOR_PNG} panel.png
    ln -svf ${HIGH_LIGHT_COLOR_PNG} highlight.png
    if [ ${HOME} != '/root' ]; then
        printf "%s\n" "正在将panel.png和highlight.png的文件权限修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
        chown -v ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} panel.png highlight.png
    fi
}
############
delete_fcitx5_material_color_theme() {
    printf "%s\n" "是否需要删除该主题？"
    printf "%s\n" "${RED}rm -rv ${MATERIAL_COLOR_FOLDER}${RESET}"
    do_you_want_to_continue
    rm -rv ${MATERIAL_COLOR_FOLDER}
    sed -i 's@^Theme=@#&@' ${FCITX5_CLASSUI_CONF_FILE}
}
###############
install_fcitx5_material_color_theme() {
    #DEPENDENCY_02='fcitx5-material-color'
    #beta_features_quick_install
    #printf '%s\n' '请前往github阅读使用说明'
    #printf '%s\n' 'https://github.com/hosxy/Fcitx5-Material-Color'
    if [ ! -e ${MATERIAL_COLOR_FOLDER} ]; then
        mkdir -p ${MATERIAL_COLOR_FOLDER}
        git clone --depth=1 https://github.com/hosxy/Fcitx5-Material-Color.git ${MATERIAL_COLOR_FOLDER}
    else
        cd ${MATERIAL_COLOR_FOLDER}
        git pull --rebase --stat --allow-unrelated-histories || git rebase --skip
    fi

    mkdir -p ${FCITX5_CLASSUI_CONF_PATH}
    cd ${FCITX5_CLASSUI_CONF_PATH}
    if ! grep -q 'Theme=Material-Color' 'classicui.conf'; then
        write_to_fcitx_classui_conf
    fi

    if [ ${HOME} != '/root' ]; then
        printf "%s\n" "正在将${MATERIAL_COLOR_FOLDER}和${FCITX5_CLASSUI_CONF_PATH}的文件权限修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
        chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${MATERIAL_COLOR_FOLDER} ${FCITX5_CLASSUI_CONF_PATH}
    fi
}
###########
write_to_fcitx_classui_conf() {
    if [ -e classicui.conf ]; then
        sed -i 's@^Vertical Candidate List=@#&@;s@^PerScreenDPI=@#&@;s@^Theme=@#&@' classicui.conf
    fi
    cat >>${FCITX5_CLASSUI_CONF_FILE} <<-'EOF'
		# 垂直候选列表
		Vertical Candidate List=False

		# 按屏幕 DPI 使用
		PerScreenDPI=True

		# 字体
		Font="Noto Sans CJK SC Medium Medium 13"

		# 主题
		Theme=Material-Color-Pink
	EOF
}
###########
install_kimpanel() {
    #NON_DEBIAN='true'
    non_debian_function
    DEPENDENCY_02='fcitx5-module-kimpanel'
    beta_features_quick_install
}
#############
install_gnome_shell_extension_kimpanel() {
    DEPENDENCY_02='gnome-shell-extension-kimpanel'
    beta_features_quick_install
}
############
check_fcitx5_dict() {
    if [ ! -d ${FCITX5_DIICT_PATH} ]; then
        mkdir -p ${FCITX5_DIICT_PATH}
    fi
    DICT_FILE="${FCITX5_DIICT_PATH}/${DICT_NAME}"
    DICT_SHARE_FILE=".${FCITX5_DIICT_PATH}/${DICT_NAME}"
    #勿忘点
    #usr/share/fcitx5/pinyin/dictionaries/
    if [ -e "${DICT_FILE}" ]; then
        printf "%s\n" "检测到您${RED}已经下载过${RESET}${DICT_NAME}了"
        printf "%s\n" "该文件位于${BLUE}${FCITX5_DIICT_PATH}${RESET}"
        printf "%s\n" "如需删除，请手动执行${RED}rm -v ${DICT_FILE}${RESET}"
        ls -lah ${DICT_FILE}
        printf "%s\n" "sha256hash: $(sha256sum ${DICT_FILE})"
        printf "%s\n" "Do you want to ${RED}update it?${RESET}"
        printf "%s\n" "是否想要更新版本？"
        do_you_want_to_continue
    fi
}
#############
move_dict_model_01() {
    if [ -e "data.tar.zst" ]; then
        tar --zstd -xvf data.tar.zst &>/dev/null || zstdcat "data.tar.zst" | tar xvf -
    elif [ -e "data.tar.xz" ]; then
        tar -Jxvf data.tar.xz 2>/dev/null
    elif [ -e "data.tar.gz" ]; then
        tar -zxvf data.tar.gz 2>/dev/null
    else
        tar -xvf data.* 2>/dev/null
    fi
    #DICT_SHARE_PATH=fcitx5/pinyin/dictionaries/moegirl.dict
    mv -fv ${DICT_SHARE_FILE} ${FCITX5_DIICT_PATH}
    printf "%s\n" "chmod +r ${DICT_FILE}"
    chmod +r ${DICT_FILE}
    cd ..
    rm -rf /tmp/.${THEME_NAME}
    printf "%s\n" "${BLUE}文件${RESET}已经保存至${DICT_FILE}"
    printf "%s\n" "${BLUE}The file${RESET} have been saved to ${DICT_FILE}"
    ls -lah ${DICT_FILE}
    printf "%s\n" "如需删除，请手动执行rm -v ${DICT_FILE}"
}
###################
download_dict_model_01() {
    GREP_NAME_V='rime'
    THEME_URL='https://mirrors.bfsu.edu.cn/archlinuxcn/aarch64/'
    THEME_NAME="${GREP_NAME}"
    FCITX5_DIICT_PATH='/usr/share/fcitx5/pinyin/dictionaries'
    check_fcitx5_dict
    download_arch_community_repo_html
    grep_arch_linux_pkg_03
    move_dict_model_01
}
############
outloudvi_fcitx5_moegirl_dict() {
    DICT_NAME='moegirl.dict'
    GREP_NAME='fcitx5-pinyin-moegirl'
    download_dict_model_01
    printf '%s\n' 'https://github.com/outloudvi/fcitx5-pinyin-moegirl'
}
#################
felixonmars_fcitx5_wiki_dict() {
    DICT_NAME='zhwiki.dict'
    GREP_NAME='fcitx5-pinyin-zhwiki'
    download_dict_model_01
    printf '%s\n' 'https://github.com/felixonmars/fcitx5-pinyin-zhwiki'
}
#################
install_onboard() {
    DEPENDENCY_01=''
    DEPENDENCY_02='onboard'
    beta_features_quick_install
}
##################
#"2" "remove other-im:移除可能引发冲突的输入法" \
tmoe_fcitx_faq() {
    #此处不要设置DEPENDENCY_01
    RETURN_TO_WHERE='tmoe_fcitx_faq'
    TMOE_APP=$(whiptail --title "${TMOE_INPUT_METHOD_FRAMEWORK} FAQ" --menu \
        "你想要对这个小可爱做什么?" 0 50 5 \
        "1" "edit /etc/environment(系统环境变量配置)" \
        "2" "im-config:配置${TMOE_INPUT_METHOD_FRAMEWORK}输入法" \
        "3" "${TMOE_INPUT_METHOD_FRAMEWORK}-diagnose:诊断" \
        "4" "edit .pam_environment(用户环境变量配置)" \
        "5" "remove 移除${TMOE_INPUT_METHOD_FRAMEWORK}" \
        "6" "disable autostart 禁止进入桌面后自启动" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${TMOE_APP}" in
    0 | "") install_pinyin_input_method ;;
    1)
        FCITX_ENV_FILE="/etc/environment"
        edit_fcitx_env_file
        ;;
    2) input_method_config ;;
    3)
        printf '%s\n' '若您无法使用fcitx,则请根据以下诊断信息自行解决'
        case ${TMOE_INPUT_METHOD_FRAMEWORK} in
        fcitx) fcitx-diagnose ;;
        fcitx5)
            FCITX_DIAGNOSES='false'
            for i in fcitx5-diagnose fcitx-diagnose; do
                if [[ $(command -v ${i}) ]]; then
                    FCITX_DIAGNOSES='true'
                    ${i}
                    break
                fi
            done
            [[ ${FCITX_DIAGNOSES} = true ]] || printf "%s\n" "Sorry，您的系统不存在${GREEN}fcitx-diagnoses${RESET}命令。"
            ;;
        *) printf '%s\n' 'Sorry，诊断功能不支持ibus' ;;
        esac
        ;;
    4)
        FCITX_ENV_FILE="${HOME}/.pam_environment"
        edit_fcitx_env_file
        [[ ${HOME} = /root ]] || chown -v ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${FCITX_ENV_FILE}
        ;;
    5)
        printf "%s\n" "${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01}"
        do_you_want_to_continue
        ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01}
        [[ $(command -v apt-get) ]] || apt autopurge || apt autoremove
        ;;
    6) disable_fcitx_xdg_autostart ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_fcitx_faq
}
#################
disable_fcitx_xdg_autostart() {
    unset AUTO_STARTUP_LNK AUTO_STARTUP_LNK_02
    unset i
    if [ -d "${XDG_AUTOSTART_DIR}" ]; then
        for i in $(ls ${XDG_AUTOSTART_DIR} | egrep 'ibus-setup|fcitx'); do
            printf "${RED}%s${BLUE}%s\n" "rm -vf" "${XDG_AUTOSTART_DIR}/${i}"
            rm -vf "${XDG_AUTOSTART_DIR}/${i}"
        done
    fi
    XDG_AUTOSTART_DIR_02=${HOME}/.config/autostart
    if [ -d "${XDG_AUTOSTART_DIR_02}" ]; then
        for i in $(ls ${XDG_AUTOSTART_DIR_02} | egrep 'ibus-setup|fcitx'); do
            printf "${RED}%s${BLUE}%s\n" "rm -vf" "${XDG_AUTOSTART_DIR_02}/${i}"
            rm -vf "${XDG_AUTOSTART_DIR_02}/${i}"
        done
    fi
    printf "%s\n" "如需添加桌面启动时自动执行的程序，则请指定${YELLOW}${APPS_LNK_DIR}${RESET}下的desktop文件,并将其复制到${BLUE}${HOME}/.config/autostart/${RESET}文件夹"
}
##################
edit_fcitx_env_file() {
    if [ $(command -v editor) ]; then
        editor ${FCITX_ENV_FILE}
    else
        nano ${FCITX_ENV_FILE}
    fi
}
###########
input_method_config() {
    cd ${HOME}
    #NON_DEBIAN='true'
    #non_debian_function
    if [ ! $(command -v im-config) ]; then
        #DEPENDENCY_01=''
        DEPENDENCY_02='zenity im-config'
        #beta_features_quick_install
        printf "%s\n" "${TMOE_INSTALLATION_COMMAND}} ${DEPENDENCY_02}"
        ${TMOE_INSTALLATION_COMMAND}} ${DEPENDENCY_02}
    fi
    #检测两次
    unset DISPLAY
    im-config
    if [ ! $(command -v im-config) ]; then
        printf '%s\n' 'Sorry，本功能只支持deb系发行版'
    fi
    chmod 755 -R .config/fcitx
    if [ ${HOME} != '/root' ]; then
        printf "%s\n" "正在将${HOME}/.config目录下的fcitx,fcitx5,ibus的文件夹权限修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
        for i in fcitx fcitx5 ibus; do
            [[ ! -e .config/${i} ]] || chown -Rv ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} .config/${i}
        done
    fi
    configure_tmoe_input_method
    #fcitx &>/dev/null || fcitx5 &>/dev/null
    #printf "%s\n" "请手动修改键盘布局，并打开fcitx-configtool"
}
################
install_fcitx_module_cloud_pinyin() {
    DEPENDENCY_01=''
    case "${LINUX_DISTRO}" in
    "debian") DEPENDENCY_02='fcitx-module-cloudpinyin' ;;
    *) DEPENDENCY_02='fcitx-cloudpinyin' ;;
    esac
    beta_features_quick_install
}
######################
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
        ${TMOE_INSTALLATION_COMMAND} unzip
    fi
    ###################
    case "${ARCH_TYPE}" in
    "amd64")
        mkdir /tmp/.BAIDU_IME
        cd /tmp/.BAIDU_IME
        THE_Latest_Link='https://imeres.baidu.com/imeres/ime-res/guanwang/img/Ubuntu_Deepin-fcitx-baidupinyin-64.zip'
        printf "%s\n" "${THE_Latest_Link}"
        aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'fcitx-baidupinyin.zip' "${THE_Latest_Link}"
        unzip 'fcitx-baidupinyin.zip'
        DEB_FILE_NAME="$(ls -l ./*deb | grep ^- | head -n 1 | awk -F ' ' '$0=$NF')"
        apt install ${DEB_FILE_NAME}
        ;;
    *)
        printf "%s\n" "架构不支持，跳过安装百度输入法。"
        arch_does_not_support
        ;;
    esac
    apt-cache show ./fcitx-baidupinyin.deb
    apt install -y ./fcitx-baidupinyin.deb
    printf "%s\n" "若安装失败，则请前往官网手动下载安装。"
    printf '%s\n' 'url: https://srf.baidu.com/site/guanwang_linux/index.html'
    cd /tmp
    rm -rfv /tmp/.BAIDU_IME
    beta_features_install_completed
}
########
install_pkg_warning() {
    printf "%s\n" "检测到${YELLOW}您已安装${RESET} ${GREEN} ${DEPENDENCY_02} ${RESET}"
    printf "%s\n" "如需${RED}卸载${RESET}，请手动输${BLUE} ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_02} ${RESET}"
    press_enter_to_reinstall_yes_or_no
}
#############
install_baidu_pinyin() {
    DEPENDENCY_02="fcitx-baidupinyin"
    if [ -e "/opt/apps/com.baidu.fcitx-baidupinyin/" ]; then
        install_pkg_warning
    fi
    case "${LINUX_DISTRO}" in
    "debian") install_debian_baidu_pinyin ;;
    "arch")
        DEPENDENCY_02="fcitx-baidupinyin"
        beta_features_quick_install
        ;;
    *)
        non_debian_function
        ;;
    esac
}
##########
#已废弃！
sougou_pinyin_amd64() {
    case "${ARCH_TYPE}" in
    "arm64" | "i386")
        LatestSogouPinyinLink=$(curl -L 'https://pinyin.sogou.com/linux' | grep ${ARCH_TYPE} | grep 'deb' | head -n 1 | cut -d '=' -f 3 | cut -d '?' -f 1 | cut -d '"' -f 2)
        printf "%s\n" "${LatestSogouPinyinLink}"
        aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o 'sogou_pinyin.deb' "${LatestSogouPinyinLink}"
        ;;
    *)
        printf "%s\n" "架构不支持，跳过安装搜狗输入法。"
        arch_does_not_support
        ;;
    esac
}
###################
install_debian_sogou_pinyin() {
    #DEPENDENCY_02="sogouimebs"
    DEPENDENCY_02='sogoupinyin'
    ###################
    if [ -e "/usr/share/fcitx-sogoupinyin" ] || [ -e "/usr/share/sogouimebs/" ]; then
        install_pkg_warning
    fi
    case "${ARCH_TYPE}" in
    amd64 | i386)
        printf "%s\n" "本脚本提供的是搜狗官网的版本"
        printf "%s\n" "Debian sid、Kali rolling和ubuntu 20.04等高版本可能无法正常运行,您可以前往优麒麟软件仓库手动下载安装。"
        printf '%s\n' 'http://archive.ubuntukylin.com/ukui/pool/main/s/sogouimebs/'
        do_you_want_to_continue
        LATEST_DEB_URL=$(curl -L 'https://pinyin.sogou.com/linux/' | grep ${ARCH_TYPE} | grep deb | awk '{print $3}' | cut -d '"' -f 2)
        LATEST_DEB_VERSION="sogouimebs_${ARCH_TYPE}.deb"
        install_deb_file_common_model_02
        ;;
    arm64)
        printf '%s\n' 'http://archive.ubuntukylin.com/ukui/pool/main/s/sogouimebs/'
        printf "%s\n" "请前往优麒麟软件仓库,手动下载安装arm64版sogouimebs"
        ;;
    esac
    printf "%s\n" "若安装失败，则请前往官网手动下载安装。"
    printf "%s\n" "url: ${YELLOW}https://pinyin.sogou.com/linux/${RESET}"
    beta_features_install_completed
}
########
install_sogou_pinyin() {
    case "${LINUX_DISTRO}" in
    "debian") install_debian_sogou_pinyin ;;
    "arch")
        DEPENDENCY_02="fcitx-sogouimebs"
        beta_features_quick_install
        ;;
    *) non_debian_function ;;
    esac
}
############
fix_fcitx5_permissions() {
    if [ ${HOME} != '/root' ]; then
        printf "%s\n" "正在将${FCITX5_FILE}的文件权限修改为${CURRENT_USER_NAME}用户和${CURRENT_USER_GROUP}用户组"
        chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${FCITX5_FILE}
    fi
}
############
install_debian_iflyime_pinyin() {
    DEPENDENCY_02="iflyime"
    beta_features_quick_install
    case "${ARCH_TYPE}" in
    amd64)
        REPO_URL='https://mirrors.bfsu.edu.cn/deepin/pool/non-free/i/iflyime/'
        GREP_NAME="${ARCH_TYPE}"
        grep_deb_comman_model_01
        ;;
    *)
        printf "%s\n" "请在更换x64架构的设备后，再来尝试"
        arch_does_not_support
        ;;
    esac
}
#############
install_iflyime_pinyin() {
    case "${LINUX_DISTRO}" in
    "debian") install_debian_iflyime_pinyin ;;
    "arch")
        DEPENDENCY_02="iflyime"
        beta_features_quick_install
        ;;
    *)
        non_debian_function
        ;;
    esac
}
################
####################
tmoe_pinyin_input_method_main "$@"
