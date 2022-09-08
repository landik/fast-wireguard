#!/bin/sh


ufw allow OpenSSH
ufw enable

add-apt-repository ppa:wireguard/wireguard
apt update
apt install -y wireguard bind9

echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.proxy_arp = 0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
sysctl -p


WIREGUARD_CONFIG=wg0.conf
WIREGUARD_PATH=/etc/wireguard
WIREGUARD_PORT=51667
ETH_INTERFACE=enp0s8

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

for num in 10 11 12 13 14 15 16 17 18 19 20
do
ip=10.8.0.$num/32
private=$(wg genkey)
public=$(echo $private | wg pubkey)
echo "$ip --- $private" >> keys
echo "[peer]" >> $WIREGUARD_PATH/$WIREGUARD_CONFIG
echo "#autogen" >> $WIREGUARD_PATH/$WIREGUARD_CONFIG
echo "PublicKey = $public" >> $WIREGUARD_PATH/$WIREGUARD_CONFIG
echo "AllowedIPs = $ip" >> $WIREGUARD_PATH/$WIREGUARD_CONFIG
done


ufw allow $WIREGUARD_PORT/udp
systemctl enable --now wg-quick@wg0

nslookup google.com 127.0.0.1

ufw allow from 10.8.0.1/24 to any app Bind9

mv named.conf.options /etc/bind/named.conf.options

systemctl enable bind9
systemctl restart bind9

nslookup google.com 127.0.0.1

#useradd -m admin
##Устанавливаем пароль для юзера
#passwd admin
##Добавляем в группу системных администраторов
#usermod -aG sudo admin #Debian/Ubuntu
#
##1 Изменение оболочки
#sudo vipw
##изменяем строку
##root:x:0:0:root:/root:/bin/bash
##на
##root:x:0:0:root:/root:/sbin/nologin
#
##2 запрет входа ssh
#echo "PermitRootLogin no" >> /etc/ssh/sshd_config
#echo "AllowUsers admin" >> /etc/ssh/sshd_config
#systemctl restart ssh

