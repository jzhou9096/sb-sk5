FROM alpine:latest

# 安装 argosb.sh 所需的基本工具和 Sing-box 依赖
RUN apk update && apk add --no-cache \
    bash \
    curl \
    tar \
    coreutils \
    openssl \
    grep \
    awk \
    sed \
    iproute2 \
    procps \
    iptables \
    util-linux \
    busybox-extras \
    jq

# 明确设置 HOME 环境变量
ENV HOME="/root" 

# 创建 argosb.sh 所需的目录
RUN mkdir -p "$HOME/agsb"

# 预下载 Sing-box 可执行文件（这是 argosb.sh 脚本的依赖）
# 使用 argosb.sh 内部使用的同一版本和下载链接，确保兼容性
ARG SINGBOX_VERSION="1.11.13" # 检查 argosb.sh 脚本中使用的 Sing-box 版本
ARG ARCH="amd64" # 你的CPU架构

RUN curl -Lo "$HOME/agsb/sing-box" -# --retry 2 "https://github.com/yonggekkk/ArgoSB/releases/download/singbox/sing-box-${ARCH}" \
    && chmod +x "$HOME/agsb/sing-box"

# 复制你修改后的 argosb.sh 脚本
COPY argosb.sh "$HOME/agsb/argosb.sh"

# 赋予 argosb.sh 可执行权限
RUN chmod +x "$HOME/agsb/argosb.sh"

# 暴露端口
EXPOSE 25635/tcp
EXPOSE 25636/tcp
EXPOSE 25636/udp

# 定义容器启动命令：直接执行 argosb.sh
# 传入一个默认协议变量，确保 argosb.sh 能够运行并生成配置
CMD ["/root/agsb/argosb.sh", "hypt="]
