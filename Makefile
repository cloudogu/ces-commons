# Basic package information
PKG_NAME=ces-commons
PKG_VERSION=0.1.3
PKG_MAINTAINER=Christoph Wolfes <christoph.wolfes@cloudogu.com>

DESTDIR=target
CONTROL=$(DESTDIR)/control
INSTALLDIR=./resources

# Deployment
APT_API_BASE_URL=https://apt-api.cloudogu.com/api

define CONTROL_CONTENT
Section: default
Priority: optional
Homepage: https://cloudogu.com
Package: $(PKG_NAME)
Version: $(PKG_VERSION)
Maintainer: $(PKG_MAINTAINER)
Architecture: amd64
Description: Ces-Commons
 Package to install the basic ces scripts
endef
export CONTROL_CONTENT

install:
	mkdir -p $(DESTDIR)
	echo "$$CONTROL_CONTENT" > "$(CONTROL)"
	fpm -s dir -t deb --deb-no-default-config-files -C $(INSTALLDIR) -n $(PKG_NAME) -v $(PKG_VERSION) -p $(DESTDIR)/$(PKG_NAME)_$(PKG_VERSION).deb --maintainer "$(PKG_MAINTAINER)" --deb-custom-control "$(CONTROL)" --after-install postinst

deb:
	make install

clean:
	rm -rf $(DESTDIR)

deploy:
	@if [ X"${APT_API_USERNAME}" = X"" ] ; then echo "supply an APT_API_USERNAME environment variable"; exit 1; fi;
	@if [ X"${APT_API_PASSWORD}" = X"" ] ; then echo "supply an APT_API_PASSWORD environment variable"; exit 1; fi;
	@curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -F 'file=@$(DESTDIR)/$(PKG_NAME)_$(PKG_VERSION).deb' "${APT_API_BASE_URL}/files/xenial" |jq
	@curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X POST "${APT_API_BASE_URL}/repos/xenial/file/xenial/${PKG_NAME}_${PKG_VERSION}.deb" |jq
	@curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X PUT -H "Content-Type: application/json" --data '{"Signing": { "Batch": true, "Passphrase": "${APT_API_SIGNPHRASE}"}}' ${APT_API_BASE_URL}/publish/xenial/xenial

undeploy:
	@if [ X"${APT_API_USERNAME}" = X"" ] ; then echo "supply an APT_API_USERNAME environment variable"; exit 1; fi;
	@if [ X"${APT_API_PASSWORD}" = X"" ] ; then echo "supply an APT_API_PASSWORD environment variable"; exit 1; fi;
	@if [ X"${APT_API_SIGNPHRASE}" = X"" ] ; then echo "supply an APT_API_SIGNPHRASE environment variable"; exit 1; fi;
	PREF=$$(curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" "${APT_API_BASE_URL}/repos/xenial/packages?q=${PKG_NAME}%20(${PKG_VERSION})"); \
	@curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X DELETE -H 'Content-Type: application/json' --data "{\"PackageRefs\": $${PREF}}" ${APT_API_BASE_URL}/repos/xenial/packages
	@curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X PUT -H "Content-Type: application/json" --data '{"Signing": { "Batch": true, "Passphrase": "${APT_API_SIGNPHRASE}"}}' ${APT_API_BASE_URL}/publish/xenial/xenial
