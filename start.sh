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
"Utility $SCRIPT for start the NiFi Environment of Apache NiFi."
"Usage: $SCRIPT [options] <command> [arguments]"
""
"Commands:"
"  all             ./cli.sh start all        - It will start all apps and monitoring"
"  monitoring      ./cli.sh start monitoring - It will start only monitoring env (Grafana and Prometheus)"
"  nifi            ./cli.sh start nifi        - It will start only NiFi"
"  services        ./cli.sh start services    - It will start services for the Apache NiFi environment"
"- Note: You can combine commands like: ./cli.sh start nifi monitoring"
""
"Options:"
"  --help, -h                Print help."
"  --version, -v             Print version."
"  --cluster, -c             It will start NiFi in a cluster mode and you must inform how many instances of NiFi will run in a cluster"
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
# Method responsible to return the NIFI scale value.
# Default is 1
#
function getScaleArgumentValue {
  SCALE_COUNTER=0;
  SCALE_VALUE=(1);
  for setUpArgument in "$@"
  do
    SCALE_COUNTER=$((SCALE_COUNTER+1));
    case "$setUpArgument" in
        --cluster | -c)
          SCALE_VALUE=("${@:$SCALE_COUNTER+1}");
        ;;
    esac
  done
  if [[ ${SCALE_VALUE[0]} ]] ; then
    echo "${SCALE_VALUE[0]}";
  else
    echo 2;
  fi

}

#
# Method responsible to check if NIFI will run in cluster mode
#
function getClusterArgumentValue {
  CLUSTER_VALUE=1;
  for setUpArgument in "$@"
  do
    case "$setUpArgument" in
        --cluster | -c)
          CLUSTER_VALUE=0;
        ;;
    esac
  done
  echo "$CLUSTER_VALUE";
}

#
# Function responsible to set-up all environment
#
function setup-all
{
  print_blue "Starting the complete Apache NiFi with Monitoring Environment";

  setup-services "$@"
  setup-nifi "$@"
  setup-monitoring "$@"

  print_green "Apache NiFi Environment is up and running";
  echo;
}

#
# Function responsible to set-up only NiFi
#
function setup-nifi
{
  CLUSTER=$(getClusterArgumentValue "$@");
  if [[ "$CLUSTER" == 0 ]] ; then
      print_cyan "Starting NIFI in a Cluster"
      docker-compose -f "$BASEDIR/docker-compose-nifi-cluster-env.yml" up -d;
      INSTANCES_SCALE=$(getScaleArgumentValue "$@");
      docker-compose -f "$BASEDIR/docker-compose-nifi-cluster.yml" up -d --scale nifi="$INSTANCES_SCALE";

      print_cyan "Waiting NiFi";
      "$BASEDIR/waitHttp.sh" 10 http://localhost:8080/nifi
  else
      print_cyan "Starting NIFI with two Single Applications"
      docker-compose -f "$BASEDIR/docker-compose-nifi-two-standalone.yml" up -d;

      print_cyan "Waiting NiFi";
      "$BASEDIR/waitHttp.sh" 10 http://localhost:8080/nifi
      "$BASEDIR/waitHttp.sh" 10 http://localhost:8089/nifi
  fi
}

#
# Function responsible to set-up only the Services
#
function setup-services
{
  print_cyan "Starting all Services of the Apache NiFi Environment"
  docker-compose -f "$BASEDIR/docker-compose-services.yml" up -d;
}

#
# Function responsible to set-up only Monitoring Env
#
function setup-monitoring
{
  CLUSTER=$(getClusterArgumentValue "$@");
  if [[ "$CLUSTER" == 0 ]] ; then
    #https://github.com/juliofalbo/docker-compose-prometheus-service-discovery
    "$HOME/workspace/docker-compose-prometheus-service-discovery/docker-prmt-serv-disc.sh" start -f "/Users/jfa/workspace/nifi-workshop/docker-prometheus-sd.yml"
    #Remember to run the Docker Compose Prometheus Service Discovery (https://github.com/juliofalbo/docker-compose-prometheus-service-discovery)
    "$BASEDIR/waitFile.sh" 1 "$BASEDIR/targets.json" 'targets'
  fi

  docker-compose -f "$BASEDIR/docker-compose-monitoring.yml" up -d;
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

        all)
            setup-all "$@"
            exit 0
        ;;

        nifi          \
        | cluster-env \
        | monitoring)
            shift
            "setup-$argument" "$@"
        ;;

    esac
done

exit 0