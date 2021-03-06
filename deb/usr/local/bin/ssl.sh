#!/bin/bash
source /etc/ces/functions.sh

# enable strict mode
set -eo pipefail
IFS=$'\n\t'

source /etc/environment
export PATH

# variables
DOMAIN=$(get_domain)
FQDN=$(get_fqdn)
IPS=$(get_ips)
PRIMARY_IP=$(get_ip)

echo "check if one of the ips matches fqdn and use it as primary if so"
for IP in $IPS; do
  if [ "${IP}" == "${FQDN}" ]; then
    PRIMARY_IP="${IP}"
  fi
done

echo "create self sigined certificate for fqdn ${FQDN} and primary ip ${PRIMARY_IP}"

echo "creating temporary directory"
SSL_DIR=$(mktemp)
rm -f "${SSL_DIR}"
mkdir -p "${SSL_DIR}"

echo "creating variables"
SSL_CONF="${SSL_DIR}/openssl.conf"
CERTIFICATE="${SSL_DIR}/server.crt"
KEY="${SSL_DIR}/server.key"
CAKEY="${SSL_DIR}/ca.key"
CA="${SSL_DIR}/ca.pem"
CSR="${SSL_DIR}/server.csr"
SIGNED="${SSL_DIR}/server.signed"
CA_DIR="${SSL_DIR}/ca"

CN="CES Self Signed"

function render_openssl_config() {
  echo "render template for ssl configuration"
  render_template "/etc/ces/ssl.conf.tpl" > "${SSL_CONF}"

  # if fqdn is an ip add alternative name
  if [[ $FQDN =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "IP = ${FQDN}" >> "${SSL_CONF}"
  fi
}

render_openssl_config

echo "creating passphrase"
PASSPHRASE=$(hexdump -n 8 -e '4/4 "%08X" 1 "\n"' /dev/urandom)

echo "creating ca key"
openssl genrsa -aes256 -passout pass:${PASSPHRASE} -out "${CAKEY}" 2048 2>/dev/null

echo "creating ca"
openssl req -x509 -new -passin pass:${PASSPHRASE} -extensions v3_ca -key "${CAKEY}" -days 3650 -out "${CA}" -sha512 -config "${SSL_CONF}" 2>/dev/null

echo "rerendering ssl configuration to change CN"
CN="${FQDN}"
render_openssl_config

echo "creating server key, request and certificate"
openssl genrsa -out "${KEY}" 4096 2>/dev/null
openssl req -new -nodes -key "${KEY}" -out "${CSR}" -config "${SSL_CONF}" -sha512 2>/dev/null

echo "creating ca database"
mkdir -p "${CA_DIR}/certs" "${CA_DIR}/newcerts"
touch "${CA_DIR}/index.txt" "${CA_DIR}/.rand"
date +%s > ${CA_DIR}/serial

echo "signing request"
openssl ca -batch -config "${SSL_CONF}" -passin pass:${PASSPHRASE} -policy policy_anything -out "${SIGNED}" -in "${CSR}" 2>/dev/null

echo "extracting certificate"
openssl x509 -in "${SIGNED}" -out "${CERTIFICATE}"

echo "adding ca to certificate"
cat "${CA}" >> "${CERTIFICATE}"

echo "writing certificate to etcd"
etcdctl --peers "//$(cat /etc/ces/node_master):4001" set /config/_global/certificate/type selfsigned > /dev/null
cat "${CERTIFICATE}" | etcdctl --peers "//$(cat /etc/ces/node_master):4001" set /config/_global/certificate/server.crt > /dev/null
cat "${KEY}" | etcdctl --peers "//$(cat /etc/ces/node_master):4001" set /config/_global/certificate/server.key > /dev/null

echo "adding ces self signed certificate to certificate authority"
etcdctl get /config/_global/certificate/server.crt > /etc/ssl/certs/ces-self-signed.crt

echo "removing temporary files"
rm -rf "${SSL_DIR}"
