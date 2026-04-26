package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class DockerInstaller : ToolInstaller {
    override val toolName = "docker"
    override val description = "Docker Engine (nécessite sudo sur Linux)"
    override val requiresElevation = true 

    override fun isInstalled(): Boolean = ProcessRunner.run("docker", "--version").success
    override fun getVersion(): String? = ProcessRunner.run("docker", "--version").stdout.trim()

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
        val installer = File(System.getenv("TEMP"), "DockerDesktopInstaller.exe")
        ProcessRunner.download(
            "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe", installer)
        val result = ProcessRunner.run(installer.absolutePath, "install", "--quiet")
        return if (result.success) InstallResult.Success("Docker Desktop installé")
        else InstallResult.Failure(result.stderr)
    }

    private fun installLinux(): InstallResult {
        println("Installation de Docker (sudo requis)...")
        val script = File("/tmp/get-docker.sh")
        ProcessRunner.download("https://get.docker.com", script)
        val result = ProcessRunner.run("sudo", "bash", script.absolutePath)
        if (!result.success) return InstallResult.Failure(result.stderr)

        ProcessRunner.run("sudo", "usermod", "-aG", "docker", System.getProperty("user.name"))
        return InstallResult.Success("Docker installé. Relancez votre session pour utiliser sans sudo.")
    }

    private fun installMac(): InstallResult {
        val brew = ProcessRunner.run("brew", "install", "--cask", "docker")
        return if (brew.success) InstallResult.Success("Docker Desktop installé via Homebrew")
        else InstallResult.Failure("Homebrew requis : https://brew.sh")
    }
}