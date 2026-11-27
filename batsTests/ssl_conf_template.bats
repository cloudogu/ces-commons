#!/usr/bin/env bash
# Bind an unbound BATS variable that fails all tests when combined with 'set -o nounset'
export BATS_TEST_START_TIME="0"

load '/workspace/target/bats_libs/bats-support/load.bash'
load '/workspace/target/bats_libs/bats-assert/load.bash'

setup() {
  export STARTUP_DIR=/workspace
  source "${STARTUP_DIR}/deb/etc/ces/functions.sh"

  TEMPLATE="${STARTUP_DIR}/deb/etc/ces/ssl.conf.tpl"
  # used by the template for the subject alternative names
  FQDN="a-very-long-label-to-exceed-the-sixty-four-characters-of-the-cn.ces.example.com"
}

@test "ssl.conf.tpl renders the CN if it is set (CA certificate)" {
  CN="CES Self Signed"

  run render_template "${TEMPLATE}"

  assert_success
  assert_line "CN = CES Self Signed"
}

@test "ssl.conf.tpl renders no CN if it is empty (server certificate)" {
  CN=""

  run render_template "${TEMPLATE}"

  assert_success
  refute_line --regexp "^CN ?="
  assert_line "DNS.1 = ${FQDN}"
}

@test "ssl.conf.tpl does not require a CN in the signing policy policy_anything" {
  run bash -c "render_template '${TEMPLATE}' | sed -n '/^\[ policy_anything \]/,/^\[/p'"

  assert_success
  assert_line --regexp "^commonName[[:space:]]+= optional$"
}
