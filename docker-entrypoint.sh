#!/bin/sh
set -e
CONFIG_FILE=/etc/ocserv/ocserv.conf

/init.sh

if [ ! -e /dev/net/tun ]; then
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

function changeConfig {
  local prop=$1
  local var=$2
  if [ -n "$var" ]; then
    echo "Setting $prop to $var"
    sed -i "/$prop\s*=/ c $prop=$var" /data/server.properties
  fi
}

changeConfig "tcp-port" "$VPN_PORT"
changeConfig "udp-port" "$VPN_PORT"
changeConfig "max-clients" "$OC_MAX_CLIENTS"
changeConfig "max-same-clients" "$OC_MAX_SAME_CLIENTS"

iptables -t nat -A POSTROUTING -s ${VPN_NETWORK}/${VPN_NETMASK} -j MASQUERADE
sed -i -e '/# EOF/,+500d' $CONFIG_FILE

if [ -z ${OC_CN_NO_ROUTE+x} ]; then
  cat /etc/ocserv/cn-no-route.txt >> $CONFIG_FILE
fi

exec ocserv -c /etc/ocserv/ocserv.conf -f -d 1 "$@"
