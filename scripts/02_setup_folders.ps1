. "$PSScriptRoot\helpers.ps1"

Write-Header "ETAPE 2 : Creation de l'arborescence ~/dev"

$folders = @(
    $script:DEV_ROOT,
    $script:DEV_DOC,
    $script:DEV_SOFT,
    $script:DEV_CONFIG,
    $script:DEV_FONTS,
    $script:DEV_SSH,
    (Join-Path $script:DEV_CONFIG "backup"),
    (Join-Path $script:DEV_CONFIG "vscode")
)

foreach ($folder in $folders) {
    if (Test-Path $folder) {
        Write-Info "Existe deja : $folder"
    } else {
        New-Item -ItemType Directory -Force -Path $folder | Out-Null
        Write-Success "Cree : $folder"
    }
    Write-Log "Folder ensured: $folder"
}

Write-Host ""
Write-Success "Arborescence ~/dev creee :"
Write-Host ""
Write-Host "       $HOME\" -ForegroundColor DarkCyan
Write-Host "       └── dev\" -ForegroundColor DarkCyan
Write-Host "           ├── doc\         (projets et documentation)" -ForegroundColor Gray
Write-Host "           ├── softwares\   (raccourcis des applications)" -ForegroundColor Gray
Write-Host "           └── config\      (cles SSH, polices, sauvegardes)" -ForegroundColor Gray
Write-Host "               ├── fonts\" -ForegroundColor Gray
Write-Host "               ├── ssh\" -ForegroundColor Gray
Write-Host "               ├── backup\" -ForegroundColor Gray
Write-Host "               └── vscode\" -ForegroundColor Gray
Write-Host ""
