#!/bin/zsh
if ! grep -q "alias auto_scan=" ~/.zshrc; then
    echo "alias auto_scan='zsh ~/tools/auto_scan.sh'" >> ~/.zshrc
fi
usage() {
    echo "Usage:"
    echo "  auto_scan -u example.com"
    echo "  auto_scan -d url_list.txt"
    exit 1
}

if [[ "$1" == "-u" ]]; then
    domains=($2)
elif [[ "$1" == "-d" ]]; then
    domains=($(<"$2"))
else
    usage
fi

TOOLS_DIR=~/tools
RECONS_DIR=~/recons
mkdir -p "$RECONS_DIR"

for domain in $domains; do
    TARGET_DIR="$RECONS_DIR/$domain"
    mkdir -p "$TARGET_DIR"
    cd "$TARGET_DIR"

    # 1. Subdomain Enumeration
    echo "[*] subfinder..."
    subfinder -d "$domain" -silent -all -o subfinder.txt

    echo "[*] assetfinder..."
    assetfinder --subs-only "$domain" > assetfinder.txt

    echo "[*] findomain..."
    findomain -t "$domain" -u findomain.txt

    echo "[*] shuffledns..."
    shuffledns -d "$domain" -list "$TOOLS_DIR/wordlists/all.txt" -o shuffledns.txt 2>/dev/null

    echo "[*] puredns..."
    puredns subdomain "$domain" --resolvers "$TOOLS_DIR/resolvers.txt" -w "$TOOLS_DIR/wordlists/all.txt" -o puredns.txt 2>/dev/null

    # 2. DNS Tools
    echo "[*] dnsx..."
    dnsx -l subfinder.txt -o dnsx.txt

    echo "[*] massdns..."
    massdns -r "$TOOLS_DIR/resolvers.txt" -t A -o S -w massdns.txt subfinder.txt

    echo "[*] dnsdumpster..."
    python3 "$TOOLS_DIR/dnsdumpster/dnsdumpster.py" "$domain" > dnsdumpster.txt

    # 3. crt.sh
    echo "[*] crt.sh..."
    curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\\n/\n/g' | sort -u > crtsh.txt

    # 4. Tổng hợp subdomain, lọc trùng
    cat subfinder.txt assetfinder.txt findomain.txt shuffledns.txt puredns.txt crtsh.txt dnsx.txt massdns.txt dnsdumpster.txt 2>/dev/null | \
        grep -E "^[a-zA-Z0-9.-]+$" | sed 's/^\\*\\.//' | sort -u > subdomain.txt

    # 5. Lọc http/https
    echo "[*] httpx..."
    httpx -l subdomain.txt -o httpx_all.txt -silent

    grep '^http://' httpx_all.txt | cut -d' ' -f1 | sort -u > http_subdomain.txt
    grep '^https://' httpx_all.txt | cut -d' ' -f1 | sort -u > https_subdomain.txt

    echo "[*] httprobe..."
    cat subdomain.txt | httprobe > httprobe_all.txt

    grep '^http://' httprobe_all.txt | cut -d' ' -f1 | sort -u >> http_subdomain.txt
    grep '^https://' httprobe_all.txt | cut -d' ' -f1 | sort -u >> https_subdomain.txt

    sort -u -o http_subdomain.txt http_subdomain.txt
    sort -u -o https_subdomain.txt https_subdomain.txt

    echo "[*] Done for $domain. Kết quả lưu tại $TARGET_DIR"
done