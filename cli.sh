#!/usr/bin/env bash

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

RED='\033[0;31m'
GREEN='\033[0;32m'
LIGHT_CYAN='\033[0;96m'
BLUE='\033[0;34m'
NOCOLOR='\033[0m'

function print_green() {
    echo -e "${GREEN}$1${NOCOLOR}"
}

function print_blue() {
    echo -e "${BLUE}$1${NOCOLOR}"
}

function print_error() {
    echo -e "${RED}$1${NOCOLOR}"
}

function print_cyan() {
    echo -e "${LIGHT_CYAN}$1${NOCOLOR}"
}

# Name of the script
SCRIPT=$( basename "$0" )

# Current version
VERSION="1.0.0"

#
# Message to display for usage and help.
#
function usage
{
    local txt=(
"Utility $SCRIPT for handle the NiFi environment."
"Usage: $SCRIPT [options] <command> [arguments]"
""
"Commands:"
"  scale            ./cli.sh scale <SERVICE> <NUMBER_OF_INSTANCES> - It will scale containers of available servers"
"  start            ./cli.sh start                                 - It will start the NiFi environment"
"  stop             ./cli.sh stop                                  - It will start the NiFi environment"
""
""
"Options:"
"  --help, -h               Print help."
"  --version, -v            Print version."
    )

    printf "%s\n" "${txt[@]}"
}

#
# Message to display for version.
#
function version
{
    local txt=("$SCRIPT version $VERSION")
    printf "%s\n" "${txt[@]}"
}

function print_banner
{
print_cyan "
      _ _____   _   _ ___ _____ ___    ____ _     ___
     | |  ___| | \ | |_ _|  ___|_ _|  / ___| |   |_ _|
  _  | | |_    |  \| || || |_   | |  | |   | |    | |
 | |_| |  _|   | |\  || ||  _|  | |  | |___| |___ | |
  \___/|_|     |_| \_|___|_|   |___|  \____|_____|___|
"

  echo
}

#
# Function responsible to scale the env
#
function setup-scale
{
  "$BASEDIR/scale.sh" "$@"
}

#
# Function responsible to start the env
#
function setup-start
{
  "$BASEDIR/start.sh" "$@"
}

#
# Function responsible to stop the env
#
function setup-stop
{
  "$BASEDIR/stop.sh" "$@"
}

#
# Process options
#
print_banner;
for argument in "$@"
do
    case "$argument" in

        --help | -h)
            usage
            exit 0
        ;;

        --version | -v)
            version
            exit 0
        ;;

        scale         \
        | start       \
        | stop)

        shift
        "setup-$argument" "$@"
        exit 0

    esac
done

exit 0