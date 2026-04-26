package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class PgAdminInstaller : ToolInstaller {
    override val toolName = "pgadmin"
    override val description = "pgAdmin 4 — GUI pour PostgreSQL"
    override val requiresElevation = true 

    override fun isInstalled(): Boolean = when {
        OsDetector.isWindows -> File("C:\\Program Files\\pgAdmin 4").exists()
        OsDetector.isMac     -> File("/Applications/pgAdmin 4.app").exists()
        else -> ProcessRunner.run("pgadmin4", "--version").success
    }

    override fun getVersion() = "pgAdmin 4 (voir app)"

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion())
        return when {
            OsDetector.isWindows -> {
                val r = ProcessRunner.run("winget", "install", "PostgreSQL.pgAdmin", "--silent")
                if (r.success) InstallResult.Success("pgAdmin 4 installé via winget") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isLinux -> {
                val cmds = listOf(
                    listOf("bash", "-c", "curl -fsSL https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/pgadmin.gpg"),
                    listOf("bash", "-c", "echo 'deb [signed-by=/usr/share/keyrings/pgadmin.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/jammy pgadmin4 main' | sudo tee /etc/apt/sources.list.d/pgadmin4.list"),
                    listOf("sudo", "apt-get", "update"),
                    listOf("sudo", "apt-get", "install", "-y", "pgadmin4-desktop")
                )
                cmds.forEach { cmd ->
                    val r = ProcessRunner.run(*cmd.toTypedArray())
                    if (!r.success) return InstallResult.Failure(r.stderr)
                }
                InstallResult.Success("pgAdmin 4 installé")
            }
            OsDetector.isMac -> {
                val r = ProcessRunner.run("brew", "install", "--cask", "pgadmin4")
                if (r.success) InstallResult.Success("pgAdmin 4 installé via Homebrew") else InstallResult.Failure(r.stderr)
            }
            else -> InstallResult.Failure("OS non supporté")
        }
    }
}