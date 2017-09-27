# Basic package information
PKG_NAME=ces-commons
PKG_DESCRIPTION="Package to install the basic ces scripts"
PKG_VERSION=0.1.0
PKG_MAINTAINER="Christoph Wolfes \<christoph.wolfes@cloudogu.com\>"
PKG_ARCH=all

DESTDIR=./target
INSTALLDIR=./resources

# Deployment
APT_API_BASE_URL=https://apt-api.cloudogu.com/api

install:
	mkdir -p $(DESTDIR)
	fpm -s dir -t deb -C $(INSTALLDIR) -n $(PKG_NAME) -v $(PKG_VERSION) -p $(DESTDIR)/$(PKG_NAME)_v$(PKG_VERSION)_$(PKG_ARCH).deb --maintainer $(PKG_MAINTAINER)

deb:
	make install

clean:
	rm -rf target

deploy:
	@case X"${PKG_VERSION}" in *-SNAPSHOT) echo "i will not upload a snaphot version for you" ; exit 1; esac;
    @if [ X"${APT_API_USERNAME}" = X"" ] ; then echo "supply an APT_API_USERNAME environment variable"; exit 1; fi;
    @if [ X"${APT_API_PASSWORD}" = X"" ] ; then echo "supply an APT_API_PASSWORD environment variable"; exit 1; fi;
    @if [ X"${APT_API_SIGNPHRASE}" = X"" ] ; then echo "supply an APT_API_SIGNPHRASE environment variable"; exit 1; fi;
    curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -F file=@"${PACKAGE}" "${APT_API_BASE_URL}/files/xenial" |jq
    curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X POST "${APT_API_BASE_URL}/repos/xenial/file/xenial/${ARTIFACT_ID}_${VERSION}.deb" |jq
    curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X PUT -H "Content-Type: application/json" --data '{"Signing": { "Batch": true, "Passphrase": "${APT_API_SIGNPHRASE}"}}' ${APT_API_BASE_URL}/publish/xenial/xenial

undeploy:
	@case X"${VERSION}" in *-SNAPSHOT) echo "i will not upload a snaphot version for you" ; exit 1; esac;
	@if [ X"${APT_API_USERNAME}" = X"" ] ; then echo "supply an APT_API_USERNAME environment variable"; exit 1; fi;
	@if [ X"${APT_API_PASSWORD}" = X"" ] ; then echo "supply an APT_API_PASSWORD environment variable"; exit 1; fi;
	@if [ X"${APT_API_SIGNPHRASE}" = X"" ] ; then echo "supply an APT_API_SIGNPHRASE environment variable"; exit 1; fi;
	PREF=$$(curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" "${APT_API_BASE_URL}/repos/xenial/packages?q=${ARTIFACT_ID}%20(${VERSION})"); \
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X DELETE -H 'Content-Type: application/json' --data "{\"PackageRefs\": $${PREF}}" ${APT_API_BASE_URL}/repos/xenial/packages
	curl --silent -u "${APT_API_USERNAME}":"${APT_API_PASSWORD}" -X PUT -H "Content-Type: application/json" --data '{"Signing": { "Batch": true, "Passphrase": "${APT_API_SIGNPHRASE}"}}' ${APT_API_BASE_URL}/publish/xenial/xenial

