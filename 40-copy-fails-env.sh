#!/bin/bash

if [[ -n "${FAILS_APP_CONFIG_JSON}" ]]; then
  echo ${FAILS_APP_CONFIG_JSON} > /usr/share/nginx/html/config/app.json
fi
