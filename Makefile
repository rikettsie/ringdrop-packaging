VERSION  ?= $(error VERSION is required — e.g. make rpm-release VERSION=0.13.0)
RELEASE  ?= 1
NAME     := ringdrop
SPECFILE := rpm/$(NAME).spec

# Path to the ringdrop source tree — override if needed.
RINGDROP := ../ringdrop

MAINTAINER := Enrico Fusto <enrico.fusto@protonmail.com>
RPM_DATE   := $(shell date "+%a %b %d %Y")

.PHONY: rpm-release vendor rpm-bump clean help

help:
	@echo "Run on Fedora:"
	@echo "  make rpm-release VERSION=x.y.z  RPM vendor + spec bump + commit/push + clean"
	@echo ""
	@echo "Individual targets:"
	@echo "  make vendor   VERSION=x.y.z   RPM vendor tarball only"
	@echo "  make rpm-bump VERSION=x.y.z   bump RPM spec only"
	@echo "  make clean                    remove generated tarballs"

## Run on Fedora: vendor + bump spec + commit/push + clean.
rpm-release: vendor rpm-bump
	git add -A && git commit -m "chore(rpm): bump to $(VERSION)" && git push
	$(MAKE) clean

## Check out v$(VERSION), generate RPM vendor tarball, return to main.
vendor:
	cd $(RINGDROP) && git fetch --tags && git checkout v$(VERSION)
	cd $(RINGDROP) && bash $(CURDIR)/rpm/vendor.sh; \
	    mv $(NAME)-$(VERSION)-vendor.tar.gz $(CURDIR)/; \
	    git checkout main

## Update Version: in the spec, update metainfo <releases>, and prepend a %changelog entry.
## No-op if version already present in changelog.
rpm-bump:
	sed -i 's/^Version:.*$$/Version:        $(VERSION)/' $(SPECFILE)
	sed -i 's|<release version="[^"]*" date="[^"]*"/>|<release version="$(VERSION)" date="$(shell date +%Y-%m-%d)"/>|' assets/ringdrop.metainfo.xml
	@if grep -q "^\\* .* - $(VERSION)-$(RELEASE)$$" $(SPECFILE); then \
	    echo "$(VERSION)-$(RELEASE) already in spec changelog, skipping"; \
	else \
	    awk '/^%changelog/{                                          \
	        print;                                                   \
	        print "* $(RPM_DATE) $(MAINTAINER) - $(VERSION)-$(RELEASE)"; \
	        print "- Update to $(VERSION)";                          \
	        print "";                                                \
	        next                                                     \
	    }1' $(SPECFILE) > $(SPECFILE).tmp && mv $(SPECFILE).tmp $(SPECFILE); \
	fi

## Remove generated tarballs.
clean:
	rm -f *.tar.gz
