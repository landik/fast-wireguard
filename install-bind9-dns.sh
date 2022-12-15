#!/bin/bash

apt install -y bind9
mv named.conf.options /etc/bind/named.conf.options
ufw allow from 10.8.0.1/24 to any port 53
systemctl disable systemd-resolved
systemctl stop systemd-resolved
echo "nameserver 127.0.0.1" > /etc/resolv.conf
echo "options edns0 trust-ad" >> /etc/resolv.conf
systemctl enable bind9
systemctl restart bind9
