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
    "  all             ./nifi-env-cli stop all        - It will stop the whole env"
    "  nifi            ./nifi-env-cli stop nifi       - It will stop only NiFi"
    "  allservices     ./nifi-env-cli stop allservices    - It will stop services for the Apache NiFi environment"
    "  mongo           ./nifi-env-cli stop mongo    - It will stop MongoDB Environment"
    "  kafka           ./nifi-env-cli stop kafka    - It will stop Apache Kafka environment"
    "  solr            ./nifi-env-cli stop solr    - It will stop Apache Solr"
    "  splunk          ./nifi-env-cli stop splunk    - It will stop Splunk"
    "  rabbitmq        ./nifi-env-cli stop rabbitmq    - It will stop RabbitMQ"
    "  registry        ./nifi-env-cli stop registry    - It will stop NiFi Registry"
    "  postgres        ./nifi-env-cli stop postgres    - It will stop Postgres"
    "  monitoring      ./nifi-env-cli stop monitoring - It will stop only Grafana and Prometheus"
    "- Note: You can combine commands like: ./nifi-env-cli stop nifi kafka monitoring"
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
  stop-allservices "$@"
  stop-monitoring "$@"
  stop-nifi "$@"
  stop-allservices "$@"
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
function stop-allservices() {
  #https://github.com/juliofalbo/docker-compose-prometheus-service-discovery
    "$HOME/workspace/docker-compose-prometheus-service-discovery/docker-prmt-serv-disc.sh" start -f "/Users/jfa/workspace/nifi-workshop/docker-prometheus-sd.yml"

  stop-kafka "$@"
  stop-mongo "$@"
  stop-registry "$@"
  stop-splunk "$@"
  stop-solr "$@"
  stop-rabbitmq "$@"
  stop-postgres "$@"
  echo
}

#
# Function responsible to stop Kafka Environment
#
function stop-kafka() {
  REMOVE_VOLUME=$(getRemoveVolumeArgumentValue "$@")
  if [ "$REMOVE_VOLUME" == 0 ]; then
    print_red "Stopping Kafka Environment removing volumes"
    docker-compose -f "$BASEDIR/docker-compose-kafka.yml" down -v
  else
    print_red "Stopping Kafka Environment keeping volumes"
    docker-compose -f "$BASEDIR/docker-compose-kafka.yml" down
  fi

  print_green "Kafka Environment stopped"
  echo
}

#
# Function responsible to stop MongoDB Environment
#
function stop-mongo() {
  REMOVE_VOLUME=$(getRemoveVolumeArgumentValue "$@")
  if [ "$REMOVE_VOLUME" == 0 ]; then
    print_red "Stopping MongoDB Environment removing volumes"
    docker-compose -f "$BASEDIR/docker-compose-mongo.yml" down -v
  else
    print_red "Stopping MongoDB Environment keeping volumes"
    docker-compose -f "$BASEDIR/docker-compose-mongo.yml" down
  fi

  print_green "MongoDB Environment stopped"
  echo

}


#
# Function responsible to stop NiFi Registry
#
function stop-registry() {
  REMOVE_VOLUME=$(getRemoveVolumeArgumentValue "$@")
  if [ "$REMOVE_VOLUME" == 0 ]; then
    print_red "Stopping NiFi Registry removing volumes"
    docker-compose -f "$BASEDIR/docker-compose-nifi-registry.yml" down -v
  else
    print_red "Stopping NiFi Registry keeping volumes"
    docker-compose -f "$BASEDIR/docker-compose-nifi-registry.yml" down
  fi

  print_green "NiFi Registry stopped"
  echo

}

#
# Function responsible to stop Postgres
#
function stop-postgres() {
  REMOVE_VOLUME=$(getRemoveVolumeArgumentValue "$@")
  if [ "$REMOVE_VOLUME" == 0 ]; then
    print_red "Stopping Postgres removing volumes"
    docker-compose -f "$BASEDIR/docker-compose-postgres.yml" down -v
  else
    print_red "Stopping Postgres keeping volumes"
    docker-compose -f "$BASEDIR/docker-compose-postgres.yml" down
  fi

  print_green "Postgres stopped"
  echo

}

#
# Function responsible to stop RabbitMQ
#
function stop-rabbitmq() {
  REMOVE_VOLUME=$(getRemoveVolumeArgumentValue "$@")
  if [ "$REMOVE_VOLUME" == 0 ]; then
    print_red "Stopping RabbitMQ removing volumes"
    docker-compose -f "$BASEDIR/docker-compose-rabbitmq.yml" down -v
  else
    print_red "Stopping RabbitMQ keeping volumes"
    docker-compose -f "$BASEDIR/docker-compose-rabbitmq.yml" down
  fi

  print_green "RabbitMQ stopped"
  echo

}

#
# Function responsible to stop Apache Solr
#
function stop-solr() {
  REMOVE_VOLUME=$(getRemoveVolumeArgumentValue "$@")
  if [ "$REMOVE_VOLUME" == 0 ]; then
    print_red "Stopping Apache Solr removing volumes"
    docker-compose -f "$BASEDIR/docker-compose-solr.yml" down -v
  else
    print_red "Stopping Apache Solr keeping volumes"
    docker-compose -f "$BASEDIR/docker-compose-solr.yml" down
  fi

  print_green "Apache Solr stopped"
  echo

}

#
# Function responsible to stop Splunk
#
function stop-splunk() {
  REMOVE_VOLUME=$(getRemoveVolumeArgumentValue "$@")
  if [ "$REMOVE_VOLUME" == 0 ]; then
    print_red "Stopping Splunk removing volumes"
    docker-compose -f "$BASEDIR/docker-compose-splunk.yml" down -v
  else
    print_red "Stopping Splunk keeping volumes"
    docker-compose -f "$BASEDIR/docker-compose-splunk.yml" down
  fi

  print_green "Splunk stopped"
  echo

}

#
# Function responsible to stop NiFi Zookeeper and Nginx
#
function stop-clusterenv() {
  REMOVE_VOLUME=$(getRemoveVolumeArgumentValue "$@")
  if [ "$REMOVE_VOLUME" == 0 ]; then
    print_red "Stopping NiFi Zookeeper and Nginx removing volumes"
    docker-compose -f "$BASEDIR/docker-compose-nifi-cluster-env.yml" down -v
  else
    print_red "Stopping NiFi Zookeeper and Nginx keeping volumes"
    docker-compose -f "$BASEDIR/docker-compose-nifi-cluster-env.yml" down
  fi

  print_green "NiFi Zookeeper and Nginx stopped"
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
# Method responsible to check if the volumes should be removed
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
  | allservices \
  | splunk \
  | solr \
  | kafka \
  | rabbitmq \
  | postgres \
  | registry \
  | mongo \
  | monitoring)
    shift
    "stop-$argument" "$@"
    ;;

  esac
done

exit 0
