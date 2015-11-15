#!/bin/bash

set -o errexit

usage() {
    echo "Usage: $0 --remote CFSSL_HOST --token TOKEN [--san SAN]*"
    echo "  -r  Generate certificate remotely using this host"
    echo "  -t  Hex(!) encoded authentication token"
    echo "  -c  Common Name. Used for identification."
    exit 1
}

validate() {
  BIN_DIR=${BIN_DIR:-/opt/bin}
  CERT_DIR=${CERT_DIR:-/etc/kubernetes/ssl}
  SANS=$(hostname -f)

  while [[ $# > 1 ]]
  do
    key="$1"

    case $key in
      -s|--san)
      SANS=("${SANS[@]}" "$2")
      shift
      ;;
      -r|--remote)
      CFSSL_HOST="$2"
      shift
      ;;
      -t|--token)
      TOKEN="$2"
      shift
      ;;
      -c|--cn)
      CN="$2"
      shift
      ;;
      *)
      usage
      exit 1
      ;;
    esac
    shift
  done

  if [[ -z $CFSSL_HOST || -z $TOKEN || -z $CN ]];
  then
    usage
    exit 1
  fi
}

prepare() {
  mkdir -p $CERT_DIR
  cd $CERT_DIR
}

download_binaries() {
  if [[ ! -f $BIN_DIR/cfssl ]];
  then
    wget -q -O $BIN_DIR/cfssl https://github.com/BugRoger/cfssl/releases/download/1.1.1/cfssl_linux-amd64
    chmod +x $BIN_DIR/cfssl
  fi


  if [[ ! -f $BIN_DIR/cfssljson ]];
  then
    wget -q -O $BIN_DIR/cfssljson https://github.com/BugRoger/cfssl/releases/download/1.1.1/cfssljson_linux-amd64
    chmod +x $BIN_DIR/cfssljson
  fi
}

generate_config() {
  (cat <<-CONFIG
    {
      "signing": {
        "profiles": {
          "client": {
            "usages": ["client auth", "digital signature"],
            "expiry": "35040h",
            "auth_key": "ca-auth"
          },
          "server": {
            "usages": ["server auth", "key encipherment", "digital signature"],
            "expiry": "35040h",
            "auth_key": "ca-auth"
          }
        }
      },
      "auth_keys": {
        "ca-auth": {
           "type":"standard",
           "key":"$TOKEN"
        }
      }
    }
CONFIG
  ) > cfssl.json 

  JSANS=""; for S in "${SANS[@]}"; do JSANS=$(printf '%s"%s"' "$JSANS", "$S"); done
  JSANS=${JSANS#,}

  (cat <<-SERVER_CSR
    {
      "hosts": [ 
        $JSANS
      ],
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "CN": "Monsoon Kubernetes Server Certificate: $CN",
      "names": [
        {
          "C": "DE",
          "L": "Berlin",
          "O": "D26A",
          "OU": "Kubernetes Operations",
          "ST": "Berlin"
        }
      ]
    }
SERVER_CSR
  ) > server.csr.json

  (cat <<-CLIENT_CSR
    {
      "hosts": [ 
        $JSANS
      ],
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "CN": "Kubernetes Client Certificate: $CN",
      "names": [
        {
          "C": "DE",
          "L": "Berlin",
          "O": "D26A",
          "OU": "Kubernetes Operations",
          "ST": "Berlin"
        }
      ]
    }
CLIENT_CSR
  ) > client.csr.json
}

fetch_certificates() {
  if [[ ! -f ca.pem ]]; 
  then
    $BIN_DIR/cfssl info -remote $CFSSL_HOST | $BIN_DIR/cfssljson -bare ca
  fi

  if [[ ! -f client.pem ]];
  then
    $BIN_DIR/cfssl gencert -remote $CFSSL_HOST \
                           -profile client \
                           --config cfssl.json \
                           client.csr.json | $BIN_DIR/cfssljson -bare client
  fi

  if [[ ! -f server.pem ]];
  then
    $BIN_DIR/cfssl gencert -remote $CFSSL_HOST \
                           -profile server \
                           --config cfssl.json \
                           server.csr.json | $BIN_DIR/cfssljson -bare server
  fi
}

fix_permissions() {
  if [[ -f /usr/sbin/groupadd ]];
  then
    /usr/sbin/groupadd -r -f kube-cert
    chgrp kube-cert $CERT_DIR/*.pem
    chmod 660 $CERT_DIR/*.pem
  fi
}

main() {
  validate "$@"
  prepare
  download_binaries
  generate_config
  fetch_certificates
  fix_permissions
}

main "$@"
