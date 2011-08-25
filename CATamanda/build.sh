#!/bin/sh
# Script to generate package
# Any similarity to aur PKGBUILDs is strictly coincidental.

#  This file is part of CATsfw.
#
#  CATsfw is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  CATsfw is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with CATsfw.  If not, see <http://www.gnu.org/licenses/>.

PKGNAME='CATamanda'
PKGVERS='3.3.0'

PREFIX=/opt/sfw
STARTDIR="`pwd`"
PKGSRC="${STARTDIR}/amanda-${PKGVERS}.tar.gz"
SRCDIR="${STARTDIR}/amanda-${PKGVERS}"
PKGDIR="${STARTDIR}/pkg"
STAGINGDIR="${PKGDIR}/staging"
PKGBLDDIR="${PKGDIR}/build"

AR=/opt/csw/bin/gar
CC=/opt/csw/gcc4/bin/gcc
CFLAGS="-I/opt/csw/include/glib-2.0 -I/opt/csw/include -I/opt/sfw/include -I/usr/include"
CPPFLAGS="-I/opt/csw/include/glib-2.0 -I/opt/csw/include -I/opt/sfw/include -I/usr/include"
CXXFLAGS="$CFLAGS"
LD=/opt/csw/gcc4/bin/ld
LDFLAGS="-L/opt/csw/lib -L/opt/sfw/lib -L/usr/lib -L/lib -R/opt/sfw/lib:/opt/csw/lib:/opt/csw/gcc4/lib:/usr/lib:/lib -lsasl2 -lintl -lgss"
PATH='/opt/csw/gnu:/opt/csw/bin:/opt/csw/gcc4/bin:/bin:/sbin'
LD_LIBRARY_PATH="/opt/sfw/lib:/opt/csw/lib:/lib:/usr/lib:/opt/csw/gcc4/lib"
PERL=/usr/bin/perl
PKG_CONFIG=/opt/csw/bin/pkg-config
GTAR="/opt/csw/bin/gtar"

export AR
export CC
export CFLAGS
export CPPFLAGS
export CXXFLAGS
export LD
export LDFLAGS
export PATH
export LD_LIBRARY_PATH
export PERL
export PKG_CONFIG
export GTAR

#=== FUNCTION ================================================================
#        NAME:  file_depends
# DESCRIPTION:  Prints the depends file for the solaris package
#=============================================================================
file_depend ()
{
	cat <<-EOF
		P CSWglib2
	EOF
}

#=== FUNCTION ================================================================
#        NAME:  file_pkginfo
# DESCRIPTION:  Prints the pkginfo file for the solaris package
#=============================================================================
file_pkginfo ()
{
	cat <<-EOF
		PKG=CATamanda
		NAME=cat_amanda
		ARCH=`uname -p`
		VERSION=${PKGVERS},REV=`date +%Y-%m-%d`
		CATEGORY=application
		VENDOR=zmanda
		EMAIL=support@cat.pdx.edu
		PSTAMP=Reid Vandewiele
		BASEDIR=${PREFIX}
		CLASSES=none
	EOF
}

#=== FUNCTION ================================================================
#        NAME:  main
# DESCRIPTION:  Does everything
#=============================================================================
main ()
{
	setup
	configure
	compile
	package	
}

#=== FUNCTION ================================================================
#        NAME:  setup
# DESCRIPTION:  Gets stuff ready
#=============================================================================
setup ()
{
	umask 0022
	# Extract the source package
	cd "${STARTDIR}"
	echo "Unzipping package source..."
	if [ -d ${SRCDIR} ] ; then
	 rm -rf ${SRCDIR} && \
	 gtar xzf ${PKGSRC} || \
	 exit 1
	else
	 gtar xzf ${PKGSRC} || \
	 exit 1
	fi

	# Get the build and staging dir stuff ready
	if [ -d ${STAGINGDIR} ] ; then
	  rm -rf "${STAGINGDIR}" && \
	  mkdir -p "${STAGINGDIR}" || \
	  exit 1
	fi
	if [ ! -d ${PKGDIR} ]; then
	 mkdir ${PKGDIR}
	fi
	if [ ! -d ${STAGINGDIR} ]; then
	 mkdir ${STAGINGDIR}
	fi
	if [ ! -d ${PKGBLDDIR} ]; then
	 mkdir ${PKGBLDDIR}
	fi
}

#=== FUNCTION ================================================================
#        NAME:  configure
# DESCRIPTION:  Configures the software for compilation
#=============================================================================
configure ()
{
	echo "Configuring Package..."

	cd ${SRCDIR} || exit 1

	if [ -f Makefile ] ; then
	  echo "Making clean in ${SRCDIR}..."
	  /opt/csw/bin/gmake clean >/dev/null || exit 1
	fi

	./configure --prefix="${PREFIX}" \
		--with-libraries="/usr/lib /usr/local/lib" \
                --with-user=amanda \
                --with-group=sys \
		--with-amperldir="$PREFIX/share/perl" \



	[ $? -eq 0 ] || exit 1
}

#=== FUNCTION ================================================================
#        NAME:  compile
# DESCRIPTION:  Compiles the software
#=============================================================================
compile ()
{
	cd ${SRCDIR} || exit 1

	echo "Compiling package..."
	/opt/csw/bin/gmake -j 17 DESTDIR="${STAGINGDIR}" || exit 1
}

#=== FUNCTION ================================================================
#        NAME:  package
# DESCRIPTION:  Creates a package for the software
#=============================================================================
package ()
{
	echo "Building package..."
	cd ${SRCDIR} || exit 1
	/opt/csw/bin/gmake -j 17 || exit 1

	echo "Installing (fake) to ${STAGINGDIR}..."
	/opt/csw/bin/gmake DESTDIR="${STAGINGDIR}" install || exit 1
	mv ${STAGINGDIR}/${PREFIX}/* ${STAGINGDIR} && rmdir ${STAGINGDIR}/${PREFIX}

	echo "Calculating prototype..."

	cd "${PKGDIR}"

	file_pkginfo     > ${PKGDIR}/pkginfo
	file_copyright   > ${PKGDIR}/copyright
	file_depend      > ${PKGDIR}/depend
	file_prototype   > ${PKGDIR}/prototype

	PKGNAME="${PKGDIR}/${PKGNAME}-${PKGVERS}-`uname -s``uname -r`-`uname -p`-CAT.pkg"

	echo "Building to ${PKGNAME}.gz"
	pkgmk -o -d "${PKGBLDDIR}"

	pkgtrans "${PKGBLDDIR}" "${PKGNAME}" <<-EOF
	all
	EOF
	gzip -f "${PKGNAME}"

}

#=== FUNCTION ================================================================
#        NAME:  file_copyright
# DESCRIPTION:  Prints the copyright file for the solaris package
#=============================================================================
file_copyright ()
{
	cat <<-EOF
	EOF
}

#=== FUNCTION ================================================================
#        NAME:  file_prototype
# DESCRIPTION:  Prints the prototype file for the solaris package
#=============================================================================
file_prototype ()
{
	USER=`id | sed 's/.*uid=[0-9]*(\([^)]*\)).*/\1/'`
	GROUP=`id | sed 's/.*gid=[0-9]*(\([^)]*\))/\1/'`
	TEMP=`mktemp`

	echo "i pkginfo"
	echo "i depend"
	echo "i copyright"
	(
		cd ${STAGINGDIR};
		pkgproto "${STAGINGDIR}=${PREFIX}" > $TEMP
                sed  "s/${USER} ${GROUP}/root bin/" $TEMP
	)
	rm $TEMP
}

#-----------------------------------------------------------------------------
# Call main to start things rolling.
#-----------------------------------------------------------------------------
main "$@"
