# 基于 ygkkk/argosb 镜像
FROM ygkkk/argosb

# 将你修改过的 argosb.sh 脚本复制到容器内部的正确位置
# 这会覆盖 ygkkk/argosb 镜像中原有的 argosb.sh
COPY argosb.sh /root/agsb/argosb.sh

# 确保脚本有执行权限 (通常默认就有，但以防万一)
RUN chmod +x /root/agsb/argosb.sh

# 暴露 SOCKS5 端口 (1080) 和 Hysteria2 端口 (25636)
# 这是一个声明，表示这些是通常会监听的端口
EXPOSE 1080
EXPOSE 25636/tcp
EXPOSE 25636/udp
