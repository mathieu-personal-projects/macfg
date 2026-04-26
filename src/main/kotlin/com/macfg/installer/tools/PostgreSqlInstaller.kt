package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component

@Component
class PostgreSqlInstaller : ToolInstaller {
    override val toolName = "postgresql"
    override val description = "PostgreSQL (avec pgAdmin)"
    override val requiresElevation = true

    override fun isInstalled() = ProcessRunner.run("psql", "--version").success
    override fun getVersion() = ProcessRunner.run("psql", "--version").stdout.trim()

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")
        return when {
            OsDetector.isWindows -> ProcessRunner.run(
                "winget", "install", "PostgreSQL.PostgreSQL.16", "--silent"
            ).let { if (it.success) InstallResult.Success("PostgreSQL 16 installé via winget") else InstallResult.Failure(it.stderr) }

            OsDetector.isLinux -> {
                val cmds = listOf(
                    listOf("bash", "-c", "curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg"),
                    listOf("bash", "-c", "echo 'deb [signed-by=/usr/share/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt jammy-pgdg main' | sudo tee /etc/apt/sources.list.d/pgdg.list"),
                    listOf("sudo", "apt-get", "update"),
                    listOf("sudo", "apt-get", "install", "-y", "postgresql-16")
                )
                cmds.forEach { cmd ->
                    val r = ProcessRunner.run(*cmd.toTypedArray())
                    if (!r.success) return InstallResult.Failure(r.stderr)
                }
                InstallResult.Success("PostgreSQL 16 installé")
            }

            OsDetector.isMac -> {
                val r = ProcessRunner.run("brew", "install", "postgresql@16")
                if (r.success) InstallResult.Success("PostgreSQL 16 installé via Homebrew") else InstallResult.Failure(r.stderr)
            }

            else -> InstallResult.Failure("OS non supporté")
        }
    }
}