# 1. 选择一个最小化的 Linux 基础镜像
# Alpine Linux 是极度轻量化的选择
FROM alpine:latest

# 2. 安装 argosb.sh 脚本所依赖的所有工具
# 这包括 shell 工具、网络工具、进程管理工具、OpenSSL、以及 sing-box 本身需要的 jq (用于未来可能的高级操作)
RUN apk update && apk add --no-cache \
    bash \          # argosb.sh 是 sh 脚本，但有时会使用 bash 特性，虽然 Alpine 默认 sh 通常是 ash
    curl \          # 用于下载 sing-box 和 cloudflared
    tar \           # 用于解压 sing-box
    coreutils \     # 提供 shuf 等工具
    openssl \       # 用于生成证书
    grep \          # 用于文本搜索
    awk \           # 用于文本处理
    sed \           # 用于文本编辑
    iproute2 \      # 提供 ss 命令
    procps \        # 提供 pgrep 等进程工具
    iptables \      # 用于防火墙规则 (argosb.sh 会用到)
    util-linux \    # 提供 systemctl-like 命令 (如果需要，但Alpine通常用rc-service)
    # 对于 crontab，通常 Alpine 会用 busybox 的 crond
    busybox-extras \ # 包含 crond 和 addgroup (argosb.sh 使用 addgroup)
    jq              # 用于 JSON 处理，虽然 argosb.sh 不直接用，但对调试有用

# 3. 创建 argosb.sh 所需的目录结构
# argosb.sh 默认会在 $HOME/agsb 下操作
ENV HOME="/root" # 明确设置 HOME 环境变量，因为 argosb.sh 依赖它
RUN mkdir -p $HOME/agsb

# 4. 复制你的 argosb.sh 脚本到容器内部
# 容器内部路径与 argosb.sh 默认操作路径一致
COPY argosb.sh $HOME/agsb/argosb.sh

# 5. 赋予 argosb.sh 可执行权限
RUN chmod +x $HOME/agsb/argosb.sh

# 6. (可选) 安装 Cloudflared (如果你的 argosb.sh 需要 Argo 隧道)
# argosb.sh 脚本内部会下载 cloudflared，但为了稳定性，也可以在这里提前安装
# 这部分可以根据你的 argosb.sh 版本和需求决定是否加入
# ARG CLOUDFLARED_VERSION="2024.5.1" # 检查 Cloudflare/cloudflared GitHub Releases
# RUN curl -Lo $HOME/agsb/cloudflared -# --retry 2 "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${ARCH}" \
#     && chmod +x $HOME/agsb/cloudflared

# 7. 暴露端口 (这是声明，实际映射在 docker run 时完成)
EXPOSE 25635/tcp # SOCKS5 端口
EXPOSE 25636/tcp # Hysteria2 TCP 端口
EXPOSE 25636/udp # Hysteria2 UDP 端口

# 8. 定义容器启动时默认执行的命令
# 直接执行 argosb.sh 脚本。
# 注意：argosb.sh 脚本需要环境变量来决定启用哪些协议。
# 这里我们传入 hypt=""，以确保脚本能够运行并生成配置。
# 你在 Claw.cloud Run 部署时仍需要传入所有环境变量 (-e hypt=25636 -e skpt=25635 等)
CMD ["/root/agsb/argosb.sh", "hypt="]
