#!/bin/bash
set -eu

case "$OSTYPE" in
  linux*)
    echo "Configuring for Ubuntu"

    echo ${ca_crt} | base64 -d > /etc/openvpn/ca.crt
    echo ${client_crt} | base64 -d > /etc/openvpn/client.crt
    echo ${client_key} | base64 -d > /etc/openvpn/client.key

    cat <<EOF > /etc/openvpn/client.conf
client
dev tun
proto ${proto}
remote ${host} ${port}
resolv-retry infinite
nobind
persist-key
persist-tun
comp-lzo
verb 3
ca ca.crt
cert client.crt
key client.key
EOF

    service openvpn start client > /dev/null 2>&1
    sleep 5

    if ifconfig | grep tun0 > /dev/null
    then
      echo "VPN connection succeeded"
    else
      echo "VPN connection failed!"
      exit 1
    fi
    ;;
  darwin*)
    echo "Configuring for Mac OS"
    echo `pwd`
    echo ${ca_crt} | base64 -D -o ca.crt > /dev/null 2>&1
    echo ${client_crt} | base64 -D -o client.crt > /dev/null 2>&1
    echo ${client_key} | base64 -D -o client.key > /dev/null 2>&1
    echo ${user_pass} | base64 -D -o user-pass > /dev/null 2>&1
    echo ${tls_auth} | base64 -D -o tls-auth.key > /dev/null 2>&1

    sudo openvpn --client --dev tun --proto ${proto} --remote ${host} ${port} --resolv-retry infinite --nobind --persist-key --persist-tun --ca ca.crt --cert client.crt --key client.key --ns-cert-type server --comp-lzo --verb 3 --auth-user-pass user-pass --tls-auth tls-auth.key 1 > /dev/null 2>&1 &

    sleep 5

    if ifconfig -l | grep utun0 > /dev/null
    then
      echo "VPN connection succeeded"
    else
      echo "VPN connection failed!"
      exit 1
    fi
    ;;
  *)
    echo "Unknown operative system: $OSTYPE, exiting"
    exit 1
    ;;
esac
