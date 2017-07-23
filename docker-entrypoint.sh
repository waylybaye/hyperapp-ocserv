#!/bin/sh
set -e
CONFIG_FILE=/etc/ocserv/ocserv.conf

function changeConfig {
  local prop=$1
  local var=$2
  if [ -n "$var" ]; then
    echo "[INFO] Setting $prop to $var"
    sed -i "/$prop\s*=/ c $prop=$var" $CONFIG_FILE
  fi
}

function commentConfig {
  local prop=$1
  echo "[INFO] disable $prop"
  sed -i "s/\($prop\s*=.*\)/#\1/" $CONFIG_FILE
}

function uncommentConfig {
  local prop=$1
  echo "[INFO] enable $prop"
  sed -i "s/#\($prop\s*=.*\)/\1/" $CONFIG_FILE
}

if [ -z $VPN_DOMAIN ]; then
  echo "[ERROR]: VPN_DOMAIN is required."
  exit 1
fi

if [ "$OC_GENERATE_KEY" = "false" ]; then
  changeConfig "server-key" "/etc/ocserv/certs/${VPN_DOMAIN}.key"
  changeConfig "server-cert" "/etc/ocserv/certs/${VPN_DOMAIN}.crt"
else
  changeConfig "server-key" "/etc/ocserv/certs/${VPN_DOMAIN}.self-signed.key"
  changeConfig "server-cert" "/etc/ocserv/certs/${VPN_DOMAIN}.self-signed.crt"
fi


#if [ "$OC_DISABLE_PLAIN" = "true" ]; then
#  commentConfig "enable-auth"
#else
#  uncommentConfig "enable-auth"
#fi

/init.sh

if [ ! -e /dev/net/tun ]; then
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

changeConfig "tcp-port" "$VPN_PORT"
changeConfig "udp-port" "$VPN_PORT"
changeConfig "max-clients" "$OC_MAX_CLIENTS"
changeConfig "max-same-clients" "$OC_MAX_SAME_CLIENTS"

iptables -t nat -A POSTROUTING -s ${VPN_NETWORK}/${VPN_NETMASK} -j MASQUERADE

if [ -z ${OC_CN_NO_ROUTE+x} ]; then
  cat /etc/ocserv/cn-no-route.txt >> $CONFIG_FILE
fi

exec ocserv -c /etc/ocserv/ocserv.conf -f -d 1 "$@"
