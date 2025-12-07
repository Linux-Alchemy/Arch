#!/bin/bash
# Script to install useful gaming addons to an Arch based distro



# Root check - make sure the user is not Root
if [ "$EUID" -eq 0 ]; then
  echo "ERROR: This script cannot be run with root privileges."
  exit 1
fi

# A check to make sure there's an AUR helper installed - yay
if ! command -v yay &> /dev/null; then
  echo "ERROR: 'yay' is not installed. Please install it before running this script."
  exit 1
fi

# Define gaming packages to be installed from official repo
pac_games=(
  "steam"
  "lutris"
  "gamemode"
  "gamescope"
  "lact"
  "mangohud"
  "goverlay"
  "retroarch"
  "discord"
  "openrgb"
  "openrazer-daemon"
  "openrazer-driver-dkms"
  "python-openrazer"
  "polychromatic"
  )

# Define gaming packages to be installed from the AUR
aur_games=(
  "heroic-games-launcher-bin"
  "bottles"
  "protonup-qt"
  "input-remapper-bin"
  )

# Install gaming packages from official repo
for pac_game in "${pac_games[@]}"; do

  if pacman -Qi "$pac_game" > /dev/null 2>&1; then
    echo "$pac_game is already installed. Skipping..."

  else
    echo "Installing $pac_game..."
    if sudo pacman -S "$pac_game" --noconfirm; then
      echo "SUCCESS: $pac_game installed."
    else
      echo "FAILURE: $pac_game could not be installed. You should probably check the logs."
      continue
    fi
  fi

done

# Install packages from the AUR
for aur_game in "${aur_games[@]}"; do

  if yay -Qi "$aur_game" > /dev/null 2>&1; then
    echo "$aur_game is already installed. Skipping..."

  else
    echo "Installing $aur_game..."
    if yay -S "$aur_game" --noconfirm; then
      echo "SUCCESS: $aur_game installed."
    else
      echo "FAILURE: $aur_game could not be installed. You might want to check the logs."
      continue
    fi
  fi

done



# Adding user to required groups
echo "Adding $USER to required groups..."
sudo usermod -aG gamemode,openrazer,plugdev,input "$USER"

echo "Install complete. Unless something buggered up, in which case you should check the logs."
echo "You will need to reboot for the group changes to take effect."



