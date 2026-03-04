<div align="center">

# ⚖️ KIRA - The Arch Linux Installer 🍎
*"I'll take a potato chip... and INSTALL ARCH LINUX!"*

<img src="https://media.giphy.com/media/YmZOBDYBcmWK4/giphy.gif" alt="Light Yagami" width="400"/>

[![Build Status](https://img.shields.io/badge/Status-Flawless-success?style=for-the-badge&logo=arch-linux)](https://archlinux.org)
[![Security](https://img.shields.io/badge/Security-LUKS2%2BLVM-black?style=for-the-badge)](https://wiki.archlinux.org/title/dm-crypt)
[![License](https://img.shields.io/badge/License-Death_Note-red?style=for-the-badge)](#)

*KIRA is a divine, automated, and ruthless installer script designed to set up Arch Linux cleanly, securely, and without any human error. Leave no trace of bloatware behind.*

</div>

---

## 📖 What is KIRA?

Just as Light Yagami sought to become the god of the new world by precisely executing criminals, the **KIRA Arch Installer** seeks to precisely configure your partitions, secure your system, and orchestrate the perfect Arch environment. No messy configurations, no bloated defaults. Just swift, absolute execution.

### ✨ Features
- 💀 **Absolute Automation:** Orchestrates standard, single-boot, dual-boot, and USB-specific setups. 
- 🔐 **Impenetrable Encryption:** Full support for `LUKS2` with or without `LVM`. Keep your files hidden from L.
- 📺 **Interactive TUI:** A stunning `whiptail` interface to effortlessly guide you, meaning you don't even need to touch the terminal manually.
- 🤖 **Preseed Automation:** Completely skip the prompts. Pass a `.conf` file and let KIRA orchestrate everything autonomously!
- 🏎️ **Microcode & GPU Awareness:** Automatically detects AMD/Intel processors and installs appropriate microcode, along with intelligent GPU driver parsing.

<div align="center">
<img src="https://media.giphy.com/media/o2KLYPem407CM/giphy.gif" alt="Writing Names" width="300"/>
</div>

---

## ⚡ Quick Start

Bring judgment to your empty drives:

### 1. Boot into the Arch Live USB
Ensure you are connected to the net and booted into the official Arch Linux installation media.
```bash
# Verify connection
ping archlinux.org -c 3
```

### 2. Procure the Death Note (Installer)
Clone the script down from your repository (or download it via curl/wget directly to your live USB):
```bash
git clone https://github.com/yourusername/kira-installer.git
cd kira-installer
chmod +x kira.sh
```

### 3. Execute Judgment
Even Kira needs root to change the world. Run the script:
```bash
sudo ./kira.sh
```

---

## 🧠 Preseed (Automated Mode)

Don't want to answer questions? Want to mass-install? Use a **Preseed**. By providing a `.conf` file, KIRA will bypass the interface and silently execute your will.

```bash
# Use the provided production configuration file
sudo ./kira.sh --preseed preseed/production.conf
```
*Tip: Check `preseed/production.conf` for a template! You can enforce absolute automation using `AUTO=true`.*

---

## 📂 Architecture

Everything operates sequentially under the module library. If you wish to look behind KIRA's mask, see the structure:

```text
kira-installer/
├── kira.sh                # Main handler; orchestrates the modules.
├── lib/                   
│   ├── bootloader.sh      # Sets up standard systemd-boot or GRUB entries
│   ├── common.sh          # Common executions, password redaction, safe execution
│   ├── disk.sh            # Target identification and partition formatting
│   ├── encryption.sh      # Secures the selected drive
│   ├── system.sh          # Package installation, region sync, user setup
│   └── ui.sh              # Interface menus, loading gauges, confirmations
└── preseed/
    └── production.conf    # Example of a flawless execution configuration.
```

<div align="center">
<img src="https://media.giphy.com/media/10bKPDUM5H7m7u/giphy.gif" alt="Kira Laughing" width="400"/>
</div>

---

## ⚠️ Disclaimer & Warning

- **DATA OBLITERATION:** Executing KIRA **WILL FORMAT AND DESTROY ALL PREVIOUS DATA ON THE TARGET DISK**. Be absolute in your targets. Understand the consequences.
- **NO SHINIGAMI EYES:** Unlike Shinigami eyes, you cannot buy back your wiped data with half your life! Have backups! 

---

<div align="center">
<b>"This system is mine. Its foundations, its bootloader, its filesystems..."</b> 🍎
</div>
