package mpp.macfg.core.util

import org.springframework.stereotype.Component

enum class OperatingSystem {
    WINDOWS, LINUX, MACOS, UNKNOWN
}

@Component
class OsDetector {

    fun detectOs(): OperatingSystem {
        val osName = System.getProperty("os.name").lowercase()
        return when {
            osName.contains("win") -> OperatingSystem.WINDOWS
            osName.contains("nix") || osName.contains("nux") || osName.contains("aix") -> OperatingSystem.LINUX
            osName.contains("mac") || osName.contains("darwin") -> OperatingSystem.MACOS
            else -> OperatingSystem.UNKNOWN
        }
    }

    fun getDevFolder(): String {
        return when (detectOs()) {
            OperatingSystem.WINDOWS -> System.getenv("USERPROFILE") + "\\dev"
            OperatingSystem.LINUX, OperatingSystem.MACOS -> System.getProperty("user.home") + "/dev"
            OperatingSystem.UNKNOWN -> System.getProperty("user.home") + "/dev"
        }
    }

    fun getHomeFolder(): String {
        return when (detectOs()) {
            OperatingSystem.WINDOWS -> System.getenv("USERPROFILE")
            else -> System.getProperty("user.home")
        }
    }
}
