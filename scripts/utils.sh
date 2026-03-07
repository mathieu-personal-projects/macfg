unzip() {
    local zipfile destdir
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -q) shift ;;
            -d) destdir="$2"; shift 2 ;;
            *) zipfile="$1"; shift ;;
        esac
    done
    powershell -Command "Expand-Archive -Path '$zipfile' -DestinationPath '$destdir' -Force"
}

get_vsc_extensions() {
    local file=$1
    sed -nr "/^\[vsc-plugins\]/ { :l n; /^\[/ q; /^[^#;].*=/ { s/^[^=]*=[ ]*//; p; }; b l; }" "$file" \
        | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'
}

ask_install(){
    read -p "Do you want to install $1:$2 ? (y/n) : " choice
    case "$choice" in
        y|Y ) return 0 ;;
        * ) return 1 ;;
    esac
}

# parse user.ini
ini_val(){
    section=$1
    key=$2
    file=$3
    sed -nr "/^\[$section\]/ { :l /^$key[ ]*=/ { s/[^=]*=[ ]*//; p; q;}; n; b l;}" "$file"
}