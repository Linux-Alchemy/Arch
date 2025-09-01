This phase will cover the basic functionality of the OS prior to the conversion to a bootable ISO file. The remaining apps will be installed after Linux Black is live.

### Installation of the DE (GNOME)

Install GNOME and Friends
```bash
# Install GNOME core, extensions, and management tools
sudo pacman -S gnome gnome-tweaks gdm gnome-shell-extensions

# for the case of installing this build as a VM in QEMU
# these packages are needed to better manage the Vm including screen rez
sudo pacman -S qemu-guest-agent spice-vdagent

# Install AUR components: extension manager, dock, and GDM settings
yay -S extension-manager gnome-shell-extension-dash-to-dock gdm-settings
```
This installs the base GNOME shell, GNOME tweaks, and the GDM display manager

Enable GDM to launch on boot up
```bash
sudo systemctl enable gdm
```

Reboot the system
```bash
sudo reboot
```

---

### Installing the Preferred Terminal (Tilix)

**Note on Tilix**: No, you don't have to use Tilix. Yes, I know Kitty is faster, and Ghostly is great. But we can at least all agree that the default GNOME terminal simply won't do. 

First install Z Shell:
```bash
sudo pacman -S zsh  # this should be done already from the main install but confirm anyways

# Make Zsh the default shell
chsh -s /bin/zsh
```

Install Tilix:
```bash
yay -S tilix
```

Tilix Integration Issue (fix)
To prevent Tilix from throwing config issues when it opens edit the `.zshrc` file:
```bash
if [[ -n "$TILIX_ID" && -f /etc/profile.d/vte.sh ]]; then
    source /etc/profile.d/vte.sh
fi
```
*add this line towards the bottom of the file*

**Potential Issue**
Sometimes GNOME will complain about Tilix integration. The fix:
```bash
sudo ln -s /etc/profile.d/vte-2.91.sh /etc/profile.d/vte.sh
```

---

### Themes, Icons & Fonts Install 
The stock GNOME dark mode is functional, but somewhat uninspired. So instead of lameness, we'll go something with a little flair and use the Material Black Dark Cherry theme. 
This will also install the Flat-Remix Icon packs.

Install Dependencies:
Ensure you have the GTK Theme-Engines. If not install it now:
```bash
# Install the GTK theming engines
sudo pacman -S gtk-engine-murrine

# Install the theme and icons from the AUR 
yay -S gtk-theme-material-black flat-remix-git
```
*Note: this command will install ALL of the repos for the Material Black theme and Flat-Remix icons.*

If you don't want the entire theme and icon packs:
```bash
yay -G gtk-theme-material-black
cd gtk-theme-material-black

# then use nano or vim to edit the MAKEPKG file to remove what you don't want
nano MAKEPKG

yay -G flat-remix-git
cd flat-remix-git
nano MAKEPKG
```

Just adding a couple font packs
```bash 
yay -S ttf-firacode ttf-symbola
```

---

### Phase 1 Clean-up

**Install pkgfile**
This package is useful for adding the 'command not found functionality' that gives suggestions on the needed command to install

```bash
sudo pacman -S pkgfile

# after the install the database needs to be updated and built
sudo pkgfile --update
```


**Enabling Periodic TRIM**
Enable and start the timer
```bash
sudo systemctl enable --now fstrim.timer

# verify
systemctl status fstrim.timer

# check default setting on timer --> should be weekly 
systemctl cat fstrim.timer

# to see what it's doing
systemctl cat fstrim.service

# `ExecStart=` line that points to `/usr/bin/fstrim -av`. The `-a` means "all mounted filesystems" and `-v` means "verbose output."
```

---

### Installing File Manager (Nemo)

```bash
# Install Nemo and key extensions for archive and preview functionality
sudo pacman -S nemo nemo-fileroller nemo-preview

# Set Nemo as the default file manager for directories
xdg-mime default nemo.desktop inode/directory

# Disable GNOME's handling of desktop icons so Nemo can take over
# This prevents conflicts and ensures a stable desktop experience
gsettings set org.gnome.desktop.background show-desktop-icons false
```

---

### Install Firefox

```bash
sudo pacman -S firefox
```

---
### Installing Security Tools

##### Firewall (ufw)
```bash
sudo pacman -S ufw
```

##### AppArmor
```bash
# Install AppArmor
sudo pacman -S apparmor

# Enable and start the service (the kernel parameter will handle the rest)
sudo systemctl enable --now apparmor.service

# Check its status
sudo aa_status

# if `aa-status` doesn't show a list of profiles running then make the following
# change to grub -- this was done in phase 1, but if it got missed do it now

sudo nano /etc/default/grub

# Find this line:
# GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"
#
# And change it to this:
# GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet apparmor=1 security=apparmor"

# save and exit

# Verify its status
sudo apparmor_status

```
*Note: In this case, AppArmor is being used to harden just the core system services.*


##### Install Flatseal (Flatpak app security management)
```bash
flatpak install flathub flatseal
```
*Note: This is being used on apps where FireJail too restrictive on app function*


##### Lynis: Vulnerability Scanning Tool
```bash
sudo pacman -S lynis
```

##### Firejail: Sandboxing for apps
```bash
sudo pacman -S firejail
firejail --version             # verify the install
```

##### ClamAV (Anti-malware)

```bash
sudo pacman -S clamav
```

Enable ClamAV
```bash
# Enable the service to start automatically on boot and start it right now
sudo systemctl enable --now clamav-freshclam.service
```


##### Timeshift
Timeshift and timeshift-autosnap will be how the rollbacks are handled on this build
```bash
sudo pacman -S timeshift

# timeshift-autosnap will hook into pacman and take snaps pre update/commands
yay -S timeshift-autosnap
```

---

### Phase 2 Wrap-up
That's P2 all done. It's now a fully functional system, and it even looks kinda cool. As alluded to earlier, I plan to convert this VM into a live bootable OS. That, as well as a handful of additional AppArmor profiles and basic system hardening will be done in Phase 3. Stay tuned fellow nerds. 

---
