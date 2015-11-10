#!/bin/bash

# Used for this script to talk to the Grafana API
GRAFANA_URL=http://localhost:3000
COOKIEJAR="/tmp/grafana_session_$$"

function grafana_url {
  echo -e ${GRAFANA_URL}/api/
}

function success {
  echo "$(tput setaf 2)""$*""$(tput sgr0)"
}

function info {
  echo "$(tput setaf 3)""$*""$(tput sgr0)"
}

function error {
  echo "$(tput setaf 1)""$*""$(tput sgr0)" 1>&2
  exit 1
}

function setup_grafana_session {
  username=${1-admin}; shift
  password=${1-admin}; shift
  if ! curl -H 'Content-Type: application/json;charset=UTF-8' \
    --data-binary "{\"user\":\"$username\",\"email\":\"\",\"password\":\"$password\"}" \
    --cookie-jar "$COOKIEJAR" \
    "${GRAFANA_URL}/login" > /dev/null 2>&1 ; then
    echo
    error "Grafana Session: Couldn't store cookies at ${COOKIEJAR}"
  fi
}

function grafana_has_data_source {
  setup_grafana_session
  curl --silent --cookie "$COOKIEJAR" "${GRAFANA_URL}/api/datasources" \
    | grep "\"name\":\"${1}\"" --silent
}

function grafana_create_data_source {
  name=$1; shift
  type=$1; shift
  url=$1; shift
  user=$1; shift
  password=$1; shift
  database=$1; shift

  setup_grafana_session
  curl --cookie "$COOKIEJAR" \
       -X POST \
       --silent \
       -H 'Content-Type: application/json;charset=UTF-8' \
       --data-binary "{\"name\":\"${name}\",\"type\":\"${type}\",\"url\":\"${url}\",\"access\":\"proxy\",\"database\":\"${database}\",\"user\":\"${user}\",\"password\":\"${password}\"}" \
       "${GRAFANA_URL}/api/datasources" 2>&1 | grep 'Datasource added' --silent;
}

function grafana_upload_dashboard {
  file=$1; shift

  setup_grafana_session
  curl --cookie "$COOKIEJAR" \
       -X POST \
       --silent \
       -H 'Content-Type: application/json;charset=UTF-8' \
       -d "{\"overwrite\": true, \"dashboard\": $(sed '0,/RE/s/"id":.*$//'  "$file")}" \
       "${GRAFANA_URL}/api/dashboards/db" 2>&1
}
