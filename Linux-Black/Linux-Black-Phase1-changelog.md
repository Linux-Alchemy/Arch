
# Linux Black - Phase 1 Build Debrief

This document summarizes the key decisions, troubleshooting steps, and final configurations for the Phase 1 build of the Linux Black system.

---

## 1. Virtual Machine Configuration (QEMU/KVM)

I decided to build the system in **QEMU/KVM with virt-manager** from the start, rather than using VMware. This aligns with the long-term goal of using QEMU as the primary hypervisor on the bare-metal host and forces familiarity with its quirks.

### Initial Setup & Graphics Troubleshooting

- **Firmware:** The VM was correctly configured to use UEFI by specifying the `OVMF_CODE_4M.fd` firmware file, which is mandatory for a modern build.
- **Initial Boot Failure:** The first attempt to boot the VM with `VirtIO` video and `OpenGL` acceleration enabled resulted in an `eglInitialize failed` error.
- **Diagnosis:** The error was traced to QEMU attempting to use the host's **NVIDIA** for rendering, whose proprietary driver rejected the connection(as far as I could figure it anyway). The host's integrated **AMD GPU** was far more cooperative.
- **Resolution 1:** The VM's `Display Spice` settings were modified to explicitly use the CPU's integrated graphics (I know, not ideal, but hey, it worked!)
- **Black Screen on Boot:** This change resolved the EGL error but resulted in a black screen on boot, indicating a driver incompatibility between the Arch ISO's kernel and the `VirtIO` virtual GPU.
- **Resolution 2:** The VM's video hardware was changed to the more compatible **`QXL` model**, and both **3D acceleration** and **OpenGL** were disabled. 

---

## 2. Core Installation & Configuration

### `fstab` Correction

- **Issue:** The `genfstab` command automatically added the `discard=async` mount option to all Btrfs subvolumes.
- **Problem:** This enables continuous TRIM, which is known to cause performance degradation and potential data corruption risks, especially in virtualized environments.
- **Resolution:** The `/mnt/etc/fstab` file was manually edited before `chroot`-ing to remove the `discard=async` option from all Btrfs mount points. The plan is to use the modern, safer method of enabling the `fstrim.timer` service from within the installed system.

### GRUB Installation for Btrfs/Snapper

- **Issue:** The original plan for `grub-install` was correct but incomplete for a system using Snapper.
- **Resolution:** The process was updated to ensure seamless snapshot integration.
    1.  The `/etc/default/grub` file was edited to add `GRUB_BTRFS_SUBMENUNAME="Arch Snapshots"` to organize snapshots into a submenu.
    2.  `grub-mkconfig` was run *after* this change.
    3.  The `grub-btrfs.path` service was enabled to ensure GRUB is automatically updated when new snapshots are created.

---

## 3. Post-Reboot Configuration & Troubleshooting

### NVIDIA Driver Deferment

- **Decision:** The entire "Install and Configure Nvidia Driver" section was deferred.
- **Reasoning:** The guest VM has no access to the host's physical NVIDIA GPU. Installing the proprietary driver inside the VM would fail or break the display drivers. This step must only be performed after Linux Black is installed on the bare-metal host.

### Snapper Configuration Errors

- **Issue:** The initial `snapper -c root create-config /` command failed with `subvolume already covered`.
- **Diagnosis:** A broken, empty `root` config file was likely created by a failing `snap-pac` hook during the `pacstrap` phase.
- **Resolution:**
    1.  The broken config was correctly identified using `sudo snapper list-configs`.
    2.  The broken config was removed using the correct syntax: `sudo snapper -c root delete-config`.
    3.  The `create-config` commands were then run successfully for both `/` and `/home`.
- **Retention Policy:** The default retention policy was deemed insufficient. A more robust policy focusing on a higher number of hourly and daily snapshots was recommended and implemented (`TIMELINE_LIMIT_HOURLY="12"`, `TIMELINE_LIMIT_DAILY="7"`).

---

## Final Status (End of Phase 1)

The system is successfully installed and boots to a command-line interface. All validation checks passed, confirming:
- The LTS kernel is running.
- Network is operational.
- The Btrfs subvolume layout is correct.
- GRUB is installed and configured for snapshots.
- Snapper is creating and managing snapshots automatically.

**Outstanding Minor Issues for Phase 2:** - The `Failed to set locale` warning needs to be resolved. - The `fstrim.timer` needs to be enabled to handle periodic TRIM for the SSD.
