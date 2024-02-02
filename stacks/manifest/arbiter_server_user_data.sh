#!/bin/bash
yum -y install epel-release && \
    yum update -y && \
    yum install -y docker \
                   wget \
                   openssl-devel \
                   libffi-devel \
                   bzip2-devel

# start docker service
service docker start

yum groupinstall "Development Tools" -y && \
    wget https://www.python.org/ftp/python/3.9.13/Python-3.9.13.tgz && \
    tar xvf Python-3.9.13.tgz && \
    cd Python-3.9*/ && \
    ./configure --enable-optimizations && \
    make altinstall

cp /usr/local/bin/python3.9 /usr/bin/
cp /usr/local/bin/pip3.9 /usr/bin/

pip3.9 install flwr

cat > /server.py <<EOF
import flwr as fl

if __name__ == "__main__":
    fl.server.start_server(server_address="0.0.0.0:8080", config=fl.server.ServerConfig(num_rounds=3))
EOF


nohup python3.9 /server.py > /output.log &