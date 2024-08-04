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
            "Raspberry Pi 5 Model B Rev 1.0")
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

# Check user privileges
# Takes one parameter: "privileged" to check if the user is root, "regular" to check if the user is not root.
function check_privileges() {
    if [[ $1 == "privileged" ]]; then
        if [[ $EUID -ne 0 ]]; then
            echo -e "${RED}This script must be run as root.${WHITE}"
            exit 1
        fi
    elif [[ $1 == "regular" ]]; then
        if [[ $EUID -eq 0 ]]; then
            echo -e "${RED}This script must be run as a regular user.${WHITE}"
            exit 1
        fi
    fi
}


# Check if the 'apt' package manager is present.
# No parameters.
function check_apt() {
    if ! command -v apt > /dev/null 2>&1; then
        echo -e "${RED}Error: apt is not installed. Exiting...${NC}"
        exit 1
    fi
}

# Update the OS using 'apt' package manager.
# Parameters:
# $1 - (Optional) The first argument, which should be "silent" to suppress output.
function update_os() {
    check_apt
    if is_silent $1; then
        echo -e "${BLUE}►► Updating all OS packages in silent mode...${NC}"
        output_redirection="> /dev/null 2>&1"
    else
        echo -e "${BLUE}►► Updating all OS packages...${NC}"
        output_redirection=""
    fi
    eval "apt -qq -y update $output_redirection"
    eval "apt -qq -y full-upgrade $output_redirection"
    eval "apt -qq -y autoremove $output_redirection"
}

# Installs packages using 'apt' package manager.
# Parameters:
# $1 - (Optional) The first argument, which should be "silent" to suppress output.
# $@ - All the arguments, which should be the names of packages to install.
function install_packages() {
    if is_silent $1; then
        output_redirection='> /dev/null 2>&1'
        shift
    else
        output_redirection=''
    fi
    
    check_apt
    echo -e "${BLUE}►► Installing dependencies...${NC}"
    eval "apt -qq -y update ${output_redirection}"
    for package in "$@"; do
        eval "apt -qq -y install ${package} ${output_redirection}"
    done
}

# Set the system timezone.
# Parameters:
# $1 - The first argument, which should be a valid timezone, e.g. "Europe/Amsterdam".
function set_timezone() {
    local timezone=$1
    if [ -f "/usr/share/zoneinfo/${timezone}" ]; then
        echo -e "${BLUE}►► Setting timezone to ${timezone}...${NC}"
        ln -fs /usr/share/zoneinfo/$timezone /etc/localtime > /dev/null
        dpkg-reconfigure -f noninteractive tzdata > /dev/null
    else
        echo -e "${RED} Error: Invalid timezone: ${timezone}${NC}"
    fi
}

# Checks the installation of packages that provide required commands
# Parameters:
# $@ - All the arguments, which should be the names of the commands to check.
function check_required_command {
  for cmd in "$@"; do
    if ! command -v "$cmd" &> /dev/null; then
      echo -e "${RED} Error: Installation failed. $cmd is not successfully installed.${NC}"
      INSTALL_FAILED=true
    fi
  done
}

# Prompt the user for input.
# If the user doesn't provide a value, the default value is assigned.
# Parameters:
# $1 - The variable name (will be all caps)
# $2 - The default value for the variable
# $3 - The prompt to display to the user
# $4 - (Optional) The type of the variable (y/n, num, str, email, host). Default is str.
# Example:
# ask_user "MY_NUM" "1" "Please enter a number" "num"
function ask_user {
  local var_name="$1"
  local default_value="$2"
  local prompt="$3"
  local var_type="${4:-str}"

  local input

  while true; do
    read -p "${prompt} [default: ${default_value}]: " input
    input="${input:-$default_value}"

    case $var_type in
      'y/n')
        if [[ "$input" =~ ^(y|n)$ ]]; then
          break
        else
          echo "Invalid input. Please enter y or n."
        fi
        ;;
      'num')
        if [[ "$input" =~ ^[0-9]+$ ]]; then
          break
        else
          echo "Invalid input. Please enter a number."
        fi
        ;;
      'str')
        if [[ -n "$input" ]]; then
          break
        else
          echo "Invalid input. Please enter a string."
        fi
        ;;
      'email')
        if [[ "$input" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
          break
        else
          echo "Invalid input. Please enter a valid e-mail address."
        fi
        ;;
      'host')
        if [[ "$input" =~ ^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$ ]]; then
          break
        else
          echo "Invalid input. Please enter a valid hostname."
        fi
        ;;  
      *)
        echo "Unknown validation type: $var_type"
        return 1
        ;;
    esac
  done


  eval "$var_name=\"$input\""
  }