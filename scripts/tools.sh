#!/bin/bash

install_vscode() {
    if ask_install "VS Code" "latest"; then
        echo "VsCdode installation (portable)"
        curl -L "$(ini_val links VSCODE ./conf/links.ini)" -o "vscode.zip"
        unzip -q "vscode.zip" -d "./bin/vscode"
        rm "vscode.zip"
        
        mkdir -p "./bin/vscode/data/user-data/User"
        cp "./conf/settings.json" "./bin/vscode/data/user-data/User/settings.json"
        
        echo "Installing extensions"
        ./bin/vscode/bin/code --user-data-dir "./bin/vscode/data" --install-extension github.copilot
        ./bin/vscode/bin/code --user-data-dir "./bin/vscode/data" --install-extension ms-python.python
    fi
}

install_bruno() {
    if ask_install "Bruno" "latest"; then
        curl -L "$(ini_val links BRUNO ./conf/links.ini)" -o "bruno.zip"
        unzip -q "bruno.zip" -d "./bin/bruno"
        rm "bruno.zip"
    fi
}