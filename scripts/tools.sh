#!/bin/bash

install_vscode() {
    if ask_install "VS Code" "latest"; then
        echo "VsCode installation (portable)"
        curl -L "$(ini_val links VSCODE ./conf/links.ini)" -o "vscode.zip"
        unzip -q "vscode.zip" -d "./bin/vscode"
        rm "vscode.zip"

        mkdir -p "./bin/vscode/data/user-data/User"
        cp "./conf/settings.json" "./bin/vscode/data/user-data/User/settings.json"

        echo "Installing extensions..."
        while IFS= read -r ext; do
            [[ -n "$ext" ]] && cmd //c ".\\bin\\vscode\\bin\\code.cmd" \
                --user-data-dir ".\\bin\\vscode\\data" \
                --install-extension "$ext"
        done < <(get_vsc_extensions "./conf/user.ini")
    fi
}

install_bruno() {
    if ask_install "Bruno" "latest"; then
        curl -L "$(ini_val links BRUNO ./conf/links.ini)" -o "bruno.zip"
        unzip -q "bruno.zip" -d "./bin/bruno"
        rm "bruno.zip"
    fi
}

install_docker() {
    if ask_install "Docker Desktop" "latest"; then
        echo "[*] Downloading Docker Desktop (this may take a while)..."
        curl -L "$(ini_val links DOCKER ./conf/links.ini)" -o "docker-installer.exe"
        echo "[!] Installing Docker Desktop with elevation..."
        powershell -Command '$p = (Get-Location).Path + "\\docker-installer.exe"; Start-Process -FilePath $p -ArgumentList "install","--quiet" -Verb RunAs -Wait'
        rm "docker-installer.exe"
    fi
}

install_cli_tools() {
    if ask_install "Make" "4.4.1"; then
        mkdir -p "./bin/make"
        curl -L "$(ini_val links MAKE ./conf/links.ini)" -o "./bin/make/make.exe"
        echo "make installed in ./bin/make"
    fi

    if ask_install "WSL2" "latest"; then
        echo "[!] WSL requires elevation..."
        powershell -Command 'Start-Process "wsl.exe" -ArgumentList "--install" -Verb RunAs -Wait'
    fi
}

install_databases() {
    if ask_install "MongoDB" "latest"; then
        echo "MongoDB installation"
        curl -L "$(ini_val links MONGODB ./conf/links.ini)" -o "mongodb.zip"
        unzip -q "mongodb.zip" -d "./bin/mongodb_tmp"
        src=$(ls -d ./bin/mongodb_tmp/mongodb-* 2>/dev/null | head -1)
        [[ -n "$src" ]] && mv "$src" "./bin/mongodb" || mv "./bin/mongodb_tmp" "./bin/mongodb"
        rm -rf "./bin/mongodb_tmp" 2>/dev/null
        rm "mongodb.zip"
        mkdir -p "./bin/mongodb/data"
        echo "[i] Start: ./bin/mongodb/bin/mongod --dbpath ./bin/mongodb/data"
    fi

    if ask_install "MySQL" "latest"; then
        echo "MySQL installation"
        curl -L "$(ini_val links MYSQL ./conf/links.ini)" -o "mysql.zip"
        unzip -q "mysql.zip" -d "./bin/mysql_tmp"
        src=$(ls -d ./bin/mysql_tmp/mysql-* 2>/dev/null | head -1)
        [[ -n "$src" ]] && mv "$src" "./bin/mysql" || mv "./bin/mysql_tmp" "./bin/mysql"
        rm -rf "./bin/mysql_tmp" 2>/dev/null
        rm "mysql.zip"
        echo "[i] Init: ./bin/mysql/bin/mysqld --initialize-insecure --basedir=./bin/mysql --datadir=./bin/mysql/data"
    fi

    if ask_install "PostgreSQL" "latest"; then
        echo "PostgreSQL installation"
        curl -L "$(ini_val links POSTGRESQL ./conf/links.ini)" -o "pgsql.zip"
        unzip -q "pgsql.zip" -d "./bin"
        rm "pgsql.zip"
        mkdir -p "./bin/pgsql/data"
        echo "[i] Init: ./bin/pgsql/bin/initdb -D ./bin/pgsql/data"
    fi
}

install_db_managers() {
    if ask_install "MongoDB Compass" "latest"; then
        echo "MongoDB Compass installation"
        curl -L "$(ini_val links COMPASS ./conf/links.ini)" -o "compass-installer.exe"
        powershell -Command '$p = (Get-Location).Path + "\\compass-installer.exe"; Start-Process -FilePath $p -Wait'
        rm "compass-installer.exe"
    fi
}