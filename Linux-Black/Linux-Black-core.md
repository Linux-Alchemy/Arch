
### Phase 1: Base Install
**If you haven't yet, download the ISO here:**

[arch_linux](https://archlinux.org/download/)

**Be sure to run the checksum to ensure the file integrity**

#### Create the new VM

*Note: I am using QEMU (via Virt Manger). Your actual setup may differ depending on what hypervisor you're using.*


In Virt Manager:
- Type: **Linux**
- Version: **Arch**
- Memory: ~12GB RAM 
- Disk: 50GB (SCSI or SATA)
- Network: NAT 
- Video: `Virtio`
- Mount the ISO as the boot device
- **Don't power on the VM right away. First be sure to set it to boot up in UEFI**

---

#### Boot into the VM

- On boot menu select: `Arch Linux install medium (x86_64, UEFI)`

---

### Testing Network Connection
*Note: I'm using a wired connection*
- **DHCP** should auto-connect
- Confirm with:
```bash
ping -c 3 archlinux.org
```

##### Keyboard layout
```bash
loadkeys us
# change `us` for whatever layout you use
```

##### Optimize Mirrorlist
```bash
pacman -Sy reflector
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak # making a back up
reflector -c [country(s)] --age 12 --protocol https --sort rate --score 10 --save /etc/pacman.d/mirrorlist
```
- `-c` -> indicate specific country
- `--age 12` -> only use mirrors updated in the last 12 hours (adjust as you want or skip)
- `--protocol https` -> ensures secure connection
- `-- sort rate` -> ranks by speed
- `--score 10` -->  grabs the highest scoring mirrorlist
- `--save` -> saves to the specified file

---

##### Partition the Disk 
Confirm the disk label
In Virt Manager it should look something like `vda` 
```bash
lsblk
```
Then run:
```bash
cfdisk /dev/vda
```
##### To create partitions (EFI + Root):

1. **Select `Free Space`** using the arrow keys.
2. Hit **Enter** on `[ New ]`.
3. You will then be prompted to **enter the partition size manually**.
     - For EFI: type `512M` → press Enter.
     - After that, select `[ Type ]` and choose **EFI System** (usually option #1).
        
4. Now repeat for the **remaining space**:
     - Arrow down to the new free space.
     - `[ New ]` → press Enter.
     - Accept the default size (it will fill the rest of the disk).
     - Leave the type as default (Linux filesystem).
5. When done, go to `[ Write ]`, type `yes` to confirm writing the partition table.
6. Then `[ Quit ]` to exit `cfdisk`.
7. Run `lsblk` again to confirm partitions

---

##### Format and Mount Partitions

*Note: This layout creates separate subvolumes for root, home, logs, and cache. This is a more robust setup for snapshot management with Snapper, as it allows you to roll back the system state (`@`) without affecting your user files (`@home`) or system logs (`@log`).*

```bash
# Format partitions 
mkfs.fat -F32 /dev/vda1 # EFI 
mkfs.btrfs -f /dev/vda2 # Root (use -f to force overwrite if needed)

# --- Create Btrfs Subvolume Layout ---
# 1. Mount the top-level Btrfs volume
mount /dev/vda2 /mnt 

# 2. Create the essential subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache

# 3. Unmount the top-level volume
umount /mnt

# --- Mount Subvolumes for Installation ---
# 1. Mount the root subvolume with SSD options
mount -o noatime,compress=zstd:1,space_cache=v2,ssd,subvol=@ /dev/vda2 /mnt 

# 2. Create the necessary mount points for the other subvolumes
mkdir -p /mnt/home
mkdir -p /mnt/var/log
mkdir -p /mnt/var/cache
mkdir -p /mnt/boot/efi

# 3. Mount the remaining subvolumes and the EFI partition
mount -o noatime,compress=zstd:1,space_cache=v2,ssd,subvol=@home /dev/vda2 /mnt/home 
mount -o noatime,compress=zstd:1,space_cache=v2,ssd,subvol=@log /dev/vda2 /mnt/var/log
mount -o noatime,compress=zstd:1,space_cache=v2,ssd,subvol=@cache /dev/vda2 /mnt/var/cache
mount /dev/vda1 /mnt/boot/efi
```

---

#### Installing the Base System and Essential Tools

*Note: This command installs the core system, an LTS kernel for stability, development tools, filesystem and bootloader components, a full audio stack, and other essential utilities. This comprehensive list ensures the system is ready for detailed configuration in the next phases.*

```bash 
pacstrap -K /mnt base base-devel linux-lts linux-lts-headers linux-firmware amd-ucode nano git dkms grub btrfs-progs efibootmgr networkmanager openssh pipewire pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack wireplumber zsh zsh-autosuggestions zsh-syntax-highlighting man-db man-pages flatpak
```
Notes:
- **`-K` Flag Added:** The `pacstrap -K` command is used to initialize the pacman keyring in the new system, preventing potential signature-checking issues. It's a best practice.
- **Core Packages Retained:** `base`, `base-devel`, `linux-lts`, `linux-lts-headers`, `linux-firmware`, `amd-ucode`, `nano`, `dkms` and `git` are all essential.
- **Networking & SSH:** `networkmanager` and `openssh` 
- **Audio Stack Refined:** The Arch tools are `pipewire`, `pipewire-audio`, `pipewire-alsa`, `pipewire-pulse`, `pipewire-jack`, and `wireplumber`. This ensures the complete audio stack is functional from the start.
- **Shell & Utilities:** `zsh` and its plugins, `man-db`, `manpages`, and `flatpak`

---

##### Generate fstab
```bash
# check for /mnt/etc/
ls /mnt/etc
# if missing -> re-run `pacstrap`

genfstab -U /mnt >> /mnt/etc/fstab

# The `genfstab` command automatically added the `discard=async` mount option to all Btrfs subvolumes. 
# The problem is that this enables continuous TRIM which is known to cause performance issues and potential data corruption

# FIX --> edit the fstab file to remove `discard=async`

nano /mnt/etc/fstab

# Save and exit

# Confirm Btrfs subvolumes are correctly listed | ensure `compress=zstd`
cat /mnt/etc/fstab
```
- `fstab` -> tells Linux what drives to mount where and with what options when the system boots up
- `-U` ->  use the `UUID` to identify each partition instead of the device name like `/dev/vda1` which can change

*Note: The better option to manage the ssd is to use `fstrim.timer` which will be setup in phase 2.*

---

##### Chroot into the new system
```bash
arch-chroot /mnt
```
- moving into the newly installed file system

---

##### Time Zone
```bash
# to find your region/city
ls /usr/share/zoneinfo
ls /usr/share/zoneinfo/[country]
ln -sf /usr/share/zoneinfo/[country]/[region] /etc/localtime
hwclock --systohc # syncs hardware clock to system time
```

---

#####  Localization (language settings)
```bash
nano /etc/locale.gen
# Uncomment: en_US.UTF-8 UTF-8

locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```
- Use whichever setting is best for your set up; I'm just using US English on UTF-8

---

##### Hostname and Hosts File
```bash
echo "hostname here" > /etc/hostname # assign name for the host

# set up host file to resolve local names
cat >> /etc/hosts <<EOF 
127.0.0.1   localhost
::1         localhost
127.0.1.1   [hostname-you-picked].localdomain [hostname-you-picked]
EOF
```

---

##### Set Root Password
```bash
passwd
```

---

##### Create a User + Sudo Access
It's always a good idea to create a non-root user
```bash
useradd -m -G wheel -s /bin/bash [newuser]
passwd [newuser]
EDITOR=nano visudo
# Uncomment: %wheel ALL=(ALL:ALL) ALL
```
- `-m` -> Creates a home directory at /home/newuser
- `G wheel` -> Adds the user to the **wheel group** which can be granted sudo rights
- `-s /bin/bash` -> Sets the login shell

---

##### Enable Networking
```bash
systemctl enable NetworkManager.service
```

---

##### Install GRUB (UEFI)
```bash
# 
# First, edit the default GRUB configuration to add kernel parameters needed for Phase 2. 
# This ensures they are baked into the final config file. 
# 
nano /etc/default/grub 
# Find this line: 
# GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet" 
# 
# And change it to this, adding parameters for AppArmor which will be installed later: 
# GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet apparmor=1 security=apparmor" 
# 
# Save and exit the editor.


# Install GRUB bootloader
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

# Now, generate the final GRUB config file 
grub-mkconfig -o /boot/grub/grub.cfg

# Verify
ls /boot/grub/grub.cfg
```

---

##### Exit and Reboot
```bash
exit
umount -R /mnt
reboot
```

---


##### Install AUR (Arch User Repo)
*Boot back in and log in as the new user*
```bash
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

---
### Validation
Confirm **LTS** kernel
```bash
uname -r
```

Verify Network
```bash
ping -c 3 archlinux.org
```

Check **Btrfs** subvolumes
```bash
btrfs subvolume list /
```

Verify **GRUB** install
```bash
ls /boot/grub
```

---

### End of Phase 1

The system is successfully installed and boots to a command-line interface. All validation checks passed, confirming:
- The LTS kernel is running.
- Network is operational.
- The Btrfs subvolume layout is correct.

##### Notes

**Outstanding Minor Issues for Phase 2:** The `fstrim.timer` needs to be enabled to handle periodic TRIM for the SSD.
