package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class MongoDbInstaller : ToolInstaller {
    override val toolName = "mongodb"
    override val description = "MongoDB Community Server"
    override val requiresElevation = true

    override fun isInstalled() = ProcessRunner.run("mongod", "--version").success
    override fun getVersion() = ProcessRunner.run("mongod", "--version").stdout.lines().firstOrNull()

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")
        return when {
            OsDetector.isWindows -> installWindows()
            OsDetector.isLinux   -> installLinux()
            OsDetector.isMac     -> installMac()
            else -> InstallResult.Failure("OS non supporté")
        }
    }

    private fun installWindows(): InstallResult {
        val result = ProcessRunner.run(
            "winget", "install", "MongoDB.Server", "--silent"
        )
        return if (result.success) InstallResult.Success("MongoDB installé via winget")
        else InstallResult.Failure(result.stderr)
    }

    private fun installLinux(): InstallResult {
        val cmds = listOf(
            listOf("bash", "-c", "curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor"),
            listOf("bash", "-c", "echo 'deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list"),
            listOf("sudo", "apt-get", "update"),
            listOf("sudo", "apt-get", "install", "-y", "mongodb-org")
        )
        for (cmd in cmds) {
            val result = ProcessRunner.run(*cmd.toTypedArray())
            if (!result.success) return InstallResult.Failure(result.stderr)
        }
        return InstallResult.Success("MongoDB 7 installé")
    }

    private fun installMac(): InstallResult {
        ProcessRunner.run("brew", "tap", "mongodb/brew")
        val result = ProcessRunner.run("brew", "install", "mongodb-community@7.0")
        return if (result.success) InstallResult.Success("MongoDB installé via Homebrew")
        else InstallResult.Failure(result.stderr)
    }
}