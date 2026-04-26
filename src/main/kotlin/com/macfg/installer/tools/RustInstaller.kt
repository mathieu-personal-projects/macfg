package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class RustInstaller : ToolInstaller {
    override val toolName = "rust"
    override val description = "Rust + Cargo via rustup (sans sudo)"
    override val requiresElevation = false

    override fun isInstalled() = ProcessRunner.run("rustc", "--version").success
    override fun getVersion() = ProcessRunner.run("rustc", "--version").stdout.trim()

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")
        return when {
            OsDetector.isWindows -> installWindows()
            else -> installUnix()
        }
    }

    private fun installWindows(): InstallResult {
        val installer = File(System.getenv("TEMP"), "rustup-init.exe")
        if (!ProcessRunner.download("https://win.rustup.rs/x86_64", installer))
            return InstallResult.Failure("Échec du téléchargement de rustup")
        val result = ProcessRunner.run(installer.absolutePath, "-y", "--no-modify-path")
        return if (result.success) InstallResult.Success("Rust installé via rustup dans ~/.cargo")
        else InstallResult.Failure(result.stderr)
    }

    private fun installUnix(): InstallResult {
        val script = File("/tmp/rustup.sh")
        if (!ProcessRunner.download("https://sh.rustup.rs", script))
            return InstallResult.Failure("Échec du téléchargement de rustup")
        val result = ProcessRunner.run("bash", script.absolutePath, "-y", "--no-modify-path")
        return if (result.success) InstallResult.Success("Rust installé via rustup dans ~/.cargo")
        else InstallResult.Failure(result.stderr)
    }
}