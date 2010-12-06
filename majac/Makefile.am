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
	-g \
	--vapidir $(top_srcdir)/majac \
	--pkg config \
	--pkg gee-1.0 \
	--pkg $(VALA_PACKAGE) \
	$(NULL)

all-local: dova-base-0.1.js dova-model-0.1.js

dova-base-0.1.js: dova-base-0.1.vala majac
	$(builddir)/majac --nostdpkg $<

dova-model-0.1.js: dova-model-0.1.vala majac
	$(builddir)/majac --vapidir $(top_srcdir)/dova-vapi --vapidir $(top_srcdir)/vapi --pkg dova-base-0.1 $<
