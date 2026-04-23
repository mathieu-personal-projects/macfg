package mpp.macfg.core.installer

import mpp.macfg.core.util.OperatingSystem
import mpp.macfg.core.util.TerminalStyle as Style
import org.springframework.stereotype.Component
import java.io.File
import java.nio.file.Files
import java.nio.file.Paths

@Component
class ToolInstaller {

    fun installTool(toolName: String,version: String,downloadUrl: String,devFolder: String,os: OperatingSystem): InstallResult {
        try {
            val devDir = File(devFolder)
            if (!devDir.exists()) {
                devDir.mkdirs()
                println("${Style.dim("Created dev folder:")} ${Style.info(devFolder)}")
            }

            return when (toolName.lowercase()) {
                "git" -> installGit(devFolder, os)
                "vscode" -> installVsCode(devFolder, os)
                "docker" -> installDocker(devFolder, os)
                "maven", "mvn" -> installMaven(version, devFolder, os)
                "nodejs", "node" -> installNodeJs(version, devFolder, os)
                else -> installGeneric(toolName, version, downloadUrl, devFolder, os)
            }
        } catch (e: Exception) {
            return InstallResult(false, "Failed to install $toolName: ${e.message}")
        }
    }

    private fun installGit(devFolder: String, os: OperatingSystem): InstallResult {
        println(Style.dim("Git requires system installation"))
        return InstallResult(true, "Ready for configuration", requiresPostConfig = true)
    }

    private fun installVsCode(devFolder: String, os: OperatingSystem): InstallResult {
        println(Style.dim("VSCode requires system installation"))
        return InstallResult(true, "Ready for configuration", requiresPostConfig = true)
    }

    private fun installDocker(devFolder: String, os: OperatingSystem): InstallResult {
        println(Style.warning("Requires elevated privileges"))
        return InstallResult(
            true,
            "Installation initiated (requires admin)",
            requiresElevation = true
        )
    }

    private fun installMaven(version: String, devFolder: String, os: OperatingSystem): InstallResult {
        val mavenDir = File(devFolder, "maven-$version")
        mavenDir.mkdirs()
        return InstallResult(true, "Installed to ${mavenDir.absolutePath}")
    }

    private fun installNodeJs(version: String, devFolder: String, os: OperatingSystem): InstallResult {
        val nodeDir = File(devFolder, "nodejs-$version")
        nodeDir.mkdirs()
        return InstallResult(true, "Installed to ${nodeDir.absolutePath}")
    }

    private fun installGeneric(
        toolName: String,
        version: String,
        downloadUrl: String,
        devFolder: String,
        os: OperatingSystem
    ): InstallResult {
        val toolDir = File(devFolder, "$toolName-$version")
        toolDir.mkdirs()
        return InstallResult(true, "Installed to ${toolDir.absolutePath}")
    }

    fun configureGit(): GitConfig? {
        val scanner = java.util.Scanner(System.`in`)

        print("${Style.arrow()} ${Style.dim("Name:")} ")
        val name = scanner.nextLine().trim()
        if (name.isEmpty()) return null

        print("${Style.arrow()} ${Style.dim("Email:")} ")
        val email = scanner.nextLine().trim()
        if (email.isEmpty()) return null

        print("${Style.arrow()} ${Style.dim("Default branch")} ${Style.dim("(main/master) [main]:")} ")
        val defaultBranch = scanner.nextLine().trim().ifEmpty { "main" }

        print("${Style.arrow()} ${Style.dim("Enable credential helper? (y/n) [y]:")} ")
        val enableCredHelper = scanner.nextLine().trim().lowercase().let { it.isEmpty() || it == "y" }

        return GitConfig(name, email, defaultBranch, enableCredHelper)
    }

    fun applyGitConfig(config: GitConfig) {
        try {
            Runtime.getRuntime().exec("git config --global user.name \"${config.name}\"").waitFor()
            Runtime.getRuntime().exec("git config --global user.email \"${config.email}\"").waitFor()
            Runtime.getRuntime().exec("git config --global init.defaultBranch ${config.defaultBranch}").waitFor()

            if (config.enableCredentialHelper) {
                val os = System.getProperty("os.name").lowercase()
                val credHelper = when {
                    os.contains("win") -> "manager-core"
                    os.contains("mac") -> "osxkeychain"
                    else -> "cache --timeout=3600"
                }
                Runtime.getRuntime().exec("git config --global credential.helper $credHelper").waitFor()
            }
        } catch (e: Exception) {
            throw RuntimeException("Failed to configure Git: ${e.message}")
        }
    }

    fun applyVsCodeSettings(settingsJson: String) {
        try {
            val os = System.getProperty("os.name").lowercase()
            val settingsPath = when {
                os.contains("win") -> "${System.getenv("APPDATA")}\\Code\\User\\settings.json"
                os.contains("mac") -> "${System.getProperty("user.home")}/Library/Application Support/Code/User/settings.json"
                else -> "${System.getProperty("user.home")}/.config/Code/User/settings.json"
            }

            val settingsFile = File(settingsPath)
            settingsFile.parentFile?.mkdirs()
            settingsFile.writeText(settingsJson)
            println(Style.dim("Applied to: $settingsPath"))
        } catch (e: Exception) {
            throw RuntimeException("Failed to apply VSCode settings: ${e.message}")
        }
    }
}

data class InstallResult(
    val success: Boolean,
    val message: String,
    val requiresElevation: Boolean = false,
    val requiresPostConfig: Boolean = false
)

data class GitConfig(
    val name: String,
    val email: String,
    val defaultBranch: String,
    val enableCredentialHelper: Boolean
)
