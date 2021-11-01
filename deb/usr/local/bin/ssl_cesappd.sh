#!/bin/bash
source /etc/ces/functions.sh

# enable strict mode
set -eo pipefail

source /usr/local/bin/ssl.sh

KEY_DIR="/etc/ces/cesappd"
KEY_FILE="${KEY_DIR}/server.key"

echo "writing certificate to etcd"
etcdctl --peers "//$(cat /etc/ces/node_master):4001" set /config/_global/certificate/cesappd/type selfsigned > /dev/null
etcdctl --peers "//$(cat /etc/ces/node_master):4001" set /config/_global/certificate/cesappd/server.crt < "${CERTIFICATE}" > /dev/null
etcdctl --peers "//$(cat /etc/ces/node_master):4001" set /config/_global/certificate/cesappd/ca.pem < "${CA}" > /dev/null
mkdir -p "${KEY_DIR}"
cat "${KEY}" > "${KEY_FILE}"

chown root:root "${KEY_FILE}"
chmod 700 "${KEY_FILE}"

echo "removing temporary files"
rm -rf "${SSL_DIR}"

IFS="${storedIFS}"
