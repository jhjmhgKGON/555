<div align="center">
    <img src="https://media.giphy.com/media/YmZOBDYBcmWK4/giphy.gif" width="100%" alt="Kira Hero">
    
    <br><br>

    <h1>𝕶𝕴𝕽𝕬 𝕴𝕹𝕾𝕿𝕬𝕷𝕷𝕰𝕽</h1>
    <h3>𝕿𝖍𝖊 𝕬𝖇𝖘𝖔𝖑𝖚𝖙𝖊 𝕬𝖗𝖈𝖍 𝕷𝖎𝖓𝖚𝖝 𝕰𝖝𝖊𝖈𝖚𝖙𝖎𝖔𝖓</h3>

    <p><i>"I'll take a potato chip... and INSTALL ARCH LINUX!"</i></p>

    <br>

    <p align="center">
        <a href="#"><img src="https://img.shields.io/badge/STATUS-FLAWLESS_EXECUTION-black?style=for-the-badge&logo=arch-linux" alt="Status" /></a>
        <a href="#"><img src="https://img.shields.io/badge/ENCRYPTION-LUKS2_%2B_LVM-darkred?style=for-the-badge&logo=gnupg" alt="Security" /></a>
        <a href="#"><img src="https://img.shields.io/badge/LICENSE-DEATH_NOTE-black?style=for-the-badge" alt="License" /></a>
    </p>

    <br>
    <p><b>KIRA is a divine, automated, and ruthless installer script designed to set up Arch Linux cleanly, securely, and without any human error. Leave no trace of bloatware behind.</b></p>
</div>

<br><br>

<div align="center">
    <table width="100%" style="border-collapse: collapse; border: none;">
        <tr style="border: none;">
            <td width="50%" align="center" style="border: none; padding: 20px;">
                <h2>𝕯𝖎𝖛𝖎𝖓𝖊 𝕬𝖚𝖙𝖔𝖒𝖆𝖙𝖎𝖔𝖓</h2>
                <img src="https://media.giphy.com/media/o2KLYPem407CM/giphy.gif" width="100%" style="border-radius: 8px;" alt="Writing names">
            </td>
            <td width="50%" align="left" style="border: none; padding: 20px;">
                <h3>The Perfect World</h3>
                <p>Just as Light Yagami sought to become the god of the new world by precisely executing criminals, the <b>KIRA Arch Installer</b> seeks to precisely configure your partitions, secure your system, and orchestrate the perfect Arch environment.</p>
                <p>No messy configurations. No bloated defaults. Just swift, absolute execution.</p>
                <br>
                <ul>
                    <li>💀 <b>Absolute Automation:</b> Single, dual, and USB setups.</li>
                    <li>🔐 <b>Impenetrable Encryption:</b> LUKS2 + LVM stealth.</li>
                    <li>📺 <b>Interactive TUI:</b> Whiptail menus do the talking.</li>
                    <li>🤖 <b>Preseed Support:</b> Point, click, walk away.</li>
                    <li>🏎️ <b>Hardware Awareness:</b> Automated CPU microcode & GPU driver parsing.</li>
                </ul>
            </td>
        </tr>
    </table>
</div>

<br><br>

<div align="center">
    <h2>📜 𝕿𝖍𝖊 𝕽𝖚𝖑𝖊𝖘 𝖔𝖋 𝕰𝖝𝖊𝖈𝖚𝖙𝖎𝖔𝖓 (𝕼𝖚𝖎𝖈𝖐 𝕾𝖙𝖆𝖗𝖙)</h2>
</div>

### 1. 𝕿𝖍𝖊 𝕻𝖗𝖊𝖕𝖆𝖗𝖆𝖙𝖎𝖔𝖓
Boot into the official Arch Linux installation media and confirm your connection to the outside world.
```bash
ping archlinux.org -c 3
```

### 2. 𝕻𝖗𝖔𝖈𝖚𝖗𝖊 𝖙𝖍𝖊 𝕯𝖊𝖆𝖙𝖍 𝕹𝖔𝖙𝖊
Bring the script down from your repository.
```bash
git clone https://github.com/jhjmhgKGON/555.git kira-installer
cd kira-installer
chmod +x kira.sh
```

### 3. 𝕰𝖝𝖊𝖈𝖚𝖙𝖊 𝕵𝖚𝖉𝖌𝖒𝖊𝖓𝖙
Even Kira needs root to change the world. Execute the script and let the judgment begin.
```bash
sudo ./kira.sh
```

<br><br>

<div align="center">
    <h2>🧠 𝕻𝖗𝖊𝖘𝖊𝖊𝖉 (𝕬𝖚𝖙𝖔𝖒𝖆𝖙𝖊𝖉 𝕸𝖔𝖉𝖊)</h2>
    <p>Don't want to answer questions? Want to mass-install? Use a <b>Preseed</b>. By providing a <code>.conf</code> file, KIRA will bypass the interface and silently execute your precise will.</p>
</div>

```bash
# Use the provided production configuration file
sudo ./kira.sh --preseed preseed/production.conf
```

<div align="center">
    <p><i>Tip: Check <code>preseed/production.conf</code> for a perfect template! You can enforce absolute automation using <code>AUTO=true</code>.</i></p>
    <br>
    <img src="https://media.giphy.com/media/o2KLYPem407CM/giphy.gif" width="60%" style="border-radius: 8px;" alt="Writing Names">
</div>

<br><br>

<div align="center">
    <h2>🧩 𝕿𝖍𝖊 𝕬𝖗𝖈𝖍𝖎𝖙𝖊𝖈𝖙𝖚𝖗𝖊</h2>
    <table width="100%" style="border: none;">
        <tr style="border: none;">
            <td width="50%" align="left" style="border: none; padding: 20px;">
                <p>Everything operates sequentially under the module library. No hidden agendas. Total control.</p>
                <ul>
                    <li><code>kira.sh</code> — <b>The Mastermind</b></li>
                    <li><code>lib/disk.sh</code> — <b>The Scythe</b> (Validation & Partitions)</li>
                    <li><code>lib/encryption.sh</code> — <b>The Vault</b> (LUKS2 & LVM)</li>
                    <li><code>lib/system.sh</code> — <b>The Pulse</b> (Pacstrap & Configs)</li>
                    <li><code>lib/ui.sh</code> — <b>The Face</b> (ASCII Menus & Progress)</li>
                </ul>
            </td>
            <td width="50%" align="center" style="border: none; padding: 20px;">
                <img src="https://media.giphy.com/media/10bKPDUM5H7m7u/giphy.gif" width="100%" style="border-radius: 8px;" alt="Kira Laughing">
            </td>
        </tr>
    </table>
</div>

<br><br>

<div align="center">
    <a href="https://discord.gg/your-invite-link">
        <img src="https://media.giphy.com/media/wMqzS9qqe6X2E/giphy.gif" width="100%" style="border-radius: 12px;" alt="Discord Presence Effect">
    </a>
</div>

<br><br>

<div align="center">
    <h2>⚠️ 𝕯𝖎𝖘𝖈𝖑𝖆𝖎𝖒𝖊𝖗</h2>
    <p><b>DATA OBLITERATION:</b> Executing KIRA <b>WILL FORMAT AND DESTROY ALL PREVIOUS DATA ON THE TARGET DISK</b>. Be absolute in your targets. Understand the consequences. Unlike Shinigami eyes, you cannot buy back your wiped data with half your life!</p>
</div>

<br><br>

<div align="center">
    <h3>"𝕿𝖍𝖎𝖘 𝖘𝖞𝖘𝖙𝖊𝖒 𝖎𝖘 𝖒𝖎𝖓𝖊. 𝕴𝖙𝖘 𝖋𝖔𝖚𝖓𝖉𝖆𝖙𝖎𝖔𝖓𝖘, 𝖎𝖙𝖘 𝖇𝖔𝖔𝖙𝖑𝖔𝖆𝖉𝖊𝖗, 𝖎𝖙𝖘 𝖋𝖎𝖑𝖊𝖘𝖞𝖘𝖙𝖊𝖒𝖘..." 🍎</h3>
</div>
