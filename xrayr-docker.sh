#!/bin/bash
# Description: 
# 自用脚本,仅测试 Debian / Ubuntu 平台
xrayr_path="/etc/XrayR"
xrayr_config=${xrayr_path}/docker-compose.yml

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
export PATH=$PATH:/usr/local/bin

pre_check() {
    if [ -e /etc/os-release ]; then
        if grep -qi "alpine" /etc/os-release; then
            os_alpine='1'
        fi
    fi
    
    if [ "${os_alpine}" != "1" ] && ! command -v systemctl >/dev/null 2>&1; then
        echo "不支持此系统：未找到 systemctl 命令"
        exit 1
    fi

    if [[ ${EUID} -ne 0 ]]; then
        echo -e "错误: 必须使用root用户运行此脚本!n"
        exit 1
    fi
    
    local ip_info
    ip_info=$(curl -m 10 -s https://ipapi.co/json)

    if [[ $? -ne 0 ]]; then
        echo "警告: 无法从 ipapi.co 获取IP信息。您需要手动指定是否使用中国镜像。"
        # 回退机制：手动输入
        read -p "您是否在中国？如果是请输入 'Y',否则输入 'N': [Y/n] " input
        input=${input:-Y} # 默认为 'Y'
    else
        if echo "${ip_info}" | grep -q 'China'; then
            echo "根据 ipapi.co 提供的信息，当前 IP 可能在中国。"
            input='Y'
        else
            input='N'
        fi
    fi

    case ${input} in
        [yY][eE][sS]|[yY])
            echo "使用中国镜像。"
            CN=true
            ;;
        [nN][oO]|[nN])
            echo "不使用中国镜像。"
            CN=false
            ;;
        *)
            echo "无效输入...默认不使用中国镜像。"
            CN=false
            ;;
    esac

    if [[ "${CN}" = false ]]; then
        Get_Docker_URL="get.docker.com"
        Get_Docker_Argu=" "
    else
        Get_Docker_URL="get.docker.com"  # 中国镜像 URL
        Get_Docker_Argu=" -s docker --mirror Aliyun"   # 中国镜像参数
    fi
}

before_show_menu() {
    # 显示提示信息并等待用户按下回车键
    echo -e "n${yellow}* 按回车返回主菜单 *${plain}"
    read -r _temp
    
    # 调用主菜单显示函数
    show_menu
}

install_base() {
    # 打印开始安装的消息
    echo "开始安装基础软件包..."

    # 更新软件源
    echo "更新软件包数据源..."
    apt-get update -y

    # 安装基础软件包，可以根据需要添加或删除软件包
    echo "正在安装软件包: sudo vim, curl, wget"
    apt-get install -y sudo vim curl wget

    # 检查软件包是否安装成功
    local packages=(sudo vim curl wget)
    for pkg in "${packages[@]}"; do
        if command -v "$pkg" >/dev/null 2>&1; then
            echo "$pkg 已成功安装."
        else
            echo "警告: 安装 $pkg 失败，继续安装其他软件包..."
        fi
    done

    # 打印完成消息
    echo "基础软件包安装完成。"
}

install_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "正在安装 Docker"
        if ! bash <(curl -sL "https://${Get_Docker_URL}") "${Get_Docker_Argu}"; then
            echo -e "下载脚本失败，请检查本机能否连接 ${Get_Docker_URL}${plain}"
            return 1
        fi
        sudo systemctl enable docker.service
        sudo systemctl start docker.service
        echo -e "${green}Docker${plain} 安装成功"
    else
        echo -e "${yellow}Docker 已安装${plain}"
    fi
}

install_xrayr() {
    pre_check
    install_base
    install_docker
    echo -e "> 安装xrayr"
    if [ ! -d ${xrayr_config} ]; then
        mkdir -p ${xrayr_path}
        touch ${xrayr_path}/xrayr.yml
    else
        echo "您可能已经安装过xrayr,重复安装会覆盖数据,请注意。"
        read -e -r -p "是否退出安装? [Y/n] " input
        case ${input} in
        [yY][eE][sS] | [yY])
            echo "退出安装"
            exit 0
            ;;
        [nN][oO] | [nN])
            echo "继续安装"
            ;;
        *)
            echo "退出安装"
            exit 0
            ;;
        esac
    fi
    chmod 755 -R ${xrayr_path}
    modify_xrayr_config 0
    before_show_menu
}

modify_xrayr_config() {
    # 先检查配置文件是否存在
    if [ -f "${xrayr_config}" ]; then
        # 存在，则使用vim编辑
        echo "配置文件已存在，正在打开编辑..."
        vim ${xrayr_config}
        echo -e "配置 ${green}修改成功，请稍等重启生效${plain}"
    else
        # 不存在，则进行创建流程    
    echo -e "修改xrayr参数"
echo "设置面板类型："
options=("NewV2board" "SSpanel")
select PanelType in "${options[@]}"; do
    case $PanelType in
        "NewV2board")
            echo "你选择了 NewV2board"
            break
            ;;
        "SSpanel")
            echo "你选择了 SSpanel"
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
echo "选择的面板类型是：$PanelType"
    read -r -ep "设置面板地址： " -i "" ApiHost
    read -r -ep "设置通讯密钥： " -i "" ApiKey
    read -r -ep "设置节点ID,默认： " -i "" NodeID
    echo "设置节点类型："
options=("Shadowsocks" "V2ray" "Trojan") 
select NodeType in "${options[@]}"; do
    case $NodeType in
        "Shadowsocks")
            echo "你选择了 Shadowsocks"
            break
            ;;
        "V2ray")
            echo "你选择了 V2ray"
            break
            ;;
        "Trojan")  
            echo "你选择了 Trojan"
            break
            ;;
        *) echo "无效选项，请重新选择。";;
    esac
done

echo "选择的节点类型是：$NodeType"

    cat >${xrayr_config} <<EOF
services:
  xrayr:
    image: ghcr.io/rebecca554owen/xrayr:latest
    container_name: xrayr
    network_mode: host # host 模式方便监听ipv4/ipv6。
    restart: always
    volumes:
        # - /etc/XrayR/xrayr.yml:/etc/XrayR/xrayr.yml # 挂载当前目录的配置文件到容器内部。
        - /etc/XrayR/cert/:/etc/XrayR/cert/ # 挂载目录用于存放证书。
        # - ./dns.json:/etc/XrayR/dns.json # 挂载当前目录的配置文件到容器内部。
        # - ./route.json:/etc/XrayR/route.json # 挂载当前目录的配置文件到容器内部。
        # - ./custom_inbound.json:/etc/XrayR/custom_inbound.json # 挂载当前目录的配置文件到容器内部。
        # - ./custom_outbound.json:/etc/XrayR/custom_outbound.json # 挂载当前目录的配置文件到容器内部。
        # - ./rulelist:/etc/XrayR/rulelist # 挂载当前目录的配置文件到容器内部。
    environment:
        # - DnsConfigPath=/etc/XrayR/dns.json
        # - RouteConfigPath=/etc/XrayR/route.json
        # - InboundConfigPath=/etc/XrayR/custom_inbound.json
        # - OutboundConfigPath=/etc/XrayR/custom_outbound.json
        - PanelType=${PanelType}
        - ApiHost=${ApiHost}
        - ApiKey=${ApiKey}
        - NodeID=${NodeID}
        - NodeType=${NodeType} # 可选 V2ray, Shadowsocks，Trojan
        # - EnableVless=true # Enable Vless for V2ray Type
        # - EnableREALITY=true # 是否开启 REALITY
        # - CertMode=http # 可选 none, file, http, tls, dns.
        # - CertDomain=xboard.com
        # - Provider=cloudflare
        # - CLOUDFLARE_EMAIL=
        # - CLOUDFLARE_API_KEY=  # 这里务必使用全局API key
EOF
        echo -e "配置文件创建成功。"
    fi
    restart_xrayr_update  # 用来重启xrayr并应用更新
    before_show_menu      # 用来返回主菜单
}

restart_xrayr_update() {
    echo -e "> 重启并更新xrayr"
    if [ -d "${xrayr_path}" ]; then
        cd "${xrayr_path}" || { echo "错误：无法进入xrayr目录 ${xrayr_path}"; return 1; }

        # 检查是否安装了 docker-compose 命令
        if command -v docker-compose >/dev/null 2>&1; then
            docker-compose pull && docker-compose down && docker-compose up -d
            echo -e "${green}xrayr 重启成功并应用了更新。${plain}"
        # 检查是否安装了 docker 命令，同时支持 compose 子命令
        elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
            docker compose pull && docker compose down && docker compose up -d
            echo -e "${green}xrayr 重启成功并应用了更新。${plain}"
        else
            echo -e "${red}错误：未找到 docker-compose 或 docker 命令。${plain}"
            return 1
        fi
    else
        echo -e "${red}错误：xrayr 配置路径 ${xrayr_path} 不存在。${plain}"
        return 1
    fi
    docker image prune -f -a
    # 调用返回主菜单函数
    before_show_menu
}

start_xrayr() {
    echo -e "> 启动xrayr"
    cd "${xrayr_path}" || exit
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose up -d
    elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        docker compose up -d
    else
        echo "未找到 Docker 或 Docker Compose 命令。"
        return 1
    fi
    before_show_menu
}

stop_xrayr() {
    echo -e "> 停止xrayr"
    cd "${xrayr_path}" || exit
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose down
    elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        docker compose down
    else
        echo "未找到 Docker 或 Docker Compose 命令。"
        return 1
    fi
    before_show_menu
}

show_xrayr_log() {
    echo -e "> 获取 xrayr 日志"
    cd "${xrayr_path}" || exit
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose logs -f
    elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        docker compose logs -f
    else
        echo "未找到 Docker 或 Docker Compose 命令。"
        return 1
    fi
    before_show_menu
}

uninstall_xrayr() {
    echo -e "> 卸载xrayr"
    if command -v docker-compose >/dev/null 2>&1; then
        cd "${xrayr_path}" && docker-compose down
    elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        cd "${xrayr_path}" && docker compose down
    else
        echo "Docker 或 Docker Compose 未安装。"
        return 1
    fi
    if [[ -d "${xrayr_path}" ]]; then
        rm -rf "${xrayr_path}"
    else
        echo "xrayr 安装目录不存在。"
    fi
    docker rmi -f ghcr.io/rebecca554owen/xrayr >/dev/null 2>&1 || echo "Docker 镜像可能已被删除。"
    before_show_menu
}

show_menu() {
    echo -e "
    ${green}自用xrayr脚本${plain} ${red}${plain}
    ————————————————
    ${green}1.${plain} 安装xrayr
    ${green}2.${plain} 修改xrayr配置
    ${green}3.${plain} 启动xrayr
    ${green}4.${plain} 停止xrayr
    ${green}5.${plain} 更新xrayr
    ${green}6.${plain} 查看xrayr日志
    ${green}7.${plain} 卸载xrayr
    ————————————————
    ${green}0.${plain}  退出脚本
    "
    echo && read -r -ep "请输入选择" num
    case ${num} in
    0)
        exit 0
        ;;
    1)
        install_xrayr
        ;;
    2)
        modify_xrayr_config
        ;;
    3)
        start_xrayr
        ;;
    4)
        stop_xrayr
        ;;
    5)
        restart_xrayr_update
        ;;
    6)
        show_xrayr_log
        ;;
    7)
        uninstall_xrayr
        ;;
    *)
        echo -e "你没有选任何一个选项"
        ;;
    esac
}

show_menu
