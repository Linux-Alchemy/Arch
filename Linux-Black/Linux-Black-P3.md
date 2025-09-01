### Hardening the System

In this phase, Linux Black will get some tightening up on the security front. There's lot of ways to secure a system, and you can in fact have too much security, so much so that the system becomes essentially unusable. 
The goal in Phase 3 is to batten down the hatches without jamming up the ship's controls.

---
#### Step 1: Timeshift
To simplify the setup and management of rollbacks this build is using **Timeshift**. The other option is **Snapper & GRUB-btrfs**, but using Timeshift is somewhat less complicated. It does have a GUI, but it can also be managed via the CLI, which is what we'll do here for the most part after the initial set up.

Timeshift was installed at the end of Phase 2, but it's good to verify:
```bash
timeshift --version
```

From the CLI:
```bash
sudo timeshift-gtk

# you can also just find the app and open it on the desktop
```

1. Select **BTRFS**
	- Since this build was designed to use **btrfs** it makes no sense to use **rsync** here. It's a little like putting low octane fuel in a fusion-powered starship -- nonsense.
2. **Snapshot Location:** The wizard should automagically detect your BTRFS partition; just double check that it's right. 
3. **Snapshot Levels (schedule):** This determines the frequency of backup snaps *in addition* to the `pacman` snaps from the autosnap hook. 
		- You can use whatever frequency you want here; my go-to is something like Weekly(1), Daily (6), Hourly (6) and Boot (1) --> the boot snap can be a lifesaver
4. By default Timeshift **excludes** the @home subvolume --> leave it like that. The snapshots are for recovering a borked system. Taking snaps of your personal files too can quickly lead to bloat. To keep your personal files safe there's other tools for that. 
5. Click `Finish`

**Verify**
1. With the Timeshift window still open, create a manual snapshot -->  Click `Create`
		- it's take just an instant (Yay btrfs!)
		- if you have yout terminal window still open, you'll see the output there, and the new snap will appear in the Timeshift window as well. 
2. For the real test -->  The `pacman` Hook.
To test this, simply install a package that is a system or core utility
```bash
sudo pacman -S pacman    # this will just re-install pacman no biggie
```
*Unlike other tools that snapshot every change, `timeshift-autosnap` intelligently creates restore points only when critical system packages, such as the kernel or core utilities, are modified. This selective process avoids clutter from routine application installs and ensures each snapshot is a meaningful backup for system recovery.*

You should see something like this as part of the output:
```bash 
:: Running pre-transaction hooks...
(1/1) Creating Timeshift snapshot before upgrade...
Using system disk as snapshot device for creating snapshots in BTRFS mode
Mounted '/dev/vda2' (subvolid=0) at '/run/timeshift/3098/backup'
btrfs: Quotas are not enabled
Creating new backup...(BTRFS)
Saving to device: /dev/vda2, mounted at path: /run/timeshift/3098/backup
Created directory: /run/timeshift/3098/backup/timeshift-btrfs/snapshots/2025-08-16_12-56-27
Created subvolume snapshot: /run/timeshift/3098/backup/timeshift-btrfs/snapshots/2025-08-16_12-56-27/@
Created control file: /run/timeshift/3098/backup/timeshift-btrfs/snapshots/2025-08-16_12-56-27/info.json
BTRFS Snapshot saved successfully (0s)
Tagged snapshot '2025-08-16_12-56-27': ondemand

```


---

#### Lynis Scan
Lynis is a little like a really picky safety inspector. It's going to comb through the system and pic at every little detail it can find and issue a score. While this is a fresh install at this point, it's still a good idea to run this before implementing any security measures so you have a baseline. 

Lynis has a lot of abilities, and you should familiarize yourself with them. For now here's some scans you can run:
```bash
sudo lynis audit system           # Perform a full system security audit
sudo lynis audit system --quick   # Run a quicker audit with default settings
sudo lynis audit system --pentest # Run audit in pentest mode (less verbose, more aggressive)
```
The output is....a lot. Even on a lean system. But at the end you'll get a tidy report with some idea of where to start. 

In this case, the one Warning was in regards to the firewall rules which works out as that's the next step anyways
```text
  Warnings (1):
  ----------------------------
  ! iptables module(s) loaded, but no rules active [FIRE-4512] 
      https://cisofy.com/lynis/controls/FIRE-4512/
```

---
#### Firewall
That warning above for the `iptables` is definitely something to take note of. `iptables/nftables` is a complex kernel security system. But to keep it simple, and still functional, we're using `ufw` (uncomplicated firewall) here.
**UFW** is the big, friendly, no-bullshit bouncer you hire to manage it for you. You don't tell him the technical details; you just give him simple rules:

1. "Don't let _anyone_ in." (Default Deny)
2. "Except these guys on the VIP list." (Allow Rules)
3. "Let anyone who's already inside leave whenever they want." (Default Allow Outgoing)

`ufw` is already installed from phase 2, but it has to first be turned on:
```bash
sudo ufw status
# Status: inactive

sudo ufw enable

# check the status again
sudo ufw status verbose
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

# this is the default setting
# If this were a web server, you'd also add rules like `sudo ufw allow http` and `sudo ufw allow https`
# but for our workstation for now we're just going to enable ssh (port 22)

sudo ufw allow ssh

# check it once more
sudo ufw status verbose
```

---
#### ClamAv 
**ClamAv** is an open source anti-malware kit, that's actually pretty solid for most users. Think of **ClamAV** as the internal patrol that sweeps the castle grounds. Its job isn't to stop invaders at the wall, but to find spies, assassins, or saboteurs who might have been smuggled inside in a wine cask. It looks for known threats that are already on your filesystem.
For our purposes here, it has two key components:
1. **`clamscan`**: The on-demand scanner. You run this manually to check files or directories.
2. **`freshclam`**: The database updater. This is a daemon that runs in the background, connects to the internet, and makes sure your list of "known spies and assassins" (the malware signature database) is always up-to-date.
**ClamAV** was installed an enabled in phase 2. So we're just going to check in on it and make sure all is well.

**Verify the Installation:** First, confirm that the `freshclam` utility is installed and see which version of the signature database is present.
```bash
freshclam --version
```

**Enable and Start Daemons:** ClamAV relies on two key services. The `clamav-daemon` is the core scanning engine, and `clamav-freshclam` is the daemon responsible for keeping the malware signature database up-to-date. We'll enable and start both.
```bash
# Enable the main scanning daemon
sudo systemctl enable --now clamav-daemon

# Enable the database update daemon
sudo systemctl enable --now clamav-freshclam
```
*Using `enable --now` ensures the services start immediately and are also configured to launch automatically on the next boot.*

**Run an Initial Manual Update:** Although the `freshclam` service will now run periodically, it's best practice to manually trigger an update immediately after installation. This ensures you have the latest definitions right away and confirms that your system can communicate with the signature update servers.
```bash
sudo freshclam
```

**Confirm Final Status:** Finally, double-check the status of both services to ensure they are `active (running)` as expected.
```bash
sudo systemctl status clamav-daemon && sudo systemctl status clamav-freshclam
```
*This confirms our internal patrol is active and its intelligence is up-to-date, leaving the system protected against known threats.*

---

#### Apparmor 
In this section, we'll briefly look at hardening a couple of system services. The intention with this build to practice "defence in depth". For that we'll be using AppArmor (AA) for system services, FireJail for internet facing "higer risk" apps, and flatpak for general use apps.
(AA) was installed in phase 2, so to begin, let's just make sure that the system is up and running.
```bash
sudo aa-status
```
This should output a list of profiles, starting with a bunch that are in 'enforce' mode, a few that might be in 'complain' mode and a bunch in 'unconfined' mode (there, but not doing anything)

In the case of Linux Black, meant to be a fairly lean system, there's a bunch of profiles showing in 'enforce' mode that just aren't needed. So we'll go ahead a disable those. The ~80 profiles don't have too much of an impact on boot time so removing a few won't make a noticable difference. That said, you CAN have a seriously locked down system with 1500+ profiles if you want. 
**Don't do this.**
It definitely impacts performance and boot time. And it gets weird to manage that many profiles because things can break when there's that much going on. Just figure out what your build specifically needs, and CYA without going over board.

In order to disable any profile, you need it's actual **filename**. What's listed in the output from `aa-status` isn't necessarily the same.
```bash
cd /etc/apparmor.d
ls 
```
*This will spit out the actual filenames needed to disable the profiles.*

Just for the example, we'll get rid of the 'sbuild' group of profiles. `sbuild` is a Debian based package builder that on an Arch based system is totally useless.

Get a list of what you want to zap:
```bash
ls -1 /etc/apparmor.d | grep 'sbuild'
```

Then take that list and drop it into a quick little bash script to avoid going one by one:
```bash
for profile in sbuild sbuild-abort sbuild-adduser sbuild-apt sbuild-checkpackages sbuild-clean sbuild-createchroot sbuild-destroychroot sbuild-distupgrade sbuild-hold sbuild-shell sbuild-unhold sbuild-update sbuild-upgrade; do
    sudo aa-disable "$profile"
done

# verify the profiles were disabled
sudo aa-status
```

This is a good spot to mention that there are a couple of repos available to import a bunch of pre-made AA profiles. It's fine if that's what you want to do, but as stated earlier, make sure you don't over do it.
My preference is to find out what's running on the system now, and then *build* the profiles that I want to use.

First, let's see what services are running:
```bash
sudo systemctl list-units --type=service --state=running

# some of the output
...snip
  clamav-daemon.service    loaded active running Clam AntiVirus userspace daemon
  clamav-freshclam.service loaded active running ClamAV virus database updater
  colord.service           loaded active running Manage, Install and Generate Color Profiles
  dbus-broker.service      loaded active running D-Bus System Message Bus
  gdm.service              loaded active running GNOME Display Manager
  ...snip...
```

We'll use `clamav-freshclam.service` for this example. If something goes wrong and the profile gets buggered up, it won't cause any real issues. If you've not built AA profiles before, fear not; I'm working my way through this too. But that said, maybe don't start with a critical system service.

For those of you familiar with **Arch**, it'll come as no surprise that there's an extra step or two to make this work.
The `apparmor audit` package is needed:
```bash 
sudo pacman -S apparmor audit

# now start the daemon
sudo systemctl enable --now auditd.service

# confirm apparmor is running
sudo aa-status

# confirm the audit daemon is running
sudo auditctl -s
```

Find the actual location of `freshclam`
```bash
which freshclam

# should be something like
# /usr/bin/freshclam
```


Next is to create the bare bones profile for `freshclam`:
```bash
sudo aa-autodep /usr/bin/freshclam
```
When this runs, it'll present you with a few options:
- (V)iew profile
- (U)se profile
- (C)reate profile
- Abo(r)t 

Since you can't view or use what doesn't exist, so go ahead and create the profile. The profile should show up as `/etc/apparmor.d/usr.bin.freshclam`. The profile, once created is automatically put into complain mode.
Now you can take a peek at it.
```bash
cat /etc/apparmor.d/usr.bin.freshclam

# Last Modified: Sat Aug 16 15:13:39 2025
abi <abi/4.0>,

include <tunables/global>

/usr/bin/freshclam flags=(complain) {
  include <abstractions/base>

  /usr/bin/freshclam mr,

}
```

Run this to make sure that AA picks up the new profile:
```bash
sudo apparmor_parser -r /etc/apparmor.d/usr.bin.freshclam
```

Now to generate an event -->  Run this:
```bash
sudo freshclam    
```

Now to build the rules interactively:
```bash
sudo aa-logprof

Reading log entries from /var/log/audit/audit.log.
Complain-mode changes:

Profile:    /usr/bin/freshclam
Capability: setgid
Severity:   9

 [1 - include <abstractions/dovecot-common>]
  2 - include <abstractions/postfix-common> 
  3 - include <abstractions/samba-rpcd> 
  4 - capability setgid, 
(A)llow / [(D)eny] / (I)gnore / Audi(t) / Abo(r)t / (F)inish



```

To be clear, there are several items flagged by AA while going through the process of building the `freshclam` profile. No, it is not the fastest way to get a new profile done. What it is though, is the best way to learn and understand exactly what a process is doing on your system, and I highly recommend doing this. For the sake of brevity, I won't post all the steps to completion for the `freshclam` profile, but here's what the finished profile looks like:
```bash 
sudo cat usr.bin.freshclam

# Last Modified: Sat Aug 16 16:14:02 2025
abi <abi/4.0>,

include <tunables/global>

/usr/bin/freshclam flags=(complain) {
  include <abstractions/base>
  include <abstractions/nameservice>

  capability setuid,

  capability setgid,

  deny owner /proc/sys/kernel/random/boot_id r,

  /etc/host.conf r,
  /etc/resolv.conf r,
  /usr/bin/freshclam mr,
  owner /etc/clamav/freshclam.conf r,
  owner /etc/group r,
  owner /etc/nsswitch.conf r,
  owner /etc/passwd r,
  owner /run/systemd/userdb/ r,
  owner /var/lib/*/ r,
  owner /var/lib/clamav/* r,
  owner /var/lib/clamav/*/ rw,

}
```

The last step is to enforce the newly created profile:
```bash 
sudo aa-enforce /etc/apparmor.d/usr.bin.freshclam
```

---

#### Firejail
FJ is a sandbox utility. It works on a blacklist model by default, specifiying what an app *can't* do or access. Like AA it has profiles that can be inspected, created or adjusted. For this example, we'll use FJ on Firefox with the default profile. You can inspect the Firefox profile with this:
```bash 
cat /etc/firejail/firefox.profile
```

To run Firefox with Firejail --> In a terminal:
```bash
firejail firefox
```
There. That's it, Firefox opens in a sandbox. 

If like most folks you prefer to run Firefox from an icon on the desktop, you'll need to tweak the `*.desktop` file for Firefox. Before editing anything, make a copy of `firefox.desktop` in  `.local/share/applications`
```bash
cp /usr/share/apllications/firefox.desktop ~/.local/share/applications

# now you can edit the local file
sudo nano ~/.local/share/applications/firefox.desktop
```
- Inside the file, look for lines that start with `Exec=`. Edit them by adding `firejail` right after the `=`. For example:
	- **Change this:** `Exec=/usr/lib/firefox/firefox %u`
	- **To this:** `Exec=firejail /usr/lib/firefox/firefox %u`
- In the `firefox.desktop` file there's three of those lines to edit. Some apps will have one line, other's more. You'll have to go through each one to find them all. 

For this build we're only using Firejail on apps that are directly exposed to the internet due to it's generally more strict rule set. So the browser, email client, PDF viewer etc. are all examples. For more general apps like Spotify or GIMP, `flatpak` will be the method of choice. 

---

That's a wrap on Phase 3. The last phase is the conversion from the VM it is now, to a bootable ISO using the ArchISO tool kit.
Stay tuned nerds!










