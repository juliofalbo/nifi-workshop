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
"Utility $SCRIPT for scale Apache NiFi instances in a cluster."
"Usage: $SCRIPT [options] <command> [arguments]"
""
"Commands:"
"  nifi            ./nifi-env-cli scale nifi <NUMBER_OF_INSTANCES> - It will scale NIFI's containers"
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

#
# Function responsible to scale NIFI
#
function scale-nifi
{
  print_cyan "Scaling NIFI for $1 instances"
  "$BASEDIR/start.sh" nifi --cluster "$1"
}

#
# Process options
#
#print_banner;
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

        nifi)
          shift
          "scale-$argument" "$@"
          exit 0
        ;;

    esac
done

exit 0