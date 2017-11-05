#!/bin/bash

USERNAME="$1"

# Create linux user
sudo useradd -m -N -g nginx $USERNAME
sudo chsh -s /bin/bash $USERNAME

# Done
echo "Done !"
