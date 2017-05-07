#!/bin/bash

# Install required packages
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common

# Add Docker repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install Docker CE from repository
sudo apt update
sudo apt install docker-ce

# Run hello-world for testing
sudo docker run --rm hello-world

# Install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.12.0/docker-compose-`uname -s`-`uname -m` > dc
sudo mv dc /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "BAMMMMM ! Ready to containerize all things !"
