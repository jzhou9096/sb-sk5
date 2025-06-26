FROM alpine:latest

# 更换 Alpine Linux 的镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache ca-certificates

ARG SINGBOX_VERSION="1.11.13" 
ARG ARCH="amd64" 

# 核心依赖安装
RUN apk add --no-cache bash \
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

ENV hypt="25636" 
ENV skpt="25635"
ENV skuser="hulu"
ENV skpass="mfxj12356"
ENV uuid="fb4115d9-a738-4b9a-9984-8cf2fc363fdd"

# ==== 关键修改：修正 CMD 指令的 JSON 数组语法 ====
# 正确的格式是 ["命令", "参数1", "参数2"]
# 如果要用 sh 来执行脚本，可以是 ["sh", "-c", "/root/agsb/argosb.sh"]
# 或者直接提供脚本路径，让 Docker 使用默认 shell 来执行
CMD ["/root/agsb/argosb.sh"]
