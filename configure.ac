#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

m4_define([maja_major], [0])
m4_define([maja_minor], [2])
m4_define([maja_micro], [0])

m4_define([maja_version], [maja_major.maja_minor.maja_micro])
m4_define([maja_api_version], [0.1])

m4_define([maja_name], [maja])

AC_PREREQ([2.64])
AC_INIT([Maja], [maja_version], [lucabru@src.gnome.org])
AC_CONFIG_HEADERS([majac/config.h])
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE([dist-bzip2])
AM_MAINTAINER_MODE

MAJA_MAJOR_VERSION=maja_major
MAJA_MINOR_VERSION=maja_minor
MAJA_MICRO_VERSION=maja_micro
MAJA_VERSION=maja_version
MAJA_API_VERSION=maja_api_version
AC_SUBST(MAJA_MAJOR_VERSION)
AC_SUBST(MAJA_MINOR_VERSION)
AC_SUBST(MAJA_MICRO_VERSION)
AC_SUBST(MAJA_VERSION)
AC_SUBST(MAJA_API_VERSION)

m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])

GLIB_REQUIRED=2.16.0
GEE_REQUIRED=0.5.0
VALA_REQUIRED=0.11.1

# Checks for programs.
AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_INSTALL
AC_PROG_LIBTOOL
AM_PROG_VALAC($VALA_REQUIRED)

VALA_PACKAGE=libvala-0.14
AC_SUBST(VALA_PACKAGE)

# Checks for libraries.
PKG_CHECK_MODULES(GEE, gee-1.0 >= $GEE_REQUIRED)
AC_SUBST(GEE_CFLAGS)
AC_SUBST(GEE_LIBS)
PKG_CHECK_MODULES(GLIB, glib-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)
PKG_CHECK_MODULES(VALA, $VALA_PACKAGE >= $VALA_REQUIRED)
AC_SUBST(VALA_CFLAGS)
AC_SUBST(VALA_LIBS)

# Checks for header files.
AC_CHECK_HEADERS([stdlib.h string.h])

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.

AC_CONFIG_FILES([Makefile
                 majac/Makefile
                 tests/Makefile
                 examples/Makefile
                 examples/qx/Makefile
                 examples/qx/helloworld/Makefile
                 maja-$MAJA_API_VERSION.pc])
AC_OUTPUT
