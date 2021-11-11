#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

source /etc/ces/functions.sh

IP_HAS_CHANGED=false

function valid_ip()
{
  local  ip=$1
  local  stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
      OIFS=$IFS
      IFS='.'
      ip=($ip)
      IFS=$OIFS
      [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
          && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
      stat=$?
  fi
  return $stat
}

function exitCodeForFqdnRequest(){
  etcdctl --peers //"$(cat /etc/ces/node_master)":4001 get /config/_global/fqdn > /dev/null; echo $?
}

function get_ip_of_default_gateway() {
    ip -4 addr show "$(ip -4 route list 0/0 | awk '{print $5}')" | grep inet | awk '{print $2}' | awk -F'/' '{print $1}'
}

function write_node_master_file() {
  NODE_MASTER_IP=$(get_ip)
  TYPE=$(get_type)
  if [ "${TYPE}" = "azure" ]; then
    # azure has an external IP which does not work for node_master
    NODE_MASTER_IP=$(get_ip_of_default_gateway)
  fi
  echo "${NODE_MASTER_IP}" > /etc/ces/node_master
}

function reinstallCertificate() {
    local CERT_TYPE=$1
    local CERT_SCRIPT=$2

    if [ "$CERT_TYPE" == "selfsigned" ]; then
        echo "$(date +%T): certificate type is selfsigned"
        source /etc/environment;
        if [ "$(cat /etc/ces/type)" == "vagrant" ]; then
            end=$((SECONDS+20)) # wait for max. 20 seconds
            while [ ! -f "${CERT_SCRIPT}" ] && [ $SECONDS -lt $end ]
            do
                sleep 0.25
                echo "$(date +%T): waiting for ${CERT_SCRIPT} to become available..."
            done
        fi
        if [ -f "${CERT_SCRIPT}" ]; then
            eval "${CERT_SCRIPT}"
        else
            echo "$(date +%T): ${CERT_SCRIPT} does not exist"
        fi
    else
        echo "$(date +%T): certificate type is not selfsigned"
    fi
}

function checkIPChange(){
  CURRIP=$(get_ip)
  write_node_master_file
  if ! etcdctl cluster-health; then
    systemctl restart etcd
  fi

  # check if global fqdn key exists
  # this will not be the case if setup has not been performed yet
  FQDN_EXIT_CODE=$(exitCodeForFqdnRequest)
  while [ "${FQDN_EXIT_CODE}" -ne 0 ]; do
    echo "etcd /config/_global/fqdn key unavailable, trying again..."
    sleep 5
    FQDN_EXIT_CODE=$(exitCodeForFqdnRequest)
  done

  end=$((SECONDS+20)) # wait for max. 20 seconds
  LASTIP=$(etcdctl --peers //"$(cat /etc/ces/node_master)":4001 get /config/_global/fqdn)
  while [ $SECONDS -lt $end ] && [ -z $LASTIP ]; do
    echo "$(date +%T): etcd unavailable, trying again..."
    sleep 0.25
    LASTIP=$(etcdctl --peers //"$(cat /etc/ces/node_master)":4001 get /config/_global/fqdn)
    CURRIP=$(get_ip)
    write_node_master_file
  done

  # Check if system has got a new IP after reboot
  # or last IP was empty or not an IP
  if [ "${LASTIP}" != "${CURRIP}" ] && [ ! -z $LASTIP ] && valid_ip ${LASTIP}; then
    echo "$(date +%T): IP has changed from >${LASTIP}< to >${CURRIP}<"
    # IP changed
    if [ ! -z ${CURRIP} ] && valid_ip ${CURRIP} ; then
      IP_HAS_CHANGED=true
      echo "$(date +%T): ${CURRIP} is a valid IP; setting fqdn"
      etcdctl --peers //"$(cat /etc/ces/node_master)":4001 set "/config/_global/fqdn" "${CURRIP}"
      ETCDCTL_EXIT=$?
      end=$((SECONDS+20)) # wait for max. 20 seconds
      while [ "${ETCDCTL_EXIT}" -ne "0" ] && [ $SECONDS -lt $end ]; do # etcd is not ready yet
        echo "$(date +%T): Redo setting fqdn"
        etcdctl --peers //"$(cat /etc/ces/node_master)":4001 set "/config/_global/fqdn" "${CURRIP}"
        ETCDCTL_EXIT=$?
        sleep 0.25
      done
      # Reinstall certificates if self-signed
      CERT_TYPE_CES=$(etcdctl --peers //"$(cat /etc/ces/node_master)":4001 get /config/_global/certificate/type)
      reinstallCertificate "${CERT_TYPE_CES}" "/usr/local/bin/ssl_ces.sh"
      # Reinstall cesappd certificate
      CERT_CESAPPD_EXIT_CODE=$(etcdctl --peers "//$(cat /etc/ces/node_master):4001" ls /config/_global/certificate/cesappd/ > /dev/null || echo $?)
      if [[ "${CERT_CESAPPD_EXIT_CODE}" -eq 0 ]]; then
        echo "generate certificate for cesappd"
        CERT_TYPE_CESAPPD=$(etcdctl --peers //"$(cat /etc/ces/node_master)":4001 get /config/_global/certificate/cesappd/type)
        reinstallCertificate "${CERT_TYPE_CES}" "/usr/local/bin/ssl_cesappd.sh"
      fi
    else
      echo "$(date +%T): ${CURRIP} is no valid IP!"
    fi
  else
    echo "$(date +%T): IP has not changed or last IP (${LASTIP}) is empty or not an IP. Current IP = $CURRIP"
  fi
}

# Check for new IP
# Repeat for 15 seconds in case the DHCP needs more time
LOOP_END=$((SECONDS+15))
while [ $SECONDS -lt ${LOOP_END} ]; do
  checkIPChange
  if [ ${IP_HAS_CHANGED} = true ]; then
    # Restart all dogus so they won't use the old IP any more
    docker restart $(docker ps -q)
    break;
  fi
  sleep 1
done
