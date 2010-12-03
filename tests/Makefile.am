NULL = 

JSBIN = smjs

TESTS_ENVIRONMENT = $(JSBIN) -f $(top_srcdir)/majac/maja-utils.js -f $(top_builddir)/majac/dova-base-0.1.js

TESTS = \
	blockcapture.js \
	$(NULL)

.vala.js:
	$(top_builddir)/majac/majac --vapidir $(top_srcdir)/dova-vapi --vapidir $(top_srcdir)/majac --pkg dova-base-0.1 --pkg dova-app-0.1 $<
