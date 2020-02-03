# Recipe:: install_test_kafka_broker.rb
#<
# description: This recipe was tested on centos 7 only (may work on centos 6 may not)

yum_package 'java-1.8.0-openjdk' do
end

#create kafka User
user 'kafka' do
  comment 'use to run zookeeper and kafka'
  shell '/bin/bash'
end

#downlowad and extract kafka
bash 'extract_kafka' do
  code <<-EOH
    mkdir -p /opt/kafka && cd /opt/kafka
    curl "https://www.apache.org/dist/kafka/2.1.1/kafka_2.11-2.1.1.tgz" -o kafka.tgz
    tar -xvf kafka.tgz --strip 1
    echo "" >> /opt/kafka/config/server.properties
    echo "delete.topic.enable = true" >> /opt/kafka/config/server.properties
    chown -Rc kafka:root /opt/kafka
  EOH
  not_if { ::File.exist?('/opt/kafka/bin') }
end

#create systemd file for zookeeper
systemd_unit 'zookeeper.service' do
  content({ Unit:
             {
               Description: 'starts zookeeper',
               Requires: 'network.target remote-fs.target',
               After: 'network.target remote-fs.target',
             },
            Service:
              {
                Type: 'simple',
                User: 'kafka',
                ExecStart: '/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties',
                ExecStop: '/opt/kafka/bin/zookeeper-server-stop.sh',
                Restart: 'on-abnormal',
              },
            Install:
              {
                WantedBy: 'multi-user.target',
              } })
  action [:create, :enable]
end

#create systemd file for kafka
systemd_unit 'kafka.service' do
  content({ Unit:
              {
                Description: 'starts kafka',
                Requires: 'zookeeper.service',
                After: 'zookeeper.service'
              },
            Service:
              {
                Type: 'simple',
                User: 'kafka',
                ExecStart: '/bin/sh -c "/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties"',
                ExecStop: '/opt/kafka/bin/kafka-server-stop.sh',
                Restart: 'on-abnormal'
              },
            Install: { WantedBy: 'multi-user.target', }
        })
  action [:create, :enable]
end

service 'zookeeper' do
  action :start
end

service 'kafka' do
  action :start
end
