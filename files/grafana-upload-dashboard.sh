#!/bin/bash

. ./grafana-lib.sh

for f in "$@"; do
  grafana_upload_dashboard "$f"
done
