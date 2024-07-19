printColor() {
    local color=$1
    local text=$2

    case $color in
        "green")
            echo -e "\e[1m\e[32m${text}\e[0m" ;;
        "red")
            echo -e "\e[1m\e[31m${text}\e[0m" ;;
        "blue")
            echo -e "\e[1m\e[34m${text}\e[0m" ;;
        "yellow")
            echo -e "\e[1m\e[33m${text}\e[0m" ;;
	"black") 
	    echo -e "\e[1m\e[30m${text}\e[0m" ;;
        *)
            echo "Unsupported color" ;;
    esac
}

function logo {
  bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
}


function printLine {
  echo "---------------------------------------------------------------------------------------"
}       

function addToPath {
    if ! echo "$PATH" | grep -q "${1}" ; then
        echo "export PATH=\$PATH:${1}" >> $HOME/.bash_profile
        source $HOME/.bash_profile
    fi
}

function printAddition {
    echo -e "\e[4m${1}\e[0m"
}

function printGreen {
    echo -e "\e[1m\e[32m${1}\e[0m"
}

function printRed {
    echo -e "\e[1m\e[31m${1}\e[0m"	
}

function printBlue {
	echo -e "\e[1m\e[34m${1}\e[0m"
}

function printYellow {
	echo -e "\e[1m\e[33m${1}\e[0m"
}
