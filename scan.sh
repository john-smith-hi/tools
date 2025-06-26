#!/bin/zsh
source "$TOOLS_DIR/include.sh"

usage() {
    echo "Usage:"
    echo "  auto_scan -u example.com"
    echo "  auto_scan -i url_list.txt"
    exit 1
}

if [[ "$1" == "-u" ]]; then
    domains=($2)
elif [[ "$1" == "-i" ]]; then
    domains=($(<"$2"))
else
    usage
fi

echo "* SCAN ----------------"
NAME_PROJECT="${domains[0]%%.*}"
for domain in $domains; do
    TARGET_RECON_DIR="$DESKTOP_DIR/$NAME_PROJECT/$domain/recon"
    TARGET_SCAN_DIR="$DESKTOP_DIR/$NAME_PROJECT/$domain/scan"
    HTTP_SUBDOMAIN="$TARGET_RECON_DIR/http_subdomain.txt"

    corsy -i "$HTTP_SUBDOMAIN" -o "$TARGET_SCAN_DIR/corsy.txt"
    crlfscanner scan -i "$HTTP_SUBDOMAIN" -o "$TARGET_SCAN_DIR/crlfscanner.txt"
    # --- NUCLEI & NIKTO SCAN ---
    mkdir -p "$TARGET_SCAN_DIR/nuclei" "$TARGET_SCAN_DIR/nikto"
    while read url; do
        subdomain=$(echo "$url" | awk -F/ '{print $3}')
        [ -z "$subdomain" ] && subdomain=$(echo "$url" | sed 's|https\?://||')
        # Nuclei scan
        nuclei -u "$url" -o "$TARGET_SCAN_DIR/nuclei/${subdomain}.txt"
        # Nikto scan
        nikto -h "$url" -output "$TARGET_SCAN_DIR/nikto/${subdomain}.txt" -Format txt
    done < "$HTTP_SUBDOMAIN"

    # --- REQUEST SMUGGLING ---
    mkdir -p "$TARGET_SCAN_DIR/request_smuggling"
    while read url; do
        subdomain=$(echo "$url" | awk -F/ '{print $3}')
        if [ -z "$subdomain" ]; then subdomain=$(echo "$url" | sed 's|https\?://||'); fi
        smuggles "$url" > "$TARGET_SCAN_DIR/request_smuggling/${subdomain}.txt"
    done < "$HTTP_SUBDOMAIN"

    # --- DIRECTORY TRAVERSAL ---
    mkdir -p "$TARGET_SCAN_DIR/directory_traversal"
    while read url; do
        subdomain=$(echo "$url" | awk -F/ '{print $3}')
        if [ -z "$subdomain" ]; then subdomain=$(echo "$url" | sed 's|https\?://||'); fi
        ffuf -w "$PAYLOADS_DIR/SecLists/Fuzzing/LFI/LFI-Jhaddix.txt" \
            -u "${url}?file=FUZZ" \
            -of csv \
            -o "$TARGET_SCAN_DIR/directory_traversal/${subdomain}.csv" \
            -mc all,-404
    done < "$HTTP_SUBDOMAIN"

    echo "[*] Scan done for $domain. Results saved at $TARGET_SCAN_DIR"
done