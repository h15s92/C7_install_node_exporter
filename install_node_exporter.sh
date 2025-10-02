#!/bin/bash
set -e

NODE_EXPORTER_VERSION="1.2.2"
NODE_EXPORTER_USER="nodeusr"
BIN_PATH="/usr/local/bin/node_exporter"
SERVICE_PATH="/etc/systemd/system/node_exporter.service"

echo "🚀 Installing Node Exporter v$NODE_EXPORTER_VERSION"

# 1. Скачиваем и распаковываем
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

# 2. Создаём пользователя без shell
if ! id -u "$NODE_EXPORTER_USER" >/dev/null 2>&1; then
    useradd -rs /bin/false $NODE_EXPORTER_USER
    echo "✅ User $NODE_EXPORTER_USER created"
else
    echo "ℹ️ User $NODE_EXPORTER_USER already exists"
fi

# 3. Перенос бинарника
mv -f node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter $BIN_PATH
chown $NODE_EXPORTER_USER:$NODE_EXPORTER_USER $BIN_PATH

# 4. Создаём systemd unit
cat <<EOF > $SERVICE_PATH
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=$NODE_EXPORTER_USER
Group=$NODE_EXPORTER_USER
Type=simple
ExecStart=$BIN_PATH

[Install]
WantedBy=multi-user.target
EOF

# 5. Релоадим systemd и запускаем
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

echo "✅ Node Exporter installed and started"
echo "📡 Check metrics: http://$(hostname -I | awk '{print $1}'):9100/metrics"
