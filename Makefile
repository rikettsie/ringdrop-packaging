VERSION  ?= $(error VERSION is required — e.g. make rpm-release VERSION=0.13.0)
RELEASE  := 1
NAME     := ringdrop
SPECFILE := rpm/$(NAME).spec

# Path to the ringdrop source tree — override if needed.
RINGDROP := ../ringdrop

MAINTAINER := Enrico Fusto <enrico.fusto@protonmail.com>
RPM_DATE   := $(shell date "+%a %b %d %Y")

.PHONY: rpm-release deb-release vendor deb-vendor rpm-bump deb-bump clean help

help:
	@echo "Run on Fedora:"
	@echo "  make rpm-release VERSION=x.y.z  RPM vendor + spec bump + commit/push + clean"
	@echo ""
	@echo "Run on Ubuntu:"
	@echo "  make deb-release VERSION=x.y.z  DEB vendor + changelog bump + commit/push + clean"
	@echo ""
	@echo "Individual targets:"
	@echo "  make vendor     VERSION=x.y.z   RPM vendor tarball only"
	@echo "  make deb-vendor VERSION=x.y.z   DEB orig tarball (source + vendor)"
	@echo "  make rpm-bump   VERSION=x.y.z   bump RPM spec only"
	@echo "  make deb-bump   VERSION=x.y.z   bump Debian changelog only"
	@echo "  make clean                      remove generated tarballs"

## Run on Fedora: vendor + bump spec + commit/push + clean.
rpm-release: vendor rpm-bump
	git add -A && git commit -m "chore(rpm): bump to $(VERSION)" && git push
	$(MAKE) clean

## Run on Ubuntu: deb-vendor + bump changelog + commit/push + clean.
deb-release: deb-vendor deb-bump
	git add -A && git commit -m "chore(deb): bump to $(VERSION)" && git push
	$(MAKE) clean

## Check out v$(VERSION), generate RPM vendor tarball, return to main.
vendor:
	cd $(RINGDROP) && git fetch --tags && git checkout v$(VERSION)
	cd $(RINGDROP) && bash $(CURDIR)/rpm/vendor.sh; \
	    mv $(NAME)-$(VERSION)-vendor.tar.gz $(CURDIR)/; \
	    git checkout main

## Check out v$(VERSION), generate DEB orig tarball (source + vendor), return to main.
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

## Remove generated tarballs.
clean:
	rm -f *.tar.gz
