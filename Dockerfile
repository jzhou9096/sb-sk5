FROM alpine:latest

# 更换 Alpine Linux 的镜像源 (通常推荐在最前面)
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache ca-certificates

ARG SINGBOX_VERSION="1.11.13" 
ARG ARCH="amd64" 

# 核心依赖安装 - 逐个安装最基本且常见的工具
RUN apk add --no-cache bash # 提供 bash shell
RUN apk add --no-cache curl # 提供 curl 命令
RUN apk add --no-cache tar # 提供 tar 命令
RUN apk add --no-cache grep # 提供 grep 命令
RUN apk add --no-cache sed # 提供 sed 命令
RUN apk add --no-cache awk # 提供 awk 命令
RUN apk add --no-cache openssl # 提供 openssl 命令
RUN apk add --no-cache coreutils # 提供 shuf 等核心工具
RUN apk add --no-cache iproute2 # 提供 ss 命令
RUN apk add --no-cache procps # 提供 pgrep 命令
RUN apk add --no-cache iptables # 提供 iptables 命令
RUN apk add --no-cache jq # 提供 jq 命令

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
