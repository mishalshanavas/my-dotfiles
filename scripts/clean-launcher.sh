#!/bin/bash

# Clean launcher script - hide junk applications from fuzzel
# Creates local desktop files with NoDisplay=true to hide them

HIDE_DIR="/home/mishal/.local/share/applications/hidden"
mkdir -p "$HIDE_DIR"

# List of applications to hide
HIDE_APPS=(
    "avahi-discover.desktop"
    "avahi-ssh-server-browser.desktop" 
    "avahi-vnc-server-browser.desktop"
    "avahi-zeroconf-browser.desktop"
    "openjdk-java-25-console.desktop"
    "openjdk-java-25-shell.desktop"
    "qt-v4l2-test-utility.desktop"
    "qt-v4l2-video-capture-utility.desktop"
    "advanced-network-configuration.desktop"
)

echo "Hiding unwanted applications..."

for app in "${HIDE_APPS[@]}"; do
    # Create a local desktop file that hides the system one
    cat > "/home/mishal/.local/share/applications/$app" << EOF
[Desktop Entry]
NoDisplay=true
EOF
    echo "Hidden: $app"
done

echo "✓ Launcher cleaned! Restart fuzzel to see changes."