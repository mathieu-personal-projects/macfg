package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class PythonInstaller : ToolInstaller {
    override val toolName = "python"
    override val description = "Python 3 via pyenv (sans sudo)"
    override val requiresElevation = false

    override fun isInstalled(): Boolean = ProcessRunner.run("python3", "--version").success || ProcessRunner.run("python", "--version").success

    override fun getVersion(): String? = ProcessRunner.run("python3", "--version").stdout.trim()

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")

        return when {
            OsDetector.isWindows -> installWindows()
            OsDetector.isLinux || OsDetector.isMac -> installViaPyenv()
            else -> InstallResult.Failure("OS non supporté")
        }
    }

    private fun installWindows(): InstallResult {
        val winget = ProcessRunner.run(
            "winget", "install", "Python.Python.3.12",
            "--scope", "user", "--silent"
        )
        return if (winget.success) InstallResult.Success("Python installé via winget")
        else {
            InstallResult.Failure("winget requis. Sinon : https://www.python.org/downloads/")
        }
    }

    private fun installViaPyenv(): InstallResult {
        val pyenvDir = File("${OsDetector.userHome}/.pyenv")
        if (!pyenvDir.exists()) {
            println("Installation de pyenv...")
            val script = File("/tmp/pyenv-install.sh")
            ProcessRunner.download("https://pyenv.run", script)
            ProcessRunner.run("bash", script.absolutePath)
        }

        val pyenv = "${OsDetector.userHome}/.pyenv/bin/pyenv"
        println("Compilation de Python 3.12 via pyenv...")
        val result = ProcessRunner.run(pyenv, "install", "3.12.3")
        if (!result.success) return InstallResult.Failure(result.stderr)

        ProcessRunner.run(pyenv, "global", "3.12.3")
        return InstallResult.Success("Python 3.12 installé via pyenv dans ~/.pyenv")
    }
}