package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class MakeInstaller : ToolInstaller {
    override val toolName = "make"
    override val description = "GNU Make (via winget/apt/brew)"
    override val requiresElevation get() = OsDetector.isWindows

    override fun isInstalled() = ProcessRunner.run("make", "--version").success
    override fun getVersion() = ProcessRunner.run("make", "--version").stdout.lines().firstOrNull()

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")
        return when {
            OsDetector.isWindows -> {
                val r = ProcessRunner.run("winget", "install", "GnuWin32.Make", "--silent")
                if (r.success) InstallResult.Success("make installé via winget") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isLinux -> {
                val r = ProcessRunner.run("sudo", "apt-get", "install", "-y", "build-essential")
                if (r.success) InstallResult.Success("make + build-essential installés") else InstallResult.Failure(r.stderr)
            }
            OsDetector.isMac -> {
                val r = ProcessRunner.run("xcode-select", "--install")
                if (r.success) InstallResult.Success("make installé via Xcode CLT") else InstallResult.Failure(r.stderr)
            }
            else -> InstallResult.Failure("OS non supporté")
        }
    }
}