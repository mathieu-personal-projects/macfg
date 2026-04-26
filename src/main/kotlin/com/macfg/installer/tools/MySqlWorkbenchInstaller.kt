package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class MySqlWorkbenchInstaller : ToolInstaller {
    override val toolName = "mysql-workbench"
    override val description = "MySQL Workbench — GUI pour MySQL"
    override val requiresElevation = true

    override fun isInstalled(): Boolean = when {
        OsDetector.isWindows -> File("C:\\Program Files\\MySQL\\MySQL Workbench 8.0").exists()
        OsDetector.isMac     -> File("/Applications/MySQLWorkbench.app").exists()
        else -> ProcessRunner.run("mysql-workbench", "--version").success
    }

    override fun getVersion() = "MySQL Workbench (voir app)"

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion())
        return when {
            OsDetector.isWindows -> {
                val r = ProcessRunner.run("winget", "install", "Oracle.MySQLWorkbench", "--silent")
                if (r.success) InstallResult.Success("MySQL Workbench installé via winget") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isLinux -> {
                val r = ProcessRunner.run("sudo", "apt-get", "install", "-y", "mysql-workbench-community")
                if (r.success) InstallResult.Success("MySQL Workbench installé") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isMac -> {
                val r = ProcessRunner.run("brew", "install", "--cask", "mysqlworkbench")
                if (r.success) InstallResult.Success("MySQL Workbench installé via Homebrew") else InstallResult.Failure(r.stderr)
            }
            else -> InstallResult.Failure("OS non supporté")
        }
    }
}