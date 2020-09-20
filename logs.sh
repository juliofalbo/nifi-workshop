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
"Utility $SCRIPT for show logs of the NiFi Environment."
"Usage: $SCRIPT [options] <command> [arguments]"
""
"Commands:"
"  nifi            ./cli.sh logs nifi - It will show the NIFI's container logs"
"  nginx           ./cli.sh logs nginx - It will show the Nginx's container logs"
"  grafana         ./cli.sh logs grafana - It will show the Grafana's container logs"
"  prometheus      ./cli.sh logs prometheus - It will show the Prometheus's container logs"
""
""
"Options:"
"  --help, -h               Print help."
"  --version, -v            Print version."
"  --instance, -i           Indicate which instance will show the logs. The default is 1"
"  --follow, -f             Indicate if you want to follow the logs."
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


# Function responsible to show the NIFI's container logs
#
function log-nifi
{
  LOG_INSTANCE_VALUE=$(getInstanceArgumentValue "$@");

  LOG_FOLLOW_VALUE=$(getFollowArgumentValue "$@");
   if [ "$LOG_FOLLOW_VALUE" == 0 ] 
  then
    docker logs "nifi-workshop_nifi_$LOG_INSTANCE_VALUE" -f
  else
    docker logs "nifi-workshop_nifi_$LOG_INSTANCE_VALUE"
  fi
}

# Function responsible to show the Nginx's container logs
#
function log-nginx
{
  LOG_FOLLOW_VALUE=$(getFollowArgumentValue "$@");
   if [ "$LOG_FOLLOW_VALUE" == 0 ] 
  then
    docker logs nginx -f
  else
    docker logs nginx
  fi
}

# Function responsible to show the Grafana's container logs
#
function log-grafana
{
  LOG_FOLLOW_VALUE=$(getFollowArgumentValue "$@");
  if [ "$LOG_FOLLOW_VALUE" == 0 ]
  then
    docker logs grafana -f
  else
    docker logs grafana
  fi
}

# Function responsible to show the Prometheus's container logs
#
function log-prometheus
{
  LOG_FOLLOW_VALUE=$(getFollowArgumentValue "$@");
   if [ "$LOG_FOLLOW_VALUE" == 0 ] 
  then
    docker logs prometheus -f
  else
    docker logs prometheus
  fi
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
# Method responsible to check if the log should be follwed
#
function getFollowArgumentValue {
  FOLLOW_RETURN_VALUE=1;
  for setUpArgument in "$@"
  do
    case "$setUpArgument" in
        --follow | -f)
          FOLLOW_RETURN_VALUE=0;
        ;;
    esac
  done
  echo "$FOLLOW_RETURN_VALUE";
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

        --version | -v)
            version
            exit 0
        ;;

        --instance | -i)
        ;;

        --follow | -f)
        ;;

        nifi         \
        | nginx      \
        | grafana    \
        | prometheus)
            shift
            "log-$argument" "$@"
            exit 0
        ;;

        *)
            print_error "Option/command '$argument' not recognized."
        ;;

    esac
done

exit 0