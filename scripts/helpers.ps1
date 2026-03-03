$script:CFG_ROOT      = Split-Path -Parent $PSScriptRoot          # racine du repo
$script:CONF_DIR      = Join-Path $CFG_ROOT "conf"
$script:LINKS_FILE    = Join-Path $CONF_DIR "links.ini"
$script:USERINI_FILE  = Join-Path $CONF_DIR "user.ini"
$script:SETTINGS_FILE = Join-Path $CONF_DIR "settings.json"

$script:DEV_ROOT      = Join-Path $HOME "dev"
$script:DEV_DOC       = Join-Path $DEV_ROOT "doc"
$script:DEV_SOFT      = Join-Path $DEV_ROOT "softwares"
$script:DEV_CONFIG    = Join-Path $DEV_ROOT "config"
$script:DEV_FONTS     = Join-Path $DEV_CONFIG "fonts"
$script:DEV_SSH       = Join-Path $DEV_CONFIG "ssh"

$script:TMP_DIR       = Join-Path $env:TEMP "cfg-setup-install"
$script:LOG_FILE      = Join-Path $DEV_CONFIG "install.log"

function Write-Header {
    param([string]$Text)
    $line = "=" * 60
    Write-Host ""
    Write-Host $line                             -ForegroundColor Cyan
    Write-Host "  $Text"                         -ForegroundColor Cyan
    Write-Host $line                             -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Text)
    Write-Host "`n  >> $Text" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Text)
    Write-Host "  [OK] $Text" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host "  [!!] $Text" -ForegroundColor DarkYellow
}

function Write-Err {
    param([string]$Text)
    Write-Host "  [KO] $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "       $Text" -ForegroundColor Gray
}

function Write-Log {
    param([string]$Text)
    $ts = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    "[${ts}] $Text" | Out-File -Append -Encoding utf8 $script:LOG_FILE
}

# hashtable [section][key] = value
function Read-Ini {
    param([string]$Path)
    $result  = @{}
    $section = "_"
    foreach ($line in Get-Content $Path) {
        $line = $line.Trim()
        if ($line -match '^\[(.+)\]$')                { $section = $Matches[1]; $result[$section] = @{} }
        elseif ($line -match '^([^=;#]+)=(.*)$')      {
            $k = $Matches[1].Trim()
            $v = $Matches[2].Trim().Trim('"')
            if (-not $result[$section]) { $result[$section] = @{} }
            $result[$section][$k] = $v
        }
    }
    return $result
}

function Get-DownloadUrl {
    param([string]$ToolName)
    foreach ($line in Get-Content $script:LINKS_FILE) {
        $line = $line.Trim()
        if ($line -match "^${ToolName}\s*=\s*`"?([^`"]+)`"?") {
            return $Matches[1].Trim()
        }
    }
    return $null
}

function Get-IniList {
    param([string]$Section, [string]$Key)
    $ini = Read-Ini $script:USERINI_FILE
    if ($ini[$Section] -and $ini[$Section][$Key]) {
        return ($ini[$Section][$Key] -split ',') | ForEach-Object { $_.Trim() }
    }
    return @()
}

function Get-Download {
    param(
        [string]$Url,
        [string]$Dest       # chemin complet destination
    )
    if (-not $Url -or $Url -eq "") {
        Write-Warn "Pas d'URL definie pour ce telechargement."
        return $false
    }
    if (Test-Path $Dest) {
        Write-Info "Fichier deja present : $(Split-Path $Dest -Leaf)"
        return $true
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $Dest) | Out-Null
    Write-Info "Telechargement : $Url"
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing -ErrorAction Stop
        Write-Success "Telecharge : $(Split-Path $Dest -Leaf)"
        Write-Log "Downloaded: $Url -> $Dest"
        return $true
    } catch {
        Write-Err "Echec du telechargement : $_"
        Write-Log "ERROR downloading $Url : $_"
        return $false
    }
}

function Invoke-Install {
    param(
        [string]$Installer,   # chemin vers le fichier a installer
        [string]$Silent = ""  # arguments silencieux optionnels
    )
    $ext = [System.IO.Path]::GetExtension($Installer).ToLower()
    Write-Info "Installation de : $(Split-Path $Installer -Leaf)"
    switch ($ext) {
        ".exe" {
            $args = if ($Silent) { $Silent } else { "/S /SILENT /NORESTART" }
            Start-Process -FilePath $Installer -ArgumentList $args -Wait -NoNewWindow
        }
        ".msi" {
            $args = "/i `"$Installer`" /qn /norestart"
            if ($Silent) { $args += " $Silent" }
            Start-Process msiexec.exe -ArgumentList $args -Wait -NoNewWindow
        }
        ".msix" {
            Add-AppxPackage -Path $Installer -ErrorAction Stop
        }
        ".zip" {
            $dest = Join-Path (Split-Path $Installer) ([System.IO.Path]::GetFileNameWithoutExtension($Installer))
            Expand-Archive -Path $Installer -DestinationPath $dest -Force
            Write-Info "Extrait dans : $dest"
            return $dest
        }
        default {
            Write-Warn "Format non gere automatiquement : $ext"
        }
    }
    Write-Log "Installed: $Installer"
}

function New-Shortcut {
    param(
        [string]$ShortcutPath,   # chemin complet du .lnk
        [string]$Target,          # exe cible
        [string]$Arguments = "",
        [string]$IconPath  = "",
        [string]$Description = ""
    )
    $WS  = New-Object -ComObject WScript.Shell
    $lnk = $WS.CreateShortcut($ShortcutPath)
    $lnk.TargetPath       = $Target
    if ($Arguments)   { $lnk.Arguments    = $Arguments }
    if ($IconPath)    { $lnk.IconLocation = $IconPath }
    if ($Description) { $lnk.Description  = $Description }
    $lnk.Save()
    Write-Success "Raccourci cree : $(Split-Path $ShortcutPath -Leaf)"
}

function Ask-YesNo {
    param([string]$ToolLabel)
    Write-Host ""
    Write-Host "  --> Installation de " -NoNewline -ForegroundColor White
    Write-Host $ToolLabel               -NoNewline -ForegroundColor Magenta
    Write-Host " : "                   -NoNewline -ForegroundColor White
    Write-Host "y"                      -NoNewline -ForegroundColor Green
    Write-Host "/"                      -NoNewline -ForegroundColor Gray
    Write-Host "n"                      -NoNewline -ForegroundColor Red
    Write-Host " ? "                   -NoNewline -ForegroundColor White
    $answer = Read-Host
    return ($answer.Trim().ToLower() -eq "y")
}

function Initialize-TmpDir {
    New-Item -ItemType Directory -Force -Path $script:TMP_DIR | Out-Null
}
