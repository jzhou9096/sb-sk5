FROM alpine:latest

# 更换 Alpine Linux 的镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache ca-certificates

ARG SINGBOX_VERSION="1.11.13" 
ARG ARCH="amd64" 

# 核心依赖安装 - 专注于非busybox核心的工具
RUN apk add --no-cache bash # 提供 bash shell (busybox提供ash，argosb.sh可能需要bash)
RUN apk add --no-cache curl # 提供 curl 命令
RUN apk add --no-cache tar # 提供 tar 命令
RUN apk add --no-cache grep # 提供 grep 命令 (grep 也是一个独立包，busybox提供简易版本)
RUN apk add --no-cache sed # 提供 sed 命令 (sed 也是一个独立包，busybox提供简易版本)
RUN apk add --no-cache openssl # 提供 openssl 命令
RUN apk add --no-cache coreutils # 提供 shuf 等核心工具
RUN apk add --no-cache iproute2 # 提供 ss 命令 (包括 ip 命令)
RUN apk add --no-cache procps # 提供 pgrep 命令 (包括 ps, top)
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

# ==== 关键修改：在 Dockerfile 内部设置默认协议变量 ====
# ENV 指令在构建时设置环境变量，这些变量在容器运行时是可用的。
# 如果用户通过 docker run -e 传递了同名变量，则用户传递的变量会覆盖这里设置的。
# 这样确保了至少有一个协议是激活的，避免脚本退出。
ENV hypt="25636" 
ENV skpt="25635"
ENV skuser="hulu"
ENV skpass="mfxj12356"
ENV uuid="fb4115d9-a738-4b9a-9984-8cf2fc363fdd"

CMD ["/root/agsb/argosb.sh"] # CMD 不再需要传入 hypt= 参数，因为它已经是 ENV 了
