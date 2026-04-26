package com.macfg.util

enum class OsType { WINDOWS, LINUX, MAC, UNKNOWN }

object OsDetector {
    val current: OsType by lazy {
        val os = System.getProperty("os.name").lowercase()
        when {
            os.contains("win")   -> OsType.WINDOWS
            os.contains("mac")   -> OsType.MAC
            os.contains("nux") || os.contains("nix") -> OsType.LINUX
            else -> OsType.UNKNOWN
        }
    }

    val isWindows get() = current == OsType.WINDOWS
    val isLinux   get() = current == OsType.LINUX
    val isMac     get() = current == OsType.MAC

    val userHome: String get() = System.getProperty("user.home")

    val localBinDir: String get() = when (current) {
        OsType.WINDOWS -> "${userHome}\\AppData\\Local\\Programs"
        else           -> "${userHome}/.local/bin"
    }
}