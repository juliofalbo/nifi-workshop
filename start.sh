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


print_cyan "Starting the Environment SetUp";
print_cyan "- Grafana";
print_cyan "- Prometheus";
print_cyan "- RabbitMQ";
print_cyan "- Mongo";
print_cyan "- Mongo Express";
print_cyan "- Postgres";
print_cyan "- NiFi";
print_cyan "- Zookeeper";

docker-compose -f "$BASEDIR/docker-compose-services.yml" up -d;

if [[ "$BUILD" = '--cluster' ]] ; then
    print_cyan "Starting NIFI in a Cluster"
    docker-compose -f "$BASEDIR/docker-compose-nifi-cluster-env.yml" up -d;
    INSTANCES_SCALE=$(getScaleArgumentValue "$@");
    docker-compose -f "$BASEDIR/docker-compose-nifi-cluster.yml" up -d --scale nifi="$INSTANCES_SCALE";
else
    print_cyan "Starting NIFI in a Single Node"
    docker-compose -f "$BASEDIR/docker-compose-nifi-two-standalone.yml" up -d;
fi


#https://github.com/juliofalbo/docker-compose-prometheus-service-discovery
"$HOME/workspace/docker-compose-prometheus-service-discovery/docker-prmt-serv-disc.sh" start -f "/Users/jfa/workspace/nifi-workshop/docker-prometheus-sd.yml"

#Remember to run the Docker Compose Prometheus Service Discovery (https://github.com/juliofalbo/docker-compose-prometheus-service-discovery)
"$BASEDIR/waitFile.sh" 1 "$BASEDIR/targets.json" 'targets'

print_cyan "Waiting NiFi";

docker-compose -f "$BASEDIR/docker-compose-monitoring.yml" up -d;

"$BASEDIR/waitHttp.sh" 10 http://localhost:8080/nifi

print_green "All environment is running!";

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
        --scale | -s)
          SCALE_VALUE=("${@:$SCALE_COUNTER+1}");
        ;;
    esac
  done
  echo "${SCALE_VALUE[0]}";
}