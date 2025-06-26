#!/bin/zsh

# ===========================
# TOOLSET UPDATE SCRIPT
# ===========================
# 1. Subdomain Enumeration:
#    - subfinder, assetfinder, findomain, shuffledns, puredns
# 2. DNS Tools:
#    - dnsx, massdns, dnsdumpster
# 3. HTTP/Web Tools:
#    - httprobe, hakrawler, katana, waybackurls, gau, ffuf, wfuzz, whatweb, nikto, dirsearch, Corsy, CRLF-Injection-Scanner, smuggles
# 4. Vulnerability Scanners:
#    - nuclei, wpscan, CMSeeK
# 5. Source Code Security:
#    - SecretFinder, trufflehog, gitleaks
# 6. 403 Bypass:
#    - bypass-403, nomore403, 4-ZERO-3
# 7. Support/Dependency:
#    - ruby-full, python3-pip, git, curl, unzip, pipx, jq
# 8. Payloads:
#   - Seclists
# ===========================

TOOLS_DIR=~/tools
ZSHRC=~/.zshrc
PAYLOADS_DIR=~/payloads

echo "* Update các tool Go..."
declare -A go_tools=(
    [subfinder]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    [assetfinder]="github.com/tomnomnom/assetfinder@latest"
    [dnsx]="github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    [puredns]="github.com/d3mondev/puredns/v2@latest"
    [httpx]="github.com/projectdiscovery/httpx/cmd/httpx@latest"
    [httprobe]="github.com/tomnomnom/httprobe@latest"
    [gau]="github.com/lc/gau/v2/cmd/gau@latest"
    [hakrawler]="github.com/hakluke/hakrawler@latest"
    [katana]="github.com/projectdiscovery/katana/cmd/katana@latest"
    [waybackurls]="github.com/tomnomnom/waybackurls@latest"
    [nuclei]="github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    [shuffledns]="github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest"
    [smuggles]="github.com/danielthatcher/smuggles@latest"
    [dalfox]="github.com/hahwul/dalfox/v2@latest"
)
for tool in ${(k)go_tools}; do
    echo "* Update $tool (Go)..."
    go install "${go_tools[$tool]}"
done

echo "* Update nuclei templates..."
nuclei -update-templates

echo "* Update các tool cài qua apt..."
sudo apt update
apt_tools=(ffuf wfuzz whatweb ruby-full python3-pip nikto git curl unzip pipx jq)
for tool in $apt_tools; do
    echo "* Update $tool (apt)..."
    sudo apt install --only-upgrade -y $tool
done

echo "* Update wpscan (gem)..."
sudo gem update wpscan

clone_and_pull() {
    local dir=$1
    local req=$2
    if [ -d "$TOOLS_DIR/$dir/.git" ]; then
        echo "* Update $dir (git)..."
        git -C "$TOOLS_DIR/$dir" pull
        if [ -n "$req" ] && [ -f "$TOOLS_DIR/$dir/$req" ]; then
            pip3 install --break-system-packages --upgrade -r "$TOOLS_DIR/$dir/$req"
        elif [ -f "$TOOLS_DIR/$dir/setup.py" ]; then
            python3 "$TOOLS_DIR/$dir/setup.py" install
        fi
    fi
}

echo "* Update các tool Python (git clone)..."
clone_and_pull "CMSeeK" "requirements.txt"
clone_and_pull "dirsearch" ""
clone_and_pull "SecretFinder" "requirements.txt"
clone_and_pull "Corsy" "requirements.txt"
clone_and_pull "CRLF-Injection-Scanner" ""
clone_and_pull "dnsdumpster" ""
clone_and_pull "XSStrike" "requirements.txt"
clone_and_pull "sqlmap" ""

echo "* Update các tool pipx..."
pipx_tools=(trufflehog arjun)
for tool in $pipx_tools; do
    echo "* Update $tool (pipx)..."
    pipx upgrade $tool
done

echo "* Update gitleaks..."
GITLEAKS_SRC="$TOOLS_DIR/gitleaks-src"
GITLEAKS_BIN="$TOOLS_DIR/gitleaks"
if [ -d "$GITLEAKS_SRC/.git" ]; then
    cd "$GITLEAKS_SRC"
    git pull
    make build
    cp ./gitleaks "$GITLEAKS_BIN"
    chmod +x "$GITLEAKS_BIN"
    sudo ln -sf "$GITLEAKS_BIN" /usr/local/bin/gitleaks
    cd "$TOOLS_DIR"
else
    git clone https://github.com/gitleaks/gitleaks.git "$GITLEAKS_SRC"
    cd "$GITLEAKS_SRC"
    make build
    cp ./gitleaks "$GITLEAKS_BIN"
    chmod +x "$GITLEAKS_BIN"
    sudo ln -sf "$GITLEAKS_BIN" /usr/local/bin/gitleaks
    cd "$TOOLS_DIR"
fi

echo "* Update findomain..."
wget -q https://github.com/findomain/findomain/releases/latest/download/findomain-linux.zip -O findomain-linux.zip
unzip -q -o findomain-linux.zip
chmod +x findomain
mv findomain "$TOOLS_DIR/"
rm findomain-linux.zip
grep -qxF "alias findomain='~/tools/findomain'" "$ZSHRC" || echo "alias findomain='~/tools/findomain'" >> "$ZSHRC"

echo "* Update các tool bypass 403..."
bypass_tools=(bypass-403 nomore403 4-ZERO-3)
for dir in $bypass_tools; do
    if [ -d "$TOOLS_DIR/$dir/.git" ]; then
        echo "* Update $dir (git)..."
        git -C "$TOOLS_DIR/$dir" pull
    fi
done

echo "* Build lại massdns nếu có thay đổi..."
if [ -d "$TOOLS_DIR/massdns/.git" ]; then
    cd "$TOOLS_DIR/massdns" && make && sudo make install
    cd "$TOOLS_DIR"
fi

echo "* Update SecLists payloads..."
if [ -d "$PAYLOADS_DIR/SecLists/.git" ]; then
    cd "$PAYLOADS_DIR/SecLists" && git pull
else
    git clone https://github.com/danielmiessler/SecLists.git "$PAYLOADS_DIR/SecLists"
fi

echo "* Đã update xong toàn bộ tool!"