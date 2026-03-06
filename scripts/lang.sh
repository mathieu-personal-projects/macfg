#!/bin/bash

install_git_tools() {
    if ask_install "SSH Keys" "ed25519"; then
        echo "Generating SSH keys"
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$(whoami)@autoinstall" -f "$HOME/.ssh/id_ed25519" -N ""
        echo "Public key (github/gitlab) :"
        cat "$HOME/.ssh/id_ed25519.pub"
    fi

    if ask_install "BusyBox" "latest"; then
        mkdir -p "./bin/busybox"
        curl -L "$(ini_val links BUSYBOX ./conf/links.ini)" -o "./bin/busybox/busybox.exe"
        echo "busybox installed in ./bin/busybox"
    fi
}

install_languages() {
    # Java
    JAVA_V=$(ini_val "tools.versions" "lang.java" "./conf/user.ini")
    if ask_install "Java" "$JAVA_V"; then
        echo "Java installation"
        curl -L "$(ini_val links JAVA ./conf/links.ini)" -o "java.zip"
        unzip -q "java.zip" -d "./bin/jdk21"
        rm "java.zip"
    fi
    
    # Python
    PY_V=$(ini_val "tools.versions" "lang.python" "./conf/user.ini")
    if ask_install "Python" "$PY_V"; then
        echo "Python installation"
        curl -L "$(ini_val links PYTHON ./conf/links.ini)" -o "python.zip"
        unzip -q "python.zip" -d "./bin/python"
        rm "python.zip"
    fi
}