# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
Always update this file when updating the project, and always report the number of tokens used with its approximation in €.

---

## Project Overview

This is a Spring Shell CLI application written in Kotlin (version 2.2.21) using Java 21 and Spring Boot.
It acts as a development environment setup tool to download and install various dev tools based on the current OS (Windows, Linux, macOS).

### Architecture
The project is built as a **single-module** application:
- No longer split into multiple services or APIs.
- Uses **Spring Shell** to provide an interactive command-line interface.
- Core commands are located in `src/main/kotlin/com/macfg/cli/InstallCommand.kt`.
- Tool installers are dynamically managed via `InstallerRegistry` and extend `ToolInstaller`.

### Key Features
- **OS Detection**: Auto-detects Windows/Linux/macOS and adapts download URLs/installation paths.
- **No Privilege Required**: Most tools are installed locally to `~/dev` or `%USERPROFILE%\dev` without elevation.
- **Privilege Warnings**: Explicitly warns when tools (Docker, PostgreSQL, WSL, etc.) require admin rights.
- **Interactive CLI**: Step-by-step guided installation process (ex: via the `select` command).

### Available Commands
Once the shell is started, the following commands are available:
- `list`: Lists all available tools grouped by category (Dev Tools, Editors, Databases, Runtimes, etc.) along with their installation status.
- `select`: Opens an interactive menu to choose tools to install by entering their corresponding numbers.
- `install <tools>`: Installs one or more tools specified by name, separated by commas (e.g., `install vscode,java,node`).
- `install-all`: Installs all tools that do not require administrative elevation.
- `status <tool>`: Checks the specific status and version of a given tool.

### Running the Application

You can launch the interactive shell directly with Maven wrapper:
```bash
./mvnw spring-boot:run
```

Once loaded, type `help` to see the available commands or `list` to see available tools.

### Running with Docker

Since turning into a CLI tool, the project can also be built and run using Docker (although its main purpose is to configure your host machine):

**Build the image:**
```bash
docker build -t macfg:latest .
```

**Run interactively:**
```bash
docker run -it --rm -v ${HOME}/dev:/root/dev macfg:latest
```

### Tools Requiring Elevation
Some tools interact with the base system and require the terminal to be run as Administrator/root:
- WSL2
- Docker
- Databases: mongodb, postgresql, mysql
- DB GUIs: pgadmin, mysql-workbench, compass
- make

The installer will warn before proceeding with these tools if they are requested.
