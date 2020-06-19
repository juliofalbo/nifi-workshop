#!/usr/bin/env bash

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

REMOVEVOLUMES=$1;

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

print_error "Stopping the complete NiFi Environment";

#https://github.com/juliofalbo/docker-compose-prometheus-service-discovery
"$HOME/workspace/docker-compose-prometheus-service-discovery/docker-prmt-serv-disc.sh" stop

if [[ "$REMOVEVOLUMES" = '-v' ]]
then
    print_error "Removing all Volumes (you will lose your data)";
    docker-compose -f "$BASEDIR/docker-compose-monitoring.yml" down -v;
    docker-compose -f "$BASEDIR/docker-compose-services.yml" down -v;
    docker-compose -f "$BASEDIR/docker-compose-nifi-cluster.yml" down -v;
    docker-compose -f "$BASEDIR/docker-compose-nifi-two-standalone.yml" down -v;
    docker-compose -f "$BASEDIR/docker-compose-nifi-cluster-env.yml" down -v;
else
    print_error "Removing all containers keeping the volumes";
    docker-compose -f "$BASEDIR/docker-compose-monitoring.yml" down;
    docker-compose -f "$BASEDIR/docker-compose-services.yml" down;
    docker-compose -f "$BASEDIR/docker-compose-nifi-cluster.yml" down;
    docker-compose -f "$BASEDIR/docker-compose-nifi-two-standalone.yml" down;
    docker-compose -f "$BASEDIR/docker-compose-nifi-cluster-env.yml" down;
fi
