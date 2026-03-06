#!/usr/bin/env bash
# 02_setup_folders.sh — Create ~/dev directory tree
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/helpers.sh"

write_header "ETAPE 2 : Creation de l'arborescence ~/dev"

folders=(
    "$DEV_ROOT"
    "$DEV_DOC"
    "$DEV_SOFT"
    "$DEV_CONFIG"
    "$DEV_FONTS"
    "$DEV_SSH"
    "$DEV_CONFIG/backup"
    "$DEV_CONFIG/vscode"
)

for folder in "${folders[@]}"; do
    if [[ -d "$folder" ]]; then
        write_info "Existe deja : $folder"
    else
        mkdir -p "$folder"
        write_success "Cree : $folder"
    fi
    write_log "Folder ensured: $folder"
done

echo ""
write_success "Arborescence ~/dev creee :"
echo ""
echo -e "${C_CYAN}       $HOME/${C_RESET}"
echo -e "${C_CYAN}       └── dev/${C_RESET}"
echo -e "${C_GRAY}           ├── doc/         (projets et documentation)${C_RESET}"
echo -e "${C_GRAY}           ├── softwares/   (raccourcis des applications)${C_RESET}"
echo -e "${C_GRAY}           └── config/      (cles SSH, polices, sauvegardes)${C_RESET}"
echo -e "${C_GRAY}               ├── fonts/${C_RESET}"
echo -e "${C_GRAY}               ├── ssh/${C_RESET}"
echo -e "${C_GRAY}               ├── backup/${C_RESET}"
echo -e "${C_GRAY}               └── vscode/${C_RESET}"
echo ""
