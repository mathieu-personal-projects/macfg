#!/usr/bin/env bash
# helpers.sh — shared variables and functions

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG_ROOT="$(dirname "$SCRIPT_DIR")"
CONF_DIR="$CFG_ROOT/conf"
LINKS_FILE="$CONF_DIR/links.ini"
USERINI_FILE="$CONF_DIR/user.ini"
SETTINGS_FILE="$CONF_DIR/settings.json"

DEV_ROOT="$HOME/dev"
DEV_DOC="$DEV_ROOT/doc"
DEV_SOFT="$DEV_ROOT/softwares"
DEV_CONFIG="$DEV_ROOT/config"
DEV_FONTS="$DEV_CONFIG/fonts"
DEV_SSH="$DEV_CONFIG/ssh"

TMP_DIR="${TMPDIR:-/tmp}/cfg-setup-install"
LOG_FILE="$DEV_CONFIG/install.log"

# ---------------------------------------------------------------------------
# Detect OS
# ---------------------------------------------------------------------------
detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "linux" ;;
        Darwin*) echo "mac"   ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)       echo "unknown" ;;
    esac
}
OS="$(detect_os)"

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
C_CYAN='\033[0;36m'
C_YELLOW='\033[0;33m'
C_GREEN='\033[0;32m'
C_RED='\033[0;31m'
C_GRAY='\033[0;90m'
C_WHITE='\033[0;37m'
C_MAGENTA='\033[0;35m'
C_RESET='\033[0m'

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
write_header() {
    local line="============================================================"
    echo ""
    echo -e "${C_CYAN}${line}${C_RESET}"
    echo -e "${C_CYAN}  $1${C_RESET}"
    echo -e "${C_CYAN}${line}${C_RESET}"
    echo ""
}

write_step()    { echo -e "\n${C_YELLOW}  >> $1${C_RESET}"; }
write_success() { echo -e "${C_GREEN}  [OK] $1${C_RESET}"; }
write_warn()    { echo -e "${C_YELLOW}  [!!] $1${C_RESET}"; }
write_err()     { echo -e "${C_RED}  [KO] $1${C_RESET}"; }
write_info()    { echo -e "${C_GRAY}       $1${C_RESET}"; }

write_log() {
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[${ts}] $1" >> "$LOG_FILE"
}

# ---------------------------------------------------------------------------
# INI parser  — ini_get <file> <section> <key>
# ---------------------------------------------------------------------------
ini_get() {
    local file="$1" section="$2" key="$3"
    local in_section=0
    local _comment_re='^[#;]'
    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"   # ltrim
        line="${line%"${line##*[![:space:]]}"}"   # rtrim
        [[ "$line" =~ $_comment_re || -z "$line" ]] && continue
        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            [[ "${BASH_REMATCH[1]}" == "$section" ]] && in_section=1 || in_section=0
            continue
        fi
        if [[ $in_section -eq 1 && "$line" =~ ^([^=]+)=(.*)$ ]]; then
            local k="${BASH_REMATCH[1]}"
            local v="${BASH_REMATCH[2]}"
            k="${k#"${k%%[![:space:]]*}"}"; k="${k%"${k##*[![:space:]]}"}"
            v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"
            v="${v%\"}"; v="${v#\"}"
            [[ "$k" == "$key" ]] && { echo "$v"; return 0; }
        fi
    done < "$file"
    return 1
}

# get_download_url <tool_name>  — reads links.ini (flat key=value, no sections)
get_download_url() {
    local tool="$1"
    local _comment_re='^[#;]'
    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        [[ "$line" =~ $_comment_re || -z "$line" ]] && continue
        if [[ "$line" =~ ^${tool}[[:space:]]*=[[:space:]]*\"?([^\"]+)\"?$ ]]; then
            echo "${BASH_REMATCH[1]}"
            return 0
        fi
    done < "$LINKS_FILE"
    return 1
}

# ---------------------------------------------------------------------------
# Download helper  — dl <url> <dest>  (returns 0/1)
# ---------------------------------------------------------------------------
dl() {
    local url="$1" dest="$2"
    if [[ -z "$url" ]]; then
        write_warn "No URL provided for download."
        return 1
    fi
    if [[ -f "$dest" ]]; then
        write_info "Already downloaded: $(basename "$dest")"
        return 0
    fi
    mkdir -p "$(dirname "$dest")"
    write_info "Downloading: $url"
    if command -v curl &>/dev/null; then
        curl -fsSL "$url" -o "$dest" && { write_success "Downloaded: $(basename "$dest")"; write_log "Downloaded: $url -> $dest"; return 0; }
    elif command -v wget &>/dev/null; then
        wget -q "$url" -O "$dest" && { write_success "Downloaded: $(basename "$dest")"; write_log "Downloaded: $url -> $dest"; return 0; }
    else
        write_err "Neither curl nor wget found."
        return 1
    fi
    write_err "Download failed: $url"
    write_log "ERROR downloading: $url"
    return 1
}

# ---------------------------------------------------------------------------
# Package manager install  — pkg_install <package>
# Installs to user prefix when possible (--user / local paths)
# ---------------------------------------------------------------------------
pkg_install() {
    local pkg="$1"
    case "$OS" in
        mac)
            if command -v brew &>/dev/null; then
                brew install "$pkg"
            else
                write_err "Homebrew not found. Install it from https://brew.sh"
                return 1
            fi
            ;;
        linux)
            if command -v apt-get &>/dev/null; then
                # Try without sudo first (e.g. in a user container); fall back to sudo
                if apt-get install -y "$pkg" 2>/dev/null; then :
                elif command -v sudo &>/dev/null; then sudo apt-get install -y "$pkg"
                else write_err "Cannot install $pkg — no package manager or sudo."; return 1; fi
            elif command -v dnf &>/dev/null; then
                if command -v sudo &>/dev/null; then sudo dnf install -y "$pkg"
                else write_err "sudo required for dnf."; return 1; fi
            elif command -v pacman &>/dev/null; then
                if command -v sudo &>/dev/null; then sudo pacman -S --noconfirm "$pkg"
                else write_err "sudo required for pacman."; return 1; fi
            else
                write_err "Unsupported package manager."
                return 1
            fi
            ;;
        windows)
            if command -v winget &>/dev/null; then
                winget install --id "$pkg" --accept-source-agreements --accept-package-agreements --scope user
            elif command -v scoop &>/dev/null; then
                scoop install "$pkg"
            else
                write_err "winget or scoop required on Windows."
                return 1
            fi
            ;;
    esac
}

# ---------------------------------------------------------------------------
# ask_yes_no <label>  — returns 0 for yes, 1 for no
# ---------------------------------------------------------------------------
ask_yes_no() {
    echo ""
    echo -e "${C_WHITE}  --> Install ${C_MAGENTA}$1${C_WHITE} : ${C_GREEN}y${C_GRAY}/${C_RED}n${C_WHITE} ? ${C_RESET}" >&2
    read -r answer
    [[ "${answer,,}" == "y" ]]
}

# ---------------------------------------------------------------------------
# Ensure tmp dir exists
# ---------------------------------------------------------------------------
init_tmp_dir() { mkdir -p "$TMP_DIR"; }

# ---------------------------------------------------------------------------
# Add a directory to PATH in the user's shell profile (idempotent)
# ---------------------------------------------------------------------------
add_to_path() {
    local dir="$1"
    # Also export in the current session
    export PATH="$dir:$PATH"

    local profile
    if [[ -n "$BASH_VERSION" ]]; then
        profile="$HOME/.bashrc"
    elif [[ -n "$ZSH_VERSION" ]]; then
        profile="$HOME/.zshrc"
    else
        profile="$HOME/.profile"
    fi
    if ! grep -qF "$dir" "$profile" 2>/dev/null; then
        echo "export PATH=\"$dir:\$PATH\"" >> "$profile"
        write_info "Added to PATH in $profile: $dir"
    fi
}

# ---------------------------------------------------------------------------
# Set an env var persistently in the user's shell profile (idempotent)
# ---------------------------------------------------------------------------
set_env_var() {
    local name="$1" value="$2"
    export "$name"="$value"

    local profile
    if [[ -n "$BASH_VERSION" ]]; then
        profile="$HOME/.bashrc"
    elif [[ -n "$ZSH_VERSION" ]]; then
        profile="$HOME/.zshrc"
    else
        profile="$HOME/.profile"
    fi
    # Remove old line if present, then append
    if grep -qE "^export ${name}=" "$profile" 2>/dev/null; then
        sed -i.bak "s|^export ${name}=.*|export ${name}=\"${value}\"|" "$profile"
    else
        echo "export ${name}=\"${value}\"" >> "$profile"
    fi
    write_info "Set $name=$value in $profile"
}
