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
DESKTOP_DIR=~/Desktop
PAYLOADS_DIR=~/payloads 
echo "* RECON ----------------"

for domain in $domains; do
    TARGET_RECON_DIR="$DESKTOP_DIR/$domain/recon"
    mkdir -p "$TARGET_RECON_DIR"
    cd "$TARGET_RECON_DIR"

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

    # 6. Crawling & URL Gathering
    echo "[*] hakrawler..."
    cat http_subdomain.txt https_subdomain.txt | hakrawler > hakrawler.txt

    echo "[*] katana..."
    katana -list http_subdomain.txt -o katana.txt

    echo "[*] waybackurls..."
    cat http_subdomain.txt https_subdomain.txt | waybackurls > waybackurls.txt

    echo "[*] gau..."
    cat http_subdomain.txt https_subdomain.txt | gau > gau.txt

    echo "[*] dirsearch..."
    python3 "$TOOLS_DIR/dirsearch/dirsearch.py" -u "$(head -n 1 http_subdomain.txt)" -e * -o dirsearch.txt --format plain

    # 7. Tổng hợp URL, lọc trùng, gom nhóm
    cat hakrawler.txt katana.txt waybackurls.txt gau.txt ffuf.txt wfuzz.txt dirsearch.txt 2>/dev/null | \
        grep -Eo 'https?://[^ ]+' | sort -u > all_url_raw.txt

    # Lọc lại qua httpx
    echo "[*] Lọc lại URL qua httpx..."
    httpx -l all_url_raw.txt -o all_url_httpx.txt -silent

    # Lọc lại qua httprobe
    echo "[*] Lọc lại URL qua httprobe..."
    cat all_url_raw.txt | httprobe > all_url_httprobe.txt

    # Tổng hợp kết quả đã lọc
    cat all_url_httpx.txt all_url_httprobe.txt | sort -u > all_url.txt

    echo "[*] Gom nhóm các URL gần giống nhau..."
    awk -F/ '{
        domain=$3;
        path="/"$4"/"$5"/"$6;
        group[domain path] = group[domain path] ? group[domain path] ORS $0 : $0
    }
    END {
        for (g in group) {
            print "# Group: " g;
            print group[g] "\n";
        }
    }' all_url.txt > all_url_grouped.txt

    echo "[*] Recon done for $domain. Kết quả lưu tại $TARGET_RECON_DIR"
done