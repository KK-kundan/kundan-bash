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

# Define the current directory and file paths
current_dir=$(pwd)
pem_file_path="$current_dir/${username}_key.pem"
pub_file_path="$current_dir/${username}_key.pub"

# Generate SSH key pair and save the private key as a .pem file
ssh-keygen -t rsa -b 2048 -f "${current_dir}/${username}_key" -N "" || error_exit "Failed to generate SSH key pair!"
mv "${current_dir}/${username}_key" "$pem_file_path"
mv "${current_dir}/${username}_key.pub" "$pub_file_path"

# Adjust permissions for the .pem file
chmod 600 "$pem_file_path" || error_exit "Failed to set permissions for .pem file!"

# Set up the user's SSH directory
ssh_dir="/home/$username/.ssh"
mkdir -p "$ssh_dir" || error_exit "Failed to create SSH directory!"
chmod 700 "$ssh_dir"

# Move the public key to the authorized_keys file
cp "$pub_file_path" "$ssh_dir/authorized_keys" || error_exit "Failed to configure authorized_keys!"
chmod 600 "$ssh_dir/authorized_keys"
chown -R "$username:$username" "$ssh_dir"

# Add the new user to the sudo group
usermod -aG sudo "$username" || error_exit "Failed to add user '$username' to sudo group!"

# Print success message and SSH login instructions
echo "User '$username' has been created and added to the sudo group."
echo "SSH key files have been created in the current directory:"
echo "Private Key (.pem): $pem_file_path"
echo "Public Key: $pub_file_path"
echo "Copy the private key (.pem) to the client machine for SSH access."

# Success
exit 0
