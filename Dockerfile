FROM alpine:latest

ARG SINGBOX_VERSION="1.11.13" 
ARG ARCH="amd64" 

# 核心安装：只安装最常用的工具
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
    jq

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
