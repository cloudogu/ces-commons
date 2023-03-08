# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Install/Update HashiCorp apt repo; #40
- Add automatic release mechanism; #38

## [v1.2.1](https://github.com/cloudogu/ces-commons/releases/tag/v1.2.1) - 2023-02-16
### Changed
- Remove unavailable docker daemon parameters; #36
- Upgrade makefiles to 7.2.0

## [v1.2.0](https://github.com/cloudogu/ces-commons/releases/tag/v1.2.0) - 2022-07-06
### Changed
- use fqdn as domain for certificate generation when no domain set (#31)

## [v1.1.0](https://github.com/cloudogu/ces-commons/releases/tag/v1.1.0) - 2021-11-11
### Added
- refactor ssl script to generate a certificate for cesappd; #29

## [v1.0.1](https://github.com/cloudogu/ces-commons/releases/tag/v1.0.1) - 2021-05-03
### Changed
- Only use new network interface names for Ubuntu versions >= 20.04

## [v1.0.0](https://github.com/cloudogu/ces-commons/releases/tag/v1.0.0) - 2021-04-30
### Changed
- Use new enp0s8 and enp0s3 network interface names to determine IP address; #26

## [v0.8.0](https://github.com/cloudogu/ces-commons/releases/tag/v0.8.0) - 2021-04-22
### Added
- Update ces apt repository configuration if it's not fitting the current Ubuntu version

## [v0.7.0](https://github.com/cloudogu/ces-commons/releases/tag/v0.7.0) - 2021-04-19
### Added
- Handle Azure machine type; #23

## [v0.6.0](https://github.com/cloudogu/ces-commons/releases/tag/v0.6.0) - 2021-04-08
### Added
- Check if etcd key `/config/_global/fqdn` exists before reading it; #21

## [v0.5.0](https://github.com/cloudogu/ces-commons/releases/tag/v0.5.0) - 2021-02-25
### Added
- Self-signed certificate is added to certification authority (#19)

## [v0.4.0](https://github.com/cloudogu/ces-commons/releases/tag/v0.4.0) - 2021-01-12
### Added
- Alternative dns entry for local.cloudogu.com (#17)

## [v0.3.1](https://github.com/cloudogu/ces-commons/releases/tag/v0.3.1) - 2020-12-11
### Fixed
- Resolve dockeroptions.conf file conflict when upgrading from 0.2.1 and lower; #15

### Changed
- Upgrade makefiles to v4.2.0

## [v0.3.0](https://github.com/cloudogu/ces-commons/releases/tag/v0.3.0) - 2020-11-05
### Added
* systemd docker service configuration (moved from ecosystem) (#13)
    * Please note: the Debian package management will require a conflict resolution if you modified the file `/etc/systemd/system/docker.service.d/dockeroptions.conf`
* Apply proxy configuration from `etcd` to new docker-metadata service (#13)
    * the docker-metadata service reads the current proxy configuration from etcd and applies it to the docker service 
    * the docker-metadata proxy file will be emptied if no proxy configuration exists or it is explicitly disabled
    * for edge cases where a proxy should be provided to Docker but not to the `cesapp` via `etcd` you may want to create a separate file `/etc/systemd/system/docker.service.d/proxy.conf`:

```
[Service]
Environment="HTTP_PROXY=1.2.3.4:8080"
Environment="HTTPS_PROXY=1.2.3.4:8080"
Environment="NO_PROXY=localhost,127.0.0.1,0.0.0.0,172.15.16.17,my.fqdn.or.external.ingress.domain.net"
```


## [v0.2.1](https://github.com/cloudogu/ces-commons/releases/tag/v0.2.1) - 2020-01-22
### Fixed
* Conflict resolution in upgrades from ces-commons < 0.1.4
* Upgrade problem with old systemd version (e.g. used in Ubuntu 16.04) (#11)

## [v0.2.0](https://github.com/cloudogu/ces-commons/releases/tag/v0.2.0) - 2019-12-11
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
