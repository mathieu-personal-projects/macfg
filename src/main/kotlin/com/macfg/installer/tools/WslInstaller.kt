package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component

@Component
class WslInstaller : ToolInstaller {
    override val toolName = "wsl"
    override val description = "Windows Subsystem for Linux (admin requis)"
    override val requiresElevation = true

    override fun isInstalled(): Boolean =
        OsDetector.isWindows && ProcessRunner.run("wsl", "--status").success

    override fun getVersion(): String? =
        ProcessRunner.run("wsl", "--version").stdout.lines().firstOrNull()

    override fun install(): InstallResult {
        if (!OsDetector.isWindows) return InstallResult.Failure("WSL uniquement sur Windows")
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")

        println("Activation de WSL (nécessite un redémarrage)...")
        val result = ProcessRunner.run(
            "powershell", "-Command",
            "Start-Process wsl -ArgumentList '--install' -Verb RunAs -Wait"
        )
        return if (result.success)
            InstallResult.Success("WSL installé. Redémarrage requis.")
        else InstallResult.Failure(result.stderr)
    }
}