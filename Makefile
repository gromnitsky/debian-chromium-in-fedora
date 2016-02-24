.PHONY: rpm
rpm:

pp-%:
	@echo "$(strip $($*))" | tr ' ' \\n

src := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

# https://packages.debian.org/jessie/i386/chromium/download
name := chromium
ver := 48.0.2564.116
src.url := http://security.debian.org/debian-security/pool/updates/main/c/chromium-browser/chromium_$(ver)-1~deb8u1_i386.deb

out := build
out.rpm := $(out)/rpm
out.udir := $(out.rpm)/$(name)-$(ver)

mkdir = mkdir -p $(dir $@)

$(out)/pkg.deb:
	$(mkdir)
	curl $(src.url) > $@

$(out.rpm)/.unpack: $(out)/pkg.deb
	$(mkdir)
	cd $(dir $@) && alien -g -r ../$(notdir $<)
	touch $@

$(out.rpm)/.patch: spec.patch $(out.rpm)/.unpack
	cp $(out.udir)/$(name)*spec $(out.udir)/1.spec
	cd $(out.udir) && patch -p0 < $(src)/$<
	touch $@

$(out.rpm)/.rpm: $(out.rpm)/.patch
	cd $(out.udir) && rpmbuild --noclean --buildroot=`pwd` -bb 1.spec
	touch $@

rpm: $(out.rpm)/.rpm
