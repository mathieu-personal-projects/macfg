package mpp.macfg.core.util

object TerminalStyle {
    // ANSI Color Codes
    private const val RESET = "[0m"
    private const val BOLD = "[1m"
    private const val DIM = "[2m"

    // Foreground Colors
    private const val BLACK = "[30m"
    private const val RED = "[31m"
    private const val GREEN = "[32m"
    private const val YELLOW = "[33m"
    private const val BLUE = "[34m"
    private const val MAGENTA = "[35m"
    private const val CYAN = "[36m"
    private const val WHITE = "[37m"

    // Bright Colors
    private const val BRIGHT_BLACK = "[90m"
    private const val BRIGHT_RED = "[91m"
    private const val BRIGHT_GREEN = "[92m"
    private const val BRIGHT_YELLOW = "[93m"
    private const val BRIGHT_BLUE = "[94m"
    private const val BRIGHT_MAGENTA = "[95m"
    private const val BRIGHT_CYAN = "[96m"
    private const val BRIGHT_WHITE = "[97m"

    // Background Colors
    private const val BG_BLACK = "[40m"
    private const val BG_BLUE = "[44m"
    private const val BG_CYAN = "[46m"

    // Box Drawing Characters
    const val BOX_H = "─"
    const val BOX_V = "│"
    const val BOX_TL = "╔"
    const val BOX_TR = "╗"
    const val BOX_BL = "╚"
    const val BOX_BR = "╝"
    const val BOX_VR = "╠"
    const val BOX_VL = "╣"
    const val BOX_HU = "╩"
    const val BOX_HD = "╦"
    const val BOX_CROSS = "╬"

    const val BOX_LIGHT_H = "─"
    const val BOX_LIGHT_V = "│"
    const val BOX_LIGHT_TL = "┌"
    const val BOX_LIGHT_TR = "┐"
    const val BOX_LIGHT_BL = "└"
    const val BOX_LIGHT_BR = "┘"
    const val BOX_LIGHT_VR = "├"
    const val BOX_LIGHT_VL = "┤"

    // Symbols
    const val CHECK = "✓"
    const val CROSS = "✗"
    const val ARROW = "→"
    const val DOT = "•"
    const val WARNING = "⚠"
    const val STAR = "★"
    const val CIRCLE = "●"
    const val SQUARE = "■"

    // Styled Output Functions
    fun primary(text: String) = "$BOLD$BRIGHT_CYAN$text$RESET"
    fun success(text: String) = "$BOLD$BRIGHT_GREEN$text$RESET"
    fun error(text: String) = "$BOLD$BRIGHT_RED$text$RESET"
    fun warning(text: String) = "$BOLD$BRIGHT_YELLOW$text$RESET"
    fun info(text: String) = "$BRIGHT_BLUE$text$RESET"
    fun dim(text: String) = "$DIM$BRIGHT_BLACK$text$RESET"
    fun highlight(text: String) = "$BOLD$BRIGHT_WHITE$text$RESET"
    fun accent(text: String) = "$BRIGHT_MAGENTA$text$RESET"

    fun checkMark() = success(CHECK)
    fun crossMark() = error(CROSS)
    fun warningMark() = warning(WARNING)
    fun arrow() = dim(ARROW)
    fun dot() = dim(DOT)

    // Box Drawing
    fun drawBox(title: String, width: Int = 60): String {
        val titleText = " $title "
        val titleLen = titleText.length
        val leftPad = (width - titleLen - 2) / 2
        val rightPad = width - titleLen - leftPad - 2

        val topLine = BOX_TL + BOX_H.repeat(leftPad) +
                      primary(titleText) +
                      BOX_H.repeat(rightPad) + BOX_TR
        val bottomLine = BOX_BL + BOX_H.repeat(width - 2) + BOX_BR

        return "$topLine\n$bottomLine"
    }

    fun drawSection(title: String, width: Int = 60): String {
        val titleText = " $title "
        val padding = (width - titleText.length) / 2
        val line = BOX_H.repeat(padding)
        return "\n${dim(line)}${highlight(titleText)}${dim(line)}\n"
    }

    fun drawLine(width: Int = 60, char: String = BOX_H) = dim(char.repeat(width))

    fun category(name: String) = accent("[$name]")
    fun toolName(name: String, version: String) = "  ${dot()} ${highlight(name)} ${dim("v$version")}"
    fun selectedTool(name: String, version: String) = "  ${checkMark()} ${highlight(name)} ${dim("v$version")}"

    fun prompt(text: String) = "${primary(">")} $text"
    fun input(text: String = "") = "${BOLD}$BRIGHT_WHITE$text$RESET"

    fun header(): String {
        val width = 60
        return """
${drawBox("MaCfg", width)}
${BOX_V}${" ".repeat((width - 30) / 2)}${primary("Machine Configuration Tool")}${" ".repeat((width - 30) / 2)}${BOX_V}
${BOX_V}${" ".repeat((width - 28) / 2)}${dim("Setup your dev environment")}${" ".repeat((width - 28) / 2)}${BOX_V}
${BOX_BL}${BOX_H.repeat(width - 2)}${BOX_BR}
        """.trimIndent()
    }

    fun progressBar(current: Int, total: Int, width: Int = 40): String {
        val progress = (current.toDouble() / total * width).toInt()
        val bar = "$BRIGHT_CYAN${"█".repeat(progress)}${DIM}${"░".repeat(width - progress)}$RESET"
        val percentage = (current.toDouble() / total * 100).toInt()
        return "$bar ${dim("$current/$total")} ${primary("$percentage%")}"
    }
}
