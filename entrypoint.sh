#!/bin/bash

set -e

cat > /etc/hysteria/config.yaml <<EOF
listen: :${UDP_PORT}

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: ${PASSWORD}

masquerade:
  type: proxy
  proxy:
    url: https://bing.com/
    rewriteHost: true
EOF

/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml &
sleep 1

SERVER_IP=$(curl -s https://api.ipify.org)
COUNTRY_CODE=$(curl -s https://ipapi.co/${SERVER_IP}/country/ || echo "XX")

echo
echo "------------------------------------------------------------------------"
echo "✅ Hysteria2 启动成功"
echo "监听端口（UDP）：${UDP_PORT}"
echo "密码：${PASSWORD}"
echo "------------------------------------------------------------------------"
echo "🎯 客户端连接配置（请将端口替换为爪云分配的外网 UDP 端口）："
echo "hy2://${PASSWORD}@${SERVER_DOMAIN}:${UDP_PORT}?sni=bing.com&insecure=1#claw.cloud-hy2-${COUNTRY_CODE}"
echo "------------------------------------------------------------------------"

wait
