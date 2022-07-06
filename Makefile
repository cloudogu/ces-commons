# Set these to the desired values
ARTIFACT_ID=ces-commons
VERSION=1.2.0

MAKEFILES_VERSION=4.4.0

.DEFAULT_GOAL:=default

# set PRE_COMPILE to define steps that shall be executed before the go build
# PRE_COMPILE=

include build/make/variables.mk

# You may want to overwrite existing variables for pre/post target actions to fit into your project.

PREPARE_PACKAGE=$(DEBIAN_CONTENT_DIR)/control/preinst $(DEBIAN_CONTENT_DIR)/control/postinst $(DEBIAN_CONTENT_DIR)/control/prerm $(DEBIAN_CONTENT_DIR)/control/prerm

include build/make/info.mk
include build/make/clean.mk
include build/make/self-update.mk
include build/make/package-debian.mk
include build/make/deploy-debian.mk
include build/make/digital-signature.mk

default: debian signature

$(DEBIAN_CONTENT_DIR)/control/preinst: $(DEBIAN_CONTENT_DIR)/control
	@install -p -m 0755 $(WORKDIR)/deb/DEBIAN/preinst $@

$(DEBIAN_CONTENT_DIR)/control/postinst: $(DEBIAN_CONTENT_DIR)/control
	@install -p -m 0755 $(WORKDIR)/deb/DEBIAN/postinst $@

$(DEBIAN_CONTENT_DIR)/control/prerm: $(DEBIAN_CONTENT_DIR)/control
	@install -p -m 0755 $(WORKDIR)/deb/DEBIAN/prerm $@

$(DEBIAN_CONTENT_DIR)/control/postrm: $(DEBIAN_CONTENT_DIR)/control
	@install -p -m 0644 $(WORKDIR)/deb/DEBIAN/postrm $@
