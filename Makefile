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
index.root := http://security.debian.org
index.dist := jessie/updates/main
index.type := binary-i386
index.url := $(index.root)/dists/$(index.dist)/$(index.type)/Packages.gz
index.local := $(out)/index

mkdir = mkdir -p $(dir $@)
pkg.data = grep -A100 '^Package: $(1)$$' $(index.local) | sed -e '2,$${/^Package: /,$$d}'
# example: $(call pkg.info,$(name),Version)
pkg.info = $(shell $(call pkg.data,$(1)) | grep '^$(2): ' | awk '{print $$2}')
pkg.url = $(index.root)/$(call pkg.info,$(NAME),Filename)

$(index.local):
	$(mkdir)
	curl $(index.url) | gunzip -c > $@

.PHONY: index
index: $(index.local)

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
