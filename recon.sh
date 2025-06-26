#!/bin/zsh
source "$TOOLS_DIR/include.sh"

usage() {
    echo "Usage:"
    echo "  auto_recon -u example.com"
    echo "  auto_recon -i url_list.txt"
    exit 1
}

if [[ "$1" == "-u" ]]; then
    domains=($2)
elif [[ "$1" == "-i" ]]; then
    domains=($(<"$2"))
else
    usage
fi

echo "* RECON ----------------"
# 1 project can have multiple initial domains
NAME_PROJECT="${domains[1]%%.*}"
for domain in $domains; do
    TARGET_RECON_DIR="$DESKTOP_DIR/$NAME_PROJECT/$domain/recon"
    rm -rf "$TARGET_RECON_DIR"
    mkdir -p "$TARGET_RECON_DIR"
    # Specify recon folder to save results
    cd "$TARGET_RECON_DIR"

    # Subdomain Enumeration
    echo "[*] subfinder..."
    subfinder -d "$domain" -silent -all -o subfinder.txt

    echo "[*] assetfinder..."
    assetfinder --subs-only "$domain" > assetfinder.txt

    echo "[*] findomain..."
    findomain -t "$domain" -u findomain.txt

    echo "[*] shuffledns..."
    shuffledns -d "$domain" -list "$TOOLS_DIR/wordlists/all.txt" -o shuffledns.txt

    echo "[*] puredns..."
    puredns subdomain "$domain" --resolvers "$TOOLS_DIR/resolvers.txt" -w "$TOOLS_DIR/wordlists/all.txt" -o puredns.txt

    # DNS Tools
    echo "[*] dnsx..."
    dnsx -l subfinder.txt -o dnsx.txt

    # crt.sh
    echo "[*] crt.sh..."
    curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\\n/\n/g' | sort -u > crtsh.txt

    # Aggregate subdomains and deduplicate
    cat subfinder.txt assetfinder.txt findomain.txt shuffledns.txt puredns.txt crtsh.txt dnsx.txt massdns.txt | \
        grep -E "^[a-zA-Z0-9.-]+$" | sed 's/^\\*\\.//' | sort -u > subdomain.txt

    # Filter http/https
    echo "[*] httprobe..."
    cat subdomain.txt | httprobe > httprobe.txt

    grep '^http://' httprobe.txt | cut -d' ' -f1 | sort -u > http_subdomain.txt
    grep '^https://' httprobe.txt | cut -d' ' -f1 | sort -u > https_subdomain.txt

    sort -u -o http_subdomain.txt http_subdomain.txt
    sort -u -o https_subdomain.txt https_subdomain.txt

    # FFUF scan for status codes
    # If ffuf directory exists, remove before creating new
    TARGET_FFUF_DIR="$TARGET_RECON_DIR/ffuf"
    mkdir -p "$TARGET_FFUF_DIR"

    # Scan links in httprobe.txt, save each status code to corresponding file
    if [[ -s "httprobe.txt" ]]; then
        ffuf -w httprobe.txt:URL -u FUZZ -mc all -of csv -o "$TARGET_FFUF_DIR/ffuf.csv" -t 50 -replay-proxy "" -request-proto http
        # Categorize by status code
        awk -F',' 'NR>1 {print $2 >> "'$TARGET_FFUF_DIR'/"$5".txt"}' "$TARGET_FFUF_DIR/ffuf.csv"
    fi

    # Delete all files except subdomain.txt, http_subdomain.txt, https_subdomain.txt, httprobe.txt
    find . -maxdepth 1 -type f ! -name 'subdomain.txt' ! -name 'http_subdomain.txt' ! -name 'https_subdomain.txt' ! -name 'httprobe.txt' -delete

    # Crawling & URL Gathering
    echo "[*] dirsearch..."
    python3 "$TOOLS_DIR/dirsearch/dirsearch.py" -u "$(head -n 1 httprobe.txt)" -e * -o dirsearch.txt --format plain

    echo "[*] hakrawler..."
    cat httprobe.txt | hakrawler > hakrawler.txt

    echo "[*] katana..."
    katana -list httprobe.txt -o katana.txt

    echo "[*] gau..."
    cat httprobe.txt | gau > gau.txt

    # Aggregate, deduplicate, and group URLs
    echo "[*] Sorting, deduplicating, aggregating URLs..."
    cat hakrawler.txt katana.txt gau.txt dirsearch.txt 2>/dev/null | \
        grep -Eo 'https?://[^ ]+' | sort -u > all_url.txt

    # Sensitive Data Discovery
    echo "[*] Filtering sensitive data..."
    cat all_url.txt | grep -Ei '\.(php|asp|aspx|jsp|html?|txt|json|xml|log|conf|cfg|ini|sql|bak|old|zip|tar|gz|7z|rar|db|sqlite|csv|xls|xlsx|doc|docx|pdf|env|yaml|yml)$' | sort -u > sensitive_url.txt

    # JS Secrets Discovery
    echo "[*] Searching for secrets in JS files..."
    cat all_url.txt | grep '\.js$' | while read -r js; do
        secretfinder -i $js -o cli >> js_secret.txt
    done

    # Grouping URLs
    echo "[*] Grouping similar URLs..."
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

    echo "[*] Recon done for $domain. Results saved