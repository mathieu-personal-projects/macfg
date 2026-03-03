. "$PSScriptRoot\helpers.ps1"

Write-Header "ETAPE 1 : Installation et configuration de Git / GitBash"
Initialize-TmpDir

Write-Step "Telechargement de Git for Windows..."

$gitUrl  = Get-DownloadUrl "git"
$gitExe  = Join-Path $script:TMP_DIR "git-installer.exe"

if (-not $gitUrl) {
    Write-Err "URL introuvable dans links.ini pour 'git'. Abandon."
    exit 1
}

$ok = Get-Download -Url $gitUrl -Dest $gitExe
if (-not $ok) {
    Write-Err "Impossible de telecharger Git. Abandon."
    exit 1
}

Write-Step "Installation de Git for Windows..."

$gitInstallDir = "$env:LOCALAPPDATA\Programs\Git"
$gitArgs = @(
    "/VERYSILENT",
    "/NORESTART",
    "/NOCANCEL",
    "/SP-",
    "/SUPPRESSMSGBOXES",
    "/DIR=`"$gitInstallDir`"",
    "/COMPONENTS=gitlfs,assoc,assoc_sh",
    "/o:PathOption=Cmd",          # Git dans le PATH
    "/o:BashTerminalOption=MinTTY"
) -join " "

Start-Process -FilePath $gitExe -ArgumentList $gitArgs -Wait -NoNewWindow
Write-Log "Git installed from $gitExe"

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path","User")

$gitBin = Get-Command git -ErrorAction SilentlyContinue
if ($gitBin) {
    $gitVer = & git --version
    Write-Success "Git installe : $gitVer"
} else {
    Write-Warn "Git n'est pas encore dans le PATH. Relancez le terminal apres l'installation."
}

Write-Header "Configuration de Git"

Write-Host ""
Write-Host "  Renseignez vos informations Git :" -ForegroundColor Cyan
Write-Host ""

do {
    Write-Host "  Votre nom (ex: John Doe) : " -NoNewline -ForegroundColor Yellow
    $gitName = Read-Host
} while ([string]::IsNullOrWhiteSpace($gitName))

do {
    Write-Host "  Votre email Git          : " -NoNewline -ForegroundColor Yellow
    $gitEmail = Read-Host
} while ([string]::IsNullOrWhiteSpace($gitEmail))

Write-Step "Application de la configuration Git..."

$gitConfigs = @(
    @("user.name",              $gitName),
    @("user.email",             $gitEmail),
    @("core.editor",            "code --wait"),
    @("init.defaultBranch",     "main"),
    @("core.autocrlf",          "true"),
    @("color.ui",               "auto")
)

foreach ($cfg in $gitConfigs) {
    & git config --global $cfg[0] $cfg[1]
    Write-Info "$($cfg[0]) = $($cfg[1])"
}

Write-Log "Git configured for user: $gitName <$gitEmail>"
Write-Success "Git configure avec succes dans $HOME\.gitconfig"

Write-Step "Contenu de .gitconfig :"
Write-Host ""
Get-Content "$HOME\.gitconfig" | ForEach-Object { Write-Host "       $_" -ForegroundColor DarkCyan }
Write-Host ""
