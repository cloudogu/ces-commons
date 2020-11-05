# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
* systemd docker service configuration (moved from ecosystem) (#13)
* docker-metadata service which reads proxy configuration from etcd and applies it to the docker service (#13)

## [v0.2.1]()(https://github.com/cloudogu/ces-commons/releases/tag/v0.2.1) - 2020-01-22
### Fixed
* Conflict resolution in upgrades from ces-commons < 0.1.4
* Upgrade problem with old systemd version (e.g. used in Ubuntu 16.04) (#11)

## [v0.2.0]()(https://github.com/cloudogu/ces-commons/releases/tag/v0.2.0) - 2019-12-11

### Changed
* Increase vm.max_map_count to 262144

## [v0.1.5](https://github.com/cloudogu/ces-commons/releases/tag/v0.1.5) - 2019-10-30

### Fixed
* #3 IP change problem: Device "onlink" does not exist

## [v0.1.4](https://github.com/cloudogu/ces-commons/releases/tag/v0.1.4) - 2019-05-21

### Changed
* Make get_ip of functions.sh work with Ubuntu 18.04

## [v0.1.3](https://github.com/cloudogu/ces-commons/releases/tag/v0.1.3) - 2019-01-10

### Changed
* Improve scripts to make them compatible to Ubuntu 18.04

## [v0.1.2](https://github.com/cloudogu/ces-commons/releases/tag/v0.1.2) - 2018-12-04

## [v0.1.1](https://github.com/cloudogu/ces-commons/releases/tag/v0.1.1) - 2018-01-11

### Changed
* getIp() - unexpected result for non-192.168.-networks (#1)

## [v0.1.0](https://github.com/cloudogu/ces-commons/releases/tag/v0.1.0) - 2017-11-09

### Added
* postinst script
