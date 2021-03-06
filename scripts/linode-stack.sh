#!/bin/bash
# <UDF name="USERNAME" Label="Linux username" />
# <UDF name="GH_USERNAME" Label="Your github username, to get public keys" />

USERNAME="khanhicetea"
GH_USERNAME="khanhicetea"
GITHUBKEYS="https://github.com/$GH_USERNAME.keys"

# Install packages
apt-get install -y sudo wget ufw

# Firewall
sed -i -e 's/IPV6=yes/IPV6=no/' /etc/default/ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw --force enable

# Disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
sysctl -p

# Adding SSH user
useradd -m $USERNAME -s /bin/bash
echo "$USERNAME   ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
echo "AllowUsers $USERNAME" >> /etc/ssh/sshd_config
mkdir -p /home/$USERNAME/.ssh
wget -q -O- "${GITHUBKEYS}" >> /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys
systemctl restart ssh

# Lock root
passwd -l root

