package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class JavaInstaller : ToolInstaller {
    override val toolName = "java"
    override val description = "JDK 21 via SDKMAN (sans sudo)"
    override val requiresElevation = false

    private val sdkman get() = "${OsDetector.userHome}/.sdkman/bin/sdkman-init.sh"

    override fun isInstalled(): Boolean = ProcessRunner.run("java", "-version").success

    override fun getVersion(): String? = ProcessRunner.run("java", "-version").stderr.lines().firstOrNull()

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")

        return when {
            OsDetector.isWindows -> installWindows()
            else -> installViaSdkman()
        }
    }

    private fun installWindows(): InstallResult {
        val result = ProcessRunner.run(
            "winget", "install", "EclipseAdoptium.Temurin.21.JDK",
            "--scope", "user", "--silent"
        )
        return if (result.success) InstallResult.Success("JDK 21 installé via winget")
        else InstallResult.Failure("Échec winget : ${result.stderr}")
    }

    private fun installViaSdkman(): InstallResult {
        if (!File(sdkman).exists()) {
            println("Installation de SDKMAN...")
            val script = File("/tmp/sdkman.sh")
            ProcessRunner.download("https://get.sdkman.io", script)
            ProcessRunner.run("bash", script.absolutePath)
        }

        println("Installation de Java 21 via SDKMAN...")
        val result = ProcessRunner.run(
            "bash", "-c", "source $sdkman && sdk install java 21.0.3-tem"
        )
        return if (result.success) InstallResult.Success("Java 21 installé via SDKMAN dans ~/.sdkman")
        else InstallResult.Failure(result.stderr)
    }
}