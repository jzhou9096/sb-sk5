# 1. 选择一个最小化的 Linux 基础镜像
# Alpine Linux 是极度轻量化的选择
FROM alpine:latest

# 2. 安装 argosb.sh 脚本所依赖的所有工具
# 这包括 shell 工具、网络工具、进程管理工具、OpenSSL、以及 sing-box 本身需要的 jq (用于未来可能的高级操作)
WORKDIR /usr/local/bin
# 确保所有 Linux 命令都以 RUN 开头
RUN curl -LO "https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-${ARCH}.tar.gz" \
    && tar -xzf "sing-box-${SINGBOX_VERSION}-linux-${ARCH}.tar.gz" \
    && rm "sing-box-${SINGBOX_VERSION}-linux-${ARCH}.tar.gz" \
    && mv sing-box-*/sing-box . \
    && chmod +x sing-box

# 3. 创建 argosb.sh 所需的目录结构
# argosb.sh 默认会在 $HOME/agsb 下操作
ENV HOME="/root" 
RUN mkdir -p $HOME/agsb


COPY argosb.sh $HOME/agsb/argosb.sh


RUN chmod +x $HOME/agsb/argosb.sh

EXPOSE 25635/tcp # SOCKS5 端口
EXPOSE 25636/tcp # Hysteria2 TCP 端口
EXPOSE 25636/udp # Hysteria2 UDP 端口

CMD ["/root/agsb/argosb.sh", "hypt="]
