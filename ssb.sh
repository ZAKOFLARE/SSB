set -e 

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${RED}======================================================${NC}"
echo -e "${RED}    您正在运行「zakoflare 笑传之Server Server Boom」v1 ${NC}"
echo -e "${RED}======================================================${NC}"
echo -e "${RED}【警告】${NC} 执行后服务器将成为一块砖头，数据永久丢失！"
echo -e "你确定要继续吗？"
read -p "请输入 'y' 确认或y以外的任意字母键取消: " confirm
if [ "$confirm" != "y" ]; then
    echo -e "${GREEN}明智的选择，脚本已取消。${NC}"
    exit 0
fi

# ---------- 步骤 2：申请 root 权限 ----------
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}检测到当前非 root 用户，请求 sudo...${NC}"
    sudo -v || { echo -e "${RED}sudo 授权失败，脚本退出。${NC}"; exit 1; }
    # 保持 sudo 有效期
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    # 用 sudo 重新执行自身
    exec sudo bash "$0" "$@"
fi

echo -e "${GREEN}已获得 root 权限，开始拆家...${NC}"
sleep 2

# 关闭 SSH 屏蔽所有端口
echo -e "${YELLOW}[1/4] 正在关闭 SSH 服务...${NC}"
systemctl stop sshd 2>/dev/null || systemctl stop ssh 2>/dev/null || true
systemctl disable sshd 2>/dev/null || systemctl disable ssh 2>/dev/null || true

echo -e "${YELLOW}[2/4] 正在屏蔽所有端口 (iptables DROP all)...${NC}"
# 清空现有规则
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
# ufw
if command -v ufw &>/dev/null; then
    ufw --force disable
    ufw default deny incoming
    ufw default deny outgoing
    ufw --force enable
fi

apt-get purge -y iptables-persistent netfilter-persistent 2>/dev/null || true

sleep 2

# 清空!
TARGET_DIRS=("/opt" "/www" "/srv" "/home" "/root" "/etc" "/var/log")
for dir in "${TARGET_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf --no-preserve-root "${dir}"/* 2>/dev/null || true
    fi
done
# 一起带走
[ -d "/var/www" ] && rm -rf --no-preserve-root /var/www/* 2>/dev/null || true

# 全清软件包!
dpkg --get-selections | grep -v deinstall | awk '{print $1}' | xargs -r apt-get purge -y --allow-remove-essential 2>/dev/null || true

# 干掉配置文件
dpkg --get-selections | grep -v deinstall | awk '{print $1}' | xargs -r dpkg --purge 2>/dev/null || true

# 清理残留
apt-get autoremove -y || true
apt-get autoclean -y || true

# 终极一步：把脚本自身也删掉（已经用不到了）
rm -- "$0" 2>/dev/null || true

# 最后尝试关机（由于网络已断，本次会话可能也会断，但无所谓）
/sbin/shutdown -h now "This is the way." 2>/dev/null || true