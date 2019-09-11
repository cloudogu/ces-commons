# Set these to the desired values
ARTIFACT_ID=ces-commons
VERSION=0.1.4

MAKEFILES_VERSION=1.0.5

.DEFAULT_GOAL:=default

# set PRE_COMPILE to define steps that shall be executed before the go build
# PRE_COMPILE=

include build/make/variables.mk

# You may want to overwrite existing variables for pre/post target actions to fit into your project.

PREPARE_PACKAGE=$(DEBIAN_CONTENT_DIR)/control/postinst $(DEBIAN_CONTENT_DIR)/control/prerm $(DEBIAN_CONTENT_DIR)/control/prerm

include build/make/info.mk
#include build/make/build.mk
#include build/make/unit-test.mk
#include build/make/static-analysis.mk
include build/make/clean.mk
include build/make/package-debian.mk
include build/make/digital-signature.mk
#include build/make/yarn.mk
#include build/make/bower.mk

default: debian signature

$(DEBIAN_CONTENT_DIR)/control/postinst: $(DEBIAN_CONTENT_DIR)/control
	@install -p -m 0755 $(WORKDIR)/deb/DEBIAN/postinst $@

$(DEBIAN_CONTENT_DIR)/control/prerm: $(DEBIAN_CONTENT_DIR)/control
	@install -p -m 0755 $(WORKDIR)/deb/DEBIAN/prerm $@

$(DEBIAN_CONTENT_DIR)/control/postrm: $(DEBIAN_CONTENT_DIR)/control
	@install -p -m 0644 $(WORKDIR)/deb/DEBIAN/postrm $@

.PHONY: update-makefiles
update-makefiles: $(TMP_DIR)
	@echo Updating makefiles...
	@curl -L --silent https://github.com/cloudogu/makefiles/archive/v$(MAKEFILES_VERSION).tar.gz > $(TMP_DIR)/makefiles-v$(MAKEFILES_VERSION).tar.gz

	@tar -xzf $(TMP_DIR)/makefiles-v$(MAKEFILES_VERSION).tar.gz -C $(TMP_DIR)
	@cp -r $(TMP_DIR)/makefiles-$(MAKEFILES_VERSION)/build/make $(BUILD_DIR)
