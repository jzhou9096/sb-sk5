# 从轻量级的 Alpine Linux 基础镜像开始
FROM alpine:latest

# 设置参数，方便管理 Sing-box 版本和架构
ARG SINGBOX_VERSION="1.11.13" 
ARG ARCH="amd64" 

# 安装 curl 和 tar，用于下载和解压 Sing-box
RUN apk add --no-cache curl tar

# 下载并安装 Sing-box
WORKDIR /usr/local/bin
RUN curl -LO "https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-${ARCH}.tar.gz" \
    && tar -xzf "sing-box-${SINGBOX_VERSION}-linux-${ARCH}.tar.gz" \
    && rm "sing-box-${SINGBOX_VERSION}-linux-${ARCH}.tar.gz" \
    && mv sing-box-*/sing-box . \
    && chmod +x sing-box

# 创建 Sing-box 配置和证书的目录
RUN mkdir -p /etc/sing-box

# 复制你的 sb.json 配置文件到容器内
COPY sb.json /etc/sing-box/config.json 

# 复制你的证书文件到容器内
COPY cert.pem /etc/sing-box/cert.pem
COPY private.key /etc/sing-box/private.key

# 暴露端口
EXPOSE 25635/tcp
EXPOSE 25636/tcp
EXPOSE 25636/udp

# 定义容器启动时运行的命令
CMD ["/usr/local/bin/sing-box", "run", "-c", "/etc/sing-box/config.json"]
