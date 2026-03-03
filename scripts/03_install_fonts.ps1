. "$PSScriptRoot\helpers.ps1"

Write-Header "ETAPE 3 : Installation des polices"
Initialize-TmpDir

$directFonts = @("JetBrains_Mono")
$browserFonts = @("Cascadia_Mono", "Fira_Code")

$fontsWinDir = "$env:WINDIR\Fonts"

function Install-FontFiles {
    param([string]$SourceDir)
    $fontFiles = Get-ChildItem -Path $SourceDir -Recurse -Include "*.ttf","*.otf"
    if (-not $fontFiles) {
        Write-Warn "Aucun fichier de police trouve dans : $SourceDir"
        return
    }
    foreach ($font in $fontFiles) {
        $dest = Join-Path $fontsWinDir $font.Name
        if (-not (Test-Path $dest)) {
            Copy-Item -Path $font.FullName -Destination $dest -Force
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            $regName = [System.IO.Path]::GetFileNameWithoutExtension($font.Name)
            New-ItemProperty -Path $regPath -Name $regName -Value $font.Name `
                             -PropertyType String -Force | Out-Null
            Write-Success "Police installee : $($font.Name)"
        } else {
            Write-Info "Deja installee   : $($font.Name)"
        }
    }
}

function Copy-FontsToConfig {
    param([string]$SourceDir, [string]$FontName)
    $destDir = Join-Path $script:DEV_FONTS $FontName
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Copy-Item -Path "$SourceDir\*" -Destination $destDir -Recurse -Force
    Write-Info "Copie dans : $destDir"
}

foreach ($fontName in $directFonts) {
    Write-Step "Police : $fontName"
    $url = Get-DownloadUrl $fontName
    if (-not $url -or $url -eq "") {
        Write-Warn "Pas d'URL pour $fontName, ignore."
        continue
    }

    $zipFile = Join-Path $script:TMP_DIR "$fontName.zip"
    $ok = Get-Download -Url $url -Dest $zipFile
    if (-not $ok) { continue }

    $extractDir = Join-Path $script:TMP_DIR $fontName
    Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force

    Write-Info "Installation des fichiers de police..."
    Install-FontFiles -SourceDir $extractDir
    Copy-FontsToConfig -SourceDir $extractDir -FontName $fontName
    Write-Log "Font installed: $fontName"
}

foreach ($fontName in $browserFonts) {
    Write-Step "Police : $fontName (Google Fonts)"
    $url = Get-DownloadUrl $fontName
    Write-Warn "Telechargement automatique impossible pour Google Fonts."
    Write-Info "Ouverture du navigateur : $url"
    if ($url) { Start-Process $url }
    Write-Info "Telechargez le ZIP manuellement, extrayez et placez les .ttf dans :"
    Write-Info "  $fontsWinDir"
    Write-Info "  puis copiez les fichiers dans : $(Join-Path $script:DEV_FONTS $fontName)"
}

Write-Host ""
Write-Success "Etape polices terminee. Fichiers sauvegardes dans : $($script:DEV_FONTS)"
