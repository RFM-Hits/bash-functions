# Init color variables for terminal output
function set_colors() {
    # Regular Colors
    BLACK='\033[0;30m'
    WHITE='\033[1;37m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'

    # Bold Colors
    BBLACK='\033[1;30m'
    BWHITE='\033[1;37m'
    BRED='\033[1;31m'
    BGREEN='\033[1;32m'
    BYELLOW='\033[1;33m'
    BBLUE='\033[1;34m'
}

# Checks if the first argument is 'silent'.
# Parameters:
# $1 - The first argument, which should be "silent" to suppress output.
function is_silent() {
    [[ $1 == "silent" ]]
}

# Checks if is a linux distribution
function is_linux() {
    if [ "$(uname)" == "Linux" ]; then
        return 0
    else
        echo -e "${RED}This script is only for Linux systems.${WHITE}"
        exit 1
    fi
}

# Checks if 64 bit
function is_64bit() {
    if [ "$(uname -m)" == "x86_64" ]; then
        return 0
    else
        echo -e "${RED}This script is only for 64 bit systems.${WHITE}"
        exit 1
    fi
}



# checks Raspberry Pi model
# minimal version is 3
function rpi_model() {
    if [ -f /proc/device-tree/model ]; then
        model=$(tr -d '\0' </proc/device-tree/model)
        case $model in
            "Raspberry Pi 3 Model B Rev 1.2")
                return 0
                ;;
            "Raspberry Pi 3 Model B Plus Rev 1.3")
                return 0
                ;;
            "Raspberry Pi 4 Model B Rev 1.1")
                return 0
                ;;
            *)
                echo -e "${RED}This script is only for Raspberry Pi 3 Model B, Raspberry Pi 3 Model B Plus and Raspberry Pi 4 Model B.${WHITE}"
                exit 1
                ;;
        esac
    else
        echo -e "${RED}This script is only for Raspberry Pi 3 Model B, Raspberry Pi 3 Model B Plus and Raspberry Pi 4 Model B.${WHITE}"
        exit 1
    fi
}