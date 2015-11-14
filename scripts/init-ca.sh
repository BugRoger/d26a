#!/bin/bash

set -o errexit

usage() {
    echo "Usage: $0 --token TOKEN"
    echo "  -t  Hex(!) encoded authentication token"
    echo "  -o  Organizationl Unit. Used as certificate identifier"
    exit 1
}

validate() {
  while [[ $# > 1 ]]
  do
    key="$1"

    case $key in
      -t|--token)
      TOKEN="$2"
      shift
      ;;
      -o|--organizational_unit)
      OU="$2"
      shift
      ;;
      *)
      usage
      exit 1
      ;;
    esac
    shift
  done

  if [[ -z $TOKEN || -z $OU ]];
  then
    usage
    exit 1
  fi
}


prepare() {
  mkdir -p /etc/kubernetes
  cd /etc/kubernetes
}

download_binaries() {
  if [[ ! -f /opt/bin/cfssl ]];
  then
    wget -q -O /opt/bin/cfssl https://github.com/BugRoger/cfssl/releases/download/1.1.1/cfssl_linux-amd64
    /usr/bin/chmod +x /opt/bin/cfssl
  fi


  if [[ ! -f /opt/bin/cfssljson ]];
  then
    wget -q -O /opt/bin/cfssljson https://github.com/BugRoger/cfssl/releases/download/1.1.1/cfssljson_linux-amd64
    /usr/bin/chmod +x /opt/bin/cfssljson
  fi
}

init_ca() {
  cat <<-EOF |
    {
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "DE",
          "L": "Berlin",
          "O": "SAP SE",
          "OU": "Monsoon Kubernetes CA Root Certificate: $OU",
          "ST": "Berlin"
        }
      ]
    }
EOF

  /opt/bin/cfssl genkey -initca - | /opt/bin/cfssljson -bare ca
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
}

main() {
  validate "$@"
  prepare
  download_binaries
  generate_config
  init_ca
}

[[ -f /etc/kubernetes/ca.pem ]] || main "$@"
