VERSION  ?= $(error VERSION is required — e.g. make release VERSION=0.13.0)
RELEASE  := 1
NAME     := ringdrop
SPECFILE := rpm/$(NAME).spec

# Path to the ringdrop source tree — override if needed.
RINGDROP := ../ringdrop

MAINTAINER := Enrico Fusto <enrico.fusto@protonmail.com>
RPM_DATE   := $(shell date "+%a %b %d %Y")

.PHONY: vendor deb-vendor rpm-bump deb-bump release publish clean help

help:
	@echo "Targets:"
	@echo "  make release    VERSION=x.y.z  full release (vendor + spec + deb)"
	@echo "  make vendor     VERSION=x.y.z  RPM vendor tarball only"
	@echo "  make deb-vendor VERSION=x.y.z  DEB orig tarball (fat, with vendor)"
	@echo "  make rpm-bump   VERSION=x.y.z  bump RPM spec only"
	@echo "  make deb-bump   VERSION=x.y.z  bump Debian changelog only"
	@echo "  make clean                     remove generated tarballs"

## Check out v$(VERSION), generate RPM vendor tarball, return to main.
vendor:
	cd $(RINGDROP) && git fetch --tags && git checkout v$(VERSION)
	cd $(RINGDROP) && bash $(CURDIR)/rpm/vendor.sh; \
	    mv $(NAME)-$(VERSION)-vendor.tar.gz $(CURDIR)/; \
	    git checkout main

## Check out v$(VERSION), generate fat DEB orig tarball (source + vendor), return to main.
deb-vendor:
	cd $(RINGDROP) && git fetch --tags && git checkout v$(VERSION)
	cd $(RINGDROP) && bash $(CURDIR)/deb/deb-vendor.sh; \
	    mv $(NAME)_$(VERSION).orig.tar.gz $(CURDIR)/; \
	    git checkout main

## Update Version: in the spec and prepend a %changelog entry.
rpm-bump:
	sed -i 's/^Version:.*$$/Version:        $(VERSION)/' $(SPECFILE)
	awk '/^%changelog/{                                          \
	    print;                                                   \
	    print "* $(RPM_DATE) $(MAINTAINER) - $(VERSION)-$(RELEASE)"; \
	    print "- Update to $(VERSION)";                          \
	    print "";                                                \
	    next                                                     \
	}1' $(SPECFILE) > $(SPECFILE).tmp && mv $(SPECFILE).tmp $(SPECFILE)

## Prepend an entry to the Debian changelog (requires devscripts).
deb-bump:
	cd deb && DEBEMAIL="$(MAINTAINER)" dch -v $(VERSION)-$(RELEASE) \
	    "Update to $(VERSION)"

## Full release: generate both vendor tarballs and bump both changelogs.
release: vendor deb-vendor rpm-bump deb-bump

## release + commit + push + clean up tarballs.
publish: release
	git add -A && git commit -m "chore: bump to $(VERSION)" && git push
	$(MAKE) clean

## Remove generated tarballs.
clean:
	rm -f *.tar.gz
