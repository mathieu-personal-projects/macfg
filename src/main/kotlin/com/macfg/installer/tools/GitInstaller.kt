package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component

@Component
class GitInstaller : ToolInstaller {
    override val toolName = "git"
    override val description = "Git version control"
    override val requiresElevation = false

    override fun isInstalled() = ProcessRunner.run("git", "--version").success
    override fun getVersion() = ProcessRunner.run("git", "--version").stdout.trim()

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")
        return when {
            OsDetector.isWindows -> {
                val r = ProcessRunner.run("winget", "install", "Git.Git", "--scope", "user", "--silent")
                if (r.success) InstallResult.Success("Git installé via winget") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isLinux -> {
                val r = ProcessRunner.run("sudo", "apt-get", "install", "-y", "git")
                if (r.success) InstallResult.Success("Git installé") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isMac -> {
                val r = ProcessRunner.run("brew", "install", "git")
                if (r.success) InstallResult.Success("Git installé via Homebrew") else InstallResult.Failure(r.stderr)
            }
            else -> InstallResult.Failure("OS non supporté")
        }
    }
}