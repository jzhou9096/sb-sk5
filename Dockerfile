# 基于 ygkkk/argosb 镜像
FROM ygkkk/argosb

# 复制你的定制 docker-entrypoint.sh 脚本


# 确保它有执行权限
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 暴露端口 (声明，实际映射在部署时完成)
EXPOSE 1080
EXPOSE 25636/tcp
EXPOSE 25636/udp

# 将你的定制脚本设置为 ENTRYPOINT
# 这样容器启动时，只会运行这个脚本，它会负责修改并执行 argosb.sh
