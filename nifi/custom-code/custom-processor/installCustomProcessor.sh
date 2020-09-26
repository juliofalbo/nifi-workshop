#!/usr/bin/env bash

BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

cd "$BASEDIR/CustomProcessor" || exit;

mvn clean install

cp "$BASEDIR/CustomProcessor/nifi-custom-nar/target/nifi-custom-nar-1.0.nar" "$BASEDIR/../../libs"