package mpp.macfg.core.cli

import mpp.macfg.core.util.OsDetector
import mpp.macfg.core.util.OperatingSystem
import mpp.macfg.core.util.TerminalStyle as Style
import mpp.macfg.core.services.ToolSelectionService
import mpp.macfg.core.installer.ToolInstaller
import org.springframework.boot.CommandLineRunner
import org.springframework.core.io.ClassPathResource
import org.springframework.stereotype.Component
import java.util.Scanner

@Component
class InstallerCli(
    private val osDetector: OsDetector,
    private val toolSelectionService: ToolSelectionService,
    private val toolInstaller: ToolInstaller
) : CommandLineRunner {

    private val scanner = Scanner(System.`in`)
    private val toolsRequiringElevation = listOf("docker", "postgresql", "mysql", "mongodb")
    private val toolsRequiringPostConfig = listOf("git", "vscode")

    override fun run(vararg args: String) {
        // Clear screen and show header
        print("[2J[H")
        println(Style.header())
        println()

        // Step 1: Detect OS
        val os = osDetector.detectOs()
        val devFolder = osDetector.getDevFolder()

        println("${Style.checkMark()} Detected OS: ${Style.info(os.toString())}")
        println("${Style.checkMark()} Installation folder: ${Style.info(devFolder)}")
        println()

        if (os == OperatingSystem.UNKNOWN) {
            println("${Style.crossMark()} ${Style.error("Unknown operating system. Cannot proceed.")}")
            return
        }

        // Step 2: Show available tools
        val allTools = getAllTools()
        if (allTools == null || allTools.isEmpty()) {
            println("${Style.crossMark()} ${Style.error("No tools available.")}")
            println(Style.dim("Make sure config service is running on port 7777."))
            return
        }

        println(Style.drawSection("Available Tools"))

        val groupedTools = allTools.groupBy { it["category"] as String }
        groupedTools.forEach { (category, tools) ->
            println(Style.category(category))
            tools.forEach { tool ->
                val name = tool["toolName"] as String
                val version = tool["version"] as String
                val requiresElevation = toolsRequiringElevation.contains(name.lowercase())
                val elevationMark = if (requiresElevation) " ${Style.warningMark()}" else ""
                println(Style.toolName(name, version) + elevationMark)
            }
            println()
        }

        println(Style.dim("${Style.WARNING} = Requires administrator privileges"))
        println()

        // Step 3: Select tools
        println(Style.drawSection("Tool Selection"))
        println(Style.dim("Enter tool names separated by space"))
        println(Style.dim("Type 'all' to select everything, 'cancel' to exit"))
        println()
        print(Style.prompt("Select tools"))
        print(" ")

        val selectedToolsInput = scanner.nextLine().trim()
        if (selectedToolsInput.lowercase() == "cancel") {
            println()
            println(Style.dim("Installation cancelled."))
            return
        }

        val selectedToolNames = if (selectedToolsInput.lowercase() == "all") {
            allTools.map { (it["toolName"] as String).lowercase() }
        } else {
            selectedToolsInput.split("\\s+".toRegex()).map { it.lowercase() }
        }

        if (selectedToolNames.isEmpty()) {
            println(Style.error("No tools selected."))
            return
        }

        // Mark tools as selected in config service
        val selectedTools = mutableListOf<Map<String, Any>>()
        selectedToolNames.forEach { toolName ->
            val tool = allTools.find { (it["toolName"] as String).lowercase() == toolName }
            if (tool != null) {
                val category = tool["category"] as String
                toolSelectionService.selectTool(category, toolName)
                selectedTools.add(tool)
            }
        }

        println()
        println("${Style.checkMark()} Selected ${Style.highlight(selectedTools.size.toString())} tool(s)")
        println()

        // Check for privilege warnings
        val toolsNeedingElevation = selectedTools.filter {
            toolsRequiringElevation.contains((it["toolName"] as String).lowercase())
        }

        if (toolsNeedingElevation.isNotEmpty()) {
            println(Style.warning("${Style.WARNING} WARNING: The following tools require administrator privileges:"))
            toolsNeedingElevation.forEach { tool ->
                println("  ${Style.dot()} ${Style.highlight(tool["toolName"] as String)}")
            }
            println()
            print(Style.prompt("Continue? (y/n)"))
            print(" ")
            val continueInstall = scanner.nextLine().trim().lowercase()
            if (continueInstall != "y" && continueInstall != "yes") {
                println()
                println(Style.dim("Installation cancelled."))
                return
            }
            println()
        }

        // Step 4: Version customization
        println(Style.drawSection("Version Customization"))
        println(Style.dim("Current versions:"))
        selectedTools.forEach { tool ->
            println("  ${Style.dot()} ${Style.highlight(tool["toolName"] as String)}: ${Style.info("v" + tool["version"])}")
        }
        println()
        print(Style.prompt("Change any versions? (y/n)"))
        print(" ")

        val changeVersions = scanner.nextLine().trim().lowercase()
        if (changeVersions == "y" || changeVersions == "yes") {
            println()
            println(Style.dim("Enter tool names to modify (space-separated):"))
            print(Style.prompt("Tools"))
            print(" ")
            val toolsToModify = scanner.nextLine().trim().split("\\s+".toRegex()).filter { it.isNotEmpty() }

            toolsToModify.forEach { toolName ->
                val tool = selectedTools.find { (it["toolName"] as String).lowercase() == toolName.lowercase() }
                if (tool != null) {
                    val currentVersion = tool["version"] as String
                    print("${Style.arrow()} ${Style.highlight(tool["toolName"] as String)} ${Style.dim("(current: $currentVersion)")}: ")
                    val newVersion = scanner.nextLine().trim()
                    if (newVersion.isNotEmpty()) {
                        val category = tool["category"] as String
                        val success = toolSelectionService.changeToolVersion(
                            category,
                            tool["toolName"] as String,
                            newVersion
                        )
                        if (success) {
                            tool as MutableMap
                            tool["version"] = newVersion
                            println("  ${Style.checkMark()} Updated to ${Style.success("v$newVersion")}")
                        } else {
                            println("  ${Style.crossMark()} ${Style.error("Failed to update")}")
                        }
                    }
                }
            }
            println()

            // Refresh selected tools with updated versions
            val updatedTools = toolSelectionService.getSelectedTools()
            if (updatedTools != null) {
                selectedTools.clear()
                selectedTools.addAll(updatedTools)
            }
        }

        // Step 5: Summary and confirmation
        println()
        println(Style.drawSection("Installation Summary"))
        println("${Style.arrow()} Location: ${Style.info(devFolder)}")
        println("${Style.arrow()} Tools to install:")
        selectedTools.forEach { tool ->
            println("  ${Style.dot()} ${Style.highlight(tool["toolName"] as String)} ${Style.info("v" + tool["version"])}")
        }
        println()
        print(Style.prompt("Proceed with installation? (y/n)"))
        print(" ")

        val proceed = scanner.nextLine().trim().lowercase()
        if (proceed != "y" && proceed != "yes") {
            println()
            println(Style.dim("Installation cancelled."))
            return
        }

        // Step 6: Installation
        println()
        println(Style.drawSection("Installing"))
        println()

        val installResults = mutableMapOf<String, Boolean>()
        val toolsNeedingConfig = mutableListOf<String>()

        selectedTools.forEachIndexed { index, tool ->
            val toolName = tool["toolName"] as String
            val version = tool["version"] as String
            val downloadUrl = tool["downloadUrl"] as String

            println("${Style.progressBar(index + 1, selectedTools.size)}")
            println(Style.dim("Installing ${toolName}..."))
            println()

            val result = toolInstaller.installTool(toolName, version, downloadUrl, devFolder, os)
            installResults[toolName] = result.success

            if (result.requiresPostConfig) {
                toolsNeedingConfig.add(toolName.lowercase())
            }

            if (result.success) {
                println("${Style.checkMark()} ${Style.highlight(toolName)}: ${Style.success(result.message)}")
            } else {
                println("${Style.crossMark()} ${Style.highlight(toolName)}: ${Style.error(result.message)}")
            }
            println()
        }

        // Step 7: Post-installation configuration
        if (toolsNeedingConfig.isNotEmpty()) {
            println(Style.drawSection("Configuration"))
            println()

            if (toolsNeedingConfig.contains("git")) {
                println(Style.accent("Git Configuration"))
                println(Style.drawLine(60, Style.BOX_LIGHT_H))
                val gitConfig = toolInstaller.configureGit()
                if (gitConfig != null) {
                    toolInstaller.applyGitConfig(gitConfig)
                    println("${Style.checkMark()} ${Style.success("Git configured successfully")}")
                } else {
                    println("${Style.crossMark()} ${Style.error("Git configuration skipped")}")
                }
                println()
            }

            if (toolsNeedingConfig.contains("vscode")) {
                try {
                    val settingsResource = ClassPathResource("tools/vscode-settings.json")
                    val settingsJson = settingsResource.inputStream.bufferedReader().use { it.readText() }
                    toolInstaller.applyVsCodeSettings(settingsJson)
                    println("${Style.checkMark()} ${Style.success("VSCode settings applied")}")
                } catch (e: Exception) {
                    println("${Style.crossMark()} ${Style.error("Failed to apply VSCode settings")}")
                }
                println()
            }
        }

        // Step 8: Final summary
        println(Style.drawSection("Complete"))

        val successful = installResults.count { it.value }
        val failed = installResults.count { !it.value }

        println("${Style.arrow()} Summary:")
        println("  ${Style.checkMark()} Successful: ${Style.success(successful.toString())}")
        if (failed > 0) {
            println("  ${Style.crossMark()} Failed: ${Style.error(failed.toString())}")
        }
        println()
        println("${Style.arrow()} Installation directory:")
        println("  ${Style.info(devFolder)}")
        println()
        println(Style.dim("${Style.WARNING} Remember to add tool paths to your PATH:"))
        println(Style.dim("  $devFolder/<tool-name>/bin"))
        println()
        println(Style.drawLine(60))
        println()
    }

    private fun getAllTools(): List<Map<String, Any>>? {
        return try {
            val url = "http://localhost:7777/api/tools"
            val restTemplate = org.springframework.web.client.RestTemplate()
            val response = restTemplate.getForObject(url, List::class.java)
            @Suppress("UNCHECKED_CAST")
            response as? List<Map<String, Any>>
        } catch (e: Exception) {
            null
        }
    }
}
