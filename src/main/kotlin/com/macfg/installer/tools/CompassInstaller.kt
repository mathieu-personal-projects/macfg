package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class CompassInstaller : ToolInstaller {
    override val toolName = "compass"
    override val description = "MongoDB Compass — GUI pour MongoDB"
    override val requiresElevation = false

    override fun isInstalled(): Boolean = when {
        OsDetector.isWindows -> File("${System.getenv("LOCALAPPDATA")}\\Programs\\MongoDB Compass").exists()
        OsDetector.isMac     -> File("/Applications/MongoDB Compass.app").exists()
        else -> ProcessRunner.run("mongodb-compass", "--version").success
    }

    override fun getVersion() = "MongoDB Compass (voir app)"

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion())
        return when {
            OsDetector.isWindows -> {
                val r = ProcessRunner.run("winget", "install", "MongoDB.Compass.Community", "--scope", "user", "--silent")
                if (r.success) InstallResult.Success("MongoDB Compass installé via winget") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isLinux -> {
                val deb = File("/tmp/compass.deb")
                if (!ProcessRunner.download(
                        "https://downloads.mongodb.com/compass/mongodb-compass_1.42.2_amd64.deb", deb))
                    return InstallResult.Failure("Échec du téléchargement")
                val r = ProcessRunner.run("sudo", "dpkg", "-i", deb.absolutePath)
                if (r.success) InstallResult.Success("MongoDB Compass installé") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isMac -> {
                val r = ProcessRunner.run("brew", "install", "--cask", "mongodb-compass")
                if (r.success) InstallResult.Success("MongoDB Compass installé via Homebrew") else InstallResult.Failure(r.stderr)
            }
            else -> InstallResult.Failure("OS non supporté")
        }
    }
}