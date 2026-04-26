package com.macfg.cli

import com.macfg.installer.InstallerRegistry
import com.macfg.installer.InstallResult
import org.springframework.shell.standard.ShellComponent
import org.springframework.shell.standard.ShellMethod
import org.springframework.shell.standard.ShellOption

@ShellComponent
class InstallCommand(private val registry: InstallerRegistry) {

    @ShellMethod(key = ["list"], value = "Lister tous les outils disponibles")
    fun list(): String {
        val sb = StringBuilder("\n")
        val groups = mapOf(
            "Dev Tools"       to listOf("git", "gitbash", "make"),
            "Éditeurs"         to listOf("vscode"),
            "Bases de données" to listOf("mongodb", "postgresql", "mysql"),
            "DB GUIs"         to listOf("compass", "pgadmin", "mysql-workbench"),
            "Runtimes JVM"     to listOf("java", "mvn"),
            "Python"           to listOf("python", "uv"),
            "JavaScript"       to listOf("node", "bun"),
            "Rust"             to listOf("rust"),
            "Conteneurs"       to listOf("docker", "wsl"),
            "Divers"           to listOf("termius", "bruno")
        )

        groups.forEach { (group, tools) ->
            sb.appendLine("\n$group")
            tools.forEach { name ->
                val tool = registry.findByName(name) ?: return@forEach
                val status  = if (tool.isInstalled()) "[X] ${tool.getVersion() ?: "installé"}" else "[ ] non installé"
                val elev    = if (tool.requiresElevation) " [admin]" else ""
                sb.appendLine("  %-20s %s%s".format("${tool.toolName}", status, elev))
            }
        }
        sb.appendLine("\nConseil : utilisez 'install vscode,java,node' ou 'select' pour le menu interactif.")
        return sb.toString()
    }

    @ShellMethod(key = ["select"], value = "Menu interactif de sélection des outils à installer")
    fun select(): String {
        val all = registry.all()
        println("\nSélectionnez les outils à installer (numéros séparés par des virgules, ex: 1,3,5)\n")

        all.forEachIndexed { idx, tool ->
            val installed = if (tool.isInstalled()) "[X]" else "[ ]"
            val elev = if (tool.requiresElevation) " [admin] " else "         "
            println("  [%2d]$elev$installed  %-20s — %s".format(idx + 1, tool.toolName, tool.description))
        }

        println("\n  [0] Tout installer (sans élévation)\n")
        print("Votre choix : ")

        val input = readLine()?.trim() ?: return "Annulé."

        val selected = if (input == "0") {
            all.filter { !it.requiresElevation }
        } else {
            input.split(",")
                .mapNotNull { it.trim().toIntOrNull() }
                .filter { it in 1..all.size }
                .map { all[it - 1] }
                .distinctBy { it.toolName }
        }

        if (selected.isEmpty()) return "Aucun outil sélectionné."

        return install(selected.joinToString(",") { it.toolName })
    }

    @ShellMethod(key = ["install"], value = "Installer un ou plusieurs outils (ex: install vscode,java,node)")
    fun install(
        @ShellOption(help = "Noms séparés par des virgules") tools: String
    ): String {
        val names = tools.split(",").map { it.trim() }
        val sb = StringBuilder("\n")

        names.forEach { name ->
            val installer = registry.findByName(name)
            if (installer == null) {
                sb.appendLine("Outil inconnu : '$name'  ->  utilisez 'list' pour voir les disponibles")
                return@forEach
            }

            if (installer.requiresElevation) {
                print("L'outil '${installer.toolName}' nécessite des droits élevés. Continuer ? [y/N] ")
                val answer = readLine()?.trim()?.lowercase()
                if (answer != "y") {
                    sb.appendLine("L'outil '${installer.toolName}' a été ignoré.")
                    return@forEach
                }
            }

            sb.append("Installation de ${installer.toolName} ... ")
            when (val result = installer.install()) {
                is InstallResult.Success          -> sb.appendLine("[SUCCESS] ${result.message}")
                is InstallResult.AlreadyInstalled -> sb.appendLine("[SKIPPED] déjà installé (${result.version})")
                is InstallResult.Failure          -> sb.appendLine("[FAILED] ${result.reason}")
                is InstallResult.ElevationRequired -> sb.appendLine("[LOCKED] ${result.hint}")
            }
        }

        return sb.toString()
    }

    @ShellMethod(key = ["install-all"], value = "Installer tout ce qui ne nécessite pas d'élévation")
    fun installAll(): String {
        val todo = registry.all().filter { !it.requiresElevation && !it.isInstalled() }
        if (todo.isEmpty()) return "Tous les outils sans élévation sont déjà installés."
        return install(todo.joinToString(",") { it.toolName })
    }

    @ShellMethod(key = ["status"], value = "Statut d'un outil précis")
    fun status(@ShellOption tool: String): String {
        val installer = registry.findByName(tool) ?: return "Outil inconnu : '$tool'"
        return if (installer.isInstalled())
            "[X] $tool — ${installer.getVersion()}"
        else
            "[ ] $tool non installé"
    }
}