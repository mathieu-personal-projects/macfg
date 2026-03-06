#!/usr/bin/env bash
# 05_install_desktop.sh — Install VSCode, Bruno and apply settings/extensions
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/helpers.sh"

write_header "ETAPE 5 : Installation VSCode / Bruno"
init_tmp_dir

# ---------------------------------------------------------------------------
# Bruno
# ---------------------------------------------------------------------------
write_step "Installation de Bruno..."

if command -v bruno &>/dev/null 2>&1 || [[ -f "$LOCALAPPDATA/Programs/Bruno/Bruno.exe" ]] 2>/dev/null; then
    write_info "Bruno deja installe."
else
    bruno_url="$(get_download_url bruno)" || true
    if [[ -z "$bruno_url" ]]; then
        write_warn "Pas d'URL pour Bruno dans links.ini."
    else
        case "$OS" in
            mac)
                pkg_install bruno
                ;;
            linux)
                # AppImage or deb depending on URL extension
                ext="${bruno_url##*.}"
                bruno_bin="$TMP_DIR/bruno-installer.$ext"
                if dl "$bruno_url" "$bruno_bin"; then
                    if [[ "$ext" == "deb" ]]; then
                        if command -v sudo &>/dev/null; then sudo dpkg -i "$bruno_bin"
                        else write_warn "sudo required to install .deb — skipping Bruno."; fi
                    else
                        # AppImage: place in ~/.local/bin
                        mkdir -p "$HOME/.local/bin"
                        cp "$bruno_bin" "$HOME/.local/bin/bruno"
                        chmod +x "$HOME/.local/bin/bruno"
                        add_to_path "$HOME/.local/bin"
                        write_success "Bruno installe dans ~/.local/bin"
                    fi
                fi
                ;;
            windows)
                bruno_exe="$TMP_DIR/bruno-installer.exe"
                if dl "$bruno_url" "$bruno_exe"; then
                    "$bruno_exe" /S
                    write_success "Bruno installe."
                    write_log "Bruno installed"
                fi
                ;;
        esac
    fi
fi

# ---------------------------------------------------------------------------
# VSCode
# ---------------------------------------------------------------------------
write_step "Installation de Visual Studio Code..."

if command -v code &>/dev/null; then
    write_info "VSCode deja installe : $(code --version | head -1)"
else
    code_url="$(get_download_url code)" || true
    case "$OS" in
        mac)
            pkg_install visual-studio-code
            ;;
        linux)
            if [[ -n "$code_url" ]]; then
                ext="${code_url##*.}"
                code_pkg="$TMP_DIR/vscode-installer.$ext"
                if dl "$code_url" "$code_pkg"; then
                    if [[ "$ext" == "deb" ]]; then
                        if command -v sudo &>/dev/null; then sudo dpkg -i "$code_pkg"
                        else write_warn "sudo required to install VSCode .deb — skipping."; fi
                    fi
                fi
            else
                pkg_install code
            fi
            ;;
        windows)
            if [[ -n "$code_url" ]]; then
                code_exe="$TMP_DIR/vscode-installer.exe"
                if dl "$code_url" "$code_exe"; then
                    "$code_exe" /VERYSILENT /NORESTART \
                        /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath
                    write_success "VSCode installe."
                    write_log "VSCode installed"
                fi
            else
                pkg_install Microsoft.VisualStudioCode
            fi
            ;;
    esac
fi

# Reload PATH so `code` is available
export PATH="$PATH:$LOCALAPPDATA/Programs/Microsoft VS Code/bin"

# ---------------------------------------------------------------------------
# VSCode settings
# ---------------------------------------------------------------------------
write_step "Application des settings VSCode..."

case "$OS" in
    mac)     vscode_settings_dir="$HOME/Library/Application Support/Code/User" ;;
    linux)   vscode_settings_dir="$HOME/.config/Code/User" ;;
    windows) vscode_settings_dir="$APPDATA/Code/User" ;;
    *)       vscode_settings_dir="$HOME/.config/Code/User" ;;
esac
vscode_settings_dest="$vscode_settings_dir/settings.json"

mkdir -p "$vscode_settings_dir"

if [[ -f "$SETTINGS_FILE" ]]; then
    cp "$SETTINGS_FILE" "$vscode_settings_dest"
    write_success "settings.json applique : $vscode_settings_dest"
    write_log "VSCode settings applied from $SETTINGS_FILE"
    mkdir -p "$DEV_CONFIG/vscode"
    cp "$SETTINGS_FILE" "$DEV_CONFIG/vscode/settings.json"
else
    write_warn "Fichier conf/settings.json introuvable."
fi

# ---------------------------------------------------------------------------
# VSCode extensions
# ---------------------------------------------------------------------------
write_step "Installation des extensions VSCode (depuis conf/user.ini [plugins])..."

if ! command -v code &>/dev/null; then
    write_warn "La commande 'code' n'est pas dans le PATH. Ajoutez VSCode au PATH et relancez."
else
    # Collect all extension IDs from every key in [plugins]
    all_extensions=()
    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        [[ "$line" =~ ^[#;] || -z "$line" ]] && continue
        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            [[ "${BASH_REMATCH[1]}" == "plugins" ]] && in_plugins=1 || in_plugins=0
            continue
        fi
        if [[ ${in_plugins:-0} -eq 1 && "$line" =~ ^[^=]+=(.+)$ ]]; then
            IFS=',' read -ra exts <<< "${BASH_REMATCH[1]}"
            for e in "${exts[@]}"; do
                e="${e#"${e%%[![:space:]]*}"}"; e="${e%"${e##*[![:space:]]}"}"
                [[ -n "$e" ]] && all_extensions+=("$e")
            done
        fi
    done < "$USERINI_FILE"

    total=${#all_extensions[@]}
    i=1
    for ext_id in "${all_extensions[@]}"; do
        echo -e "${C_GRAY}  [$i/$total] ${C_WHITE}Installation de ${C_CYAN}$ext_id${C_RESET}"
        code --install-extension "$ext_id" --force &>/dev/null
        write_log "VSCode extension: $ext_id"
        (( i++ )) || true
    done
    write_success "$total extension(s) installee(s)."
fi
