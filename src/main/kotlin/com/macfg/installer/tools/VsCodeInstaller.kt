package com.macfg.installer.tools

import com.macfg.installer.InstallResult
import com.macfg.installer.ToolInstaller
import com.macfg.util.OsDetector
import com.macfg.util.ProcessRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class VsCodeInstaller : ToolInstaller {
    override val toolName = "vscode"
    override val description = "Visual Studio Code (user install + settings + extensions)"
    override val requiresElevation = false

    private val settingsFile: File get() = when {
        OsDetector.isWindows -> File("${System.getenv("APPDATA")}\\Code\\User\\settings.json")
        OsDetector.isMac     -> File("${OsDetector.userHome}/Library/Application Support/Code/User/settings.json")
        else                 -> File("${OsDetector.userHome}/.config/Code/User/settings.json")
    }

    private val settingsJson = """
{
    "files.autoSave": "afterDelay",
    "extensions.ignoreRecommendations": true,
    "git.confirmSync": false,
    "material-icon-theme.files.associations": {
        "**.jks": "Lock",
        "*.ksql": "3d",
        "cacerts": "Certificate",
        "*.xml": "Parcel",
        "*.avsc": "Raml",
        "*.sh": "Verilog"
    },
    "terminal.integrated.defaultProfile.windows": "Git Bash",
    "terminal.integrated.fontFamily": "Fira Code",
    "terminal.integrated.stickyScroll.enabled": false,
    "workbench.colorTheme": "Default Light Modern",
    "workbench.iconTheme": "material-icon-theme",
    "editor.fontFamily": "Consolas, 'Courier New', monospace",
    "editor.stickyScroll.enabled": false,
    "editor.foldingImportsByDefault": true,
    "editor.inlineSuggest.enabled": false,
    "github.copilot.nextEditSuggestions.enabled": false,
    "java.jdt.ls.java.home": "C:\\Users\\${System.getenv("USERNAME") ?: "%USERNAME%"}\\jdk21",
    "[java]": {
        "editor.fontFamily": "JetBrains Mono, Consolas, 'Courier New', monospace"
    },
    "JAVA_HOME": "C:\\Program Files\\Java\\jdk21",
    "jdk.telemetry.enabled": false,
    "[python]": {
        "editor.fontFamily": "Cascadia Mono, Consolas, 'Courier New', monospace",
        "editor.formatOnType": true,
        "editor.fontLigatures": true
    },
    "python.createEnvironment.trigger": "off",
    "[shellscript]": {
        "editor.fontFamily": "Cascadia Code"
    },
    "[json]": {
        "editor.fontFamily": "IBM Plex Mono"
    },
    "[avro]": {
        "editor.fontFamily": "IBM Plex Mono"
    },
    "files.exclude": {
        "**/*.class": true,
        "**/__pycache__": true,
        "**/.pytest_cache": true,
        "**/*egg-info": true
    },
    "sonarlint.focusOnNewCode": false
}
    """.trimIndent()

    private val extensions = listOf(
        "1yib.rust-bundle",
        "anthropic.claude-code",
        "christian-kohler.path-intellisense",
        "fill-labs.dependi",
        "formulahendry.code-runner",
        "fwcd.kotlin",
        "github.copilot-chat",
        "goopware.raythis",
        "ms-python.debugpy",
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-python.vscode-python-envs",
        "ms-vscode-remote.remote-wsl",
        "pkief.material-icon-theme",
        "redhat.java",
        "repreng.csv",
        "rherre86.best-toml",
        "sonarsource.sonarlint-vscode",
        "tomoki1207.pdf",
        "vivaxy.vscode-conventional-commits",
        "vscjava.vscode-java-debug",
        "vscjava.vscode-java-dependency",
        "vscjava.vscode-java-pack",
        "vscjava.vscode-java-test",
        "vscjava.vscode-maven"
    )

    override fun isInstalled() = ProcessRunner.run("code", "--version").success
    override fun getVersion() = ProcessRunner.run("code", "--version").stdout.lines().firstOrNull()

    override fun install(): InstallResult {
        if (isInstalled()) {
            println("[SUCCESS] VS Code déjà installé — application des settings et extensions...")
            configureSettings()
            installExtensions()
            return InstallResult.AlreadyInstalled(getVersion() ?: "?")
        }

        val installResult = when {
            OsDetector.isWindows -> installWindows()
            OsDetector.isLinux   -> installLinux()
            OsDetector.isMac     -> installMac()
            else -> return InstallResult.Failure("OS non supporté")
        }

        if (installResult is InstallResult.Success) {
            configureSettings()
            installExtensions()
        }

        return installResult
    }

    private fun installWindows(): InstallResult {
        val installer = File(System.getenv("TEMP"), "vscode-installer.exe")
        if (!ProcessRunner.download(
                "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user",
                installer))
            return InstallResult.Failure("Échec du téléchargement")

        val result = ProcessRunner.run(
            installer.absolutePath, "/VERYSILENT", "/MERGETASKS=!runcode", "/NORESTART"
        )
        return if (result.success) InstallResult.Success("VS Code installé (user install)")
        else InstallResult.Failure(result.stderr)
    }

    private fun installLinux(): InstallResult {
        val snap = ProcessRunner.run("snap", "install", "--classic", "code")
        if (snap.success) return InstallResult.Success("VS Code installé via snap")

        val tarball = File("/tmp/vscode.tar.gz")
        if (!ProcessRunner.download(
                "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64",
                tarball))
            return InstallResult.Failure("Échec download")

        val dest = File("${OsDetector.userHome}/.local/opt/vscode")
        dest.mkdirs()
        ProcessRunner.run("tar", "-xzf", tarball.absolutePath, "-C", dest.absolutePath, "--strip-components=1")

        val link = File("${OsDetector.localBinDir}/code")
        link.parentFile.mkdirs()
        ProcessRunner.run("ln", "-sf", "${dest.absolutePath}/bin/code", link.absolutePath)
        return InstallResult.Success("VS Code installé dans ~/.local")
    }

    private fun installMac(): InstallResult {
        val r = ProcessRunner.run("brew", "install", "--cask", "visual-studio-code")
        return if (r.success) InstallResult.Success("VS Code installé via Homebrew")
        else InstallResult.Failure("Homebrew requis sur Mac : https://brew.sh")
    }

    private fun configureSettings() {
        try {
            settingsFile.parentFile.mkdirs()
            settingsFile.writeText(settingsJson)
            println("settings.json écrit dans ${settingsFile.absolutePath}")
        } catch (e: Exception) {
            println("Impossible d'écrire settings.json : ${e.message}")
        }
    }

    private fun installExtensions() {
        println("Installation de ${extensions.size} extensions VS Code...")
        var ok = 0; var ko = 0
        extensions.forEach { ext ->
            print("   • $ext ... ")
            val result = ProcessRunner.run("code", "--install-extension", ext, "--force")
            if (result.success) { println("[X]"); ok++ } else { println("[ ] ${result.stderr.lines().firstOrNull()}"); ko++ }
        }
        println("   → $ok installée(s), $ko échouée(s)")
    }
}