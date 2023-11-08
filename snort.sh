#!/bin/bash

# Update the package list and upgrade existing packages
sudo apt update
sudo apt upgrade -y

# Install required packages
sudo apt install -y snort

# Copy the provided SQL injection rules file to the correct directory
sudo cp sql-injection.rules /etc/snort/rules/sql-injection.rules

# Enable the local rules file
echo "include \$RULE_PATH/sql-injection.rules" | sudo tee -a /etc/snort/snort.conf

# Restart Snort to apply the configuration changes
sudo service snort restart

echo "Snort installation and SQL injection rules configuration completed."



# https://medium.com/@johnsamuelthiongo52/sql-injection-ids-using-snort-ffd639cb0f3f
