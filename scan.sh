#!/bin/zsh
source "$TOOLS_DIR/include.sh"

if ! grep -q "alias auto_scan=" "$ZSHRC"; then
    echo "alias auto_scan='zsh $TOOLS_DIR/scan.sh'" >> "$ZSHRC"
fi
usage() {
    echo "Usage:"
    echo "  scan -u example.com"
    echo "  scan -i url_list.txt"
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
NAME_PROJECT="${domains[1]%%.*}"
for domain in $domains; do
    TARGET_RECON_DIR="$DESKTOP_DIR/$NAME_PROJECT/$domain/recon"
    TARGET_SCAN_DIR="$DESKTOP_DIR/$NAME_PROJECT/$domain/scan"
    HTTPROBE="$TARGET_RECON_DIR/httprobe.txt"

    corsy -i "$HTTPROBE" -o "$TARGET_SCAN_DIR/corsy.txt"
    crlfscanner scan -i "$HTTPROBE" -o "$TARGET_SCAN_DIR/crlfscanner.txt"
    # cat "$HTTPROBE" | smuggles >> "$TARGET_SCAN_DIR/smuggles.txt"
    # --- PATH TRAVERSAL ---
    # if [ ! -d "$TARGET_SCAN_DIR/ffuf" ]; then
    #     mkdir -p "$TARGET_SCAN_DIR/ffuf"
    # fi
    # cat "$HTTPROBE" | while read url; do
    #     ffuf -w "$PAYLOADS_DIR/SecLists/Fuzzing/LFI/LFI-Jhaddix.txt" \
    #         -u "${url}?file=FUZZ" \
    #         -of csv \
    #         -o "$TARGET_SCAN_DIR/ffuf/temp.csv" \
    #         -mc all,-404
    # done
    
done
