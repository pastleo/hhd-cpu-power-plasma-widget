#!/bin/bash

# Ask for the username
read -rp "Enter your username: " USERNAME

# Validate that the user exists
if ! id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' does not exist."
    exit 1
fi

# Define the file to be added
SUDOERS_LINE="$USERNAME ALL=(ALL) NOPASSWD: $HOME/.local/share/plasma/plasmoids/org.kde.plasma.desktoptdpcontrol/contents/libs/ryzenadj"

# Create a temporary file for sudoers.d
TMPFILE=$(mktemp)

# Write the rule into the temp file
echo "$SUDOERS_LINE" > "$TMPFILE"

# Move the file into sudoers.d with proper permissions
sudo mv "$TMPFILE" "/etc/sudoers.d/plasma_ryzenadj"
sudo chmod 440 "/etc/sudoers.d/plasma_ryzenadj"

echo "Sudoers rule added successfully for user $USERNAME."
