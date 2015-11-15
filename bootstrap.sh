#!/usr/bin/env bash

set -o errexit
set -o pipefail

cd "$(dirname "$0")"

KUBERNETES_VERSION=v1.1.1

function wait_for_kubernetes_api {
    echo "Waiting for Kubernetes API..."
    until curl --silent "http://127.0.0.1:8080/version" &> /dev/null
    do
        sleep 1
    done
    echo "Cluster Online. Ready for your orders, sir!"
}

function download_kubernetes {
    mkdir -p /opt/bin

    if ! kubelet --version=true 2> /dev/null | grep -q $KUBERNETES_VERSION
    then
      echo "Downloading Kubelet ${KUBERNETES_VERSION}..."
      systemctl stop kubelet &> /dev/null || true
      wget -N -q -P /opt/bin https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubelet
      chmod +x /opt/bin/kubelet
    fi

    if ! kubectl version -c 2> /dev/null | grep -q $KUBERNETES_VERSION
    then
      echo "Downloading Kubectl ${KUBERNETES_VERSION}..."
      wget -N -q -P /opt/bin https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl
      chmod +x /opt/bin/kubectl
    fi
}

function copy_configuration {
    cp -R etc /
    systemctl daemon-reload
}

function setup_kubernetes {
    systemctl enable kubelet
    systemctl start kubelet
}

function setup_networking {
    SUBNET_ID=$(echo $COREOS_PUBLIC_IPV4 | cut -f 4 -d.)
    SUBNET=172.16.$SUBNET_ID.1/24

    #if ifconfig docker0 &> /dev/null
    #then
    #    echo "Deleting docker0 bridge"
    #    systemctl stop docker
    #    ip link set dev docker0 down
    #    brctl delbr docker0
    #    iptables -t nat -F POSTROUTING
    #fi

    local TEMPLATE=/etc/systemd/system/docker.service.d/90-d26a-network.conf
    [ -f $TEMPLATE ] || {
        echo "Writing Template: $TEMPLATE"
        mkdir -p $(dirname $TEMPLATE)
        systemctl stop docker
        cat << EOF > $TEMPLATE
[Service]
Environment="DOCKER_OPTS=--bip=$SUBNET --ip-masq=false"
EOF
        systemctl daemon-reload
      }

    systemctl start docker
}

function install_cluster_addons {
    # TODO: Use CURL to push this in. Remove kubectl from downloads
    echo "Installing cluster addons..."
    if ! kubectl get namespace kube-system &> /dev/null 
    then
      cat <<EOF | kubectl create -f - -- &> /dev/null || true
apiVersion: v1
kind: Namespace
metadata:
  name: kube-system
EOF
    fi
}

download_kubernetes
copy_configuration
setup_networking
setup_kubernetes
wait_for_kubernetes_api
install_cluster_addons

