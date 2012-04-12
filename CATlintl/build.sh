#!/bin/sh

wget http://www.sunfreeware.com/intel/10/libintl-3.4.0-sol10-x86-local.gz
mkdir old new
gunzip -f libintl-3.4.0-sol10-x86-local.gz
echo | pkgtrans libintl-3.4.0-sol10-x86-local old/
cp old/SMClintl/pkginfo ./
sed 's/\/usr\/local/\/opt\/sfw/' old/SMClintl/pkginfo > pkginfo

pkgproto `pwd`/old/SMClintl/reloc= > proto
echo i pkginfo=`pwd`/pkginfo | cat - proto > prototype
rm proto

pkgmk -o -d new
NAME="libintl-3.4.0,REV=`date +%Y-%m-%d`-`uname -s``uname -r`-`uname -p`-CAT.pkg"
echo | pkgtrans new/ $NAME
mv new/$NAME ./
gzip -f $NAME
