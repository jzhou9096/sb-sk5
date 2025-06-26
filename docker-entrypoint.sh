#!/bin/sh

# 1. 下载最新原始的 argosb.sh 脚本
# 确保这个 URL 是 ygkkk/argosb 脚本的最新下载地址
echo "Downloading original argosb.sh..."
curl -Ls https://raw.githubusercontent.com/yonggekkk/argosb/main/argosb.sh -o /tmp/argosb.sh
chmod +x /tmp/argosb.sh

# 2. 注入 SOCKS5 变量定义到 /tmp/argosb.sh 脚本的头部变量声明部分
echo "Injecting SOCKS5 variable definitions..."
sed -i '/export ipsw=${ip:-'\''}/a\
export port_socks5=${skpt:-''}\
export socks5_user=${skuser:-"your_username"}\
export socks5_pass=${skpass:-"password"}\
' /tmp/argosb.sh
# 还需要在协议激活检查那里添加 skp
sed -i 's/|| \[ "$anp" = yes \] || { echo "提示：使用此脚本时，请在脚本前至少设置一个协议变量哦，再见！"; exit; }/|| \[ "$anp" = yes \] || \[ "$skp" = yes \] || { echo "提示：使用此脚本时，请在脚本前至少设置一个协议变量哦，再见！"; exit; }/' /tmp/argosb.sh
sed -i '/\[ -z "${anpt+x}" \] || anp=yes/a\
\[ -z "${skpt+x}" \] || skp=yes\
' /tmp/argosb.sh


# 3. 注入 SOCKS5 Inbound 配置到 /tmp/argosb.sh 脚本的 inbounds 生成逻辑中
# 找到 'sed -i '${s/,\s*$//}' "$HOME/agsb/sb.json"' 这一行前面，插入 SOCKS5 逻辑
echo "Injecting SOCKS5 inbound configuration..."
sed -i '/sed -i '\''\$\{s\/,\\s\*$\/\/\}'\'' "$HOME\/agsb\/sb.json"/i\
if [ -n "$skp" ]; then\
    if [ -z "$port_socks5" ]; then\
        port_socks5=$(shuf -i 10000-65535 -n 1)\
    fi\
    echo "SOCKS5端口：$port_socks5"\
cat >> "$HOME/agsb/sb.json" <<EOF_SOCKS5\
    {\
        "type": "socks",\
        "tag": "socks-in",\
        "listen": "0.0.0.0",\
        "listen_port": ${port_socks5},\
        "udp": true,\
        "sniff": true,\
        "sniff_override_destination": true,\
        "users": [\
            {\
                "name": "${socks5_user}",\
                "password": "${socks5_pass}"\
            }\
        ]\
    },\
EOF_SOCKS5\
fi\
' /tmp/argosb.sh

# 4. 执行被修改过的 argosb.sh 脚本
# "$@" 会将所有传递给当前容器的参数（例如 hypt="" 等）都传递给 argosb.sh
echo "Executing modified argosb.sh..."
exec /tmp/argosb.sh "$@"
