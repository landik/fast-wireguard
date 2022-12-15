#!/bin/bash

WIREGUARD_IP=0.0.0.0
ETH_INTERFACE=ens3

WIREGUARD_PORT=443
WIREGUARD_CONFIG=wg0.conf
WIREGUARD_PATH=/etc/wireguard

add-apt-repository ppa:wireguard/wireguard
apt update
apt install -y wireguard stubby qrencode zip

echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.proxy_arp = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
sysctl -p

private_server=$(wg genkey)
public_server=$(echo $private_server | wg pubkey)
echo $public_server > public.key
echo "SERVER public key $public_server" >> keys
echo "SERVER port $WIREGUARD_PORT" >> keys

echo "[Interface]" > $WIREGUARD_PATH/$WIREGUARD_CONFIG
echo "Address = 10.8.0.1/24" >> $WIREGUARD_PATH/$WIREGUARD_CONFIG
echo "ListenPort = $WIREGUARD_PORT" >> $WIREGUARD_PATH/$WIREGUARD_CONFIG
echo "PrivateKey = $private_server" >> $WIREGUARD_PATH/$WIREGUARD_CONFIG
echo "PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $ETH_INTERFACE -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT;" >> $WIREGUARD_PATH/$WIREGUARD_CONFIG
echo "PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $ETH_INTERFACE -j MASQUERADE; ip6tables -D FORWARD -i wg0 -j ACCEPT;" >> $WIREGUARD_PATH/$WIREGUARD_CONFIG

num=115
while [ $num -gt 100 ]; do
    ip=10.8.0.$num/32
    private=$(wg genkey)
    public=$(echo $private | wg pubkey)
    echo "$ip --- $private" >> keys
    echo "[peer]" >> $WIREGUARD_PATH/$WIREGUARD_CONFIG
    echo "#autogen" >> $WIREGUARD_PATH/$WIREGUARD_CONFIG
    echo "PublicKey = $public" >> $WIREGUARD_PATH/$WIREGUARD_CONFIG
    echo "AllowedIPs = $ip" >> $WIREGUARD_PATH/$WIREGUARD_CONFIG

    echo "[Interface]" >> client$num.conf
    echo "PrivateKey = $private" >> client$num.conf
    echo "Address = $ip" >> client$num.conf
    echo "DNS = 10.8.0.1" >> client$num.conf
    echo "" >> client$num.conf
    echo "[Peer]" >> client$num.conf
    echo "PublicKey = $public_server" >> client$num.conf
    echo "Endpoint = $WIREGUARD_IP:$WIREGUARD_PORT" >> client$num.conf
    echo "AllowedIPs = 0.0.0.0/0" >> client$num.conf
    echo "PersistentKeepalive = 20" >> client$num.conf
    qrencode -t ansiutf8 < client$num.conf > client$num-qr.txt
    num=$[ $num - 1 ]
done

zip -r -9 configs.zip client*

ufw allow $WIREGUARD_PORT/udp
systemctl enable --now wg-quick@wg0

nslookup google.com

ufw allow from 10.8.0.1/24 to any port 53

mv stubby.yml /etc/stubby/stubby.yml
systemctl disable systemd-resolved
systemctl stop systemd-resolved

echo "nameserver 127.0.0.1" > /etc/resolv.conf
echo "options edns0 trust-ad" >> /etc/resolv.conf

systemctl enable stubby
systemctl restart stubby

nslookup google.com

