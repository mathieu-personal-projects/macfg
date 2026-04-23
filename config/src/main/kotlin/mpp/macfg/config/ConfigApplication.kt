package mpp.macfg.config

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import io.github.oshai.kotlinlogging.KotlinLogging

@SpringBootApplication
class ConfigApplication

fun main(args: Array<String>) {
	val logger = KotlinLogging.logger {}

	logger.trace { "Starting Kotlin Springboot application" }
	runApplication<ConfigApplication>(*args)
	
	val banner = ConfigApplication::class.java.getResource("/static/banner.txt")?.readText() ?: ""
	logger.info { "\n$banner\nMaCfg • V0.1.0 • Configuration setupper" }
}
