
<!-- AdvSophish – Advanced Phishing Framework (Educational) -->
<p align="center">
  <img src=".github/misc/logo.png" alt="AdvSophish Logo" width="200">
</p>

<h1 align="center">AdvSophish</h1>
<p align="center">
  <strong>Advanced Phishing Framework with Dashboard, Obfuscation & 2FA Capture</strong><br>
  <em>For authorised security testing and educational purposes only</em>
</p>

<p align="center">
  <a href="https://github.com/mahi-cyberaware/AdvSophish/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/mahi-cyberaware/AdvSophish?color=blue&style=flat-square">
  </a>
  <a href="https://github.com/mahi-cyberaware/AdvSophish">
    <img src="https://img.shields.io/github/stars/mahi-cyberaware/AdvSophish?style=flat-square">
  </a>
  <a href="https://github.com/mahi-cyberaware/AdvSophish/issues">
    <img src="https://img.shields.io/github/issues/mahi-cyberaware/AdvSophish?color=red&style=flat-square">
  </a>
  <img src="https://img.shields.io/badge/Version-3.2.0-green?style=flat-square">
  <img src="https://img.shields.io/badge/Author-mahi--cyberaware-blue?style=flat-square">
</p>

---

## ⚠️ Legal Disclaimer
**This tool is for educational and authorised penetration testing only.**  
The author (`mahi-cyberaware`) is **not responsible** for any misuse or illegal activity.  
By using AdvSophish, you agree that you will comply with all applicable laws.

---

## 🚀 Features
- **Two‑stage phishing** – captures username/password **and** OTP (2FA) codes.
- **35+ realistic templates** – each with original brand colors, logos, and modern UI (auto‑generated).
- **Graphical dashboard** – view, export, and clear captured data at `http://127.0.0.1:8081`.
- **URL obfuscation** – automatic shortening (is.gd / tinyurl) and optional custom masking.
- **Three tunneling options** – Localhost, Cloudflared, LocalXpose.
- **Cross‑platform** – Termux, Kali Linux, Ubuntu, Debian, Arch, Fedora.
- **Zero configuration** – all templates are generated on first run.

---

## 📦 Installation

### From source (Linux / Termux / macOS)
```bash
git clone https://github.com/mahi-cyberaware/AdvSophish.git
cd AdvSophish
bash AdvSophish.sh
