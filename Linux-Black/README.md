### Arch Linux: The Manual Build

_A repository documenting a manual Arch installation. Because I had the time and a pretty decent neckbeard on the go._

#### The Philosophy
This isn't a tutorial; it's an autopsy of a system built from scratch. If a package is installed, I put it there. If a service is running, I enabled it. If it breaks, I broke it.

#### The Architecture

**Phase 1: The Foundation (The Good Stuff)**

- **Filesystem:** Btrfs with a specific subvolume layout (@, @home, @log, @cache).
- **Resilience:** Configured for transactional rollbacks. Don't reinstall; rewind.
- **Kernel:** LTS for stability.

---

**Phase 2: The Environment (The OK Stuff)**

- **Desktop:** GNOME.
- **Terminal:** Tilix.
- **Browser:** Firefox.

**Note:** Yes, I used Tilix (gross), GNOME and Firefox (also gross). If I were to do this again now, I'd make different choices. But the setup is sound. 

---

**Phase 3: The Fortress (The Paranoia)**

- **AppArmor:** Custom profiles generated via auditd and aa-logprof.
- **Sandboxing:** Firejail integration hard-coded into `.desktop` launchers.
- **Lynis:** The really picky safety inspector
- **Network:** UFW default-deny.
- **ClamAV:** An open source malware detector

---

**Conclusion:**

I did this manual build just to say that I did it.

I will _not_ do it again.

It's a pain in the ass, and not all things that are difficult are valuable. Just use the bloody `archinstall` script.
