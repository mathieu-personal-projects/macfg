# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
Always update this file when updating the project, and always report the number of tokens used with its approximation in €.

---

## Project Overview

This is a Spring Boot multi-module Maven project written in Kotlin (version 2.2.21) using Java 21.

### Modules
- **config**: Configuration service module (Port 7777)
  - Tools configuration and version management
  - REST API for tool operations
  - INI file parser for default versions
  - Download URL generation
- **core**: Core application module (Port 7778)
  - Interactive CLI for tool selection
  - Client service for config module

### Security & Certificates

The project includes a complete PKI setup for SSL/TLS:
- Self-signed CA for development
- Server certificates with SAN (localhost, *.localhost, 127.0.0.1)
- Client certificates for mutual TLS
- Java keystores (JKS and PKCS12 formats)
- Truststore for CA certificates

#### Certificate Management
- Generation script: `generate-certs.sh` 
- Location: `config/src/main/resources/certs/`
- Documentation: `README-CERTIFICATES.md`
- SSL configuration profile: `application-ssl.properties`

#### Running with SSL
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=ssl
```

### Tools Configuration & Interactive Installer

The project includes a comprehensive development environment installer with OS detection and clean installation.

#### Key Features
- **OS Detection**: Auto-detects Windows/Linux/macOS and adapts download URLs
- **No Privilege Required**: Installs to `~/dev` or `%USERPROFILE%\dev` without elevation
- **Privilege Warnings**: Warns when tools (Docker, PostgreSQL, etc.) require admin rights
- **Version Management**: Default versions from `tools.ini`, customizable during installation
- **Interactive CLI**: Step-by-step guided installation process
- **Post-Configuration**: Special handling for Git (config prompts) and VSCode (applies settings)
- **Clean Installation**: All tools organized in dedicated dev folder
- **REST API**: Full programmatic access to tool management

#### Configuration Files
- **tools.ini**: `config/src/main/resources/tools/tools.ini` - Tool definitions and default versions
- **vscode-settings.json**: `config/src/main/resources/tools/vscode-settings.json` - VSCode preferences to apply
- Documentation: `README-INSTALLER.md`

#### Running the Interactive Installer
```bash
# Terminal 1: Start config service
cd config && mvn spring-boot:run

# Terminal 2: Start interactive installer
cd core && mvn spring-boot:run
```

The installer will:
1. Detect your OS
2. Show available tools by category
3. Let you select tools to install
4. Warn about privilege requirements
5. Allow version customization
6. Install to dev folder
7. Configure Git and VSCode post-installation

#### API Endpoints (Config Service - Port 7777)
- `GET /api/tools` - List all tools with versions and download URLs
- `GET /api/tools/{category}/{tool}` - Get specific tool
- `PUT /api/tools/{category}/{tool}/version` - Change version (body: `{"version": "26"}`)
- `PUT /api/tools/{category}/{tool}/select/{true|false}` - Set selection state
- `PUT /api/tools/{category}/{tool}/select` - Toggle selection
- `GET /api/tools/selected` - Get all selected tools
- `DELETE /api/tools/selected` - Clear all selections

Swagger UI: http://localhost:7777/swagger-ui.html

#### Tools Requiring Elevation
- docker (Hyper-V/WSL2)
- postgresql, mysql, mongodb (system services)

The installer warns before proceeding with these tools.

---