#!/bin/zsh

TOOLS_DIR=~/tools 
ZSHRC=~/.zshrc
PAYLOADS_DIR=~/payloads
DESKTOP_DIR=~/Desktop
PAYLOADS_DIR=~/payloads 
GITLEAKS_SRC="$TOOLS_DIR/gitleaks-src"
GITLEAKS_BIN="$TOOLS_DIR/gitleaks"

# Tạo folder tools nếu chưa có
if [ ! -d "$TOOLS_DIR" ]; then
    mkdir -p "$TOOLS_DIR"
fi

# Định nghĩa các file không copy
EXCLUDE_FILES=("README.md")

# Lặp qua các file trong thư mục hiện tại
for file in *; do
    # Bỏ qua nếu là thư mục
    [ -d "$file" ] && continue

    # Kiểm tra file có nằm trong danh sách loại trừ không
    skip=false
    for exclude in "${EXCLUDE_FILES[@]}"; do
        if [ "$file" = "$exclude" ]; then
            skip=true
            break
        fi
    done

    # Nếu không nằm trong danh sách loại trừ thì copy
    if [ "$skip" = false ]; then
        cp "$file" "$TOOLS_DIR/"
    fi
done