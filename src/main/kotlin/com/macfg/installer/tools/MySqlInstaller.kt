package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component

@Component
class MySqlInstaller : ToolInstaller {
    override val toolName = "mysql"
    override val description = "MySQL Community Server"
    override val requiresElevation = true

    override fun isInstalled() = ProcessRunner.run("mysql", "--version").success
    override fun getVersion() = ProcessRunner.run("mysql", "--version").stdout.trim()

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")
        return when {
            OsDetector.isWindows -> {
                val r = ProcessRunner.run("winget", "install", "Oracle.MySQL", "--silent")
                if (r.success) InstallResult.Success("MySQL installé via winget") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isLinux -> {
                val r = ProcessRunner.run("sudo", "apt-get", "install", "-y", "mysql-server")
                if (r.success) InstallResult.Success("MySQL installé") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isMac -> {
                val r = ProcessRunner.run("brew", "install", "mysql")
                if (r.success) InstallResult.Success("MySQL installé via Homebrew") else InstallResult.Failure(r.stderr)
            }
            else -> InstallResult.Failure("OS non supporté")
        }
    }
}