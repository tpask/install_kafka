#!/usr/bin/env bash
# This script installs kafka for testing. 
# Since Kafka runs as root it is not recommended to be used in production as is.
# You can create kafka user and configure kafka to be run as kafka user to be safe.

yum -y install java-1.8.0-openjdk
mkdir -p /opt/kafka && cd /opt/kafka
curl "https://www.apache.org/dist/kafka/2.1.1/kafka_2.11-2.1.1.tgz" -o kafka.tgz
tar -xvf kafka.tgz --strip 1
echo "" >> /opt/kafka/config/server.properties
echo "delete.topic.enable = true" >> /opt/kafka/config/server.properties

cat <<EOF > /etc/systemd/system/zookeeper.service
[Unit]
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
User=root
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF1 > /etc/systemd/system/kafka.service
[Unit]
Requires=zookeeper.service
After=zookeeper.service

[Service]
Type=simple
User=root
ExecStart=/bin/sh -c '/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties'
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF1

chmod 755 /etc/systemd/system/kafka.service
chmod 755 /etc/systemd/system/zookeeper.service

systemctl enable kafka.service
systemctl enable zookeeper.service
