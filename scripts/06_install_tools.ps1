. "$PSScriptRoot\helpers.ps1"

Write-Header "ETAPE 6 : Installation des outils (BIN / DB / LANG)"
Initialize-TmpDir

$alreadyInstalled = @("git","gitbash","code","bruno","wsl","JetBrains_Mono","Cascadia_Mono","Fira_Code")

# Format : nom_outil => @{ args silencieux ; post-script facultatif }
$toolStrategies = @{
    docker         = @{ Silent = ""; PostInstall = {
        Write-Info "Ajout de docker au PATH systeme..."
        $dockerPath = "C:\Program Files\Docker\Docker\resources\bin"
        $cur = [System.Environment]::GetEnvironmentVariable("Path","User")
        if ($cur -notmatch [regex]::Escape($dockerPath)) {
            [System.Environment]::SetEnvironmentVariable("Path", "$cur;$dockerPath", "User")
        }
    }}
    docker_compose = @{ Silent = ""; PostInstall = {
        # docker-compose est un exe a placer dans le PATH
        $dcDest = "$env:LOCALAPPDATA\Programs\docker-compose.exe"
        $dcSrc  = Join-Path $script:TMP_DIR "docker_compose-installer.exe"
        if (Test-Path $dcSrc) { Copy-Item $dcSrc $dcDest -Force }
        $cur = [System.Environment]::GetEnvironmentVariable("Path","User")
        $dir = Split-Path $dcDest
        if ($cur -notmatch [regex]::Escape($dir)) {
            [System.Environment]::SetEnvironmentVariable("Path","$cur;$dir","User")
        }
    }}
    make           = @{ Silent = ""; PostInstall = $null }
    mongodb        = @{ Silent = "/S"; PostInstall = {
        $shortcut = Join-Path $script:DEV_SOFT "MongoDB.lnk"
        $target   = "C:\Program Files\MongoDB\Server\7.0\bin\mongod.exe"
        if (Test-Path $target) { New-Shortcut $shortcut $target -Description "MongoDB Server" }
    }}
    mysql          = @{ Silent = ""; PostInstall = {
        $shortcut = Join-Path $script:DEV_SOFT "MySQL Installer.lnk"
        $target   = "C:\Program Files (x86)\MySQL\MySQL Installer for Windows\MySQLInstaller.exe"
        if (Test-Path $target) { New-Shortcut $shortcut $target -Description "MySQL Installer" }
    }}
    postgresql     = @{ Silent = ""; PostInstall = $null }
    python         = @{ Silent = ""; PostInstall = $null }
    java           = @{ Silent = ""; PostInstall = {
        # JDK extrait en ZIP : definir JAVA_HOME
        $jdkDir = Join-Path $script:TMP_DIR "java"
        $jdkExtracted = Get-ChildItem $jdkDir -Directory | Select-Object -First 1
        if ($jdkExtracted) {
            $jdkDest = "$HOME\jdk21"
            if (-not (Test-Path $jdkDest)) {
                Copy-Item $jdkExtracted.FullName $jdkDest -Recurse -Force
            }
            [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $jdkDest, "User")
            $cur = [System.Environment]::GetEnvironmentVariable("Path","User")
            if ($cur -notmatch "jdk21") {
                [System.Environment]::SetEnvironmentVariable("Path","$cur;$jdkDest\bin","User")
            }
            Write-Success "JAVA_HOME defini : $jdkDest"

            $vsSettings = Join-Path $env:APPDATA "Code\User\settings.json"
            if (Test-Path $vsSettings) {
                $content = Get-Content $vsSettings -Raw
                $content = $content -replace '"java\.jdt\.ls\.java\.home":\s*"[^"]*"',
                           "`"java.jdt.ls.java.home`": `"$($jdkDest -replace '\\','\\')`""
                Set-Content -Path $vsSettings -Value $content -Encoding UTF8
                Write-Info "settings.json VSCode mis a jour avec java.home"
            }
        }
    }}
    rust           = @{ Silent = "-y --no-modify-path"; PostInstall = {
        $cur = [System.Environment]::GetEnvironmentVariable("Path","User")
        if ($cur -notmatch "\.cargo\\bin") {
            [System.Environment]::SetEnvironmentVariable("Path","$cur;$HOME\.cargo\bin","User")
        }
    }}
}

$toolMeta = @{
    docker         = @{ Label = "Docker Engine"          ; Ext = ".zip"  }
    docker_compose = @{ Label = "Docker Compose"         ; Ext = ".exe"  }
    make           = @{ Label = "GNU Make"                ; Ext = ".exe"  }
    mongodb        = @{ Label = "MongoDB 7"               ; Ext = ".zip"  }
    mysql          = @{ Label = "MySQL 8 Installer"       ; Ext = ".msi"  }
    postgresql     = @{ Label = "PostgreSQL 14"           ; Ext = ".zip"  }
    python         = @{ Label = "Python Manager (uv/msix)"; Ext = ".msix" }
    java           = @{ Label = "OpenJDK 21 (Temurin)"   ; Ext = ".zip"  }
    rust           = @{ Label = "Rust (rustup)"           ; Ext = ".exe"  }
}

$ini       = Read-Ini $script:USERINI_FILE
$sections  = @("BIN","DB","LANG")
$toolsList = @()

foreach ($section in $sections) {
    $raw = $ini["tools"]
    if ($raw) {
        foreach ($key in $raw.Keys) {
            if ($key.ToUpper() -eq $section) {
                ($raw[$key] -split ",") | ForEach-Object {
                    $t = $_.Trim()
                    if ($t -and $t -notin $alreadyInstalled) {
                        $toolsList += @{ Name = $t; Section = $section }
                    }
                }
            }
        }
    }
}

if ($toolsList.Count -eq 0) {
    Write-Info "Aucun outil a installer dans BIN / DB / LANG."
    exit 0
}

Write-Host ""
Write-Host "  Les outils suivants peuvent etre installes :" -ForegroundColor Cyan
Write-Host "  Repondez " -NoNewline -ForegroundColor White
Write-Host "y" -NoNewline -ForegroundColor Green
Write-Host " pour installer, " -NoNewline -ForegroundColor White
Write-Host "n" -NoNewline -ForegroundColor Red
Write-Host " pour passer." -ForegroundColor White
Write-Host ""

foreach ($tool in $toolsList) {
    $name  = $tool.Name
    $meta  = $toolMeta[$name]
    $label = if ($meta) { $meta.Label } else { $name.ToUpper() }

    $install = Ask-YesNo $label
    if (-not $install) {
        Write-Info "Ignore : $name"
        Write-Log "Skipped: $name"
        continue
    }

    Write-Step "Installation de $label..."

    $url = Get-DownloadUrl $name
    if (-not $url -or $url -eq "") {
        Write-Warn "Pas d'URL dans links.ini pour '$name'. Installation ignoree."
        continue
    }

    $ext       = if ($meta) { $meta.Ext } else { [System.IO.Path]::GetExtension($url) }
    $destFile  = Join-Path $script:TMP_DIR "${name}-installer${ext}"

    $ok = Get-Download -Url $url -Dest $destFile
    if (-not $ok) { continue }

    if ($ext -eq ".zip") {
        $extractDir = Join-Path $script:TMP_DIR $name
        Expand-Archive -Path $destFile -DestinationPath $extractDir -Force
        Write-Info "Archive extraite dans : $extractDir"
    } elseif ($ext -eq ".msix") {
        Add-AppxPackage -Path $destFile -ErrorAction SilentlyContinue
    } elseif ($ext -eq ".msi") {
        $strategy = $toolStrategies[$name]
        $sArgs    = if ($strategy -and $strategy.Silent) { $strategy.Silent } else { "" }
        Start-Process msiexec.exe -ArgumentList "/i `"$destFile`" /qn /norestart $sArgs" -Wait -NoNewWindow
    } elseif ($ext -eq ".exe") {
        $strategy = $toolStrategies[$name]
        $sArgs    = if ($strategy -and $strategy.Silent) { $strategy.Silent } else { "/S" }
        Start-Process -FilePath $destFile -ArgumentList $sArgs -Wait -NoNewWindow
    }

    $strategy = $toolStrategies[$name]
    if ($strategy -and $strategy.PostInstall) {
        & $strategy.PostInstall
    }

    Write-Success "$label installe."
    Write-Log "Installed: $name"
}

Write-Host ""
Write-Success "Installation des outils terminee."
