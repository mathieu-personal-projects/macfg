#!/bin/bash

install_git_tools() {
    if ask_install "SSH Keys" "ed25519"; then
        echo "Generating SSH keys"
        mkdir -p "$HOME/.ssh"
        read -p "Email (SSH key comment): " mail
        ssh-keygen -t ed25519 -C "$mail" -f "$HOME/.ssh/id_ed25519" -N ""
        echo "Public key (github/gitlab) :"
        cat "$HOME/.ssh/id_ed25519.pub"
    fi

    if ask_install "BusyBox" "latest"; then
        mkdir -p "./bin/busybox"
        curl -L "$(ini_val links BUSYBOX ./conf/links.ini)" -o "./bin/busybox/busybox.exe"
        "./bin/busybox/busybox.exe" --install "./bin/busybox"
        echo "busybox installed in ./bin/busybox"
    fi
}

install_languages() {
    # Java
    JAVA_V=$(ini_val "tools.versions" "lang.java" "./conf/user.ini")
    if ask_install "Java" "$JAVA_V"; then
        echo "Java installation"
        curl -L "$(ini_val links JAVA ./conf/links.ini)" -o "java.zip"
        unzip -q "java.zip" -d "./bin/jdk21_tmp"
        src=$(ls -d ./bin/jdk21_tmp/jdk-* 2>/dev/null | head -1)
        [[ -n "$src" ]] && mv "$src" "./bin/jdk21" || mv "./bin/jdk21_tmp" "./bin/jdk21"
        rm -rf "./bin/jdk21_tmp" 2>/dev/null
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

    # Rust
    RUST_V=$(ini_val "tools.versions" "lang.rust" "./conf/user.ini")
    if ask_install "Rust" "$RUST_V"; then
        echo "Rust installation (via rustup)"
        export CARGO_HOME="$(pwd)/bin/rust/cargo"
        export RUSTUP_HOME="$(pwd)/bin/rust/rustup"
        mkdir -p "$CARGO_HOME" "$RUSTUP_HOME"
        curl -L "$(ini_val links RUST ./conf/links.ini)" -o "rustup-init.exe"
        ./rustup-init.exe -y --no-modify-path
        rm "rustup-init.exe"
    fi
}