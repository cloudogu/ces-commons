#!/usr/bin/env bash
# Bind an unbound BATS variable that fails all tests when combined with 'set -o nounset'
export BATS_TEST_START_TIME="0"

load '/workspace/target/bats_libs/bats-support/load.bash'
load '/workspace/target/bats_libs/bats-assert/load.bash'
load '/workspace/target/bats_libs/bats-mock/load.bash'

setup() {
  export STARTUP_DIR=/workspace

  # bats-mock/mock_create needs to be injected into the path so the production code will find the mock
  etcdctl="$(mock_create)"
  export etcdctl
  ln -s "${etcdctl}" "${BATS_TMPDIR}/etcdctl"

  # put mocked command in front of PATH to avoid calling existing commands
  export PATH="${BATS_TMPDIR}:${PATH}"
}

teardown() {
  rm "${BATS_TMPDIR}/etcdctl"
}

@test "safely_migrate_no_proxy_key skips migrating when no proxy config exists at all" {
  mock_set_status "${etcdctl}" 4 1
  mock_set_output "${etcdctl}" "Error:  100: Key not found (/ignoremelol) [21131]" 1

  source ${STARTUP_DIR}/deb/DEBIAN/postinst

  run safely_migrate_no_proxy_key

  assert_success
  assert_equal "$(mock_get_call_num "${etcdctl}")" "1"
  assert_equal "$(mock_get_call_args "${etcdctl}" "1")" "get /config/_global/proxy"
  assert_line "Check migration of the deprecated no_proxy etcd key..."
  assert_line "There is no proxy configuration altogether. Skipping."
}

@test "safely_migrate_no_proxy_key migrates filled legacy non-proxy key to empty new non-proxy key" {
  mock_set_status "${etcdctl}" 1 1
  mock_set_output "${etcdctl}" "/config/_global/proxy: is a directory" 1
  mock_set_status "${etcdctl}" 4 2
  mock_set_output "${etcdctl}" "Error:  100: Key not found (/ignoremelol) [21131]" 2
  mock_set_status "${etcdctl}" 0 3
  mock_set_output "${etcdctl}" "fqdn.invalid,192.*,192.168.56.123" 3
  mock_set_status "${etcdctl}" 0 4
  mock_set_output "${etcdctl}" "" 4

  source ${STARTUP_DIR}/deb/DEBIAN/postinst

  run safely_migrate_no_proxy_key

  assert_success
  assert_equal "$(mock_get_call_num "${etcdctl}")" "4"
  assert_equal "$(mock_get_call_args "${etcdctl}" "1")" "get /config/_global/proxy"
  assert_equal "$(mock_get_call_args "${etcdctl}" "2")" "get /config/_global/proxy/no_proxy_hosts"
  assert_equal "$(mock_get_call_args "${etcdctl}" "3")" "get /config/_global/proxy/no_proxy"
  assert_equal "$(mock_get_call_args "${etcdctl}" "4")" "set /config/_global/proxy/no_proxy_hosts fqdn.invalid,192.*,192.168.56.123"
  assert_line "Check migration of the deprecated no_proxy etcd key..."
  assert_line "Migrate /config/_global/proxy/no_proxy to /config/_global/proxy/no_proxy_hosts..."
  assert_line "Done."
}

@test "safely_migrate_no_proxy_key migrates filled legacy non-proxy key to non-existing new non-proxy key" {
  mock_set_status "${etcdctl}" 1 1
  mock_set_output "${etcdctl}" "/config/_global/proxy: is a directory" 1
  mock_set_status "${etcdctl}" 4 2
  mock_set_output "${etcdctl}" "Error:  100: Key not found (/ignoremelol) [21131]" 2
  mock_set_status "${etcdctl}" 0 3
  mock_set_output "${etcdctl}" "fqdn.invalid,192.*,192.168.56.123" 3
  mock_set_status "${etcdctl}" 0 4
  mock_set_output "${etcdctl}" "" 4

  source ${STARTUP_DIR}/deb/DEBIAN/postinst

  run safely_migrate_no_proxy_key

  assert_success
  assert_equal "$(mock_get_call_num "${etcdctl}")" "4"
  assert_equal "$(mock_get_call_args "${etcdctl}" "1")" "get /config/_global/proxy"
  assert_equal "$(mock_get_call_args "${etcdctl}" "2")" "get /config/_global/proxy/no_proxy_hosts"
  assert_equal "$(mock_get_call_args "${etcdctl}" "3")" "get /config/_global/proxy/no_proxy"
  assert_equal "$(mock_get_call_args "${etcdctl}" "4")" "set /config/_global/proxy/no_proxy_hosts fqdn.invalid,192.*,192.168.56.123"
  assert_line "Check migration of the deprecated no_proxy etcd key..."
  assert_line "Migrate /config/_global/proxy/no_proxy to /config/_global/proxy/no_proxy_hosts..."
  assert_line "Done."
}


@test "safely_migrate_no_proxy_key fails while migrating filled legacy non-proxy key to non-existing new non-proxy key" {
  mock_set_status "${etcdctl}" 1 1
  mock_set_output "${etcdctl}" "/config/_global/proxy: is a directory" 1
  mock_set_status "${etcdctl}" 4 2
  mock_set_output "${etcdctl}" "Error:  100: Key not found (/ignoremelol) [21131]" 2
  mock_set_status "${etcdctl}" 0 3
  mock_set_output "${etcdctl}" "fqdn.invalid,192.*,192.168.56.123" 3
  mock_set_status "${etcdctl}" 1 4
  mock_set_output "${etcdctl}" "oh no something bad happened" 4

  source ${STARTUP_DIR}/deb/DEBIAN/postinst

  run safely_migrate_no_proxy_key

  assert_success
  assert_equal "$(mock_get_call_num "${etcdctl}")" "4"
  assert_equal "$(mock_get_call_args "${etcdctl}" "1")" "get /config/_global/proxy"
  assert_equal "$(mock_get_call_args "${etcdctl}" "2")" "get /config/_global/proxy/no_proxy_hosts"
  assert_equal "$(mock_get_call_args "${etcdctl}" "3")" "get /config/_global/proxy/no_proxy"
  assert_equal "$(mock_get_call_args "${etcdctl}" "4")" "set /config/_global/proxy/no_proxy_hosts fqdn.invalid,192.*,192.168.56.123"
  assert_line "Check migration of the deprecated no_proxy etcd key..."
  assert_line "Migrate /config/_global/proxy/no_proxy to /config/_global/proxy/no_proxy_hosts..."
  assert_line "Migration /config/_global/proxy/no_proxy to /config/_global/proxy/no_proxy_hosts failed with exit code 1. Continuing anyway."
  assert_line "Done."
}

@test "safely_migrate_no_proxy_key skips migrating because of filled new non proxy key" {
  mock_set_status "${etcdctl}" 1 1
  mock_set_output "${etcdctl}" "/config/_global/proxy: is a directory" 1
  mock_set_status "${etcdctl}" 0 2
  mock_set_output "${etcdctl}" "fqdn.invalid,192.*,192.168.56.123" 2

  source ${STARTUP_DIR}/deb/DEBIAN/postinst

  run safely_migrate_no_proxy_key

  # never fail the maintainer script
  assert_success

  assert_equal "$(mock_get_call_num "${etcdctl}")" "2"
  assert_equal "$(mock_get_call_args "${etcdctl}" "1")" "get /config/_global/proxy"
  assert_equal "$(mock_get_call_args "${etcdctl}" "2")" "get /config/_global/proxy/no_proxy_hosts"
  assert_line "There already exists a value at /config/_global/proxy/no_proxy_hosts already: 'fqdn.invalid,192.*,192.168.56.123'. Skipping migration."
}

@test "safely_migrate_no_proxy_key skips migrating because of there is no old value to migrate from (but there exist other proxy keys)" {
  mock_set_status "${etcdctl}" 1 1
  mock_set_output "${etcdctl}" "/config/_global/proxy: is a directory" 1
  mock_set_status "${etcdctl}" 4 2
  mock_set_output "${etcdctl}" "Error:  100: Key not found (/config/_global/proxy/no_proxy_host) [21139]" 2
  mock_set_status "${etcdctl}" 4 3
  mock_set_output "${etcdctl}" "Error:  100: Key not found (/config/_global/proxy/no_proxy) [21131]" 3

  source ${STARTUP_DIR}/deb/DEBIAN/postinst

  run safely_migrate_no_proxy_key

  # never fail the maintainer script
  assert_success

  assert_equal "$(mock_get_call_num "${etcdctl}")" "3"
  assert_equal "$(mock_get_call_args "${etcdctl}" "1")" "get /config/_global/proxy"
  assert_equal "$(mock_get_call_args "${etcdctl}" "2")" "get /config/_global/proxy/no_proxy_hosts"
  assert_equal "$(mock_get_call_args "${etcdctl}" "3")" "get /config/_global/proxy/no_proxy"
  assert_line "There doesn't exist a no-proxy value to migrate. Skipping migration."
}

@test "safely_migrate_no_proxy_key skips migrating because of error on fetching target key" {
  mock_set_status "${etcdctl}" 1 1
  mock_set_output "${etcdctl}" "/config/_global/proxy: is a directory" 1
  mock_set_status "${etcdctl}" 1 2
  mock_set_output "${etcdctl}" "error: timeout or any other funny error for etcd server" 2

  source ${STARTUP_DIR}/deb/DEBIAN/postinst

  run safely_migrate_no_proxy_key

  # never fail the maintainer script
  assert_success

  assert_equal "$(mock_get_call_num "${etcdctl}")" "2"
  assert_equal "$(mock_get_call_args "${etcdctl}" "1")" "get /config/_global/proxy"
  assert_equal "$(mock_get_call_args "${etcdctl}" "2")" "get /config/_global/proxy/no_proxy_hosts"
  assert_line "Reading new no_proxy key failed with exit code 1. Skipping."
}

@test "safely_migrate_no_proxy_key skips migrating because of error on fetching source key" {
  mock_set_status "${etcdctl}" 1 1
  mock_set_output "${etcdctl}" "/config/_global/proxy: is a directory" 1
  mock_set_status "${etcdctl}" 4 2 # the target key may not exist or be empty
  mock_set_output "${etcdctl}" "Error:  100: Key not found (/ignoremelol) [21131]" 2
  mock_set_status "${etcdctl}" 1 3 # actual error trigger
  mock_set_output "${etcdctl}" "Error:  oh no something bad happened" 3

  source ${STARTUP_DIR}/deb/DEBIAN/postinst

  run safely_migrate_no_proxy_key

  # never fail the package maintainer script
  assert_success

  assert_equal "$(mock_get_call_num "${etcdctl}")" "3"
  assert_equal "$(mock_get_call_args "${etcdctl}" "1")" "get /config/_global/proxy"
  assert_equal "$(mock_get_call_args "${etcdctl}" "2")" "get /config/_global/proxy/no_proxy_hosts"
  assert_equal "$(mock_get_call_args "${etcdctl}" "3")" "get /config/_global/proxy/no_proxy"
  assert_line "Reading deprecated no_proxy key failed with exit code 1. Skipping."
}