#!/usr/bin/env bash
# 06_install_tools.sh — Install dev tools (Docker, DBs, languages)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/helpers.sh"

write_header "ETAPE 6 : Installation des outils (BIN / DB / LANG)"
init_tmp_dir

ALREADY_DONE=(git gitbash code bruno wsl JetBrains_Mono Cascadia_Mono Fira_Code)

# ---------------------------------------------------------------------------
# Tool metadata: label and file extension per OS
# ---------------------------------------------------------------------------
declare -A TOOL_LABEL=(
    [docker]="Docker Engine"
    [docker_compose]="Docker Compose"
    [make]="GNU Make"
    [mongodb]="MongoDB 7"
    [mysql]="MySQL 8"
    [postgresql]="PostgreSQL 14"
    [python]="Python (uv / manager)"
    [java]="OpenJDK 21 (Temurin)"
    [rust]="Rust (rustup)"
    [uv]="uv (Python package manager)"
    [maven39]="Apache Maven 3.9"
)

# ---------------------------------------------------------------------------
# Per-tool post-install hooks
# ---------------------------------------------------------------------------

post_install_docker() {
    case "$OS" in
        linux)
            # Add current user to docker group so no sudo needed
            if command -v getent &>/dev/null && getent group docker &>/dev/null; then
                if command -v sudo &>/dev/null; then
                    sudo usermod -aG docker "$(whoami)" || true
                    write_info "Ajout au groupe docker — relancez votre session."
                fi
            fi
            ;;
        windows)
            docker_path="$LOCALAPPDATA/Programs/Docker/Docker/resources/bin"
            add_to_path "$docker_path"
            ;;
    esac
}

post_install_docker_compose() {
    case "$OS" in
        windows)
            dc_dest="$LOCALAPPDATA/Programs/docker-compose.exe"
            dc_src="$TMP_DIR/docker_compose-installer.exe"
            [[ -f "$dc_src" ]] && cp "$dc_src" "$dc_dest"
            add_to_path "$(dirname "$dc_dest")"
            ;;
        linux|mac)
            mkdir -p "$HOME/.local/bin"
            cp "$TMP_DIR/docker_compose-installer" "$HOME/.local/bin/docker-compose" 2>/dev/null || true
            chmod +x "$HOME/.local/bin/docker-compose" 2>/dev/null || true
            add_to_path "$HOME/.local/bin"
            ;;
    esac
}

post_install_java() {
    jdk_tmp="$TMP_DIR/java"
    jdk_extracted="$(find "$jdk_tmp" -maxdepth 1 -mindepth 1 -type d | head -1)" 2>/dev/null || true
    if [[ -n "$jdk_extracted" ]]; then
        jdk_dest="$HOME/jdk21"
        if [[ ! -d "$jdk_dest" ]]; then
            cp -r "$jdk_extracted" "$jdk_dest"
        fi
        set_env_var "JAVA_HOME" "$jdk_dest"
        add_to_path "$jdk_dest/bin"
        write_success "JAVA_HOME defini : $jdk_dest"

        # Patch VSCode settings.json
        case "$OS" in
            mac)     vscode_settings="$HOME/Library/Application Support/Code/User/settings.json" ;;
            linux)   vscode_settings="$HOME/.config/Code/User/settings.json" ;;
            windows) vscode_settings="$APPDATA/Code/User/settings.json" ;;
        esac
        if [[ -f "$vscode_settings" ]]; then
            escaped="${jdk_dest//\//\\/}"
            sed -i.bak "s|\"java\\.jdt\\.ls\\.java\\.home\":[[:space:]]*\"[^\"]*\"|\"java.jdt.ls.java.home\": \"$jdk_dest\"|g" \
                "$vscode_settings"
            write_info "settings.json VSCode mis a jour avec java.home"
        fi
    fi
}

post_install_rust() {
    add_to_path "$HOME/.cargo/bin"
}

post_install_uv() {
    add_to_path "$HOME/.local/bin"
}

post_install_maven39() {
    mvn_dir="$(find "$TMP_DIR/maven39" -maxdepth 1 -mindepth 1 -type d | head -1)" 2>/dev/null || true
    if [[ -n "$mvn_dir" ]]; then
        mvn_dest="$HOME/.local/share/maven"
        mkdir -p "$mvn_dest"
        cp -r "$mvn_dir/." "$mvn_dest/"
        add_to_path "$mvn_dest/bin"
        write_success "Maven installe dans $mvn_dest"
    fi
}

# ---------------------------------------------------------------------------
# Install a single tool
# ---------------------------------------------------------------------------
install_tool() {
    local name="$1"
    local label="${TOOL_LABEL[$name]:-$name}"

    ask_yes_no "$label" || { write_info "Ignore : $name"; write_log "Skipped: $name"; return 0; }

    write_step "Installation de $label..."

    url="$(get_download_url "$name")" || true
    if [[ -z "$url" ]]; then
        write_warn "Pas d'URL dans links.ini pour '$name'. Tentative via gestionnaire de paquets..."
        pkg_install "$name" || write_err "Impossible d'installer $name."
        return
    fi

    ext="${url##*.}"
    dest_file="$TMP_DIR/${name}-installer.${ext}"

    dl "$url" "$dest_file" || { write_err "Telechargement echoue pour $name."; return 1; }

    case "$ext" in
        zip|gz|tar)
            extract_dir="$TMP_DIR/$name"
            mkdir -p "$extract_dir"
            if [[ "$ext" == "zip" ]]; then
                unzip -qo "$dest_file" -d "$extract_dir"
            else
                tar -xf "$dest_file" -C "$extract_dir" --strip-components=1
            fi
            write_info "Archive extraite dans : $extract_dir"
            ;;
        exe)
            case "$OS" in
                windows)
                    "$dest_file" /S /SILENT /NORESTART 2>/dev/null || \
                    "$dest_file" -y --no-modify-path 2>/dev/null || \
                    "$dest_file" /VERYSILENT /NORESTART
                    ;;
                *) write_warn ".exe ignoré sur $OS" ;;
            esac
            ;;
        msi)
            case "$OS" in
                windows) msiexec //i "$dest_file" //qn //norestart ;;
                *)        write_warn ".msi ignoré sur $OS" ;;
            esac
            ;;
        msix)
            case "$OS" in
                windows) powershell -Command "Add-AppxPackage -Path '$dest_file'" ;;
                *)        write_warn ".msix ignoré sur $OS" ;;
            esac
            ;;
        *)
            write_warn "Format non geré automatiquement : $ext"
            ;;
    esac

    # Run post-install hook if it exists
    hook="post_install_${name}"
    if declare -f "$hook" &>/dev/null; then
        "$hook"
    fi

    write_success "$label installe."
    write_log "Installed: $name"
}

# ---------------------------------------------------------------------------
# Build list of tools from user.ini [tools] sections BIN / DB / LANG
# ---------------------------------------------------------------------------
tools_list=()
for section_key in BIN DB LANG; do
    raw="$(ini_get "$USERINI_FILE" tools "${section_key,,}" 2>/dev/null)" || \
    raw="$(ini_get "$USERINI_FILE" tools "$section_key"    2>/dev/null)" || true
    [[ -z "$raw" ]] && continue
    IFS=',' read -ra arr <<< "$raw"
    for t in "${arr[@]}"; do
        t="${t#"${t%%[![:space:]]*}"}"; t="${t%"${t##*[![:space:]]}"}"
        skip=0
        for done_tool in "${ALREADY_DONE[@]}"; do
            [[ "$t" == "$done_tool" ]] && skip=1 && break
        done
        [[ $skip -eq 0 && -n "$t" ]] && tools_list+=("$t")
    done
done

if [[ ${#tools_list[@]} -eq 0 ]]; then
    write_info "Aucun outil a installer dans BIN / DB / LANG."
    exit 0
fi

echo ""
echo -e "${C_CYAN}  Les outils suivants peuvent etre installes.${C_RESET}"
echo -e "${C_WHITE}  Repondez ${C_GREEN}y${C_WHITE} pour installer, ${C_RED}n${C_WHITE} pour passer.${C_RESET}"

for tool in "${tools_list[@]}"; do
    install_tool "$tool" || true
done

echo ""
write_success "Installation des outils terminee."
