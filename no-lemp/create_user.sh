#!/bin/bash

USERNAME="$1"

# Create linux user
sudo useradd -m -N -g nginx $USERNAME
sudo chsh -s /bin/bash $USERNAME
echo "umask 027" | sudo tee -a /home/$USERNAME/.bashrc

# Done
echo "Done !"
