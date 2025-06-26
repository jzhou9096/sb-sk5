FROM alpine:latest

ARG SINGBOX_VERSION="1.11.13" 
ARG ARCH="amd64" 

# 第一次安装：核心工具
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
    busybox-extras \
    jq

# 第二次安装：iptables (可能需要单独安装或在不同阶段)
RUN apk add --no-cache iptables

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
