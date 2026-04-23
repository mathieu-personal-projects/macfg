package mpp.macfg.config.util

import mpp.macfg.config.classes.Tools
import org.springframework.stereotype.Component

@Component
class FetchVersions(private val osDetector: OsDetector) {

    fun fetchDownloadUrl(tool: Tools): String {
        return fetchDownloadUrl(tool, osDetector.detectOs())
    }

    fun fetchDownloadUrl(tool: Tools, os: OperatingSystem): String {
        return when (tool.category.name.lowercase()) {
            "languages" -> fetchLanguageUrl(tool, os)
            "dbms" -> fetchDbmsUrl(tool, os)
            "cli" -> fetchCliUrl(tool, os)
            "other" -> fetchOtherUrl(tool, os)
            "pms" -> fetchPmsUrl(tool, os)
            "code" -> fetchCodeUrl(tool, os)
            "fonts" -> fetchFontUrl(tool, os)
            "ops" -> fetchOpsUrl(tool, os)
            else -> ""
        }
    }

    private fun fetchLanguageUrl(tool: Tools, os: OperatingSystem): String {
        return when (tool.toolName.lowercase()) {
            "java" -> when (os) {
                OperatingSystem.WINDOWS -> "https://download.oracle.com/java/${tool.version}/latest/jdk-${tool.version}_windows-x64_bin.zip"
                OperatingSystem.LINUX -> "https://download.oracle.com/java/${tool.version}/latest/jdk-${tool.version}_linux-x64_bin.tar.gz"
                OperatingSystem.MACOS -> "https://download.oracle.com/java/${tool.version}/latest/jdk-${tool.version}_macos-x64_bin.tar.gz"
                else -> ""
            }
            "python" -> when (os) {
                OperatingSystem.WINDOWS -> "https://www.python.org/ftp/python/${tool.version}/python-${tool.version}-amd64.exe"
                OperatingSystem.LINUX -> "https://www.python.org/ftp/python/${tool.version}/Python-${tool.version}.tgz"
                OperatingSystem.MACOS -> "https://www.python.org/ftp/python/${tool.version}/python-${tool.version}-macos11.pkg"
                else -> ""
            }
            "rust" -> when (os) {
                OperatingSystem.WINDOWS -> "https://static.rust-lang.org/dist/rust-${tool.version}-x86_64-pc-windows-msvc.msi"
                OperatingSystem.LINUX -> "https://static.rust-lang.org/dist/rust-${tool.version}-x86_64-unknown-linux-gnu.tar.gz"
                OperatingSystem.MACOS -> "https://static.rust-lang.org/dist/rust-${tool.version}-x86_64-apple-darwin.tar.gz"
                else -> ""
            }
            "javascript" -> "" // JavaScript is bundled with browsers/Node.js
            else -> ""
        }
    }

    private fun fetchDbmsUrl(tool: Tools, os: OperatingSystem): String {
        return when (tool.toolName.lowercase()) {
            "mongodb" -> when (os) {
                OperatingSystem.WINDOWS -> "https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-${tool.version}-signed.msi"
                OperatingSystem.LINUX -> "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${tool.version}.tgz"
                OperatingSystem.MACOS -> "https://fastdl.mongodb.org/osx/mongodb-macos-x86_64-${tool.version}.tgz"
                else -> ""
            }
            "mysql" -> when (os) {
                OperatingSystem.WINDOWS -> "https://dev.mysql.com/get/Downloads/MySQLInstaller/mysql-installer-community-${tool.version}.0-windows-x64.msi"
                else -> "https://dev.mysql.com/downloads/mysql/"
            }
            "postgresql" -> when (os) {
                OperatingSystem.WINDOWS -> "https://get.enterprisedb.com/postgresql/postgresql-${tool.version}-windows-x64.exe"
                else -> "https://www.postgresql.org/download/"
            }
            else -> ""
        }
    }

    private fun fetchCliUrl(tool: Tools, os: OperatingSystem): String {
        return when (tool.toolName.lowercase()) {
            "make" -> when (os) {
                OperatingSystem.WINDOWS -> "https://github.com/mbuilov/gnumake-windows/releases/latest"
                else -> "# Usually pre-installed or via package manager"
            }
            "wsl" -> if (os == OperatingSystem.WINDOWS) "https://aka.ms/wslinstall" else ""
            "gitbash" -> if (os == OperatingSystem.WINDOWS) "https://github.com/git-for-windows/git/releases/latest" else ""
            "termius" -> when (os) {
                OperatingSystem.WINDOWS -> "https://termius.com/windows"
                OperatingSystem.MACOS -> "https://termius.com/mac"
                OperatingSystem.LINUX -> "https://termius.com/linux"
                else -> ""
            }
            else -> ""
        }
    }

    private fun fetchOtherUrl(tool: Tools, os: OperatingSystem): String {
        return when (tool.toolName.lowercase()) {
            "bruno" -> when (os) {
                OperatingSystem.WINDOWS -> "https://github.com/usebruno/bruno/releases/download/v${tool.version}/bruno_${tool.version}_x64_win.exe"
                OperatingSystem.LINUX -> "https://github.com/usebruno/bruno/releases/download/v${tool.version}/bruno_${tool.version}_amd64.deb"
                OperatingSystem.MACOS -> "https://github.com/usebruno/bruno/releases/download/v${tool.version}/bruno_${tool.version}_x64_mac.dmg"
                else -> ""
            }
            "compass" -> when (os) {
                OperatingSystem.WINDOWS -> "https://downloads.mongodb.com/compass/mongodb-compass-${tool.version}-win32-x64.exe"
                OperatingSystem.LINUX -> "https://downloads.mongodb.com/compass/mongodb-compass_${tool.version}_amd64.deb"
                OperatingSystem.MACOS -> "https://downloads.mongodb.com/compass/mongodb-compass-${tool.version}-darwin-x64.dmg"
                else -> ""
            }
            "pgadmin" -> when (os) {
                OperatingSystem.WINDOWS -> "https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v${tool.version}/windows/pgadmin4-${tool.version}-x64.exe"
                OperatingSystem.MACOS -> "https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v${tool.version}/macos/pgadmin4-${tool.version}.dmg"
                else -> "https://www.pgadmin.org/download/"
            }
            "mysql_wb" -> "https://dev.mysql.com/downloads/workbench/"
            "nodejs" -> when (os) {
                OperatingSystem.WINDOWS -> "https://nodejs.org/dist/${tool.version}/node-${tool.version}-win-x64.zip"
                OperatingSystem.LINUX -> "https://nodejs.org/dist/${tool.version}/node-${tool.version}-linux-x64.tar.xz"
                OperatingSystem.MACOS -> "https://nodejs.org/dist/${tool.version}/node-${tool.version}-darwin-x64.tar.gz"
                else -> ""
            }
            else -> ""
        }
    }

    private fun fetchPmsUrl(tool: Tools, os: OperatingSystem): String {
        return when (tool.toolName.lowercase()) {
            "mvn" -> "https://dlcdn.apache.org/maven/maven-3/${tool.version}/binaries/apache-maven-${tool.version}-bin.zip"
            "uv" -> "https://github.com/astral-sh/uv/releases/latest"
            "bun" -> when (os) {
                OperatingSystem.WINDOWS -> "https://github.com/oven-sh/bun/releases/latest/download/bun-windows-x64.zip"
                OperatingSystem.LINUX -> "https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip"
                OperatingSystem.MACOS -> "https://github.com/oven-sh/bun/releases/latest/download/bun-darwin-x64.zip"
                else -> ""
            }
            else -> ""
        }
    }

    private fun fetchCodeUrl(tool: Tools, os: OperatingSystem): String {
        return when (tool.toolName.lowercase()) {
            "vscode" -> when (os) {
                OperatingSystem.WINDOWS -> "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-archive"
                OperatingSystem.LINUX -> "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"
                OperatingSystem.MACOS -> "https://code.visualstudio.com/sha/download?build=stable&os=darwin-universal"
                else -> ""
            }
            else -> ""
        }
    }

    private fun fetchFontUrl(tool: Tools, os: OperatingSystem): String {
        return when (tool.toolName.lowercase()) {
            "jetbrains_mono" -> "https://github.com/JetBrains/JetBrainsMono/releases/latest/download/JetBrainsMono.zip"
            "cascadia_mono" -> "https://github.com/microsoft/cascadia-code/releases/latest/download/CascadiaCode.zip"
            "fira_code" -> "https://github.com/tonsky/FiraCode/releases/latest/download/Fira_Code.zip"
            else -> ""
        }
    }

    private fun fetchOpsUrl(tool: Tools, os: OperatingSystem): String {
        return when (tool.toolName.lowercase()) {
            "git" -> when (os) {
                OperatingSystem.WINDOWS -> "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/PortableGit-2.47.1.2-64-bit.7z.exe"
                OperatingSystem.LINUX -> "# Install via package manager: apt install git"
                OperatingSystem.MACOS -> "# Install via homebrew: brew install git"
                else -> ""
            }
            "docker" -> when (os) {
                OperatingSystem.WINDOWS -> "https://desktop.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
                OperatingSystem.MACOS -> "https://desktop.docker.com/mac/stable/Docker.dmg"
                OperatingSystem.LINUX -> "# Install via package manager"
                else -> ""
            }
            else -> ""
        }
    }

    fun updateToolDownloadUrl(tool: Tools) {
        tool.downloadUrl = fetchDownloadUrl(tool)
    }
}
