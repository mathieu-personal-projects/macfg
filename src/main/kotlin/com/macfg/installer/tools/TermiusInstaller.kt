package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class TermiusInstaller : ToolInstaller {
    override val toolName = "termius"
    override val description = "Termius SSH client"
    override val requiresElevation = false 

    override fun isInstalled(): Boolean {
        return when {
            OsDetector.isWindows -> File("${System.getenv("LOCALAPPDATA")}\\Programs\\Termius").exists()
            OsDetector.isLinux   -> ProcessRunner.run("termius-app", "--version").success
            OsDetector.isMac     -> File("/Applications/Termius.app").exists()
            else -> false
        }
    }

    override fun getVersion() = "Termius (voir app)"

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion())
        return when {
            OsDetector.isWindows -> {
                val r = ProcessRunner.run("winget", "install", "Termius.Termius", "--scope", "user", "--silent")
                if (r.success) InstallResult.Success("Termius installé via winget") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isLinux -> {
                val snap = ProcessRunner.run("snap", "install", "termius-app")
                if (snap.success) return InstallResult.Success("Termius installé via snap")
                val deb = File("/tmp/termius.deb")
                if (!ProcessRunner.download("https://www.termius.com/download/linux/Termius.deb", deb))
                    return InstallResult.Failure("Échec du téléchargement")
                val r = ProcessRunner.run("sudo", "dpkg", "-i", deb.absolutePath)
                if (r.success) InstallResult.Success("Termius installé") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isMac -> {
                val r = ProcessRunner.run("brew", "install", "--cask", "termius")
                if (r.success) InstallResult.Success("Termius installé via Homebrew") else InstallResult.Failure(r.stderr)
            }
            else -> InstallResult.Failure("OS non supporté")
        }
    }
}