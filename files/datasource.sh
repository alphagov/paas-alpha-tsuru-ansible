#!/bin/bash

COOKIEJAR=$(mktemp)
trap 'unlink ${COOKIEJAR}' EXIT

function grafana_has_data_source {
  setup_grafana_session
  curl --silent --cookie "$COOKIEJAR" "$(grafana_url)datasources" \
    | grep "{\"name\":\"${1}\"}" --silent
}

function influxfb_remote_url {
  echo -e "http://localhost:8086/"
}

function grafana_url {
  echo -e http://localhost:3000/api/
}
 
# Used for this script to talk to the InfluxDB API
function influxfb_local_url {
  echo -e "http://localhost:8086/"
}


function setup_grafana_session {
  if ! curl -H 'Content-Type: application/json;charset=UTF-8' \
    --data-binary '{"user":"admin","email":"","password":"admin"}' \
    --cookie-jar "$COOKIEJAR" \
    'http://localhost:3000/login' > /dev/null 2>&1 ; then
    echo
    error "Grafana Session: Couldn't store cookies at ${COOKIEJAR}"
  fi
}
function grafana_create_data_source {
  setup_grafana_session
  curl --cookie "$COOKIEJAR" \
       -X PUT \
       --silent \
       -H 'Content-Type: application/json;charset=UTF-8' \
       --data-binary "{\"name\":\"${1}\",\"type\":\"influxdb\",\"url\":\"$(influxfb_remote_url)\",\"access\":\"proxy\",\"IsDefault\":true,\"database\":\"${1}\",\"user\":\"${1}\",\"password\":\"${1}\"}" \
       "$(grafana_url)datasources" 2>&1 | grep 'Datasource added' --silent;
}

function setup_grafana {
  if grafana_has_data_source "$1"; then
    info "Grafana: Data source ${1} already exists"
  else
    if grafana_create_data_source "$1"; then
      success "Grafana: Data source ${1} created"
    else
      error "Grafana: Data source ${1} could not be created"
    fi
  fi
}
 
function success {
  echo "$(tput setaf 2)""$*""$(tput sgr0)"
}
 
function info {
  echo "$(tput setaf 3)""$*""$(tput sgr0)"
}
 
function error {
  echo "$(tput setaf 1)""$*""$(tput sgr0)" 1>&2
}
 
function setup {
  setup_grafana "$1"
}

setup $1
