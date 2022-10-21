#!/bin/bash
# enable strict mode
set -eo pipefail

source /usr/local/bin/ssl.sh 365

echo "writing certificate to etcd"
etcdctl --peers "//localhost:4001" set /config/_global/certificate/type selfsigned > /dev/null
cat "${CERTIFICATE}" | etcdctl --peers "//localhost:4001" set /config/_global/certificate/server.crt > /dev/null
cat "${KEY}" | etcdctl --peers "//localhost:4001" set /config/_global/certificate/server.key > /dev/null

echo "adding ces self signed certificate to certificate authority"
etcdctl get /config/_global/certificate/server.crt > /etc/ssl/certs/ces-self-signed.crt

echo "removing temporary files"
rm -rf "${SSL_DIR}"
