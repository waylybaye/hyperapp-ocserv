#!/bin/sh
set -e

sed -i -e "s@^ipv4-network =.*@ipv4-network = ${VPN_NETWORK}@" \
       -e "s@^ipv4-netmask =.*@ipv4-netmask = ${VPN_NETMASK}@" /etc/ocserv/ocserv.conf
      #  -e "1s@^no-route =.*@no-route = ${LAN_NETWORK}/${LAN_NETMASK}@"

echo "${VPN_PASSWORD}" | ocpasswd -c /etc/ocserv/ocpasswd "${VPN_USERNAME}"
CLIENT="${VPN_USERNAME}@${VPN_DOMAIN}"

mkdir -p /etc/ocserv/certs
cd /etc/ocserv/certs

cat > ocserv-ca.tmpl <<_EOF_
cn = "ocserv Root CA"
organization = "ocserv"
serial = 1
expiration_days = 3650
ca
signing_key
cert_signing_key
crl_signing_key
_EOF_

cat > ocserv-server.tmpl <<_EOF_
cn = "${VPN_DOMAIN}"
dns_name = "${VPN_DOMAIN}"
organization = "ocserv"
serial = 2
expiration_days = 3650
encryption_key
signing_key
tls_www_server
_EOF_

cat > ocserv-client.tmpl <<_EOF_
cn = "${CLIENT}"
uid = "${CLIENT}"
unit = "ocserv"
expiration_days = 3650
signing_key
tls_www_client
_EOF_


if [ ! -f /etc/ocserv/certs/ocserv-ca-key.pem ]; then
  echo "[INFO] generating root CA"
  # gen ca keys
  certtool --generate-privkey \
           --outfile ocserv-ca-key.pem

  certtool --generate-self-signed \
           --load-privkey /etc/ocserv/certs/ocserv-ca-key.pem \
           --template ocserv-ca.tmpl \
           --outfile ocserv-ca-cert.pem
fi


if [ "$OC_GENERATE_KEY" != "false" ] && [ ! -f /etc/ocserv/certs/"${VPN_DOMAIN}".self-signed.crt ] ; then
  echo "[INFO] generating server certs"
  # gen server keys
  certtool --generate-privkey \
           --outfile "${VPN_DOMAIN}".self-signed.key

  certtool --generate-certificate \
           --load-privkey "${VPN_DOMAIN}".self-signed.key \
           --load-ca-certificate ocserv-ca-cert.pem \
           --load-ca-privkey ocserv-ca-key.pem \
           --template ocserv-server.tmpl \
           --outfile "${VPN_DOMAIN}".self-signed.crt
fi


if [ ! -f /etc/ocserv/certs/"${CLIENT}".p12 ]; then
  echo "[INFO] generating client certs"

  # gen client keys
  certtool --generate-privkey \
           --outfile "${CLIENT}"-key.pem

  certtool --generate-certificate \
           --load-privkey "${CLIENT}"-key.pem \
           --load-ca-certificate ocserv-ca-cert.pem \
           --load-ca-privkey ocserv-ca-key.pem \
           --template ocserv-client.tmpl \
           --outfile "${CLIENT}"-cert.pem

  certtool --to-p12 \
           --pkcs-cipher 3des-pkcs12 \
           --load-ca-certificate ocserv-ca-cert.pem \
           --load-certificate "${CLIENT}"-cert.pem \
           --load-privkey "${CLIENT}"-key.pem \
           --outfile "${CLIENT}".p12 \
           --outder \
           --p12-name "${VPN_DOMAIN}" \
           --password "${VPN_PASSWORD}"
fi

rm ocserv-ca.tmpl
rm ocserv-server.tmpl
rm ocserv-client.tmpl
