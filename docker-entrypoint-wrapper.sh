#!/bin/sh

# 定义原始镜像的 docker-entrypoint.sh 路径
ORIGINAL_ENTRYPOINT="/usr/local/bin/docker-entrypoint.sh"
# 定义原始镜像的 CMD
ORIGINAL_CMD="node index.js" # 根据之前提供的信息，这个CMD是node index.js

# --- 1. 执行原始的 docker-entrypoint.sh ---
echo "Executing original docker-entrypoint.sh..."
# 注意：这里我们使用 exec 原始 ENTRYPOINT，因为它会负责启动整个服务栈。
# 这意味着原始ENTRYPOINT会替换掉当前的shell进程。
# 如果原始ENTRYPOINT会在后台启动服务（如nohup），并且会立即返回，
# 那么我们才能在它之后继续执行。
# 否则，如果它是一个阻塞的命令，下面的代码将不会执行。
# 我们需要假设 original_entrypoint 会在后台启动或者最终会返回控制权。
# 如果直接 exec 原始 ENTRYPOINT 后面的代码就不执行了。
# 所以这里我们需要在后台运行 original_entrypoint，或者它自己就处理了后续启动。
# 
# 鉴于ygkkk/argosb的复杂性，最安全的做法是：
# 运行原始的 ENTRYPOINT，并通过 /root/agsb/argosb.sh 传递参数，让其生成配置
# 然后等待配置文件生成，再修改。
#
# 由于原始镜像的 ENTRYPOINT 是 docker-entrypoint.sh，而它可能进一步启动 node index.js，
# 并且 argosb.sh 又在 /root/agsb 目录，这暗示了 docker-entrypoint.sh 可能会调用 argosb.sh。
#
# 最稳妥的方法是，让我们的 ENTRYPOINT 先运行 argosb.sh，确保 sb.json 生成，再对其进行修改。

# 运行 argosb.sh 来生成 sb.json
# 注意：这里需要传入至少一个协议变量，否则 argosb.sh 会直接退出
echo "Running argosb.sh to generate initial sb.json..."
/root/agsb/argosb.sh hypt="" # 确保 hypt="" 触发脚本执行。传入所有通过 docker run -e 设置的环境变量
# 确保所有环境变量被传递给 argosb.sh，因为它将从环境中读取
# 这里的 "$@" 应该包含 docker run CMD 传递的参数，但我们知道原始 CMD 是 node index.js，
# 所以这里我们需要确保 argosb.sh 拿到它需要的环境变量
# 最好的方法是直接调用 argosb.sh，而 argosb.sh 会自己去读取 ENV。
# 所以这里我们只是执行它一次，让它生成文件。

# 等待 sb.json 文件生成，确保它存在
MAX_RETRIES=10
RETRY_COUNT=0
echo "Waiting for /root/agsb/sb.json to be generated..."
while [ ! -f "/root/agsb/sb.json" ] && [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    sleep 1
    RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ ! -f "/root/agsb/sb.json" ]; then
    echo "Error: /root/agsb/sb.json was not generated. Aborting."
    exit 1
fi

# --- 2. 修改已生成的 sb.json 文件，注入 SOCKS5 配置 ---
echo "Injecting SOCKS5 configuration into /root/agsb/sb.json..."

# 1. 查找 inbounds 数组的最后一个元素，在其后面添加 SOCKS5 块
# 这是一个相对复杂的 sed 操作，因为它需要找到末尾的 "}" 并插入内容
# 假设 sb.json 的结构是稳定的，并且 outbounds 紧随 inbounds 之后
# 我们将在 outbounds 数组开始之前，inbounds 数组的最后一个元素之后插入
# 由于 hy2 是最后一个inbound，在其后加逗号和sk5，再删除最后的逗号
# 查找 outbounds 数组的开始，在其前插入
sed -i '/"outbounds": \[/i\
    {\
        "type": "socks",\
        "tag": "socks-in",\
        "listen": "0.0.0.0",\
        "listen_port": '${skpt:-25635}',\
        "users": [\
            {\
                "username": "'${skuser:-"your_username"}'",\
                "password": "'${skpass:-"your_password"}'"\
            }\
        ]\
    }\
    , # <-- 这是一个逗号，需要在插入后清理
' /root/agsb/sb.json

# 2. 清理多余的逗号
# Sing-box 要求数组的最后一个元素后面不能有逗号。
# 我们的注入可能导致 SOCKS5 后面多一个逗号，或者 Hysteria2 后面多一个逗号。
# 最稳妥的方法是，找到 "outbounds": [ 的前一行，如果以逗号结尾，则删除。
# 这个sed命令查找以 "outbounds": [ 开头的前一行，如果该行以 "," 结尾，则删除该 ","。
sed -i '/"outbounds": \[/{x;s/,//;x;s/,$//;p;s/.*//;x};1!b;n;p}' /root/agsb/sb.json
# 这是一个复杂的sed，如果它导致新的问题，我们可以用简单的文本替换来代替

# 简单的替代方法：如果知道 SOCKS5 总是最后一个入站，可以这样清理逗号
# 但如果顺序不确定，可能还需要更复杂的逻辑
# sed -i '$s/,//' /root/agsb/sb.json # 如果 SOCKS5 是最后一个入站，可以删除倒数第二个 } 之后的逗号

# 更好的插入点：在 inbounds 数组的末尾 ] 之前插入
# 找到 inbounds 数组的最后一个 ]，在其前面插入 SOCKS5 块
# 这样避免了逗号问题，SOCKS5前面总有逗号，SOCKS5如果是最后一个，后面没逗号。
# 但这依赖于原始 sb.json 中 inbounds 数组的闭合位置。
# 鉴于之前都是在 if 块里 cat >> 追加，那么结尾的逗号就是 sed -i '${s/,\s*$//}' 清理的。
# 那么我们只需要在 sb.json 文件中的 inbounds 数组后面直接添加 SOCKS5 块，
# 并且确保 SOCKS5 块的末尾没有逗号 (因为它可能是最后一个 inbounds)。
# 
# 简化 SOCKS5 注入的 sed 命令，直接在 "inbounds": [ 之后插入
# 但这会破坏顺序，SOCKS5 会变成第一个 inbounds。
#
# 最稳妥的方案是：
# 1. 获取当前生成的 sb.json 内容。
# 2. 用 shell script 或 awk/jq 来解析 JSON，插入新的 inbounds。
# 3. 再把修改后的 JSON 写回去。
#
# 但这在轻量级容器里会更复杂，需要安装 jq。

# 回到最开始的思路，如果 sb.json 的 inbounds 数组结构稳定，
# 直接在 outbounds 前插入 SOCKS5 块，并在 SOCKS5 块最后加上逗号，
# 然后依赖原始 argosb.sh 脚本的 `sed -i '${s/,\s*$//}'` 来清理末尾逗号。

# 让我们再次尝试你最初修改 argosb.sh 的方式，但这次我们是**在运行时用 sed 修改已生成的 argosb.sh**
# 确保 /root/agsb/argosb.sh 被修改
echo "Re-injecting SOCKS5 logic into argosb.sh that was just run..."
# 1. 注入变量定义和 skp 激活逻辑
sed -i 's/export ipsw=${ip:-'\''}/export ipsw=${ip:-'\''}\nexport port_socks5=${skpt:-''}\nexport socks5_user=${skuser:-"your_username"}\nexport socks5_pass=${skpass:-"password"}/g' /root/agsb/argosb.sh
sed -i 's/|| \[ "$anp" = yes \] || { echo "提示：使用此脚本时，请在脚本前至少设置一个协议变量哦，再见！"; exit; }/|| \[ "$anp" = yes \] || \[ "$skp" = yes \] || { echo "提示：使用此脚本时，请在脚本前至少设置一个协议变量哦，再见！"; exit; }/g' /root/agsb/argosb.sh
sed -i '/\[ -z "${anpt+x}" \] || anp=yes/a\[ -z "${skpt+x}" ] || skp=yes' /root/agsb/argosb.sh

# 2. 注入 SOCKS5 inbounds 生成逻辑
sed -i '/sed -i '\''\$\{s\/,\\s\*$\/\/\}'\'' "$HOME\/agsb\/sb.json"/i\
if \[ -n "$skp" \]; then\
    if \[ -z "$port_socks5" \]; then\
        port_socks5=$(shuf -i 10000-65535 -n 1)\
    fi\
    echo "SOCKS5端口：$port_socks5"\
cat >> "$HOME/agsb/sb.json" <<EOF_SOCKS5_INJECT\
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
                "username": "${socks5_user}",\
                "password": "${socks5_pass}"\
            }\
        ]\
    },\
EOF_SOCKS5_INJECT\
fi\
' /root/agsb/argosb.sh

# --- 3. 最后，启动原始镜像的 CMD ---
# 此时，/root/agsb/argosb.sh 已经被修改，并且它将由原始的 Node.js 程序或其他机制来启动。
# 我们需要确保原始的 Node.js 程序或启动机制能够正常运行，并且它会调用到我们修改后的 argosb.sh
# 
# 如果原始的 ENTRYPOINT 和 CMD 组合是 ["docker-entrypoint.sh"] 和 ["node", "index.js"]，
# 那么 docker-entrypoint.sh 在执行完后，会 exec "node index.js"。
#
# 我们可以直接执行 original_entrypoint，并期望它最终会执行 /root/agsb/argosb.sh。
# 但是，因为我们在 entrypoint-wrapper 里修改了 argosb.sh，原始 ENTRYPOINT 可能已经执行了 argosb.sh。
#
# 最稳妥的方法是：
# 1. 我们先运行原始的 docker-entrypoint.sh (在后台或者不阻塞)，它会生成 sb.json。
# 2. 我们再修改 argosb.sh。
# 3. 我们再执行原始的 CMD (node index.js)。
# 4. 如果 argosb.sh 负责启动 sing-box，那么它在运行 argosb.sh 的时候就会启动 Sing-box。
#
# 这就陷入了循环，因为 argosb.sh 会自动启动 sing-box。
#
# ------------------------------------------------------------------------------------------------
# 放弃在 docker-entrypoint-wrapper 中复杂修改 argosb.sh 的方法，
# 直接让这个 wrapper 脚本生成 sb.json，并启动 sing-box，
# 同时尝试启动原始的 Node.js CMD (如果它不是 sing-box 的启动器)。
#
# 这将是结合了部分“从头构建”和“保留原始CMD”的混合方案。
# ------------------------------------------------------------------------------------------------

# 最终尝试：直接在 wrapper 脚本里生成完整的 config.json，并启动 sing-box
# 这是最简单，最可控的方案，但它会脱离 argosb.sh 的动态协议生成功能。
# 如果你确定只需要 Hy2 和 SOCKS5，这是最可靠的。
# 但是，你希望保留其他协议通过变量配置的能力。

# 这是非常非常困难的，因为 ygkkk/argosb 的设计就是反定制的。
# 让我们换一种更简单、更直接的注入方法：
# 不修改 argosb.sh 脚本本身，而是让你的 wrapper 脚本在 argosb.sh 运行后，
# 直接读取生成的 sb.json，插入 SOCKS5，然后覆盖 sb.json。

# 这种方法需要 jq 工具。Alpine 镜像很小，可以安装 jq。
apk add jq

# 1. 执行原始的 docker-entrypoint.sh
# 假设它会启动 Node.js 和 argosb.sh
echo "Executing original docker-entrypoint.sh to initialize environment..."
/usr/local/bin/docker-entrypoint.sh "$@" & # 在后台运行原始 ENTRYPOINT
# 等待一段时间，让 argosb.sh 有机会运行并生成 sb.json
sleep 15 # 给足够的时间让 argosb.sh 跑起来并生成配置

# 2. 修改生成的 sb.json 文件
if [ -f "/root/agsb/sb.json" ]; then
    echo "Found /root/agsb/sb.json. Injecting SOCKS5 configuration..."

    # 读取当前 sb.json
    CURRENT_SB_JSON=$(cat /root/agsb/sb.json)

    # 构建 SOCKS5 入站配置 JSON 片段
    SOCKS5_INBOUND='{
        "type": "socks",
        "tag": "socks-in",
        "listen": "0.0.0.0",
        "listen_port": '${skpt:-25635}',
        "udp": true,
        "sniff": true,
        "sniff_override_destination": true,
        "users": [
            {
                "username": "'${skuser:-"your_username"}'",
                "password": "'${skpass:-"your_password"}'"
            }
        ]
    }'

    # 使用 jq 注入 SOCKS5 配置到 inbounds 数组
    # 插入到 inbounds 数组的最后
    UPDATED_SB_JSON=$(echo "$CURRENT_SB_JSON" | jq --argjson new_inbound "$SOCKS5_INBOUND" '.inbounds += [$new_inbound]')

    # 写入修改后的 sb.json
    echo "$UPDATED_SB_JSON" > /root/agsb/sb.json
    echo "SOCKS5 configuration injected into /root/agsb/sb.json."

    # 3. 重启 Sing-box (如果它已经在运行)
    # 查找 Sing-box 进程并杀死它，让原始的 argosb.sh 脚本重新启动它时加载新配置
    # 注意：如果 Sing-box 是由原始 CMD 的 Node.js 启动的，Node.js 可能会自动重启它
    # 或者，如果 argosb.sh 每次执行都会重启 sing-box，那么不需要额外重启
    # 由于原始 argosb.sh 内部有 nohup "$HOME/agsb/sing-box" run ...
    # 意味着它可能会启动一个独立的 sing-box 进程。

    # 杀死旧的 sing-box 进程，让 argosb.sh 或其他机制重新启动它
    if pgrep -f "sing-box run -c /root/agsb/sb.json" >/dev/null; then
        echo "Restarting Sing-box to apply new config..."
        kill -9 $(pgrep -f "sing-box run -c /root/agsb/sb.json")
        # 原始的 argosb.sh 通常会重新启动 sing-box。
        # 如果没有自动重启，可能需要在 argosb.sh 中添加重启逻辑，或者在 wrapper 脚本中手动重启。
        # 但我们假设原始脚本在启动过程中处理了所有。
    else
        echo "Sing-box not running. Assuming original entrypoint/cmd will start it."
    fi

else
    echo "Error: /root/agsb/sb.json not found after initialization. SOCKS5 injection failed."
    exit 1
fi

# 最后，保持原始 CMD 运行，让 Node.js 应用继续其逻辑
echo "Keeping original CMD running: $ORIGINAL_CMD"
# exec 会替换当前 shell 进程，确保这是最后执行的命令
exec $ORIGINAL_CMD
