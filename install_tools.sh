#!/bin/zsh

# ===========================
# TOOLSET INSTALL SCRIPT
# ===========================
# 1. Subdomain Enumeration:
#    - subfinder, assetfinder, findomain, shuffledns, puredns
# 2. DNS Tools:
#    - dnsx, massdns, dnsdumpster
# 3. HTTP/Web Tools:
#    - httpx, httprobe, hakrawler, katana, waybackurls, gau, ffuf, wfuzz, whatweb, nikto, dirsearch, Corsy, CRLF-Injection-Scanner, smuggles
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

echo "* Tạo thư mục $TOOLS_DIR và chuẩn bị môi trường..."
mkdir -p "$TOOLS_DIR"
cd "$TOOLS_DIR"

# --- GO ENVIRONMENT ---
echo "* Kiểm tra và cài đặt Go nếu cần..."
if ! command -v go &> /dev/null; then
    wget -q https://go.dev/dl/go1.22.3.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz
    rm -f go1.22.3.linux-amd64.tar.gz
    grep -qxF 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' "$ZSHRC" || echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$ZSHRC"
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
fi

# --- GO TOOLS ---
echo "* Cài các tool viết bằng Go..."
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
    if ! command -v $tool &> /dev/null; then
        go install "${go_tools[$tool]}"
    else
        echo "$tool đã được cài đặt"
    fi
    mkdir -p "$TOOLS_DIR/$tool"
done

# --- APT TOOLS ---
echo "* Cài thêm các công cụ hỗ trợ khác..."
sudo apt update
apt_tools=(ffuf wfuzz whatweb ruby-full python3-pip nikto git curl unzip pipx jq)
for tool in $apt_tools; do
    if ! command -v $tool &> /dev/null && ! dpkg -s $tool &> /dev/null; then
        sudo apt install -y $tool
    else
        echo "$tool đã được cài đặt"
    fi
    mkdir -p "$TOOLS_DIR/$tool"
done

# --- RUBY GEM TOOLS ---
echo "* Cài wpscan..."
if ! command -v wpscan &> /dev/null; then
    sudo gem install wpscan
else
    echo "wpscan đã được cài đặt"
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
        return 0    # mới clone, cần cài req
    else
        echo "$dir đã được cài đặt"
        return 1    # đã clone, không cần cài req
    fi
}

# CMSeeK
echo "* Cài CMSeeK..."
if clone_and_alias "https://github.com/Tuhinshubhra/CMSeeK.git" "CMSeeK" "cmseek" "alias cmseek='python3 ~/tools/CMSeeK/cmseek.py'"; then
    pip3 install --break-system-packages -r "$TOOLS_DIR/CMSeeK/requirements.txt"
fi

# dirsearch (không cần pip)
echo "* Cài dirsearch..."
clone_and_alias "https://github.com/maurosoria/dirsearch.git" "dirsearch" "dirsearch" "alias dirsearch='python3 ~/tools/dirsearch/dirsearch.py'"

# SecretFinder
echo "* Cài SecretFinder..."
if clone_and_alias "https://github.com/m4ll0k/SecretFinder.git" "SecretFinder" "secretfinder" "alias secretfinder='python3 ~/tools/SecretFinder/SecretFinder.py'"; then
    pip3 install --break-system-packages -r "$TOOLS_DIR/SecretFinder/requirements.txt"
fi

# Corsy
echo "* Cài Corsy..."
if clone_and_alias "https://github.com/s0md3v/Corsy.git" "Corsy" "corsy" "alias corsy='python3 ~/tools/Corsy/corsy.py'"; then
    pip3 install --break-system-packages -r "$TOOLS_DIR/Corsy/requirements.txt"
fi

# CRLF-Injection-Scanner
echo "* Cài CRLF-Injection-Scanner..."
if clone_and_alias "https://github.com/MichaelStott/CRLF-Injection-Scanner.git" "CRLF-Injection-Scanner" "crlfscanner" "alias crlfscanner='python3 ~/tools/CRLF-Injection-Scanner/crlf.py'"; then
    python3 "$TOOLS_DIR/CRLF-Injection-Scanner/setup.py" install
fi

# dnsdumpster
echo "* Cài dnsdumpster tool..."
if clone_and_alias "https://github.com/PaulSec/API-dnsdumpster.com.git" "dnsdumpster" "dnsdumpster" "alias dnsdumpster='python3 ~/tools/dnsdumpster/dnsdumpster.py'"; then
    python3 "$TOOLS_DIR/dnsdumpster/setup.py" install
fi

# XSStrike
echo "* Cài XSStrike..."
if clone_and_alias "https://github.com/s0md3v/XSStrike.git" "XSStrike" "xsstrike" "alias xsstrike='python3 ~/tools/XSStrike/xsstrike.py'"; then
    pip3 install --break-system-packages -r "$TOOLS_DIR/XSStrike/requirements.txt"
fi

# sqlmap (không cần pip)
echo "* Cài sqlmap..."
clone_and_alias "https://github.com/sqlmapproject/sqlmap.git" "sqlmap" "sqlmap" "alias sqlmap='python3 ~/tools/sqlmap/sqlmap.py'"

# --- TRUFFLEHOG (pipx) ---
echo "* Cài truffleHog..."
if ! command -v trufflehog &> /dev/null; then
    pipx install trufflehog
else
    echo "trufflehog đã được cài đặt"
fi
mkdir -p "$TOOLS_DIR/trufflehog"

# --- GITLEAKS (BINARY) ---
echo "* Cài Gitleaks..."
if ! command -v gitleaks &> /dev/null; then
    # Thư mục chứa mã nguồn và binary
    GITLEAKS_SRC="$TOOLS_DIR/gitleaks-src"
    GITLEAKS_BIN="$TOOLS_DIR/gitleaks"

    # Xóa mã nguồn cũ nếu có
    [ -d "$GITLEAKS_SRC" ] && rm -rf "$GITLEAKS_SRC"

    # Clone mã nguồn Gitleaks
    git clone https://github.com/gitleaks/gitleaks.git "$GITLEAKS_SRC"

    # Build Gitleaks
    cd "$GITLEAKS_SRC"
    make build

    # Copy binary ra thư mục tools và phân quyền
    cp ./gitleaks "$GITLEAKS_BIN"
    chmod +x "$GITLEAKS_BIN"

    # Tạo symlink vào /usr/local/bin
    sudo ln -sf "$GITLEAKS_BIN" /usr/local/bin/gitleaks

    # Quay lại thư mục tools
    cd "$TOOLS_DIR"
else
    echo "gitleaks đã được cài đặt"
fi

# --- BYPASS 403 TOOLS ---
echo \"* Cài các tool bypass 403...\"
clone_and_alias \"https://github.com/iamj0ker/bypass-403.git\" \"bypass-403\" \"bypass403\" \"alias bypass403='bash ~/tools/bypass-403/bypass-403.sh'\"
clone_and_alias \"https://github.com/devploit/nomore403.git\" \"nomore403\" \"nomore403\" \"alias nomore403='bash ~/tools/nomore403/nomore403.sh'\"
clone_and_alias \"https://github.com/Dheerajmadhukar/4-ZERO-3.git\" \"4-ZERO-3\" \"zero403\" \"alias zero403='bash ~/tools/4-ZERO-3/403.sh'\"

# --- FINDOMAIN (BINARY) ---
echo \"* Cài findomain...\"
if ! command -v findomain &> /dev/null; then
    wget -q https://github.com/findomain/findomain/releases/latest/download/findomain-linux.zip -O findomain-linux.zip
    unzip -q findomain-linux.zip
    chmod +x findomain
    mv findomain \"$TOOLS_DIR/\"
    rm findomain-linux.zip
    grep -qxF \"alias findomain='~/tools/findomain'\" \"$ZSHRC\" || echo \"alias findomain='~/tools/findomain'\" >> \"$ZSHRC\"
else
    echo \"findomain đã được cài đặt\"
fi

# --- MASSDNS ---
echo \"* Cài massdns...\"
if [ ! -d \"$TOOLS_DIR/massdns\" ]; then
    git clone https://github.com/blechschmidt/massdns.git \"$TOOLS_DIR/massdns\"
    cd \"$TOOLS_DIR/massdns\" && make && sudo make install
else
    echo \"massdns đã được cài đặt\"
fi

echo "* Cài arjun (pipx)..."
if ! command -v arjun &> /dev/null; then
    pipx install arjun
else
    echo "arjun đã được cài đặt"
fi
mkdir -p "$TOOLS_DIR/arjun"

# --- PAYLOADS ---
echo "* Cài SecLists..."
if [ ! -d "$PAYLOADS_DIR/SecLists" ]; then
    git clone https://github.com/danielmiessler/SecLists.git "$PAYLOADS_DIR/SecLists"
else
    echo "SecLists đã được cài đặt"
fi

# --- ALIAS TOOLS ---
echo "* Thêm alias tools vào $ZSHRC..."
if ! grep -q "alias tools=" "$ZSHRC"; then
    echo "alias tools='ls $TOOLS_DIR'" >> "$ZSHRC"
else
    echo "Alias tools đã tồn tại trong $ZSHRC"
fi

source \"$ZSHRC\"