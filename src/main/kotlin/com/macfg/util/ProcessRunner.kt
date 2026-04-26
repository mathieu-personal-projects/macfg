package com.macfg.util

import java.io.File

data class ProcessResult(val exitCode: Int, val stdout: String, val stderr: String) {
    val success get() = exitCode == 0
}

object ProcessRunner {

    fun run( vararg command: String, workDir: File? = null, elevated: Boolean = false, env: Map<String, String> = emptyMap()): ProcessResult {
        val cmd = if (elevated) elevate(command.toList()) else command.toList()

        val pb = ProcessBuilder(cmd).apply {
            workDir?.let { directory(it) }
            environment().putAll(env)
            redirectErrorStream(false)
        }

        try {
            val process = pb.start()
            val stdout  = process.inputStream.bufferedReader().readText()
            val stderr  = process.errorStream.bufferedReader().readText()
            val exit    = process.waitFor()

            return ProcessResult(exit, stdout, stderr)
        } catch (e: Exception) {
            return ProcessResult(-1, "", e.message ?: "Unknown error")
        }
    }

    fun download(url: String, destination: File): Boolean {
        destination.parentFile?.mkdirs()
        val result = if (OsDetector.isWindows) {
            run("powershell", "-Command",
                "Invoke-WebRequest -Uri '$url' -OutFile '${destination.absolutePath}'")
        } else {
            run("curl", "-fsSL", url, "-o", destination.absolutePath)
        }
        return result.success
    }

    private fun elevate(cmd: List<String>): List<String> = when {
        OsDetector.isWindows -> listOf("powershell", "-Command","Start-Process -Verb RunAs -FilePath '${cmd[0]}' -ArgumentList '${cmd.drop(1).joinToString(" ")}'")
        else -> listOf("sudo") + cmd
    }
}