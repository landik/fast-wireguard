#!/bin/bash

ufw allow OpenSSH
ufw enable
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
systemctl restart ssh
apt update
apt -y upgrade
apt install -y git