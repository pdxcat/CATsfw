#!/bin/sh

USER=$USER
GROUP=`id | sed 's/.*gid=[0-9]*(\([^)]*\))/\1/'`

wget http://www.sunfreeware.com/intel/10/libintl-3.4.0-sol10-x86-local.gz
mkdir old new
gunzip -f libintl-3.4.0-sol10-x86-local.gz
echo | pkgtrans libintl-3.4.0-sol10-x86-local old/
cp old/SMClintl/pkginfo ./
sed -e 's/\/usr\/local/\/opt\/sfw/' -e 's/SMClintl/CATlintl/' old/SMClintl/pkginfo > pkginfo

pkgproto `pwd`/old/SMClintl/reloc= > prototype.1
sed "s/$USER $GROUP/root bin/" prototype.1 > prototype.2
echo i pkginfo=`pwd`/pkginfo | cat - prototype.2 > prototype
rm prototype.1 prototype.2

pkgmk -o -d new
NAME="libintl-3.4.0,REV=`date +%Y-%m-%d`-`uname -s``uname -r`-`uname -p`-CAT.pkg"
echo | pkgtrans new/ $NAME
mv new/$NAME ./
gzip -f $NAME
