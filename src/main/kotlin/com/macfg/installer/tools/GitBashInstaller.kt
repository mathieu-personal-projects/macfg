package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class GitBashInstaller : ToolInstaller {
    override val toolName = "gitbash"
    override val description = "Git for Windows (inclut Git Bash) — Windows seulement"
    override val requiresElevation = false 

    override fun isInstalled(): Boolean {
        if (!OsDetector.isWindows) return true
        return File("C:\\Program Files\\Git\\bin\\bash.exe").exists() ||
               ProcessRunner.run("git", "--version").success
    }

    override fun getVersion() = ProcessRunner.run("git", "--version").stdout.trim()

    override fun install(): InstallResult {
        if (!OsDetector.isWindows) return InstallResult.AlreadyInstalled("bash natif disponible")
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")

        val installer = File(System.getenv("TEMP"), "git-installer.exe")
        if (!ProcessRunner.download(
                "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe",
                installer))
            return InstallResult.Failure("Échec du téléchargement")

        val result = ProcessRunner.run(
            installer.absolutePath,
            "/VERYSILENT", "/NORESTART",
            "/COMPONENTS=icons,ext\\reg\\shellhere,assoc,assoc_sh"
        )
        return if (result.success) InstallResult.Success("Git Bash installé")
        else InstallResult.Failure(result.stderr)
    }
}