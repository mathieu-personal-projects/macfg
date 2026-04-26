package com.macfg.installer

import org.springframework.stereotype.Component

@Component
class InstallerRegistry(private val installers: List<ToolInstaller>) {

    fun findByName(name: String): ToolInstaller? = installers.firstOrNull { it.toolName.equals(name, ignoreCase = true) }

    fun all(): List<ToolInstaller> = installers

    fun listNames(): List<String> = installers.map { it.toolName }
}