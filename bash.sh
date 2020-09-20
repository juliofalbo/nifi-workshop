#!/usr/bin/env bash

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
"Utility $SCRIPT for enter in the containers of the NiFi environment."
"Usage: $SCRIPT [options] <command> [arguments]"
""
"Commands:"
"  nifi            ./cli.sh bash nifi - It will enter in the bash of NIFI's container"
"  nginx           ./cli.sh bash nginx - It will enter in the bash of Nginx's container"
"  grafana         ./cli.sh bash grafana - It will enter in the bash of Grafana's container"
""
""
"Options:"
"  --help, -h               Print help."
"  --version, -v            Print version."
"  --instance, -i           Indicate which instance will show the logs. The default is 1"
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

# Function responsible to enter in the NiFi's container bash
#
function bash-nifi
{
  print_cyan "Entering in the bash NiFi container"
  LOG_INSTANCE_VALUE=$(getInstanceArgumentValue "$@");
  docker exec -it "nifi-workshop_nifi_$LOG_INSTANCE_VALUE" bash
}

# Function responsible to enter in the Nginx's container bash
#
function bash-nginx
{
  print_cyan "Entering in the bash NGINX container"
  docker exec -it nginx bash
}

# Function responsible to enter in the Grafana's container bash
#
function bash-grafana
{
  print_cyan "Entering in the bash GRAFANA container"
  docker exec -it grafana bash
}

# Function responsible to enter in the Prometheus's container bash
#
function bash-prometheus
{
  print_cyan "Entering in the bash PROMETHEUS container"
  docker exec -it prometheus bash
}

#
# Method responsible to return the specific APP scale value.
# Default is 1
#
function getInstanceArgumentValue {
  INSTANCE_COUNTER=0;
  INSTANCE_VALUE=(1);
  for setUpArgument in "$@"
  do
    INSTANCE_COUNTER=$((INSTANCE_COUNTER+1));
    case "$setUpArgument" in
        --instance | -i)
          INSTANCE_VALUE=("${@:INSTANCE_COUNTER+1}");
        ;;
    esac
  done
  echo "${INSTANCE_VALUE[0]}";
}

#
# Process options
#
for argument in "$@"
do
    case "$argument" in

        --help | -h)
            usage
            exit 0
        ;;

        --instance | -i)
        ;;

        --version | -v)
            version
            exit 0
        ;;

        nifi         \
        | nginx      \
        | grafana)
            shift
            "bash-$argument" "$@"
            exit 0
        ;;

        *)
            print_error "Option/command '$argument' not recognized."
        ;;

    esac
done

exit 0