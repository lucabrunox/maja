NULL = 

JSBIN = smjs

TESTS_ENVIRONMENT = $(JSBIN) \
	-f $(top_srcdir)/majac/maja-utils.js \
	-f $(top_builddir)/majac/dova-base-0.1.js \
	-f $(top_builddir)/majac/dova-model-0.1.js

TESTS = \
	dovabase.js \
	dovamodel.js \
	langsupport.js \
	$(NULL)

all-local: dovajs.js dovajs.html

$(builddir)/%.js: $(srcdir)/%.vala $(top_builddir)/majac/majac
	$(top_builddir)/majac/majac --vapidir $(top_srcdir)/dova-vapi --vapidir $(top_srcdir)/vapi --vapidir $(top_builddir)/majac --pkg js-lang --pkg dova-base-0.1 --pkg dova-app-0.1 --pkg dova-model-0.1 --pkg dova-js $<

%.html:
	echo "<html><head><script src=\"$(top_builddir)/majac/maja-utils.js\"></script><script src=\"$(top_builddir)/majac/dova-base-0.1.js\"></script><script src=\"$(top_builddir)/majac/dova-model-0.1.js\"></script><script src=\"$(top_builddir)/majac/dova-js.js\"></script><script src=\"$(builddir)/dovajs.js\"></script></head><body></body></html>" > $@

BROWSER_OBJS = dovajs.js dovajs.html

.PHONY: browser
browser: $(BROWSER_OBJS)
	xdg-open dovajs.html &

EXTRA_DIST = \
	dovajs.vala \
	$(NULL)

CLEANFILES = \
	$(BROWSER_OBJS) \
	$(TESTS) \
	$(NULL)
