#!/usr/bin/env bash

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

cd "$BASEDIR/CustomService" || exit;

mvn clean install

cp "$BASEDIR/CustomService/nifi-customservice-nar/target/nifi-customservice-nar-1.0.nar" "$BASEDIR/../../libs"