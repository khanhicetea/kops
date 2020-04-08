#!/bin/bash

USERNAME="$1"

# Create linux user
sudo useradd -m -N -g nginx $USERNAME
sudo chsh -s /bin/bash $USERNAME
echo "umask 027" | sudo tee -a /home/$USERNAME/.bashrc

# Jobber
sudo systemctl restart jobber
sleep 3
sudo runuser -l $USERNAME -c 'jobber init'
cat >/tmp/user_jobber <<EOF
version: 1.4

prefs:
    logPath: logs/jobber.main.log
    runLog:
        type: file
        path: /home/${USERNAME}/logs/jobber.run.log
        maxFileLen: 50m
        maxHistories: 2

jobs:
EOF
sudo mv /tmp/user_jobber /home/$USERNAME/.jobber
sudo chown -R $USERNAME:www-data /home/$USERNAME/.jobber
sudo chmod 600 /home/$USERNAME/.jobber
sudo runuser -l $USERNAME -c 'jobber reload'

# Done
echo "Done !"
