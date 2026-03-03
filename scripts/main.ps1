#Requires -RunAsAdministrator
param(
    [int[]]   $Steps        = @(1,2,3,4,5,6,7), 
    [switch]  $SkipCleanup  = $false
)

Set-StrictMode   -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\helpers.ps1"

# --- Banniere -----------------------------------------------------------------
Clear-Host
Write-Host ""
Write-Host "  ██████╗███████╗ ██████╗       ███████╗███████╗████████╗██╗   ██╗██████╗ " -ForegroundColor Cyan
Write-Host "  ██╔════╝██╔════╝██╔════╝       ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗" -ForegroundColor Cyan
Write-Host "  ██║     █████╗  ██║  ███╗█████╗███████╗█████╗     ██║   ██║   ██║██████╔╝" -ForegroundColor Cyan
Write-Host "  ██║     ██╔══╝  ██║   ██║╚════╝╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ " -ForegroundColor Cyan
Write-Host "  ╚██████╗██║     ╚██████╔╝       ███████║███████╗   ██║   ╚██████╔╝██║     " -ForegroundColor Cyan
Write-Host "   ╚═════╝╚═╝      ╚═════╝        ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     " -ForegroundColor Cyan
Write-Host ""
Write-Host "              Configuration de l'environnement de developpement" -ForegroundColor White
Write-Host "              Machine : $env:COMPUTERNAME  |  User : $env:USERNAME" -ForegroundColor DarkGray
Write-Host ""

New-Item -ItemType Directory -Force -Path $script:TMP_DIR | Out-Null

# table des etapes disponibles
$allSteps = @(
    @{ Id = 1; Name = "Git & GitBash - Installation et configuration"
       Script = "01_install_git.ps1" },

    @{ Id = 2; Name = "Arborescence ~/dev"
       Script = "02_setup_folders.ps1" },

    @{ Id = 3; Name = "Polices (JetBrains Mono, Cascadia, Fira Code)"
       Script = "03_install_fonts.ps1" },

    @{ Id = 4; Name = "Cles SSH - Copie dans ~/dev/config/ssh"
       Script = "04_copy_ssh_config.ps1" },

    @{ Id = 5; Name = "WSL Debian / Bruno / VSCode + plugins + settings"
       Script = "05_install_desktop.ps1" },

    @{ Id = 6; Name = "Outils (Docker, DB, Python, Java, Rust...)"
       Script = "06_install_tools.ps1" },

    @{ Id = 7; Name = "Nettoyage + Backup"
       Script = "07_cleanup_backup.ps1" }
)

Write-Host "  Etapes selectionnees :" -ForegroundColor Yellow
Write-Host ""
foreach ($step in $allSteps) {
    $selected = $Steps -contains $step.Id
    $prefix   = if ($selected) { "  [x]" } else { "  [ ]" }
    $color    = if ($selected) { "Green" } else { "DarkGray" }
    Write-Host "$prefix $($step.Id). $($step.Name)" -ForegroundColor $color
}
Write-Host ""

Write-Host "  Dossier de travail : $($script:DEV_ROOT)" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Appuyez sur " -NoNewline -ForegroundColor White
Write-Host "ENTREE" -NoNewline -ForegroundColor Green
Write-Host " pour demarrer ou " -NoNewline -ForegroundColor White
Write-Host "CTRL+C" -NoNewline -ForegroundColor Red
Write-Host " pour annuler." -ForegroundColor White
Read-Host

$script:LOG_FILE = Join-Path $script:TMP_DIR "install_early.log"
Write-Log "=== cfg-setup started ==="
Write-Log "Steps: $($Steps -join ',')"

$startTime  = Get-Date
$stepErrors = @()

foreach ($step in $allSteps) {
    if ($Steps -notcontains $step.Id) { continue }

    $scriptPath = Join-Path $PSScriptRoot $step.Script
    if (-not (Test-Path $scriptPath)) {
        Write-Err "Script introuvable : $scriptPath"
        $stepErrors += $step.Id
        continue
    }

    try {
        & $scriptPath
        Write-Log "Step $($step.Id) completed: $($step.Name)"
    } catch {
        Write-Err "Erreur a l'etape $($step.Id) : $_"
        Write-Log "ERROR Step $($step.Id): $_"
        $stepErrors += $step.Id

        Write-Host ""
        Write-Host "  Continuer malgre l'erreur ? " -NoNewline -ForegroundColor Yellow
        Write-Host "y" -NoNewline -ForegroundColor Green
        Write-Host "/" -NoNewline -ForegroundColor Gray
        Write-Host "n ? " -NoNewline -ForegroundColor Red
        $cont = Read-Host
        if ($cont.Trim().ToLower() -ne "y") { break }
    }

    if ($step.Id -eq 2 -and (Test-Path $script:DEV_CONFIG)) {
        $script:LOG_FILE = Join-Path $script:DEV_CONFIG "install.log"
        if (Test-Path (Join-Path $script:TMP_DIR "install_early.log")) {
            Get-Content (Join-Path $script:TMP_DIR "install_early.log") |
                Add-Content $script:LOG_FILE
        }
    }
}

if ($SkipCleanup) {
    Write-Warn "Nettoyage ignore (--SkipCleanup)."
}

$duration = (Get-Date) - $startTime
Write-Host ""
Write-Host "  =================================================================" -ForegroundColor Cyan
Write-Host "  INSTALLATION TERMINEE" -ForegroundColor Green
Write-Host "  Duree totale  : $([math]::Round($duration.TotalMinutes, 1)) min" -ForegroundColor White
Write-Host "  Etapes OK     : $($Steps.Count - $stepErrors.Count) / $($Steps.Count)" -ForegroundColor White
if ($stepErrors.Count -gt 0) {
    Write-Host "  Etapes en erreur : $($stepErrors -join ', ')" -ForegroundColor Red
}
Write-Host "  Log           : $($script:LOG_FILE)" -ForegroundColor White
Write-Host "  Dev folder    : $($script:DEV_ROOT)" -ForegroundColor White
Write-Host "  =================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Warn "Un redemarrage peut etre necessaire pour appliquer toutes les modifications PATH."
Write-Host ""
Write-Log "=== cfg-setup finished in $([math]::Round($duration.TotalMinutes,1)) min ==="
