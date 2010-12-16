NULL = 

all-local: ValaApplication.js

ValaApplication.js: $(srcdir)/main.vala $(top_builddir)/majac/majac
	$(top_builddir)/majac/majac --vapidir $(top_srcdir)/dova-vapi --vapidir $(top_srcdir)/vapi --vapidir $(top_srcdir)/majac --pkg dova-base-0.1 --pkg qx -o ValaApplication $(srcdir)/main.vala

EXTRA_DIST = \
	main.vala \
	$(NULL)

CLEANFILES = \
	ValaApplication.js \
	$(NULL)
