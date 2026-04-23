package mpp.macfg.core.cli

import mpp.macfg.core.services.ToolSelectionService
import org.springframework.boot.CommandLineRunner
import org.springframework.stereotype.Component
import java.util.Scanner

// @Component - Disabled in favor of InstallerCli
class ToolSelectionCli(
    private val toolSelectionService: ToolSelectionService) : CommandLineRunner {

    override fun run(vararg args: String) {
        if (args.contains("--interactive-old")) {
            startInteractiveMode()
        }
    }

    private fun startInteractiveMode() {
        val scanner = Scanner(System.`in`)
        println("\n=== MaCfg Tool Selection CLI ===")
        println("Commands:")
        println("  select <category> <tool> - Select a tool")
        println("  deselect <category> <tool> - Deselect a tool")
        println("  toggle <category> <tool> - Toggle tool selection")
        println("  version <category> <tool> <version> - Change tool version")
        println("  list - List selected tools")
        println("  exit - Exit interactive mode")
        println()

        while (true) {
            print("> ")
            val input = scanner.nextLine().trim()
            val parts = input.split(" ")

            when (parts.getOrNull(0)?.lowercase()) {
                "select" -> {
                    if (parts.size >= 3) {
                        val success = toolSelectionService.selectTool(parts[1], parts[2])
                        println(if (success) "✓ Tool selected" else "✗ Failed to select tool")
                    } else {
                        println("Usage: select <category> <tool>")
                    }
                }
                "deselect" -> {
                    if (parts.size >= 3) {
                        val success = toolSelectionService.deselectTool(parts[1], parts[2])
                        println(if (success) "✓ Tool deselected" else "✗ Failed to deselect tool")
                    } else {
                        println("Usage: deselect <category> <tool>")
                    }
                }
                "toggle" -> {
                    if (parts.size >= 3) {
                        val success = toolSelectionService.toggleToolSelection(parts[1], parts[2])
                        println(if (success) "✓ Tool toggled" else "✗ Failed to toggle tool")
                    } else {
                        println("Usage: toggle <category> <tool>")
                    }
                }
                "version" -> {
                    if (parts.size >= 4) {
                        val success = toolSelectionService.changeToolVersion(parts[1], parts[2], parts[3])
                        println(if (success) "✓ Version changed" else "✗ Failed to change version")
                    } else {
                        println("Usage: version <category> <tool> <version>")
                    }
                }
                "list" -> {
                    val tools = toolSelectionService.getSelectedTools()
                    if (tools != null && tools.isNotEmpty()) {
                        println("Selected tools:")
                        tools.forEach { tool ->
                            println("  ✓ ${tool["category"]}/${tool["toolName"]} - v${tool["version"]}")
                        }
                    } else {
                        println("No tools selected")
                    }
                }
                "exit" -> {
                    println("Goodbye!")
                    break
                }
                else -> {
                    println("Unknown command. Type 'exit' to quit.")
                }
            }
        }
    }
}
