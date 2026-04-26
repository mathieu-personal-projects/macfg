package com.macfg.installer

interface ToolInstaller {
    val toolName: String
    val description: String
    val requiresElevation: Boolean get() = false

    fun isInstalled(): Boolean
    fun install(): InstallResult
    fun getVersion(): String?
}

sealed class InstallResult {
    data class Success(val message: String) : InstallResult()
    data class AlreadyInstalled(val version: String) : InstallResult()
    data class Failure(val reason: String) : InstallResult()
    data class ElevationRequired(val hint: String) : InstallResult()
}