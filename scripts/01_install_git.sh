#!/usr/bin/env bash
# 01_install_git.sh — Install git and configure global settings
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/helpers.sh"

write_header "ETAPE 1 : Installation et configuration de Git"
init_tmp_dir

# ---------------------------------------------------------------------------
# Install git if missing
# ---------------------------------------------------------------------------
if command -v git &>/dev/null; then
    write_info "Git deja installe : $(git --version)"
else
    write_step "Installation de Git..."
    case "$OS" in
        mac)
            # Prefer the download URL from links.ini if it points to a pkg/dmg,
            # otherwise fall back to Homebrew
            pkg_install git
            ;;
        linux)
            pkg_install git
            ;;
        windows)
            url="$(get_download_url git)" || true
            if [[ -n "$url" ]]; then
                installer="$TMP_DIR/git-installer.exe"
                dl "$url" "$installer"
                git_install_dir="$LOCALAPPDATA/Programs/Git"
                write_info "Running Git installer (user-only)..."
                "$installer" \
                    /VERYSILENT /NORESTART /NOCANCEL /SP- /SUPPRESSMSGBOXES \
                    "/DIR=$git_install_dir" \
                    /COMPONENTS=gitlfs,assoc,assoc_sh \
                    /o:PathOption=Cmd \
                    /o:BashTerminalOption=MinTTY
                add_to_path "$git_install_dir/cmd"
                write_log "Git installed to $git_install_dir"
            else
                pkg_install Git.Git   # winget id
            fi
            ;;
    esac

    if command -v git &>/dev/null; then
        write_success "Git installe : $(git --version)"
    else
        write_warn "Git n'est pas encore dans le PATH. Relancez le terminal."
    fi
fi

# ---------------------------------------------------------------------------
# Configure git globals
# ---------------------------------------------------------------------------
write_header "Configuration de Git"

echo ""
echo -e "${C_CYAN}  Renseignez vos informations Git :${C_RESET}"
echo ""

while true; do
    echo -e "${C_YELLOW}  Votre nom (ex: John Doe) : ${C_RESET}" >&2
    read -r git_name
    [[ -n "$git_name" ]] && break
done

while true; do
    echo -e "${C_YELLOW}  Votre email Git          : ${C_RESET}" >&2
    read -r git_email
    [[ -n "$git_email" ]] && break
done

write_step "Application de la configuration Git..."

git config --global user.name        "$git_name"
git config --global user.email       "$git_email"
git config --global core.editor      "code --wait"
git config --global init.defaultBranch main
git config --global color.ui         auto

case "$OS" in
    windows) git config --global core.autocrlf true  ;;
    *)       git config --global core.autocrlf input ;;
esac

write_log "Git configured for user: $git_name <$git_email>"
write_success "Git configure : $HOME/.gitconfig"

write_step "Contenu de .gitconfig :"
echo ""
while IFS= read -r line; do write_info "$line"; done < "$HOME/.gitconfig"
echo ""
