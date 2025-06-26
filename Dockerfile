# 基于 ygkkk/argosb 镜像
FROM ygkkk/argosb

# 复制你的定制 docker-entrypoint.sh 脚本
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# 确保它有执行权限
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 暴露端口 (声明，实际映射在部署时完成)
EXPOSE 1080
EXPOSE 25636/tcp
EXPOSE 25636/udp

# 将你的定制脚本设置为 ENTRYPOINT
# 这样容器启动时，只会运行这个脚本，它会负责修改并执行 argosb.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# CMD 可以提供默认参数，如 "hypt="，但由于 docker-entrypoint.sh 会处理，这里可以留空
CMD []
