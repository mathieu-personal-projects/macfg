#!/usr/bin/env bash
# 04_copy_ssh_config.sh — Copy/generate SSH keys into ~/dev/config/ssh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/helpers.sh"

write_header "ETAPE 4 : Copie des cles SSH vers ~/dev/config/ssh"

ssh_source="$HOME/.ssh"
ssh_dest="$DEV_SSH"

if [[ ! -d "$ssh_source" ]]; then
    write_warn "Aucun dossier .ssh trouve dans $HOME"
    write_info "Vous pouvez generer une cle SSH avec :"
    echo ""
    echo -e "${C_CYAN}       ssh-keygen -t ed25519 -C \"votre@email.com\"${C_RESET}"
    echo ""
    echo -e "${C_YELLOW}  Voulez-vous generer une cle SSH maintenant ? ${C_GREEN}y${C_GRAY}/${C_RED}n${C_WHITE} ? ${C_RESET}"
    read -r gen
    if [[ "${gen,,}" == "y" ]]; then
        echo -e "${C_YELLOW}  Email pour la cle SSH : ${C_RESET}"
        read -r ssh_email
        mkdir -p "$ssh_source"
        ssh-keygen -t ed25519 -C "$ssh_email" -f "$ssh_source/id_ed25519" -N ""
        chmod 700 "$ssh_source"
        chmod 600 "$ssh_source/id_ed25519"
        write_success "Cle SSH generee : $ssh_source/id_ed25519"
        write_log "SSH key generated: $ssh_source/id_ed25519"
    else
        write_warn "Generation ignoree. Le dossier SSH sera vide."
        exit 0
    fi
fi

mkdir -p "$ssh_dest"
chmod 700 "$ssh_dest"

count=0
while IFS= read -r -d '' f; do
    fname="$(basename "$f")"
    dest_file="$ssh_dest/$fname"
    cp "$f" "$dest_file"
    chmod 600 "$dest_file"
    write_success "Copie : $fname"
    write_log "SSH file copied: $f -> $dest_file"
    (( count++ )) || true
done < <(find "$ssh_source" -maxdepth 1 -type f -print0)

if [[ $count -eq 0 ]]; then
    write_warn "Aucun fichier trouve dans $ssh_source"
    exit 0
fi

echo ""
write_success "Cles SSH sauvegardees dans : $ssh_dest"
write_warn "Ces fichiers sont sensibles. Ne les partagez pas."
