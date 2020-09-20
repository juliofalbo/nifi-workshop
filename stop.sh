#!/usr/bin/env bash

BASEDIR="$(
  cd "$(dirname "$0")" >/dev/null 2>&1
  pwd -P
)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NOCOLOR='\033[0m'

function print_green() {
  echo -e "${GREEN}$1${NOCOLOR}"
}

function print_blue() {
  echo -e "${BLUE}$1${NOCOLOR}"
}

function print_red() {
  echo -e "${RED}$1${NOCOLOR}"
}

# Name of the script
SCRIPT=$(basename "$0")

# Current version
VERSION="1.0.0"

#
# Message to display for usage and help.
#
function usage() {
  local txt=(
    "Utility $SCRIPT for stop the Apache NiFi environment."
    "Usage: $SCRIPT [options] <command> [arguments]"
    ""
    "Commands:"
    "  all             ./cli.sh stop all        - It will stop the whole env"
    "  nifi            ./cli.sh stop nifi       - It will stop only NiFi"
    "  services        ./cli.sh stop services   - It will stop all services around NiFi"
    "  monitoring      ./cli.sh stop monitoring - It will stop only Grafana and Prometheus"
    "- Note: You can combine commands like: ./cli.sh stop nifi monitoring"
    ""
    ""
    "Options:"
    "  --help, -h               Print help."
    "  --version, -v            Print version."
    "  --remove-volumes, -rv    Remove all volumes (it means that you will loose all your data)."
    "  --instance, -i           Indicate which instance should be stopped"
  )

  printf "%s\n" "${txt[@]}"
}

#
# Message to display for version.
#
function version() {
  local txt=("$SCRIPT version $VERSION")
  printf "%s\n" "${txt[@]}"
}

#
# Function responsible to stop ALL apps
#
function stop-all() {
  stop-services "$@"
  stop-monitoring "$@"
  stop-nifi "$@"
  stop-services "$@"
  echo
}

#
# Function responsible to stop NiFi
#
function stop-nifi() {
  STOP_INSTANCE_VALUE=$(getInstanceArgumentValue "$@")

  if [ -n "$STOP_INSTANCE_VALUE" ]; then
    print_red "Stopping NiFi instance $STOP_INSTANCE_VALUE"
    docker stop "nifi-workshop_nifi_$STOP_INSTANCE_VALUE"
  else
    REMOVE_VOLUME=$(getRemoveVolumeArgumentValue "$@")
    if [ "$REMOVE_VOLUME" == 0 ]; then
      print_red "Stopping NiFi removing volumes"
      docker-compose -f "$BASEDIR/docker-compose-nifi-cluster.yml" down -v
      docker-compose -f "$BASEDIR/docker-compose-nifi-two-standalone.yml" down -v
    else
      print_red "Stopping NiFi keeping volumes"
      docker-compose -f "$BASEDIR/docker-compose-nifi-cluster.yml" down
      docker-compose -f "$BASEDIR/docker-compose-nifi-two-standalone.yml" down
    fi

    #https://github.com/juliofalbo/docker-compose-prometheus-service-discovery
  "$HOME/workspace/docker-compose-prometheus-service-discovery/docker-prmt-serv-disc.sh" stop

    print_green "NiFi stopped"
    echo
  fi

}

#
# Function responsible to stop all Services
#
function stop-services() {
  REMOVE_VOLUME=$(getRemoveVolumeArgumentValue "$@")
  if [ "$REMOVE_VOLUME" == 0 ]; then
    print_red "Stopping all Services removing volumes"
    docker-compose -f "$BASEDIR/docker-compose-services.yml" down -v
    docker-compose -f "$BASEDIR/docker-compose-services.yml" down -v
    docker-compose -f "$BASEDIR/docker-compose-nifi-cluster-env.yml" down -v
    docker-compose -f "$BASEDIR/docker-compose-nifi-cluster-env.yml" down -v
  else
    print_red "Stopping all Services keeping volumes"
    docker-compose -f "$BASEDIR/docker-compose-services.yml" down
    docker-compose -f "$BASEDIR/docker-compose-nifi-cluster-env.yml" down
  fi

  print_green "All services stopped"
  echo

}

#
# Function responsible to stop MONITORING env
#
function stop-monitoring() {
  REMOVE_VOLUME=$(getRemoveVolumeArgumentValue "$@")
  if [ "$REMOVE_VOLUME" == 0 ]; then
    print_red "Stopping MONITORING env removing volumes"
    docker-compose -f "$BASEDIR/docker-compose-monitoring.yml" down -v
  else
    print_red "Stopping MONITORING env keeping volumes"
    docker-compose -f "$BASEDIR/docker-compose-monitoring.yml" down
  fi

  print_green "MONITORING env stopped"
  echo
}

#
# Method responsible to check if the database should start with reset argument
#
function getRemoveVolumeArgumentValue() {
  REMOVE_VOLUMES_RETURN_VALUE=1
  for setUpArgument in "$@"; do
    case "$setUpArgument" in
    --remove-volumes | -rv)
      REMOVE_VOLUMES_RETURN_VALUE=0
      ;;
    esac
  done
  echo "$REMOVE_VOLUMES_RETURN_VALUE"
}

#
# Method responsible to return the specific APP scale value.
# Default is 1
#
function getInstanceArgumentValue() {
  INSTANCE_COUNTER=0
  INSTANCE_VALUE=()
  for setUpArgument in "$@"; do
    INSTANCE_COUNTER=$((INSTANCE_COUNTER + 1))
    case "$setUpArgument" in
    --instance | -i)
      INSTANCE_VALUE=("${@:INSTANCE_COUNTER+1}")
      ;;
    esac
  done
  echo "${INSTANCE_VALUE[0]}"
}

#
# Process options
#
#print_banner;
for argument in "$@"; do
  case "$argument" in

  --help | -h)
    usage
    exit 0
    ;;

  --version | -v)
    version
    exit 0
    ;;

  --remove-volumes | -rv) ;;

  --instance | -i) ;;

  all)
    stop-all "$@"
    exit 0
  ;;

  nifi \
  | services \
  | monitoring)
    shift
    "stop-$argument" "$@"
    ;;

  esac
done

exit 0
