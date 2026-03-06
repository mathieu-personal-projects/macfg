#!/usr/bin/env bash
# 03_install_fonts.sh — Install developer fonts (user-level)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/helpers.sh"

write_header "ETAPE 3 : Installation des polices"
init_tmp_dir

# User-level font directories (no root required)
case "$OS" in
    mac)     FONTS_DIR="$HOME/Library/Fonts" ;;
    linux)   FONTS_DIR="$HOME/.local/share/fonts" ;;
    windows) FONTS_DIR="$LOCALAPPDATA/Microsoft/Windows/Fonts" ;;
    *)       FONTS_DIR="$HOME/.fonts" ;;
esac
mkdir -p "$FONTS_DIR"

# install_font_files <source_dir>
install_font_files() {
    local src="$1"
    local count=0
    while IFS= read -r -d '' font; do
        local fname
        fname="$(basename "$font")"
        local dest="$FONTS_DIR/$fname"
        if [[ ! -f "$dest" ]]; then
            cp "$font" "$dest"
            write_success "Police installee : $fname"
            (( count++ )) || true
        else
            write_info "Deja installee : $fname"
        fi
    done < <(find "$src" \( -name "*.ttf" -o -name "*.otf" \) -print0)

    # Refresh font cache on Linux
    if [[ "$OS" == "linux" ]] && command -v fc-cache &>/dev/null; then
        fc-cache -f "$FONTS_DIR" &>/dev/null
    fi

    [[ $count -gt 0 ]] || write_warn "Aucun fichier de police trouve dans : $src"
}

# Register font in Windows registry (user hive — no elevation needed)
register_font_windows() {
    local font_path="$1"
    local fname
    fname="$(basename "$font_path")"
    local reg_key='HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
    local font_name="${fname%.*}"
    reg add "$reg_key" /v "$font_name" /t REG_SZ /d "$fname" /f &>/dev/null || true
}

copy_fonts_to_config() {
    local src="$1" font_name="$2"
    local dest_dir="$DEV_FONTS/$font_name"
    mkdir -p "$dest_dir"
    cp -r "$src/." "$dest_dir/"
    write_info "Copie dans : $dest_dir"
}

# ---------------------------------------------------------------------------
# JetBrains Mono  (direct download)
# ---------------------------------------------------------------------------
write_step "Police : JetBrains Mono"
url="$(get_download_url JetBrains_Mono)" || true
if [[ -z "$url" ]]; then
    write_warn "Pas d'URL pour JetBrains_Mono, ignore."
else
    zip_file="$TMP_DIR/JetBrains_Mono.zip"
    extract_dir="$TMP_DIR/JetBrains_Mono"
    if dl "$url" "$zip_file"; then
        mkdir -p "$extract_dir"
        unzip -qo "$zip_file" -d "$extract_dir"
        install_font_files "$extract_dir"
        if [[ "$OS" == "windows" ]]; then
            while IFS= read -r -d '' font; do
                register_font_windows "$font"
            done < <(find "$FONTS_DIR" \( -name "JetBrainsMono*.ttf" -o -name "JetBrainsMono*.otf" \) -print0)
        fi
        copy_fonts_to_config "$extract_dir" "JetBrains_Mono"
        write_log "Font installed: JetBrains_Mono"
    fi
fi

# ---------------------------------------------------------------------------
# Google Fonts (Cascadia Mono, Fira Code) — manual download required
# ---------------------------------------------------------------------------
for font_name in Cascadia_Mono Fira_Code; do
    write_step "Police : $font_name (Google Fonts)"
    url="$(get_download_url "$font_name")" || true
    write_warn "Telechargement automatique impossible pour Google Fonts."
    write_info "Ouvrez ce lien dans un navigateur : $url"
    write_info "Telechargez le ZIP, extrayez et placez les .ttf dans :"
    write_info "  $FONTS_DIR"
    write_info "  puis copiez les fichiers dans : $DEV_FONTS/$font_name"
done

echo ""
write_success "Etape polices terminee. Fichiers sauvegardes dans : $DEV_FONTS"
