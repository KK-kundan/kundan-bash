#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Read the username
read -p "Enter the username to create: " USERNAME

# Create the user
if id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME already exists."
else
    adduser $USERNAME
    echo "User $USERNAME has been created."
fi

# Add user to sudo group
usermod -aG sudo $USERNAME
echo "User $USERNAME has been added to the sudo group."

# Set up SSH for the user
USER_HOME="/home/$USERNAME"
SSH_DIR="$USER_HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

mkdir -p $SSH_DIR
chmod 700 $SSH_DIR
touch $AUTHORIZED_KEYS
chmod 600 $AUTHORIZED_KEYS
chown -R $USERNAME:$USERNAME $SSH_DIR

echo "SSH setup for $USERNAME has been completed. Place the public key in $AUTHORIZED_KEYS."

echo "User $USERNAME has been created with sudo privileges and SSH access enabled."
