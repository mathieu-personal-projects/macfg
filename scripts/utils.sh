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