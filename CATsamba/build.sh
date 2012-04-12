#!/bin/sh
# Script to generate CATsamba package
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

PKGNAME='CATsamba'
PKGVERS='3.6.4'

PREFIX=/opt/sfw
STARTDIR="`pwd`"
PKGSRC="${STARTDIR}/samba-${PKGVERS}.tar.gz"
PKGDIR="${STARTDIR}/pkg"
SRCDIR="${STARTDIR}/samba-${PKGVERS}/source3"
STAGINGDIR="${PKGDIR}/staging"
PKGBLDDIR="${PKGDIR}/build"
PYTHON=/opt/csw/bin/python
PYTHON_CONFIG=/opt/csw/bin/python-config

OPENLDAPVERS='2.2.26'

AR=/opt/csw/bin/gar
CC=/opt/SUNWspro/bin/cc
LD=/usr/ccs/bin/ld
PATH='/bin:/sbin:/opt/sfw/bin:/opt/csw/bin:/opt/csw/gcc4/bin'
LDFLAGS="-L/opt/csw/lib -L/opt/csw/gcc4/lib -R/opt/csw/lib -R/opt/csw/gcc4/lib -lsasl2 -lintl -lgss"
CFLAGS="-I/opt/csw/include"
CPPFLAGS="$CFLAGS"
CXXFLAGS="$CFLAGS"
LIBS="-lintl -liconv"
LD_LIBRARY_PATH=/opt/csw/lib

export AR
export CC
export CFLAGS
export CPPFLAGS
export CXXFLAGS
export LD
export export PATH
export PYTHON
export PYTHON_CONFIG
export LIBS
export LD_LIBRARY_PATH

#=== FUNCTION ================================================================
#        NAME:  configure
# DESCRIPTION:  Configures the software for compilation
#=============================================================================
configure ()
{
	cd ${SRCDIR} || exit 1
	echo "Running configure script..."
	/opt/csw/bin/gmake clean 1>/dev/null 2>/dev/null

	./configure \
		--prefix="${PREFIX}" \
		--sysconfdir=${PREFIX}/etc \
		--with-configdir=${PREFIX}/etc/samba \
		--with-logfilebase=/var/samba \
		--with-lockdir=/var/samba/locks \
		--with-piddir=/var/samba/locks \
		--with-privatedir=${PREFIX}/etc/samba/private \
		--with-winbind \
		--with-acl-support \
		--with-quotas \
		--with-ldap=/opt/csw \
		--with-krb5=/opt/csw \
		--with-libiconv=/opt/csw \
		--with-syslog \
		--with-utmp \
		--with-shared-modules=vfs_zfsacl,idmap_ldap,idmap_rid,idmap_ad,idmap_adex,idmap_hash,idmap_tdb2 \
		--enable-shared-libs=yes \
		--enable-shared=yes \
		--enable-socket-wrapper=yes \
		--enable-static=no \
		--disable-swat \
		--disable-external-libtalloc \
		--disable-external-libtdb

	[ $? -eq 0 ] || exit 1
}

#=== FUNCTION ================================================================
#        NAME:  file_depends
# DESCRIPTION:  Prints the depends file for the solaris package
#=============================================================================
file_depend ()
{
	cat <<-EOF
		P CSWlibintl8
		P CSWkrb5lib
		P CSWoldap
		P CSWsasl
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
	hacktomakeitwork
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

	# Haven't figured out how to work around this, so...
	PAUSE=0
	if /bin/test ! -e /opt/csw/lib/libintl.so ]; then
		echo
		echo "To make this work, you probably need to run:"
		echo "ln -s /opt/csw/lib/libintl.so.8 /opt/csw/lib/libintl.so"
		echo
		PAUSE=1
	fi

	if /bin/test ! -e /opt/csw/lib/libiconv.so ]; then
		echo
		echo "To make this work, you probably need to run:"
		echo "ln -s /opt/csw/lib/libiconv.so.8 /opt/csw/lib/libiconv.so"
		echo
		PAUSE=1
	fi

	if [ "$PAUSE" -eq 1 ]; then
		echo "Press Enter to continue or Ctrl-C to cancel..."
		read PAUSED
	fi
}

#=== FUNCTION ================================================================
#        NAME:  hacktomakeitwork
# DESCRIPTION:  http://web.archiveorange.com/archive/v/WEFLnF9YRDi0ckIbnaaG
#               Basically, samba on solaris is broken. all hail samba.
#=============================================================================
hacktomakeitwork ()
{
	cd ${SRCDIR} || exit 1
	sed -e 's/LIBNETAPI_LIBS=bin\/libnetapi.a/LIBNETAPI_LIBS=bin\/libnetapi.a -lintl/' \
	    -e 's/PAM_WINBIND_OBJ) -lpam/PAM_WINBIND_OBJ) -lpam -lintl/' \
	    Makefile > Makefile.1
	mv Makefile.1 Makefile
}

#=== FUNCTION ================================================================
#        NAME:  compile
# DESCRIPTION:  Compiles the software
#=============================================================================
compile ()
{
	echo "Compiling package..."
	cd ${SRCDIR} || exit 1
	/opt/csw/bin/gmake -j 17 || exit 1
}

#=== FUNCTION ================================================================
#        NAME:  package
# DESCRIPTION:  Creates a package for the software
#=============================================================================
package ()
{
	echo "Building package..."
	cd ${SRCDIR} || exit 1
	echo "Installing (fake) to ${STAGINGDIR}..."
	/opt/csw/bin/gmake DESTDIR="${STAGINGDIR}" install || exit 1
	echo "Calculating prototype..."

	cd "${PKGDIR}"

	mkdir -p ${STAGINGDIR}/var/samba/locks
	touch ${STAGINGDIR}/var/samba/locks/nmbd.pid
	touch ${STAGINGDIR}/var/samba/locks/smbd.pid

	mkdir -p ${STAGINGDIR}/${PREFIX}/var/svc/manifest/network
	file_smbd_manifest > ${STAGINGDIR}/${PREFIX}/var/svc/manifest/network/samba.xml
	file_nmbd_manifest > ${STAGINGDIR}/${PREFIX}/var/svc/manifest/network/wins.xml
	file_pkginfo     > ${PKGDIR}/pkginfo
	file_space       > ${PKGDIR}/space
	file_depend      > ${PKGDIR}/depend
	file_prototype   > ${PKGDIR}/prototype
	file_postinstall > ${PKGDIR}/postinstall
	file_preremove   > ${PKGDIR}/preremove

	PKGNAME="${PKGDIR}/${PKGNAME}-${PKGVERS}-`uname -s``uname -r`-`uname -p`-CAT.pkg"

	echo "Building to ${PKGNAME}.gz"
	pkgmk -o -d "${PKGBLDDIR}"

	pkgtrans "${PKGBLDDIR}" "${PKGNAME}" <<-EOF
	all
	EOF
	gzip -f "${PKGNAME}"

}

#=== FUNCTION ================================================================
#        NAME:  file_space
# DESCRIPTION:  Prints the space file for the solaris package
#=============================================================================
file_space ()
{
	cat <<-EOF
	EOF
}

#=== FUNCTION ================================================================
#        NAME:  file_checkinstall
# DESCRIPTION:  Prints the checkinstall file for the solaris package
#=============================================================================
file_checkinstall ()
{
	cat <<-EOF
	EOF
}

#=== FUNCTION ================================================================
#        NAME:  file_postinstall
# DESCRIPTION:  Prints the postinstall file for the solaris package
#=============================================================================
file_postinstall ()
{
	cat <<-EOF
		mkdir -p /var/samba/locks
		touch /var/samba/locks/nmbd.pid
		touch /var/samba/locks/smbd.pid
		/usr/sbin/svccfg import ${PREFIX}/var/svc/manifest/network/samba.xml
		/usr/sbin/svccfg import ${PREFIX}/var/svc/manifest/network/wins.xml
		/usr/sbin/svcadm disable -s svc:network/samba:cat
		/usr/sbin/svcadm disable -s svc:network/wins:cat
		exit 0
	EOF
}

#=== FUNCTION ================================================================
#        NAME:  file_preremove
# DESCRIPTION:  Prints the preremove file for the solaris package
#=============================================================================
file_preremove ()
{
	cat <<-EOF
		/usr/sbin/svcadm disable -s svc:network/samba:cat
		/usr/sbin/svcadm disable -s svc:network/wins:cat
		/usr/sbin/svccfg delete svc:network/samba:cat
		/usr/sbin/svccfg delete svc:network/wins:cat
		exit 0
	EOF
}

#=== FUNCTION ================================================================
#        NAME:  file_pkginfo
# DESCRIPTION:  Prints the pkginfo file for the solaris package
#=============================================================================
file_pkginfo ()
{
	cat <<-EOF
		PKG=CATsamba
		NAME=cat_samba
		ARCH=`uname -p`
		VERSION=${PKGVERS},REV=`date +%Y-%m-%d`
		CATEGORY=application
		VENDOR=The Samba Group
		EMAIL=support@cat.pdx.edu
		PSTAMP=Reid Vandewiele
		BASEDIR=${PREFIX}
		CLASSES=none
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
	echo "i postinstall"
	echo "i preremove"
	echo "i space"
	echo "i depend"
	(
		cd ${STAGINGDIR};
		pkgproto "${STAGINGDIR}/${PREFIX}=" > $TEMP
                sed  "s/${USER} ${GROUP}/root bin/" $TEMP
	)
	rm $TEMP
}

#=== FUNCTION ================================================================
#        NAME:  file_smbd_manifest
# DESCRIPTION:  Prints the service manifest file for smbd
#=============================================================================
file_smbd_manifest ()
{
	cat <<-EOF
		<?xml version="1.0"?>
		<!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">
		<service_bundle type='manifest' name='CATsamba:samba'>
		<service name='network/samba' type='service' version='1'>
		  <dependency name='net-loopback' grouping='require_any' restart_on='none' type='service'>
		    <service_fmri value='svc:/network/loopback' />
		  </dependency>
		  <dependency name='net-service' grouping='require_all' restart_on='none' type='service'>
		    <service_fmri value='svc:/network/service'/>
		  </dependency>
		  <dependency name='net-physical' grouping='require_all' restart_on='none' type='service'>
		    <service_fmri value='svc:/network/physical' />
		  </dependency>
		  <dependency name='filesystem-local' grouping='require_all' restart_on='none' type='service'>
		  <service_fmri value='svc:/system/filesystem/local' />
		  </dependency>
		  <dependent name='samba_multi-user-server' grouping='optional_all' restart_on='none'>
		    <service_fmri value='svc:/milestone/multi-user-server' />
		  </dependent>
		  <instance name='cat' enabled='true'>
		    <exec_method type='method' name='start' exec='${PREFIX}/sbin/smbd -D' timeout_seconds='170'>
		      <method_context>
		        <method_environment>
		          <envvar name="LD_LIBRARY_PATH" value="${PREFIX}/lib:/opt/csw/lib:/opt/csw/gcc4/lib:/lib:/usr/lib" />
		        </method_environment>
		      </method_context>
		    </exec_method>
		    <exec_method type='method' name='stop' exec='/usr/bin/kill \`cat /var/samba/locks/smbd.pid\`' timeout_seconds='60' />
		  </instance>
		  <stability value='Unstable' />
		  <template>
		    <common_name>
		      <loctext xml:lang='C'>
		      SMB file server
		      </loctext>
		    </common_name>
		    <documentation>
		      <manpage title='smbd' section='1m'
			  manpath='${PREFIX}/man' />
		      <manpage title='smb.conf' section='4'
			  manpath='${PREFIX}/man' />
		    </documentation>
		  </template>
		</service>
		</service_bundle>
	EOF
}

#=== FUNCTION ================================================================
#        NAME:  file_nmbd_manifest
# DESCRIPTION:  Prints the service manifest file for nmbd
#=============================================================================
file_nmbd_manifest ()
{
	cat <<-EOF
		<?xml version="1.0"?>
		<!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">
		<service_bundle type='manifest' name='CATsamba:wins'>
		<service name='network/wins' type='service' version='1'>
		  <dependency name='net-loopback' grouping='require_any' restart_on='none' type='service'>
		    <service_fmri value='svc:/network/loopback' />
		  </dependency>
		  <dependency name='net-service' grouping='require_all' restart_on='none' type='service'>
		    <service_fmri value='svc:/network/service'/>
		  </dependency>
		  <dependency name='net-physical' grouping='require_all' restart_on='none' type='service'>
		    <service_fmri value='svc:/network/physical' />
		  </dependency>
		  <dependency name='filesystem-local' grouping='require_all' restart_on='none' type='service'>
		  <service_fmri value='svc:/system/filesystem/local' />
		  </dependency>
		  <dependent name='wins_multi-user-server' grouping='optional_all' restart_on='none'>
		    <service_fmri value='svc:/milestone/multi-user-server' />
		  </dependent>
		  <instance name='cat' enabled='true'>
		    <exec_method type='method' name='start' exec='${PREFIX}/sbin/nmbd -D' timeout_seconds='170'>
		      <method_context>
		        <method_environment>
		          <envvar name="LD_LIBRARY_PATH" value="${PREFIX}/lib:/opt/csw/lib:/opt/csw/gcc4/lib:/lib:/usr/lib" />
		        </method_environment>
		      </method_context>
		    </exec_method>
		    <exec_method type='method' name='stop' exec='/usr/bin/kill \`cat /var/samba/locks/nmbd.pid\`' timeout_seconds='60' />
		  </instance>
		  <stability value='Unstable' />
		  <template>
		    <common_name>
		      <loctext xml:lang='C'>
		      SMB file server
		      </loctext>
		    </common_name>
		    <documentation>
		      <manpage title='nmbd' section='1m'
			  manpath='${PREFIX}/man' />
		      <manpage title='smb.conf' section='4'
			  manpath='${PREFIX}/man' />
		    </documentation>
		  </template>
		</service>
		</service_bundle>
	EOF
}


#-----------------------------------------------------------------------------
# Call main to start things rolling.
#-----------------------------------------------------------------------------
main "$@"
