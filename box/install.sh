#!/bin/sh
set -eu

apk add --no-cache jq openssh nftables iproute2 socat doas xxd file nano less bind-tools tcpdump nmap curl
adduser -D -s /bin/sh learner
passwd -d learner >/dev/null
mkdir -p /etc/doas.d /var/lib/lab
echo "permit nopass learner as root cmd /usr/local/sbin/lab-root" >/etc/doas.d/lab.conf
chown learner:learner /var/lib/lab
install -D -m 755 lab /usr/local/bin/lab
install -D -m 755 lab-root /usr/local/sbin/lab-root
install -D -m 644 lib.sh /opt/lab/lib.sh
install -D -m 644 motd /etc/motd
