NULL = 

bin_PROGRAMS = majac

majac_SOURCES = \
	main.vala \
	jscodegen.vala \
	jscode.vala \
	jswriter.vala \
	$(NULL)

majac_LDADD = \
	$(GLIB_LIBS) \
	$(GEE_LIBS) \
	$(VALA_LIBS) \
	$(NULL)

majac_CFLAGS = \
	$(GLIB_CFLAGS) \
	$(GEE_CFLAGS) \
	$(VALA_CFLAGS) \
	$(NULL)

majac_VALAFLAGS = \
	--vapidir $(top_srcdir)/majac \
	--pkg config \
	--pkg gee-1.0 \
	--pkg $(VALA_PACKAGE) \
	-g \
	$(NULL)

JS_OBJS = dova-base-0.1.js dova-model-0.1.js dova-js.js

all-local: $(JS_OBJS)

dova-base-0.1.js: dova-base-0.1.vala $(builddir)/majac
	$(builddir)/majac --vapidir $(top_srcdir)/vapi --pkg js-lang --nostdpkg $<

dova-model-0.1.js: dova-model-0.1.vala $(builddir)/majac
	$(builddir)/majac --vapidir $(top_srcdir)/dova-vapi --vapidir $(top_srcdir)/vapi --pkg js-lang $<

dova-js.js: dova-js.vala $(builddir)/majac
	$(builddir)/majac --vapidir $(top_srcdir)/dova-vapi --vapidir $(top_srcdir)/vapi --library dova-js $<

EXTRA_DIST = \
	maja-utils.js \
	dova-base-0.1.vala \
	dova-model-0.1.vala \
	dova-js.vala \
	$(NULL)

CLEANFILES = \
	$(JS_OBJS) \
	dova-js.vapi \
	$(NULL)
