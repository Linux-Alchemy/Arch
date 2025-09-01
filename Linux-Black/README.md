## Arch Linux Black

**Arch Linux Black** is a proof-of-concept build created as a lightweight, heavily customized Arch-based system. This is actually my fourth attempt to get it 'just right'.
The more know ya I guess...The goal was to replicate the overall usability and visual styling of my daily driver — but built entirely from scratch on Arch, for full control and performance.

This build/project was as much about getting better with Linux as much as it was to have some fun with it.

---

### 🧱 What This Is

- Clean Arch install with a full Phase 1–3 build process
- GNOME desktop environment with a groovy but minimalist theme
- Daily apps, core utilities, privacy tools, and system hardening included
- System managed with Btrfs subvolumes, Snapper snapshots, and minimal startup overhead
- Targeted app sandboxing using Firejail + Flatpak
- AppArmor enabled and protecting core services (after some manual setup)

All build phases are fully documented in this repo.

---

### 🧪 What Broke / What Bit Back

- All in all, this was alright. My previous three builds taught me a bunch. Nevertheless, there were a few issues with screen resolution and window resizing related to my GPU setup. You can find the details in the [changelog](https://github.com/RogueWizard42/linux_labs/blob/main/OS_Builds/arch-linux/Linux-Black-Phase1-changelog.md)

---

### 🔐 Security Highlights

- **AppArmor** active for core system services
- **Firejail** manually applied to high-risk apps (Firefox, VLC, Tor Browser, etc.)
- **Flatpak** used where Firejail was overkill or too restrictive
- **Timeshift** used in place of *snapper* for snapshot and rollback management
- **UFW** active with sane default rules

---

### 🧠 Final Thoughts

Finally. Linux-Black LIVES!! So anyways, this was fun, and now Arch is my favorite thing.

Highly recommend building it yourself if you're even a little curious. There’s no substitute for bleeding a bit on the Arch altar.

---

### 📁 Repo Structure

- `Phase 1`: Base system install + filesystem + essential packages
- `Phase 2`: Daily apps, DE, theming, tools
- `Phase 3`: Hardening + security layers
- `Phase 4`: ISO conversion via `ArchISO` (Under Construction)

Each phase is its own Markdown doc — clean, annotated, and meant to be cloned, modified, or built on.

---

#### 🛠️ Status

Project is complete(ish) 
