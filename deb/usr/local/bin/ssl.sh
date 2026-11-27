#!/bin/bash
source /etc/ces/functions.sh
# enable strict mode
set -eo pipefail

storedIFS="${IFS}"
IFS=$'\n\t'

source /etc/environment
export PATH

# variables
# shellcheck disable=SC2034
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
SSL_DIR=$(mktemp -d)

echo "creating variables"
DAYS=$1
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

  # delete unused definition from randfile to avoid error messages signing the request
  sed -i "/ ::HOME/d" "${SSL_CONF}"

  # if fqdn is an ip add alternative name
  if [[ $FQDN =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "IP = ${FQDN}" >> "${SSL_CONF}"
  fi
}

# runs openssl quietly but prints its error output if the command fails
function run_openssl() {
  local output
  if ! output=$(openssl "$@" 2>&1); then
    echo "ERROR: openssl $1 failed:" >&2
    echo "${output}" >&2
    return 1
  fi
}

render_openssl_config

echo "creating passphrase"
PASSPHRASE=$(hexdump -n 8 -e '4/4 "%08X" 1 "\n"' /dev/urandom)

echo "creating ca key"
run_openssl genrsa -aes256 -passout pass:"${PASSPHRASE}" -out "${CAKEY}" 2048

echo "creating ca"
run_openssl req -x509 -new -passin pass:"${PASSPHRASE}" -extensions v3_ca -key "${CAKEY}" -days 24855 -out "${CA}" -sha512 -config "${SSL_CONF}"

echo "rerendering ssl configuration without CN"
# the server certificate has no CN, because the CN is limited to 64 characters and deprecated for hostname
# verification. The FQDN is contained in the subject alternative names instead.
# shellcheck disable=SC2034
CN=""
render_openssl_config

echo "creating server key, request and certificate"
run_openssl genrsa -out "${KEY}" 4096
run_openssl req -new -nodes -key "${KEY}" -out "${CSR}" -config "${SSL_CONF}" -sha512

echo "creating ca database"
mkdir -p "${CA_DIR}/certs" "${CA_DIR}/newcerts"
touch "${CA_DIR}/index.txt" "${CA_DIR}/.rand"
date +%s > "${CA_DIR}"/serial

echo "signing request"

if [[ "${DAYS}" == "" ]]; then
    # if days are not set use default value
    DAYS=365
fi

run_openssl ca -batch -config "${SSL_CONF}" -passin pass:"${PASSPHRASE}" -policy policy_anything -out "${SIGNED}" -in "${CSR}" -days "${DAYS}"

echo "extracting certificate"
openssl x509 -in "${SIGNED}" -out "${CERTIFICATE}"

echo "adding ca to certificate"
touch "${CERTIFICATE}"
cat "${CA}" >> "${CERTIFICATE}"

IFS="${storedIFS}"