FROM alpine:latest

# 更换 Alpine Linux 的镜像源为清华大学开源软件镜像站 (tuna.moe)
# 这通常能提供更稳定的下载，避免 apk add 失败
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache ca-certificates

ARG SINGBOX_VERSION="1.11.13" 
ARG ARCH="amd64" 

# 核心依赖安装 - 保持精简
RUN apk add --no-cache \
    bash \
    curl \
    tar \
    grep \
    sed \
    awk \
    openssl \
    coreutils \
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
