#!/bin/zsh

# ===========================
# TOOLSET INSTALL SCRIPT
# ===========================
# 1. Subdomain Enumeration:
#    - subfinder, assetfinder, findomain, shuffledns, puredns
# 2. DNS Tools:
#    - dnsx, massdns
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

source "$TOOLS_DIR/include.sh"

# --- GO ENVIRONMENT ---
echo "* Checking and installing Go if needed..."
if ! command -v go &> /dev/null; then
    wget -q https://go.dev/dl/go1.22.3.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz
    rm -f go1.22.3.linux-amd64.tar.gz
    grep -qxF 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' "$ZSHRC" || echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$ZSHRC"
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
fi

# --- GO TOOLS ---
echo "* Installing Go-based tools..."
declare -A go_tools=(
    [subfinder]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    [assetfinder]="github.com/tomnomnom/assetfinder@latest"
    [dnsx]="github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    [puredns]="github.com/d3mondev/puredns/v2@latest"
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
    if ! command -v $tool &> /dev/null; then
        go install "${go_tools[$tool]}"
    else
        echo "$tool is already installed"
    fi
    mkdir -p "$TOOLS_DIR/$tool"
done

# --- APT TOOLS ---
echo "* Installing additional support tools..."
sudo apt update
apt_tools=(ffuf wfuzz whatweb ruby-full python3-pip nikto git curl unzip pipx jq findomain)
for tool in $apt_tools; do
    if ! command -v $tool &> /dev/null && ! dpkg -s $tool &> /dev/null; then
        sudo apt install -y $tool
    else
        echo "$tool is already installed"
    fi
    mkdir -p "$TOOLS_DIR/$tool"
done

# --- RUBY GEM TOOLS ---
echo "* Installing wpscan..."
if ! command -v wpscan &> /dev/null; then
    sudo gem install wpscan
else
    echo "wpscan is already installed"
fi
mkdir -p "$TOOLS_DIR/wpscan"

# --- CLONE & ALIAS FUNCTION ---
clone_and_alias() {
    local repo=$1
    local dir=$2
    local alias_name=$3
    local cmd=$4
    if [ ! -d "$TOOLS_DIR/$dir" ]; then
        git clone "$repo" "$TOOLS_DIR/$dir"
        [ -n "$cmd" ] && grep -qxF "$cmd" "$ZSHRC" || echo "$cmd" >> "$ZSHRC"
        return 0    # freshly cloned, need to install requirements
    else
        echo "$dir is already installed"
        return 1    # already cloned, no need to install requirements
    fi
}

# CMSeeK
echo "* Installing CMSeeK..."
if clone_and_alias "https://github.com/Tuhinshubhra/CMSeeK.git" "CMSeeK" "cmseek" "alias cmseek='python3 ~/tools/CMSeeK/cmseek.py'"; then
    pip3 install --break-system-packages -r "$TOOLS_DIR/CMSeeK/requirements.txt"
fi

# dirsearch (no pip needed)
echo "* Installing dirsearch..."
clone_and_alias "https://github.com/maurosoria/dirsearch.git" "dirsearch" "dirsearch" "alias dirsearch='python3 ~/tools/dirsearch/dirsearch.py'"

# SecretFinder
echo "* Installing SecretFinder..."
if clone_and_alias "https://github.com/m4ll0k/SecretFinder.git" "SecretFinder" "secretfinder" "alias secretfinder='python3 ~/tools/SecretFinder/SecretFinder.py'"; then
    pip3 install --break-system-packages -r "$TOOLS_DIR/SecretFinder/requirements.txt"
fi

# Corsy
echo "* Installing Corsy..."
if clone_and_alias "https://github.com/s0md3v/Corsy.git" "Corsy" "corsy" "alias corsy='python3 ~/tools/Corsy/corsy.py'"; then
    pip3 install --break-system-packages -r "$TOOLS_DIR/Corsy/requirements.txt"
fi

# CRLF-Injection-Scanner
echo "* Installing CRLF-Injection-Scanner..."
if clone_and_alias "https://github.com/MichaelStott/CRLF-Injection-Scanner.git" "CRLF-Injection-Scanner" "crlfscanner" "alias crlfscanner='python3 ~/tools/CRLF-Injection-Scanner/crlf.py'"; then
    python3 "$TOOLS_DIR/CRLF-Injection-Scanner/setup.py" install
fi

# XSStrike
echo "* Installing XSStrike..."
if clone_and_alias "https://github.com/s0md3v/XSStrike.git" "XSStrike" "xsstrike" "alias xsstrike='python3 ~/tools/XSStrike/xsstrike.py'"; then
    pip3 install --break-system-packages -r "$TOOLS_DIR/XSStrike/requirements.txt"
fi

# sqlmap (no pip needed)
echo "* Installing sqlmap..."
clone_and_alias "https://github.com/sqlmapproject/sqlmap.git" "sqlmap" "sqlmap" "alias sqlmap='python3 ~/tools/sqlmap/sqlmap.py'"

# --- TRUFFLEHOG (pipx) ---
echo "* Installing truffleHog..."
if ! command -v trufflehog &> /dev/null; then
    pipx install trufflehog
else
    echo "trufflehog is already installed"
fi
mkdir -p "$TOOLS_DIR/trufflehog"

# --- GITLEAKS (BINARY) ---
echo "* Installing Gitleaks..."
if ! command -v gitleaks &> /dev/null; then
    # Source and binary directories

    # Remove old source if exists
    [ -d "$GITLEAKS_SRC" ] && rm -rf "$GITLEAKS_SRC"
    [ -f "$GITLEAKS_BIN" ] && rm -f "$GITLEAKS_BIN"
    [ -d "$GITLEAKS_BIN" ] && rm -rf "$GITLEAKS_BIN"

    # Clone Gitleaks source
    git clone https://github.com/gitleaks/gitleaks.git "$GITLEAKS_SRC"

    # Build Gitleaks
    cd "$GITLEAKS_SRC"
    make build

    # Copy binary to tools directory and set permission
    cp ./gitleaks "$GITLEAKS_BIN"
    chmod +x "$GITLEAKS_BIN"

    # Create symlink to /usr/local/bin
    sudo ln -sf "$GITLEAKS_BIN" /usr/local/bin/gitleaks

    # Return to tools directory
    cd "$TOOLS_DIR"
else
    echo "gitleaks is already installed"
fi

# --- BYPASS 403 TOOLS ---
echo "[*] Installing bypass 403 tools..."
clone_and_alias "https://github.com/iamj0ker/bypass-403.git" "bypass-403" "bypass403" "alias bypass403='bash ~/tools/bypass-403/bypass-403.sh'"
clone_and_alias "https://github.com/devploit/nomore403.git" "nomore403" "nomore403" "alias nomore403='bash ~/tools/nomore403/nomore403.sh'"
clone_and_alias "https://github.com/Dheerajmadhukar/4-ZERO-3.git" "4-ZERO-3" "zero403" "alias zero403='bash ~/tools/4-ZERO-3/403.sh'"

# --- MASSDNS ---
echo "[*] Installing massdns..."
if [ ! -d "$TOOLS_DIR/massdns" ]; then
    git clone https://github.com/blechschmidt/massdns.git "$TOOLS_DIR/massdns"
    cd "$TOOLS_DIR/massdns" && make && sudo make install
else
    echo "massdns is already installed"
fi

echo "* Installing arjun (pipx)..."
if ! command -v arjun &> /dev/null; then
    pipx install arjun
else
    echo "arjun is already installed"
fi
mkdir -p "$TOOLS_DIR/arjun"

# --- PAYLOADS ---
echo "* Installing SecLists..."
if [ ! -d "$PAYLOADS_DIR/SecLists" ]; then
    git clone https://github.com/danielmiessler/SecLists.git "$PAYLOADS_DIR/SecLists"
else
    echo "SecLists is already installed"
fi

# --- ALIAS TOOLS ---
echo "* Adding tools alias to $ZSHRC..."
if ! grep -q "alias tools=" "$ZSHRC"; then
    echo "alias tools='ls $TOOLS_DIR'" >> "$ZSHRC"
else
    echo "Alias tools already exists in $ZSHRC"