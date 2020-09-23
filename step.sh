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
sndbuf 0
rcvbuf 0
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher AES-256-CBC
;setenv opt block-outside-dns
key-direction 1
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
    
    echo ${ca_crt} | base64 -D -o ca.crt > /dev/null 2>&1
    echo ${client_crt} | base64 -D -o client.crt > /dev/null 2>&1
    echo ${client_key} | base64 -D -o client.key > /dev/null 2>&1
    echo ${tls_auth} | base64 -D -o tls-auth.key > /dev/null 2>&1

    cat <<EOF > client.conf
client
dev tun
proto ${proto}
remote ${host} ${port}
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
comp-lzo
verb 3
auth SHA512
remote-cert-tls server
pull-filter ignore "redirect-gateway"
tls-auth tls-auth.key 1
${openvpn_options}
EOF

    sudo openvpn --config client.conf > /dev/null 2>&1 &
    #sudo openvpn --client --dev tun --proto ${proto} --remote ${host} ${port} --resolv-retry infinite --nobind --persist-key --persist-tun --ca ca.crt --cert client.crt --key client.key --ns-cert-type server --comp-lzo --verb 3 --auth SHA512 --remote-cert-tls server --pull-filter ignore "redirect-gateway" --tls-auth tls-auth.key 1 > /dev/null 2>&1 &

    sleep 5

    if ifconfig -l | grep utun1 > /dev/null
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
