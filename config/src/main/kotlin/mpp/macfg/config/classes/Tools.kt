package mpp.macfg.config.classes

enum class Categories {
    LANGUAGES, DBMS, CLI, OTHER, PMS, CODE, FONTS, OPS
}

data class Tools (
    val toolName: String,
    val category: Categories,
    var version: String,
    var downloadUrl: String = "",
    var isSelected: Boolean = false,
    val requiresElevation: Boolean = false,
    val installationType: InstallationType = InstallationType.PORTABLE
)

enum class InstallationType {
    PORTABLE,      // Extract and run from dev folder
    INSTALLER,     // Run installer (may need elevation)
    PACKAGE,       // Package manager (apt, brew, choco)
    MANUAL         // Manual configuration required
}
