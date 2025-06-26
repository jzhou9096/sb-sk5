FROM alpine:latest

ARG SINGBOX_VERSION="1.11.13" 
ARG ARCH="amd64" 

# 确保 apk update 能稳定执行，并安装常见的依赖
# busybox 提供了大部分核心命令，full/build-base 提供了编译工具和常用系统工具
RUN apk update && apk add --no-cache \
    busybox-extras \
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
    jq \
    ca-certificates

ENV HOME="/root" 
RUN mkdir -p "$HOME/agsb"

RUN curl -Lo "$HOME/agsb/sing-box" -# --retry 2 "https://github.com/yonggekkk/ArgoSB/releases/download/singbox/sing-box-${ARCH}" \
    && chmod +x "$HOME/agsb/sing-box"

COPY argosb.sh "$HOME/agsb/argosb.sh"
RUN chmod +x "$HOME/agsb/argosb.sh"

EXPOSE 25635/tcp
EXPOSE 25636/tcp
EXPOSE 25636/udp

CMD ["/root/agsb/argosb.sh", "hypt="]
