#!/bin/bash
if [ $# -lt 1 ] ; then
	USERNAME=oracle
	echo -e  "\n"
	echo "###################################################"
	echo "USAGE: $0  USERNAME"
	echo "if you not set, default username/password is oracle"
	echo "如果你不加任何参数的话，默认的用户名和密码就是 oracle"
	echo "###################################################"
	echo -e  "\n"
fi
if [ $# = 1 ] ; then
	USERNAME=${1}
fi

docker rm -f ciscoanyconnect > /dev/null 2>&1
cat > /root/ocserv.env <<_EOF_
VPN_DOMAIN=oracle.heibang.club
VPN_USERNAME=${USERNAME}
VPN_PASSWORD=${USERNAME}
OC_CERT_AND_PLAIN=false
OC_GENERATE_KEY=false
_EOF_

docker run -d --restart=always -p 443:443/tcp -p 443:443/udp --env-file /root/ocserv.env -v /srv/docker/certs:/etc/ocserv/certs/ --cap-add=NET_ADMIN  --name ciscoanyconnect bao3/ssl-only-ocserv
docker logs ciscoanyconnect
rm -rf /root/ocserv.env

	echo "###################################################"
	echo "you could use some command to see who connecnt to your server"
	echo "docker exec -it ciscoanyconnect occtl --help"
	echo "###################################################"
	echo " Goold Luck ,guy"
