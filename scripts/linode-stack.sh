#!/bin/bash
# <UDF name="GH_USERNAME" Label="Your github username, to get public keys" />

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
useradd -m $GH_USERNAME -s /bin/bash
echo "$GH_USERNAME   ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
echo "AllowUsers $GH_USERNAME" >> /etc/ssh/sshd_config
mkdir -p /home/$GH_USERNAME/.ssh
wget -q -O- "${GITHUBKEYS}" >> /home/$GH_USERNAME/.ssh/authorized_keys
chown -R $GH_USERNAME:$GH_USERNAME /home/$GH_USERNAME/.ssh
chmod 600 /home/$GH_USERNAME/.ssh/authorized_keys
service ssh restart

# Lock root
passwd -l root

