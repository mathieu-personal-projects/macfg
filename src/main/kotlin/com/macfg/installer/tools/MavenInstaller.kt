package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class MavenInstaller : ToolInstaller {
    override val toolName = "mvn"
    override val description = "Apache Maven (sans sudo — install dans ~/.local)"
    override val requiresElevation = false

    private val MVN_VERSION = "3.9.6"
    private val installDir get() = File("${OsDetector.userHome}/.local/opt/maven-$MVN_VERSION")
    private val binLink    get() = File("${OsDetector.localBinDir}/mvn")

    override fun isInstalled() = ProcessRunner.run("mvn", "--version").success
    override fun getVersion() = ProcessRunner.run("mvn", "--version").stdout.lines().firstOrNull()

    override fun install(): InstallResult {
        if (isInstalled()) return InstallResult.AlreadyInstalled(getVersion() ?: "?")
        return when {
            OsDetector.isWindows -> installWindows()
            else -> installUnix()
        }
    }

    private fun installWindows(): InstallResult {
        val winget = ProcessRunner.run("winget", "install", "Apache.Maven", "--scope", "user", "--silent")
        return if (winget.success) InstallResult.Success("Maven installé via winget")
        else installManual()
    }

    private fun installUnix(): InstallResult {
        val sdkman = "${OsDetector.userHome}/.sdkman/bin/sdkman-init.sh"
        if (File(sdkman).exists()) {
            val r = ProcessRunner.run("bash", "-c", "source $sdkman && sdk install maven $MVN_VERSION")
            if (r.success) return InstallResult.Success("Maven $MVN_VERSION installé via SDKMAN")
        }
        return installManual()
    }

    private fun installManual(): InstallResult {
        val ext = if (OsDetector.isWindows) "zip" else "tar.gz"
        val url = "https://downloads.apache.org/maven/maven-3/$MVN_VERSION/binaries/apache-maven-$MVN_VERSION-bin.$ext"
        val archive = File(System.getProperty("java.io.tmpdir"), "maven.$ext")

        println("Téléchargement de Maven $MVN_VERSION...")
        if (!ProcessRunner.download(url, archive)) return InstallResult.Failure("Échec téléchargement")

        installDir.mkdirs()
        if (OsDetector.isWindows) {
            ProcessRunner.run("powershell", "-Command",
                "Expand-Archive -Path '${archive.absolutePath}' -DestinationPath '${installDir.parent}' -Force")
        } else {
            ProcessRunner.run("tar", "-xzf", archive.absolutePath, "-C", installDir.parent, "--strip-components=1")
            binLink.parentFile.mkdirs()
            ProcessRunner.run("ln", "-sf", "${installDir.absolutePath}/bin/mvn", binLink.absolutePath)
        }

        return if (File(installDir, "bin/mvn").exists() || binLink.exists())
            InstallResult.Success("Maven $MVN_VERSION installé dans ${installDir.absolutePath}")
        else InstallResult.Failure("Échec de l'installation manuelle")
    }
}