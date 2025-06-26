#!/bin/sh
export LANG=en_US.UTF-8

# (原脚本开头部分保持不变，直到第一个 if 语句块)
# 这一段条件判断，在 Docker 容器中可能会导致问题，因为容器启动时 sing-box 肯定还没运行。
# 我们可以简化它，或者在 Dockerfile 中确保 argosb.sh 总是被执行。
# 考虑到 arsgb.sh 后面有 if ... else ins; fi 这样的结构，我们保留这个判断，
# 但确保它不会因为 Docker 环境而误判。
# 实际上，外层的 if 块是检查服务是否已安装或正在运行，如果是，就显示帮助并退出。
# 对于 Docker 容器，我们希望它每次都执行安装流程 (ins)。
# 所以我们可以修改 Dockerfile 的 CMD 来直接调用 ins 函数，或者确保这个 if 语句不阻止 ins。

# 重新修改 argosb.sh，为了 Docker 环境：
# 移除所有与持久化、系统服务管理、SSH 快捷方式相关的部分，因为 Docker 容器是临时的。
# 移除所有下载 sing-box 和 cloudflared 的逻辑，因为我们将在 Dockerfile 中预下载。
# 移除防火墙、crontab、bashrc 等。

# ======= 开始修改 =======
# 移除顶部的大 if 块，让脚本每次都执行安装/启动逻辑
# 这意味着容器每次启动都会重新生成配置并启动 sing-box
# 如果你不想每次都重新生成，则需要一个不同的 Dockerfile 策略（例如挂载配置文件）
# 但你明确表示要用 argosb.sh。

# 从 `if ! find /proc/*/exe ...` 开始，到 `fi` 结束，**整个大 if/else 块都移除掉**
# 确保文件开头就是环境变量声明

# 你的环境变量声明保持不变
export uuid=${uuid:-''}
export port_vl_re=${vlpt:-''}
export port_vm_ws=${vmpt:-''}
export port_hy2=${hypt:-''}
export port_tu=${tupt:-''}
export ym_vl_re=${reym:-''}
export argo=${argo:-''}
export ARGO_DOMAIN=${agn:-''}
export ARGO_AUTH=${agk:-''}
export ipsw=${ip:-''}
export port_socks5=${skpt:-''}
export socks5_user=${skuser:-''}
export socks5_pass=${skpass:-''}

# 修改协议激活检查，确保它能被环境变量触发
# 保持这个 if 块，但简化内部逻辑，去掉提示 exit
# 原来是 || { echo ... exit; }
if [ -z "$vlp" ] && [ -z "$vmp" ] && [ -z "$hyp" ] && [ -z "$tup" ] && [ -z "$anp" ] && [ -z "$skp" ]; then
  echo "提示：使用此脚本时，请在脚本前至少设置一个协议变量哦，再见！";
  exit 1; # 如果没有设置任何协议变量，则退出
fi

showmode(){ # 这个函数可以保留，但其内容可能不再完全适用于 Docker 环境
echo "显示节点信息：agsb或者脚本 list"
echo "双栈VPS显示IPv4节点配置：ip=4 agsb或者脚本 list"
echo "双栈VPS显示IPv6节点配置：ip=6 agsb或者脚本 list"
echo "卸载脚本：agsb或者脚本 del"
}
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "甬哥Github项目 ：github.com/yonggekkk"
echo "甬哥Blogger博客 ：ygkkk.blogspot.com"
echo "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
echo "ArgoSB一键无交互脚本"
echo "当前版本：25.6.18 (Dockerized)" # 修改版本号，表示是 Docker 化版本
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
hostname=$(uname -a | awk '{print $2}') # 保留
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2) # 保留
[ -z "$(systemd-detect-virt 2>/dev/null)" ] && vi=$(virt-what 2>/dev/null) || vi=$(systemd-detect-virt 2>/dev/null) # 保留
case $(uname -m) in # 保留
aarch64) cpu=arm64;;
x86_64) cpu=amd64;;
*) echo "目前脚本不支持$(uname -m)架构" && exit
esac
mkdir -p "$HOME/agsb" # 保留
warpcheck(){ # 保留
wgcfv6=$(curl -s6m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
wgcfv4=$(curl -s4m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
}
# === ins() 函数，核心生成逻辑，需要大改动 ===
ins(){
# 移除 if [ ! -e "$HOME/agsb/sing-box" ]; then ... fi 块，因为 sing-box 会在 Dockerfile 中预安装
# sbcore=$("$HOME/agsb/sing-box" version 2>/dev/null | awk '/version/{print $NF}') # 保留，但需要确保 sing-box 已存在
# echo "已安装Sing-box正式版内核：$sbcore"

# 确保 sing-box 可执行文件路径正确，不再依赖脚本下载
sbcore=$("$HOME/agsb/sing-box" version 2>/dev/null | awk '/version/{print $NF}')
echo "已安装Sing-box正式版内核：$sbcore"

cat > "$HOME/agsb/sb.json" <<EOF
{
"log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
EOF
if [ -z "$uuid" ]; then
uuid=$("$HOME/agsb/sing-box" generate uuid)
fi
echo "$uuid" > "$HOME/agsb/uuid"
echo "UUID密码：$uuid"
# 移除 openssl 相关命令，证书由 Dockerfile 复制
# 移除 if [ ! -f "$HOME/agsb/private.key" ]; then ... fi 块，证书由 Dockerfile 复制

# Vless-reality 部分保持不变，假设它生成了 private_key, public_key, short_id
# 你需要确保这些文件路径正确，并且这些命令能在 Docker 环境中执行
if [ -n "$vlp" ]; then
vlp=vlpt
if [ -z "$port_vl_re" ]; then
port_vl_re=$(shuf -i 10000-65535 -n 1)
fi
if [ -z "$ym_vl_re" ]; then
ym_vl_re=www.yahoo.com
fi
echo "$port_vl_re" > "$HOME/agsb/port_vl_re"
echo "$ym_vl_re" > "$HOME/agsb/ym_vl_re"
# === 修改这里 === 移除检查文件存在性，直接生成 key_pair
# if [ ! -e "$HOME/agsb/private_key" ]; then
key_pair=$("$HOME/agsb/sing-box" generate reality-keypair)
private_key=$(echo "$key_pair" | awk '/PrivateKey/ {print $2}' | tr -d '"')
public_key=$(echo "$key_pair" | awk '/PublicKey/ {print $2}' | tr -d '"')
short_id=$("$HOME/agsb/sing-box" generate rand --hex 4)
echo "$private_key" > "$HOME/agsb/private_key"
echo "$public_key" > "$HOME/agsb/public.key"
echo "$short_id" > "$HOME/agsb/short_id"
# fi # === 修改这里 ===
private_key=$(cat "$HOME/agsb/private_key")
public_key=$(cat "$HOME/agsb/public.key")
short_id=$(cat "$HOME/agsb/short_id")
echo "Vless-reality端口：$port_vl_re"
echo "Reality域名：$ym_vl_re"
cat >> "$HOME/agsb/sb.json" <<EOF
    {
      "type": "vless",
      "tag": "vless-sb",
      "listen": "::",
      "listen_port": ${port_vl_re},
      "users": [
        {
          "uuid": "${uuid}",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "${ym_vl_re}",
          "reality": {
          "enabled": true,
          "handshake": {
            "server": "${ym_vl_re}",
            "server_port": 443
          },
          "private_key": "$private_key",
          "short_id": ["$short_id"]
        }
      }
    },
EOF
else
vlp=vlptargo
fi
# Vmess 部分保持不变，确保路径正确
if [ -n "$vmp" ]; then
vmp=vmpt
if [ -z "$port_vm_ws" ]; then
port_vm_ws=$(shuf -i 10000-65535 -n 1)
fi
echo "$port_vm_ws" > "$HOME/agsb/port_vm_ws"
echo "Vmess-ws端口：$port_vm_ws"
cat >> "$HOME/agsb/sb.json" <<EOF
{
        "type": "vmess",
        "tag": "vmess-sb",
        "listen": "::",
        "listen_port": ${port_vm_ws},
        "users": [
            {
                "uuid": "${uuid}",
                "alterId": 0
            }
        ],
        "transport": {
            "type": "ws",
            "path": "${uuid}-vm",
            "max_early_data":2048,
            "early_data_header_name": "Sec-WebSocket-Protocol"
        },
        "tls":{
                "enabled": false,
                "server_name": "www.bing.com",
                "certificate_path": "$HOME/agsb/cert.pem",
                "key_path": "$HOME/agsb/private.key"
            }
    },
EOF
else
vmp=vmptargo
fi
# Hysteria2 部分保持不变，确保路径正确
if [ -n "$hyp" ]; then
hyp=hypt
if [ -z "$port_hy2" ]; then
port_hy2=$(shuf -i 10000-65535 -n 1)
fi
echo "$port_hy2" > "$HOME/agsb/port_hy2"
echo "Hysteria-2端口：$port_hy2"
cat >> "$HOME/agsb/sb.json" <<EOF
    {
        "type": "hysteria2",
        "tag": "hy2-sb",
        "listen": "::",
        "listen_port": ${port_hy2},
        "users": [
            {
                "password": "${uuid}"
            }
        ],
        "ignore_client_bandwidth":false,
        "tls": {
            "enabled": true,
            "alpn": [
                "h3"
            ],
            "certificate_path": "$HOME/agsb/cert.pem",
            "key_path": "$HOME/agsb/private.key"
        }
    },
EOF
else
hyp=hyptargo
fi
# Tuic 部分保持不变，确保路径正确
if [ -n "$tup" ]; then
tup=tupt
if [ -z "$port_tu" ]; then
port_tu=$(shuf -i 10000-65535 -n 1)
fi
echo "$port_tu" > "$HOME/agsb/port_tu"
echo "Tuic-v5端口：$port_tu"
cat >> "$HOME/agsb/sb.json" <<EOF
        {
            "type":"tuic",
            "tag": "tuic5-sb",
            "listen": "::",
            "listen_port": ${port_tu},
            "users": [
                {
                    "uuid": "${uuid}",
                    "password": "${uuid}"
                }
            ],
            "congestion_control": "bbr",
            "tls":{
                "enabled": true,
                "alpn": [
                    "h3"
                ],
                "certificate_path": "$HOME/agsb/cert.pem",
                "key_path": "$HOME/agsb/private.key"
            }
        },
EOF
else
tup=tuptargo
fi
# Anytls 部分保持不变，确保路径正确
if [ -n "$anp" ]; then
anp=anpt
if [ -z "$port_an" ]; then
port_an=$(shuf -i 10000-65535 -n 1)
fi
echo "$port_an" > "$HOME/agsb/port_an"
echo "Anytls端口：$port_tu"
cat >> "$HOME/agsb/sb.json" <<EOF
        {
            "type":"anytls",
            "tag":"anytls-sb",
            "listen":"::",
            "listen_port":${port_an},
            "users":[
                {
                  "password":"${uuid}"
                }
            ],
            "padding_scheme":[],
            "tls":{
                "enabled": true,
                "certificate_path": "$HOME/agsb/cert.pem",
                "key_path": "$HOME/agsb/private.key"
            }
        },
EOF
else
anp=anptargo
fi
# SOCKS5 部分 (你添加的，保持不变)
if [ -n "$skp" ]; then
    if [ -z "$port_socks5" ]; then
        port_socks5=$(shuf -i 10000-65535 -n 1)
    fi
    socks5_user=${skuser:-"your_username"}
    socks5_pass=${skpass:-"password"}

    echo "SOCKS5端口：$port_socks5"

cat >> "$HOME/agsb/sb.json" <<EOF
    {
        "type": "socks",
        "tag": "socks-in",
        "listen": "::",
        "listen_port": ${port_socks5},
        "users": [
            {
                "username": "${socks5_user}",
                "password": "${socks5_pass}"
            }
        ]
    },
EOF
fi
sed -i '${s/,\s*$//}' "$HOME/agsb/sb.json"
cat >> "$HOME/agsb/sb.json" <<EOF
],
"outbounds": [
{
"type":"direct",
"tag":"direct"
}
]
}
EOF
nohup "$HOME/agsb/sing-box" run -c "$HOME/agsb/sb.json" >/dev/null 2>&1 &

# === 修改这里 === 移除 Cloudflared Argo 的安装和启动逻辑
# 因为我们不确定它在 Docker 容器内的行为，这部分是导致复杂性的来源。
# 如果你需要 Argo，你可能需要单独的 Cloudflared Docker 镜像，或在另一个容器中运行。
# 移除 if [ -n "$argo" ]; then ... fi 整个块

# === 修改这里 === 移除 SSH 快捷方式、bashrc、crontab、systemctl、iptables 等系统管理和持久化逻辑
# 这些在 Docker 容器中通常不适用或不需要。
# 找到 if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' ... else ... fi 整个大块，移除
# 替换为直接调用 cip 函数，然后让容器保持运行

# 确保脚本不会退出，以便容器持续运行 Sing-box
cip # 调用 cip 函数，打印 IP 信息
echo "Sing-box and ArgoSB setup complete. Container will remain running."

# 保持容器活跃，防止 CMD 命令结束后容器退出。
# Sing-box 已经通过 nohup 在后台运行了，所以这里只需要一个无限循环来保持容器存活。
tail -f /dev/null # 或者 sleep infinity
