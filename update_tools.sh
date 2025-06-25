#!/bin/zsh

# ===========================
# TOOLSET UPDATE SCRIPT
# ===========================
# 1. Subdomain Enumeration:
#    - subfinder, assetfinder, findomain, shuffledns, puredns
# 2. DNS Tools:
#    - dnsx, massdns, dnsdumpster
# 3. HTTP/Web Tools:
#    - httpx, httprobe, hakrawler, katana, waybackurls, gau, ffuf, wfuzz, whatweb, nikto, dirsearch, Corsy, CRLF-Injection-Scanner, smuggles, XSStrike, dalfox, sqlmap, arjun
# 4. Vulnerability Scanners:
#    - nuclei, wpscan, CMSeeK
# 5. Source Code Security:
#    - github-dorks, SecretFinder, trufflehog, gitleaks
# 6. 403 Bypass:
#    - bypass-403, nomore403, 4-ZERO-3
# 7. Support/Dependency:
#    - ruby-full, python3-pip, git, curl, unzip, pipx
# ===========================

TOOLS_DIR=~/tools
ZSHRC=~/.zshrc

# --- GO TOOLS UPDATE ---
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
    [github-dorks]="github.com/hahwul/github-dorks@latest"
    [shuffledns]="github.com/projectdiscovery/shuffledns@latest"
    [smuggles]="github.com/danielthatcher/smuggles@latest"
    [dalfox]="github.com/hahwul/dalfox/v2@latest"
)
for tool in ${(k)go_tools}; do
    echo "[*] Update $tool (Go)..."
    go install $go_tools[$tool]
done

# --- NUCLEI TEMPLATES UPDATE ---
echo "[*] Update nuclei templates..."
nuclei -update-templates

# --- APT TOOLS UPDATE ---
echo "[*] Update các tool cài qua apt..."
sudo apt update
apt_tools=(ffuf wfuzz whatweb ruby-full python3-pip nikto git curl unzip pipx)
sudo apt install --only-upgrade -y $apt_tools

# --- RUBY GEM TOOLS UPDATE ---
echo "[*] Update wpscan (gem)..."
sudo gem update wpscan

# --- PYTHON TOOLS (CLONE) UPDATE ---
python_tools=(
    "CMSeeK|requirements.txt"
    "dirsearch|"
    "SecretFinder|requirements.txt"
    "Corsy|requirements.txt"
    "CRLF-Injection-Scanner|requirements.txt"
    "dnsdumpster|requirements.txt"
    "XSStrike|requirements.txt"
    "sqlmap|"
)
for entry in $python_tools; do
    IFS='|' read -r dir req <<< "$entry"
    if [ -d "$TOOLS_DIR/$dir/.git" ]; then
        echo "[*] Update $dir (git)..."
        git -C "$TOOLS_DIR/$dir" pull
        if [ -n "$req" ] && [ -f "$TOOLS_DIR/$dir/$req" ]; then
            pip3 install --upgrade -r "$TOOLS_DIR/$dir/$req"
        fi
    fi
done

# --- PIPX TOOLS UPDATE ---
pipx_tools=(trufflehog arjun)
for tool in $pipx_tools; do
    echo "[*] Update $tool (pipx)..."
    pipx upgrade $tool
done

# --- GITLEAKS UPDATE ---
echo "[*] Update gitleaks..."
latest_url=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep "browser_download_url.*linux_amd64" | cut -d '"' -f 4)
wget -q $latest_url -O gitleaks
chmod +x gitleaks
mv gitleaks "$TOOLS_DIR/"
sudo ln -sf "$TOOLS_DIR/gitleaks" /usr/local/bin/gitleaks

# --- FINDOMAIN UPDATE ---
echo "[*] Update findomain..."
wget -q https://github.com/findomain/findomain/releases/latest/download/findomain-linux.zip -O findomain-linux.zip
unzip -q -o findomain-linux.zip
chmod +x findomain
mv findomain "$TOOLS_DIR/"
rm findomain-linux.zip

# --- BYPASS 403 TOOLS UPDATE ---
bypass_tools=(bypass-403 nomore403 4-ZERO-3)
for dir in $bypass_tools; do
    if [ -d "$TOOLS_DIR/$dir/.git" ]; then
        echo "[*] Update $dir (git)..."
        git -C "$TOOLS_DIR/$dir" pull
    fi
done

# --- MASSDNS BUILD ---
if [ -d "$TOOLS_DIR/massdns/.git" ]; then
    echo "[*] Build lại massdns nếu có thay đổi..."
    cd "$TOOLS_DIR/massdns" && make && sudo make install
    cd "$TOOLS_DIR"
fi

echo "[*] Đã update xong toàn bộ tool!"