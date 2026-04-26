package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class BunInstaller : ToolInstaller {
    override val toolName = "bun"
    override val description = "Bun — runtime JS/TS ultra-rapide (sans sudo)"
    override val requiresElevation = false

    override fun isInstalled() = ProcessRunner.run("bun", "--version").success
    override fun getVersion() = ProcessRunner.run("bun", "--version").stdout.trim()

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")
        return when {
            OsDetector.isWindows -> {
                val result = ProcessRunner.run(
                    "powershell", "-ExecutionPolicy", "Bypass", "-Command",
                    "irm https://bun.sh/install.ps1 | iex"
                )
                if (result.success) InstallResult.Success("Bun installé dans %USERPROFILE%\\.bun\\bin")
                else InstallResult.Failure(result.stderr)
            }
            else -> {
                val script = File("/tmp/bun-install.sh")
                if (!ProcessRunner.download("https://bun.sh/install", script))
                    return InstallResult.Failure("Échec du téléchargement")
                val result = ProcessRunner.run("bash", script.absolutePath)
                if (result.success) InstallResult.Success("Bun installé dans ~/.bun/bin")
                else InstallResult.Failure(result.stderr)
            }
        }
    }
}