# 基于 ygkkk/argosb 镜像
FROM ygkkk/argosb

# 安装 jq (用于在运行时修改 JSON)
RUN apk add --no-cache jq

# 复制你的定制 docker-entrypoint-wrapper.sh 脚本
COPY docker-entrypoint-wrapper.sh /usr/local/bin/docker-entrypoint-wrapper.sh

# 确保它有执行权限
RUN chmod +x /usr/local/bin/docker-entrypoint-wrapper.sh

# 暴露端口 (声明，实际映射在部署时完成)
EXPOSE 1080
EXPOSE 25635/tcp
EXPOSE 25636/tcp
EXPOSE 25636/udp

# 将你的定制脚本设置为 ENTRYPOINT
# 这样容器启动时，只会运行这个脚本，它会负责注入并启动原始服务
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-wrapper.sh"]

# 保持原始镜像的 CMD，它会作为参数传递给 ENTRYPOINT，并在最后被 ENTRYPOINT 执行
CMD ["node", "index.js"] # 根据你提供的信息，原始CMD是 node index.js
