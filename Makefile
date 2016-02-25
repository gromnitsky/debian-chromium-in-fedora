.PHONY: rpm
rpm:

.DELETE_ON_ERROR:
pp-%:
	@echo "$(strip $($*))" | tr ' ' \\n

src := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

NAME := chromium
out := build
out.rpm := $(out)/rpm
out.files := $(out.rpm)/files

# https://wiki.debian.org/RepositoryFormat
index.release := jessie
index.1.root := http://ftp.us.debian.org/debian
index.1.dist := $(index.release)/main
index.2.root := http://security.debian.org
index.2.dist := $(index.release)/updates/main
index.type := binary-i386

index.local = $(out)/index.$(1)
index.url = $(call index.$(1).root)/dists/$(call index.$(1).dist)/$(index.type)/Packages.gz

mkdir = @mkdir -p $(dir $@)
pkg.data = grep -A100 '^Package: $(2)$$' $(call index.local,$(1)) | sed -e '2,$${/^Package: /,$$d}'
pkg.info = $(shell $(call pkg.data,$(1),$(2)) | grep '^$(3): ' | awk '{print $$2}')
pkg._ver = $(call pkg.info,$(1),$(NAME),Version)
pkg._url = $(call index.$(1).root)/$(call pkg.info,$(1),$(NAME),Filename)

define pkg.url =
$(shell dpkg --compare-versions '$(call pkg._ver,2)' gt '$(call pkg._ver,1)'; \
	if [ $$? -eq 0 ]; then echo '$(call pkg._url,2)'; else echo "$(call pkg._url,1)"; fi)
endef

.PHONY: ver
ver:
	@printf "%-20s: %s\n" $(index.1.dist) $(call pkg._ver,1)
	@printf "%-20s: %s\n" $(index.2.dist) $(call pkg._ver,2)
	@printf "\n%-20s: %s\n" latest $(pkg.url)

$(out)/index.%:
	$(mkdir)
	curl -Rfl --connect-timeout 10 $(call index.url,$*) | gunzip -c > $@

.PHONY: index
index: $(call index.local,1) $(call index.local,2)

.PHONY: url
url:
	@echo $(pkg.url)

$(out)/pkg.deb:
	$(mkdir)
	curl $(pkg.url) > $@

$(out.files): $(out)/pkg.deb
	$(mkdir)
	cd $(dir $@) && alien -k -g -r ../$(notdir $<)
	mv $(out.rpm)/$(NAME)-* $@

$(out.rpm)/.patch: spec.patch $(out.files)
	cp $(out.files)/$(NAME)-*.spec $(out.files)/1.spec
	cd $(out.files) && patch -p0 < $(src)/$<
	touch $@

$(out.rpm)/.rpm: $(out.rpm)/.patch
	cd $(out.files) && rpmbuild --noclean --buildroot=`pwd` -bb 1.spec
	touch $@

rpm: $(out.rpm)/.rpm
