#!/bin/bash
source /etc/ces/functions.sh

# enable strict mode
set -eo pipefail

source /usr/local/bin/ssl.sh

echo "writing certificate to etcd"
etcdctl --peers "//$(cat /etc/ces/node_master):4001" set /config/_global/certificate/type selfsigned > /dev/null
cat "${CERTIFICATE}" | etcdctl --peers "//$(cat /etc/ces/node_master):4001" set /config/_global/certificate/server.crt > /dev/null
cat "${KEY}" | etcdctl --peers "//$(cat /etc/ces/node_master):4001" set /config/_global/certificate/server.key > /dev/null

echo "adding ces self signed certificate to certificate authority"
etcdctl get /config/_global/certificate/server.crt > /etc/ssl/certs/ces-self-signed.crt

echo "removing temporary files"
rm -rf "${SSL_DIR}"
