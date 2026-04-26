package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class UvInstaller : ToolInstaller {
    override val toolName = "uv"
    override val description = "uv — gestionnaire de paquets Python ultra-rapide (sans sudo)"
    override val requiresElevation = false

    override fun isInstalled() = ProcessRunner.run("uv", "--version").success
    override fun getVersion() = ProcessRunner.run("uv", "--version").stdout.trim()

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")
        return when {
            OsDetector.isWindows -> {
                val result = ProcessRunner.run(
                    "powershell", "-ExecutionPolicy", "Bypass", "-Command",
                    "irm https://astral.sh/uv/install.ps1 | iex"
                )
                if (result.success) InstallResult.Success("uv installé dans %USERPROFILE%\\.cargo\\bin")
                else InstallResult.Failure(result.stderr)
            }
            else -> {
                val script = File("/tmp/uv-install.sh")
                if (!ProcessRunner.download("https://astral.sh/uv/install.sh", script))
                    return InstallResult.Failure("Échec du téléchargement")
                val result = ProcessRunner.run("bash", script.absolutePath)
                if (result.success) InstallResult.Success("uv installé dans ~/.cargo/bin")
                else InstallResult.Failure(result.stderr)
            }
        }
    }
}