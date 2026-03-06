#!/bin/bash
chcp 65001 > /dev/null

source ./scripts/utils.sh
source ./scripts/lang.sh
source ./scripts/tools.sh

clear
echo "███╗   ███╗ █████╗  ██████╗███████╗ ██████╗" 
echo "████╗ ████║██╔══██╗██╔════╝██╔════╝██╔════╝" 
echo "██╔████╔██║███████║██║     █████╗  ██║  ███╗"
echo "██║╚██╔╝██║██╔══██║██║     ██╔══╝  ██║   ██║"
echo "██║ ╚═╝ ██║██║  ██║╚██████╗██║     ╚██████╔╝"
echo "............................................"
echo "USER: $(whoami) | PATH: $(pwd)"

mkdir -p ./bin

echo "[*] Customizing settings.json to match your user..."
USER_NAME=$(whoami)
sed -i "s/<NAME>/$USER_NAME/g" ./conf/settings.json

install_git_tools     
install_languages     
install_vscode        
install_bruno         

if ask_install "Fonts" "JetBrainsMono"; then
    echo "[*] Font installation..."
    mkdir -p "./bin/fonts"
    curl -L "$(ini_val links FONT_JB ./conf/links.ini)" -o "fonts.zip"
    unzip -q "fonts.zip" -d "./bin/fonts"
    rm "fonts.zip"
    echo "Install manually ttf fonts"
fi

echo "[*] generating set_env.bat..."
cat <<EOF > set_env.bat
@echo off
set "ROOT=%CD%"
set "PATH=%ROOT%\bin\git\bin;%ROOT%\bin\git\usr\bin;%ROOT%\bin\jdk21\bin;%ROOT%\bin\python;%ROOT%\bin\vscode\bin;%ROOT%\bin\busybox;%PATH%"
set "JAVA_HOME=%ROOT%\bin\jdk21"
echo [OK] Dev env loaded
EOF

echo "............................................"
echo "start set_env.bat to finis"