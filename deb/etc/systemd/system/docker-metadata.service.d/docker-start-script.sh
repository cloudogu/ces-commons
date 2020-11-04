#!/bin/bash

TARGET_FILE=/etc/systemd/system/docker-metadata.service.d/docker-metadata-environment

function get_enabled(){
  etcdctl get config/_global/proxy/enabled || echo "false"
}

if [ "$(get_enabled)" == "true" ]
then
  echo "collecting https proxy config steps..."
  HOST="$(etcdctl get config/_global/proxy/server)" || (echo "ERROR: Could not read from etcd: proxy host" && exit 0)
  PORT="$(etcdctl get config/_global/proxy/port)" || (echo "ERROR: Could not read from etcd: proxy port" && exit 0)
  USERNAME="$(etcdctl get config/_global/proxy/username)" || echo "WARNING: Could not read from etcd: proxy username"
  PASSWORD="$(etcdctl get config/_global/proxy/password)" || echo "WARNING: Could not read from etcd: proxy password"
  NO_PROXY="NO_PROXY=$(etcdctl get config/_global/proxy/no_proxy)" || echo "WARNING: Could not read from etcd: proxy no_proxy"
  AUTH=""
  if [ "${USERNAME}" != "" ] && [ "${USERNAME}" != "" ]
  then
    AUTH="${USERNAME}:${PASSWORD}@"
  else
    echo "No username and password for proxy configured."
  fi

  HTTP_URL="http://${AUTH}${HOST}:${PORT}"
  HTTPS_URL="https://${AUTH}${HOST}:${PORT}"

  curl "${HTTP_URL}"
  SUPPORTS_HTTP=$?
  curl "${HTTPS_URL}"
  SUPPORTS_HTTPS=$?

  if [ "${SUPPORTS_HTTP}" != "0" ] && [ "${SUPPORTS_HTTPS}" != "0" ]
  then
    echo "The configured proxy was unreachable..."
    exit 1
  fi

  HTTP_CONFIG="HTTP_PROXY=${HTTP_URL}"
  HTTPS_CONFIG="HTTPS_PROXY=${HTTP_URL}"

  if [ "${SUPPORTS_HTTP}" != "0" ]
  then
      HTTP_CONFIG="HTTP_PROXY=${HTTPS_URL}"
  fi

  if [ "${SUPPORTS_HTTPS}" == "0" ]
  then
    HTTPS_CONFIG="HTTPS_PROXY=${HTTPS_URL}"
  fi

  {
    echo "${HTTPS_CONFIG}"
    echo "${HTTP_CONFIG}"
    echo "${NO_PROXY}"
  } > "${TARGET_FILE}"
else
  # Clear environment file
  echo "" > "${TARGET_FILE}"
fi


