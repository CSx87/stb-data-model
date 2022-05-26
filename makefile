PKGDIR = ./output/$(MACHINE)/pkg/

define create_changelog
	@$(ECHO) "Update changelog"
	mv CHANGELOG.md CHANGELOG.md.bak
	head -n 9 CHANGELOG.md.bak > CHANGELOG.md
	$(ECHO) "" >> CHANGELOG.md
	$(ECHO) "## Release $(VERSION) - $(NOW)" >> CHANGELOG.md
	$(ECHO) "" >> CHANGELOG.md
	$(GIT) log --pretty=format:"- %s" $$($(GIT) describe --tags | grep -v "merge" | cut -d'-' -f1)..HEAD  >> CHANGELOG.md
	$(ECHO) "" >> CHANGELOG.md
	tail -n +10 CHANGELOG.md.bak >> CHANGELOG.md
	rm CHANGELOG.md.bak
endef

# targets
all:
	$(MAKE) -C src all

clean:
	$(MAKE) -C src clean
	$(MAKE) -C test clean

install: all
	$(INSTALL) -D -p -m 0644 output/$(MACHINE)/$(COMPONENT).so $(DEST)/usr/lib/amx/$(COMPONENT)/$(COMPONENT).so
	$(INSTALL) -D -p -m 0644 odl/$(COMPONENT).odl $(DEST)/etc/amx/$(COMPONENT)/$(COMPONENT).odl
	$(INSTALL) -D -p -m 0644 odl/$(COMPONENT)_definition.odl $(DEST)/etc/amx/$(COMPONENT)/$(COMPONENT)_definition.odl
	$(INSTALL) -D -p -m 0660 acl/admin/$(COMPONENT).json $(DEST)$(ACLDIR)/admin/$(COMPONENT).json
	$(INSTALL) -d -m 0755 $(DEST)$(BINDIR)
	$(INSTALL) -D -p -m 0755 scripts/$(COMPONENT).sh $(DEST)$(INITDIR)/$(COMPONENT)
	ln -sfr $(DEST)$(BINDIR)/amxrt $(DEST)$(BINDIR)/$(COMPONENT)

package: all
	$(INSTALL) -D -p -m 0644 output/$(MACHINE)/$(COMPONENT).so $(PKGDIR)/usr/lib/amx/$(COMPONENT)/$(COMPONENT).so
	$(INSTALL) -D -p -m 0644 odl/$(COMPONENT).odl $(PKGDIR)/etc/amx/$(COMPONENT)/$(COMPONENT).odl
	$(INSTALL) -D -p -m 0644 odl/$(COMPONENT)_definition.odl $(PKGDIR)/etc/amx/$(COMPONENT)/$(COMPONENT)_definition.odl
	$(INSTALL) -D -p -m 0660 acl/admin/$(COMPONENT).json $(PKGDIR)$(ACLDIR)/admin/$(COMPONENT).json
	$(INSTALL) -d -m 0755 $(PKGDIR)$(BINDIR)
	$(INSTALL) -D -p -m 0755 scripts/$(COMPONENT).sh $(PKGDIR)$(INITDIR)/$(COMPONENT)
	cd $(PKGDIR) && $(TAR) -czvf ../$(COMPONENT)-$(VERSION).tar.gz .
	cp $(PKGDIR)../$(COMPONENT)-$(VERSION).tar.gz .
	make -C packages

changelog:
	$(call create_changelog)

doc:
	$(eval ODLFILES += odl/$(COMPONENT).odl)
	$(eval ODLFILES += odl/$(COMPONENT)_definition.odl)

	mkdir -p output/xml
	mkdir -p output/html
	amxo-cg -Gxml,output/xml/$(COMPONENT).xml $(or $(ODLFILES), "")
	amxo-xml-to -x html -o output-dir=output/html -o title="$(COMPONENT)" -o version=$(VERSION) -o sub-title="Datamodel reference" output/xml/*.xml

test:
	$(MAKE) -C test run
	$(MAKE) -C test coverage

.PHONY: all clean changelog install package doc test

