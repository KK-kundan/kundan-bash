#!/bin/bash

# Function to print error messages
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Ensure script is run with root privileges
if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run as root!"
fi

# Prompt for the new user's username
read -p "Enter the username for the new user: " username

# Check if the username already exists
if id "$username" &>/dev/null; then
    error_exit "User '$username' already exists!"
fi

# Create the new user
useradd -m -s /bin/bash "$username" || error_exit "Failed to create user '$username'!"

# Generate SSH key pair
ssh_dir="/home/$username/.ssh"
mkdir -p "$ssh_dir" || error_exit "Failed to create SSH directory!"
ssh-keygen -t rsa -b 2048 -f "$ssh_dir/id_rsa" -N "" || error_exit "Failed to generate SSH key pair!"

# Set appropriate permissions for the SSH directory and files
chmod 700 "$ssh_dir"
chmod 600 "$ssh_dir/id_rsa"
chmod 644 "$ssh_dir/id_rsa.pub"

# Move public key to authorized_keys
mv "$ssh_dir/id_rsa.pub" "$ssh_dir/authorized_keys" || error_exit "Failed to configure authorized_keys!"
chown -R "$username:$username" "$ssh_dir"

# Add the new user to the sudo group
usermod -aG sudo "$username" || error_exit "Failed to add user '$username' to sudo group!"

# Print success message and SSH login instructions
echo "User '$username' has been created and added to the sudo group."
echo "SSH private key for the user:"
cat "$ssh_dir/id_rsa"
echo
echo "Copy the above private key to the client machine to access the server using the username '$username'."

# Success
exit 0
