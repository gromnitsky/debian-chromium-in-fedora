.PHONY: rpm
rpm:

.DELETE_ON_ERROR:
pp-%:
	@echo "$(strip $($*))" | tr ' ' \\n

src := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
include $(src)/conf.mk

patch := $(src)/patch/$(NAME).patch
out := build
out.rpm := $(out)/rpm
out.files := $(out.rpm)/files

# https://wiki.debian.org/RepositoryFormat
index.1.root := http://ftp.us.debian.org/debian
index.1.dist := $(index.release)/main
index.2.root := http://ftp.us.debian.org/debian
index.2.dist := $(index.release)-updates/main
index.3.root := http://security.debian.org
index.3.dist := $(index.release)/updates/main
index.type := binary-i386

curl := curl -Rfl --connect-timeout 10

index.local = $(out)/index.$(1)
index.url = $(call index.$(1).root)/dists/$(call index.$(1).dist)/$(index.type)/Packages.gz

mkdir = @mkdir -p $(dir $@)
pkg.data = grep -A100 '^Package: $(2)$$' $(call index.local,$(1)) | sed -e '2,$${/^Package: /,$$d}'
pkg.info = $(shell $(call pkg.data,$(1),$(2)) | grep '^$(3): ' | awk '{print $$2}')
pkg._ver = $(call pkg.info,$(1),$(NAME),Version)
pkg._url = $(call index.$(1).root)/$(call pkg.info,$(1),$(NAME),Filename)

pkg.latest := 1
define pkg.max =
$(foreach idx, 1 2 3, $(if $(subst bigger,,$(shell \
	dpkg --compare-versions '$(call pkg._ver,$(idx))' gt '$(call pkg._ver,$(pkg.latest))'; \
	if [ $$? -eq 0 ] ; then echo bigger; else echo smaller; fi
)),,$(eval pkg.latest := $$(idx))))
endef

pkg.url = $(pkg.max)$(call pkg._url,$(pkg.latest))

.PHONY: ver
ver:
	@printf "%-32s %-20s %s\n" $(index.1.root) $(index.1.dist) $(call pkg._ver,1)
	@printf "%-32s %-20s %s\n" $(index.2.root) $(index.2.dist) $(call pkg._ver,2)
	@printf "%-32s %-20s %s\n" $(index.3.root) $(index.3.dist) $(call pkg._ver,3)
	@echo
	@echo latest: $(pkg.url)

$(out)/index.%:
	$(mkdir)
	$(curl) $(call index.url,$*) | gunzip -c > $@

.PHONY: index
index: $(call index.local,1) $(call index.local,2) $(call index.local,3)

.PHONY: url
url:
	@echo $(pkg.url)

$(out)/pkg.deb:
	$(mkdir)
	$(curl) $(pkg.url) > $@

$(out.files): $(out)/pkg.deb
	$(mkdir)
	cd $(dir $@) && alien -k -g -r ../$(notdir $<)
	mv $(out.rpm)/$(NAME)-* $@

$(patch):

$(out.rpm)/.patch: $(patch) $(out.files)
	cp $(out.files)/$(NAME)-*.spec $(out.files)/1.spec
ifneq ($(wildcard $(src)/patch/$(NAME).patch),)
	cd $(out.files) && patch -p0 < $(patch)
endif
	touch $@

$(out.rpm)/.rpm: $(out.rpm)/.patch
	cd $(out.files) && rpmbuild --noclean --buildroot=`pwd` -bb 1.spec
	touch $@

rpm: $(out.rpm)/.rpm
