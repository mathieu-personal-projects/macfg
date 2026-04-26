package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class NodeInstaller : ToolInstaller {
    override val toolName = "node"
    override val description = "Node.js LTS via nvm (sans sudo)"
    override val requiresElevation = false

    override fun isInstalled(): Boolean = ProcessRunner.run("node", "--version").success
    override fun getVersion(): String? = ProcessRunner.run("node", "--version").stdout.trim()

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")

        return when {
            OsDetector.isWindows -> installWindows()
            else -> installViaNvm()
        }
    }

    private fun installWindows(): InstallResult {
        val installer = File(System.getenv("TEMP"), "nvm-setup.exe")
        val url = "https://github.com/coreybutler/nvm-windows/releases/latest/download/nvm-setup.exe"
        if (!ProcessRunner.download(url, installer)) return InstallResult.Failure("Échec download")
        ProcessRunner.run(installer.absolutePath, "/S")   // silent
        ProcessRunner.run("nvm", "install", "lts")
        ProcessRunner.run("nvm", "use", "lts")
        return InstallResult.Success("Node.js LTS installé via nvm-windows")
    }

    private fun installViaNvm(): InstallResult {
        val nvmDir = File("${OsDetector.userHome}/.nvm")
        if (!nvmDir.exists()) {
            val script = File("/tmp/nvm-install.sh")
            val url = "https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh"
            ProcessRunner.download(url, script)
            ProcessRunner.run("bash", script.absolutePath)
        }
        val nvm = "source ${OsDetector.userHome}/.nvm/nvm.sh"
        ProcessRunner.run("bash", "-c", "$nvm && nvm install --lts && nvm use --lts")
        return InstallResult.Success("Node.js LTS installé via nvm dans ~/.nvm")
    }
}