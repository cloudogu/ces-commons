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

function checkIPChange(){
  CURRIP=$(get_ip)
  echo ${CURRIP} > /etc/ces/node_master
  if ! etcdctl cluster-health; then
    systemctl restart etcd
  fi
  end=$((SECONDS+20)) # wait for max. 20 seconds
  LASTIP=$(etcdctl --peers //${CURRIP}:4001 get /config/_global/fqdn)
  while [ $SECONDS -lt $end ] && [ -z $LASTIP ]; do
    echo "$(date +%T): etcd unavailable, trying again..."
    sleep 0.25
    LASTIP=$(etcdctl --peers //${CURRIP}:4001 get /config/_global/fqdn)
    CURRIP=$(get_ip)
    echo ${CURRIP} > /etc/ces/node_master
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
      CERT_TYPE=$(etcdctl --peers //"$(cat /etc/ces/node_master)":4001 get /config/_global/certificate/type)
      if [ "$CERT_TYPE" == "selfsigned" ]; then
        echo "$(date +%T): certificate type is selfsigned"
        source /etc/environment;
        if [ "$(cat /etc/ces/type)" == "vagrant" ]; then
          end=$((SECONDS+20)) # wait for max. 20 seconds
          while [ ! -f /usr/local/bin/ssl.sh ] && [ $SECONDS -lt $end ]
          do
            sleep 0.25
            echo "$(date +%T): waiting for /usr/local/bin/ssl.sh to become available..."
          done
        fi
        if [ -f /usr/local/bin/ssl.sh ]; then
          /usr/local/bin/ssl.sh
        else
          echo "$(date +%T): /usr/local/bin/ssl.sh does not exist"
        fi
      else
        echo "$(date +%T): certificate type is not selfsigned"
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
