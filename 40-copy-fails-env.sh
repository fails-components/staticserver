#!/bin/bash

if [[ -n "${FAILS_APP_CONFIG_JSON}" ]]; then
  echo ${FAILS_APP_CONFIG_JSON} > /usr/share/nginx/html/config/app.json
  chmod gou+r /usr/share/nginx/html/config/app.json
fi
if [[ -n "${FAILS_APP_CONFIG_JSON}" ]]; then
  echo ${FAILS_JUPYTER_PROXY_CONFIG} > /usr/share/nginx/html/config/proxy.json
  chmod gou+r /usr/share/nginx/html/config/proxy.json
fi
