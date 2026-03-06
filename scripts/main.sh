#!/usr/bin/env bash
# main.sh — cfg-setup entry point
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/helpers.sh"

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
clear
echo ""
echo -e "${C_CYAN}███╗   ███╗ █████╗  ██████╗███████╗ ██████╗ ${C_RESET}"
echo -e "${C_CYAN}████╗ ████║██╔══██╗██╔════╝██╔════╝██╔════╝ ${C_RESET}"
echo -e "${C_CYAN}██╔████╔██║███████║██║     █████╗  ██║  ███╗${C_RESET}"
echo -e "${C_CYAN}██║╚██╔╝██║██╔══██║██║     ██╔══╝  ██║   ██║${C_RESET}"
echo -e "${C_CYAN}██║ ╚═╝ ██║██║  ██║╚██████╗██║     ╚██████╔╝${C_RESET}"
echo -e "${C_CYAN}╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝      ╚═════╝ ${C_RESET}"
echo ""
echo -e "${C_WHITE}  CFG-SETUP  --  Configuration de l'environnement de dev${C_RESET}"
echo -e "${C_GRAY}  Machine : $(hostname)  |  User : $(whoami)  |  OS : $OS${C_RESET}"
echo ""

# ---------------------------------------------------------------------------
# Parse arguments  —  --steps 1,2,3  (default: all)
# ---------------------------------------------------------------------------
STEPS="${1:-1,2,3,4,5,6,7}"
IFS=',' read -ra STEPS_ARR <<< "$STEPS"

# ---------------------------------------------------------------------------
# Step registry
# ---------------------------------------------------------------------------
declare -a STEP_IDS=(1 2 3 4 5 6 7)
declare -A STEP_NAMES=(
    [1]="Git & GitBash - Installation et configuration"
    [2]="Arborescence ~/dev"
    [3]="Polices (JetBrains Mono, Cascadia, Fira Code)"
    [4]="Cles SSH - Copie dans ~/dev/config/ssh"
    [5]="VSCode / Bruno"
    [6]="Outils (Docker, DB, Python, Java, Rust...)"
    [7]="Nettoyage + Backup"
)
declare -A STEP_SCRIPTS=(
    [1]="01_install_git.sh"
    [2]="02_setup_folders.sh"
    [3]="03_install_fonts.sh"
    [4]="04_copy_ssh_config.sh"
    [5]="05_install_desktop.sh"
    [6]="06_install_tools.sh"
    [7]="07_cleanup_backup.sh"
)

# ---------------------------------------------------------------------------
# Show selected steps
# ---------------------------------------------------------------------------
echo -e "${C_YELLOW}  Etapes selectionnees :${C_RESET}"
echo ""
for id in "${STEP_IDS[@]}"; do
    if printf '%s\n' "${STEPS_ARR[@]}" | grep -qx "$id"; then
        echo -e "${C_GREEN}  [x] $id. ${STEP_NAMES[$id]}${C_RESET}"
    else
        echo -e "${C_GRAY}  [ ] $id. ${STEP_NAMES[$id]}${C_RESET}"
    fi
done
echo ""
echo -e "${C_GRAY}  Dossier de travail : $DEV_ROOT${C_RESET}"
echo ""
echo -e "${C_WHITE}  Appuyez sur ${C_GREEN}ENTREE${C_WHITE} pour demarrer ou ${C_RED}CTRL+C${C_WHITE} pour annuler.${C_RESET}"
read -r

# ---------------------------------------------------------------------------
# Initialise
# ---------------------------------------------------------------------------
init_tmp_dir
mkdir -p "$(dirname "$LOG_FILE")"
write_log "=== cfg-setup started === Steps: $STEPS"
START_TS="$SECONDS"
STEP_ERRORS=()

# ---------------------------------------------------------------------------
# Run steps
# ---------------------------------------------------------------------------
for id in "${STEP_IDS[@]}"; do
    printf '%s\n' "${STEPS_ARR[@]}" | grep -qx "$id" || continue

    script="$SCRIPT_DIR/${STEP_SCRIPTS[$id]}"
    if [[ ! -f "$script" ]]; then
        write_err "Script introuvable : $script"
        STEP_ERRORS+=("$id")
        continue
    fi

    set +e
    bash "$script"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        write_err "Erreur a l'etape $id (code $rc)"
        write_log "ERROR Step $id: exit code $rc"
        STEP_ERRORS+=("$id")
        echo ""
        echo -e "${C_YELLOW}  Continuer malgre l'erreur ? ${C_GREEN}y${C_GRAY}/${C_RED}n${C_WHITE} ? ${C_RESET}"
        read -r cont
        [[ "${cont,,}" == "y" ]] || break
    else
        write_log "Step $id completed: ${STEP_NAMES[$id]}"
    fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
ELAPSED=$(( SECONDS - START_TS ))
echo ""
echo -e "${C_CYAN}  =================================================================${C_RESET}"
if [[ ${#STEP_ERRORS[@]} -eq 0 ]]; then
    echo -e "${C_GREEN}  Toutes les etapes terminees avec succes (${ELAPSED}s)${C_RESET}"
else
    echo -e "${C_YELLOW}  Termine avec des erreurs aux etapes : ${STEP_ERRORS[*]} (${ELAPSED}s)${C_RESET}"
fi
echo -e "${C_CYAN}  Log : $LOG_FILE${C_RESET}"
echo -e "${C_CYAN}  =================================================================${C_RESET}"
echo ""
