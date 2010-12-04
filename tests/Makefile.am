NULL = 

JSBIN = smjs

TESTS_ENVIRONMENT = $(JSBIN) -f $(top_srcdir)/majac/maja-utils.js -f $(top_builddir)/majac/dova-base-0.1.js

TESTS = \
	blockcapture.js \
	capturedloop.js \
	$(NULL)

CLEANFILES = \
	$(TESTS) \
	$(NULL)

%.js: %.vala $(top_builddir)/majac/majac
	$(top_builddir)/majac/majac --vapidir $(top_srcdir)/dova-vapi --vapidir $(top_srcdir)/vapi --pkg dova-base-0.1 --pkg dova-app-0.1 $<
