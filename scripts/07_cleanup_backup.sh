#!/usr/bin/env bash
# 07_cleanup_backup.sh — Backup config files and clean up temp files
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/helpers.sh"

write_header "ETAPE 7 : Nettoyage et sauvegarde"

backup_base="$DEV_CONFIG/backup"
timestamp="$(date '+%Y%m%d_%H%M%S')"
backup_stamp="$backup_base/backup_$timestamp"

mkdir -p "$backup_stamp"
write_step "Sauvegarde des fichiers de configuration..."

# Determine VSCode user settings path
case "$OS" in
    mac)     vscode_user_settings="$HOME/Library/Application Support/Code/User/settings.json" ;;
    linux)   vscode_user_settings="$HOME/.config/Code/User/settings.json" ;;
    windows) vscode_user_settings="$APPDATA/Code/User/settings.json" ;;
    *)       vscode_user_settings="$HOME/.config/Code/User/settings.json" ;;
esac

declare -a BACKUP_SRCS=(
    "$SETTINGS_FILE"
    "$USERINI_FILE"
    "$LINKS_FILE"
    "$HOME/.gitconfig"
    "$vscode_user_settings"
    "$DEV_SSH"
)
declare -a BACKUP_NAMES=(
    "settings.json"
    "user.ini"
    "links.ini"
    ".gitconfig"
    "vscode-user-settings.json"
    "ssh"
)

for i in "${!BACKUP_SRCS[@]}"; do
    src="${BACKUP_SRCS[$i]}"
    name="${BACKUP_NAMES[$i]}"
    dest="$backup_stamp/$name"

    if [[ ! -e "$src" ]]; then
        write_info "Non trouve (ignore) : $name"
        continue
    fi

    if [[ -d "$src" ]]; then
        cp -r "$src" "$dest"
    else
        cp "$src" "$dest"
    fi
    write_success "Sauvegarde : $name"
    write_log "Backed up: $src -> $dest"
done

# README in backup
cat > "$backup_stamp/README.txt" <<EOF
Sauvegarde cfg-setup
Date    : $(date '+%d/%m/%Y %H:%M:%S')
Machine : $(hostname)
User    : $(whoami)
OS      : $OS

Contenu :
  .gitconfig              - Configuration Git utilisateur
  settings.json           - Template settings VSCode (conf/)
  vscode-user-settings    - Settings VSCode actifs
  user.ini                - Configuration d'installation
  links.ini               - URLs de telechargement
  ssh/                    - Cles SSH (CONFIDENTIEL)
EOF
write_info "README cree dans le backup."

# ---------------------------------------------------------------------------
# Clean up temp dir
# ---------------------------------------------------------------------------
write_step "Nettoyage des fichiers temporaires..."

if [[ -d "$TMP_DIR" ]]; then
    if command -v du &>/dev/null; then
        size_kb="$(du -sk "$TMP_DIR" 2>/dev/null | cut -f1)"
        size_mb="$(echo "scale=2; $size_kb/1024" | bc 2>/dev/null || echo "?")"
        write_info "${size_mb} Mo"
    fi
    rm -rf "$TMP_DIR"
    write_success "Dossier temp supprime : $TMP_DIR"
    write_log "Cleaned up: $TMP_DIR"
else
    write_info "Aucun dossier temporaire a nettoyer."
fi

# ---------------------------------------------------------------------------
# Empty trash (optional)
# ---------------------------------------------------------------------------
echo ""
echo -e "${C_YELLOW}  Vider la corbeille ? ${C_GREEN}y${C_GRAY}/${C_RED}n${C_WHITE} ? ${C_RESET}"
read -r empty_bin
if [[ "${empty_bin,,}" == "y" ]]; then
    case "$OS" in
        mac)     rm -rf "$HOME/.Trash/"* 2>/dev/null || true ;;
        linux)   command -v trash-empty &>/dev/null && trash-empty || rm -rf "$HOME/.local/share/Trash/"* 2>/dev/null || true ;;
        windows) powershell -Command "Clear-RecycleBin -Force" 2>/dev/null || true ;;
    esac
    write_success "Corbeille videe."
fi

echo ""
echo -e "${C_CYAN}  =================================================================${C_RESET}"
echo -e "${C_CYAN}  Backup disponible dans :${C_RESET}"
echo -e "${C_WHITE}    $backup_stamp${C_RESET}"
echo -e "${C_CYAN}  Log d'installation    :${C_RESET}"
echo -e "${C_WHITE}    $LOG_FILE${C_RESET}"
echo -e "${C_CYAN}  =================================================================${C_RESET}"
echo ""
