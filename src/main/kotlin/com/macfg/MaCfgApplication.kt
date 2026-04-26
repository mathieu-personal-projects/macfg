package com.macfg

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class MaCfgApplication

fun main(args: Array<String>) {
    val banner = MaCfgApplication::class.java.getResourceAsStream("/banner.txt")?.bufferedReader()?.readText()
    if (banner != null) println(banner)

    runApplication<MaCfgApplication>(*args)
}