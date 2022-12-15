#!/bin/bash

ufw allow from 10.8.0.1/24 to any port 53
mv stubby.yml /etc/stubby/stubby.yml
systemctl disable systemd-resolved
systemctl stop systemd-resolved
echo "nameserver 127.0.0.1" > /etc/resolv.conf
echo "options edns0 trust-ad" >> /etc/resolv.conf
systemctl enable stubby
systemctl restart stubby
nslookup google.com