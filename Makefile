# Basic package information
PKG_NAME=ces-commons
PKG_DESCRIPTION="Package to install the basic ces scripts"
PKG_VERSION=0.1.0
PKG_MAINTAINER="Christoph Wolfes \<christoph.wolfes@cloudogu.com\>"
PKG_ARCH=all

DESTDIR=./target
INSTALLDIR=./resources

install:
	mkdir -p $(DESTDIR)
	fpm -s dir -t deb -C $(INSTALLDIR) -n $(PKG_NAME) -v $(PKG_VERSION) -p $(DESTDIR)/$(PKG_NAME)_v$(PKG_VERSION)_$(PKG_ARCH).deb --maintainer $(PKG_MAINTAINER)

deb:
	make install
