package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class BrunoInstaller : ToolInstaller {
    override val toolName = "bruno"
    override val description = "Bruno — client API REST (alternative Postman)"
    override val requiresElevation = false

    override fun isInstalled(): Boolean = when {
        OsDetector.isWindows -> File("${System.getenv("LOCALAPPDATA")}\\Programs\\Bruno").exists()
        OsDetector.isMac     -> File("/Applications/Bruno.app").exists()
        else -> ProcessRunner.run("bruno", "--version").success
    }

    override fun getVersion() = "Bruno (voir app)"

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion())
        return when {
            OsDetector.isWindows -> {
                val r = ProcessRunner.run("winget", "install", "Bruno.Bruno", "--scope", "user", "--silent")
                if (r.success) InstallResult.Success("Bruno installé via winget") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isLinux -> {
                val cmds = listOf(
                    listOf("bash", "-c", "curl -fsSL https://www.usebruno.com/downloads/linux/gpg | sudo gpg --dearmor -o /usr/share/keyrings/bruno.gpg"),
                    listOf("bash", "-c", "echo 'deb [signed-by=/usr/share/keyrings/bruno.gpg] https://apt.usebruno.com stable main' | sudo tee /etc/apt/sources.list.d/bruno.list"),
                    listOf("sudo", "apt-get", "update"),
                    listOf("sudo", "apt-get", "install", "-y", "bruno")
                )
                cmds.forEach { cmd ->
                    val r = ProcessRunner.run(*cmd.toTypedArray())
                    if (!r.success) return InstallResult.Failure(r.stderr)
                }
                InstallResult.Success("Bruno installé")
            }
            OsDetector.isMac -> {
                val r = ProcessRunner.run("brew", "install", "--cask", "bruno")
                if (r.success) InstallResult.Success("Bruno installé via Homebrew") else InstallResult.Failure(r.stderr)
            }
            else -> InstallResult.Failure("OS non supporté")
        }
    }
}