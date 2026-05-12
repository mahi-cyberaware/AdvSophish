<!-- AdvSophish – Advanced Phishing Framework (Educational) -->

<p align="center">
  <img src="logo.png" alt="AdvSophish Logo" width="220">
</p>

<h1 align="center">AdvSophish</h1>

<p align="center">
  <strong>Advanced Phishing Framework for Security Awareness & Authorised Penetration Testing</strong><br>
  <em>Educational use only • Dashboard • 2FA Capture Simulation • Browser Permission Demonstration</em>
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

  <img src="https://img.shields.io/badge/version-3.2.0-green?style=flat-square">
  <img src="https://img.shields.io/badge/platform-linux%20%7C%20termux%20%7C%20macos-blue?style=flat-square">
  <img src="https://img.shields.io/badge/author-mahi--cyberaware-cyan?style=flat-square">
</p>

---

# ⚠️ Legal Disclaimer

**AdvSophish is strictly developed for educational demonstrations, cybersecurity awareness training, and authorised penetration testing.**

The developer and contributors are **not responsible** for misuse, illegal activity, unauthorised targeting, credential theft, or any violation of local/international cybercrime laws.

By using this project, you agree that:

- You will use it only in lab environments or with explicit permission.
- You understand the legal implications of phishing simulations.
- You accept full responsibility for your actions.

---

# 🚀 Features

- **Two-stage credential simulation**
  - Captures username/password and OTP (2FA) flows for awareness demonstrations.

- **35+ realistic templates**
  - Modern login pages with brand styling, responsive layouts, and dynamic rendering.

- **Permission request simulation**
  - Templates can request browser permissions such as:
    - 📍 Location
    - 🎤 Microphone
    - 📷 Camera

- **Rich victim environment information**
  - Collects:
    - IP Address
    - User-Agent
    - Device Type
    - Browser Information
    - Operating System
    - Screen Resolution
    - Language & Timezone
    - Geolocation (if allowed)

- **Graphical dashboard**
  - Web-based panel for:
    - Viewing captured logs
    - Exporting results
    - Clearing sessions
    - Monitoring activity

- **URL obfuscation**
  - Automatic shortening using:
    - is.gd
    - tinyurl
  - Optional custom masking support.

- **Multiple tunneling options**
  - Localhost
  - Cloudflared
  - LocalXpose

- **Cross-platform support**
  - Kali Linux
  - Ubuntu
  - Debian
  - Fedora
  - Arch Linux
  - Termux
  - macOS

- **Zero configuration**
  - Templates auto-generate during first launch.

- **Professional CLI interface**
  - Hacker-style animated terminal UI with colored output and dependency checks.

---

# 📸 Dashboard Preview

```text
http://127.0.0.1:8081
```

Dashboard capabilities include:

- Live captured session monitoring
- Credential logs
- OTP logs
- Device analytics
- Permission status tracking
- Export & cleanup options

---

# 📦 Installation

## Linux / Kali / Ubuntu / Debian / Arch

```bash
git clone https://github.com/mahi-cyberaware/AdvSophish.git

cd AdvSophish

chmod +x AdvSophish.sh

bash AdvSophish.sh
```

---

## Termux Installation

```bash
pkg update && pkg upgrade -y

pkg install git php curl wget proot tar -y

git clone https://github.com/mahi-cyberaware/AdvSophish.git

cd AdvSophish

chmod +x AdvSophish.sh

bash AdvSophish.sh
```

---

# 🌐 Tunneling Options

AdvSophish supports secure external exposure using:

| Tunnel Service | Supported |
|----------------|-----------|
| Cloudflared | ✅ |
| LocalXpose | ✅ |
| Localhost | ✅ |

---

# 🛠 Requirements

Required dependencies:

- bash
- php
- curl
- wget
- unzip
- tar

Most dependencies install automatically during startup.

---

# 🔐 Educational Use Cases

This project can be used for:

- Cybersecurity awareness training
- Red team 
- Security workshops
- Browser permission 
- Phishing detection 
- Social engineering

---

# 🚫 Prohibited Usage

You must NOT use this framework for:

- Unauthorised phishing
- Credential theft
- Financial fraud
- Malware delivery
- Real-world illegal targeting

Violation of laws may result in criminal prosecution.

---

# 🤝 Contributing

Pull requests, feature suggestions, and security improvements are welcome.

```bash
# Fork repository
# Create feature branch
# Commit changes
# Open pull request
```

---

# ⭐ Support

If you found this project useful for educational research:

- ⭐ Star the repository
- 🍴 Fork the project
- 🛡 Share responsibly

---

# 📜 License

Licensed under the GPL-3.0 License.

See:

```text
LICENSE
```

---

# 👨‍💻 Author

### mahi-cyberaware

- GitHub: https://github.com/mahi-cyberaware

---

<p align="center">
  <strong>AdvSophish • Security Awareness Through Practical Demonstration</strong>
</p>
