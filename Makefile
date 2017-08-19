.PHONY: rpm
rpm:

src := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
include $(src)/conf.mk

patch := $(src)/patch/$(index.type).spec.patch
out := build
out.rpm := $(out)/fedora/$(NAME)
out.files := $(out.rpm)/files
deb = $(src)/$(out)/debian/$(NAME).deb

# https://wiki.debian.org/RepositoryFormat
index.1.root := http://ftp.us.debian.org/debian
index.1.dist := $(index.release)/main
index.2.root := http://ftp.us.debian.org/debian
index.2.dist := $(index.release)-updates/main
index.3.root := http://security.debian.org
index.3.dist := $(index.release)/updates/main

curl := curl -Rfl --connect-timeout 10

index.local = $(out)/index.$(1)
index.url = $(index.$(1).root)/dists/$(index.$(1).dist)/$(index.type)/Packages.gz
indices := $(foreach idx,1 2 3, $(call index.local,$(idx)) )

mkdir = @mkdir -p $(dir $@)
pkg.data = grep -A100 '^Package: $(2)$$' $(call index.local,$(1)) | sed -e '2,$${/^Package: /,$$d}'
pkg.info = $(word 2, $(shell $(call pkg.data,$(1),$(2)) | grep '^$(3): '))
pkg._ver = $(call pkg.info,$(1),$(NAME),Version)
pkg._url = $(index.$(1).root)/$(call pkg.info,$(1),$(NAME),Filename)

pkg._max := 1
define pkg.max =
$(foreach idx, 1 2 3, $(if $(filter 0,$(shell \
	dpkg --compare-versions \
		'$(call pkg._ver,$(idx))' gt '$(call pkg._ver,$(pkg._max))'; \
	echo $$?
)),$(eval pkg._max := $$(idx))))
endef

pkg.url = $(pkg.max)$(call pkg._url,$(pkg._max))

.PHONY: ver
ver:
	@$(foreach idx, 1 2 3, printf "%-32s %-20s %s\n" '$(index.$(idx).root)' '$(index.$(idx).dist)' '$(call pkg._ver,$(idx))'; )
	@echo
	@echo latest: $(pkg.url)

$(out)/index.%:
	$(mkdir)
	$(curl) $(call index.url,$*) | gunzip -c > $@

.PHONY: index
index: $(indices)

.PHONY: url
url: $(indices)
	@echo $(pkg.url)

$(deb): $(indices)
	$(mkdir)
	$(curl) $(pkg.url) > $@

$(out.files): $(deb)
	$(mkdir)
	cd $(dir $@) && alien -k -g -r $<
	mv $(out.rpm)/$(NAME)-* $@

# if it doesn't exist it always 'newer' then $(out.rpm)/.patch
$(patch):

$(out.rpm)/.patch: $(patch) $(out.files)
	mv $(out.files)/$(NAME)-*.spec $(dir $@)/1.spec
ifneq ($(wildcard $(patch)),)
	cd $(dir $@) && patch -p0 < $(patch)
endif
	@touch $@

$(out.rpm)/.rpm: $(out.rpm)/.patch
	cd $(out.files) && rpmbuild --quiet --noclean --buildroot=`pwd` -bb ../1.spec $(rpmbuild)
	@touch $@

rpm: $(out.rpm)/.rpm
