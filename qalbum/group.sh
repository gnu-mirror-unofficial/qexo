#! /bin/bash
scriptdir=$(dirname $(which $0))
. $scriptdir/setup.sh
libdir=`sed -n -e 's/<group libdir="\(.*\)">/\1/p' <index.xml`
if test -n "$libdir" ; then true
elif test -f ../lib/picture.js; then libdir=../lib
elif test -f ../../lib/picture.js; then libdir=../../lib
elif test -f ../../../lib/picture.js; then libdir=../../../lib
else echo missing libdir; exit -1
fi
for file in picture.js group.js help.html; do
  test $scriptdir/$file -nt $libdir/$file && cp $scriptdir/$file $libdir/$file
done
  
for id in `sed -n -e 's/<picture id="\(.*\)">/\1/p' <index.xml`
do
  infofile="$id"-info.txt
  filename=`sed -n -e '/<picture id="'$id'">/,/<.picture>/s/<[a-z]*-*image[^>]*>\(.*[0-9]\)[tpr]*[.]jpg<[/].*image>/\1.jpg/p' <index.xml | uniq`
  echo '<pre>' >$infofile
  $JHEAD $filename >>$infofile
  echo '</pre>' >>$infofile
done

#$KAWA -xquery -f $scriptdir/pictures.xql
#(cd $scriptdir; $KAWA -xquery --main -C pictures.xql)
$JAVA -cp $scriptdir:${KAWAJAR} pictures libdir=$libdir

#export KAWAJAR=/tmp/kawa-1.6.99.jar
#CLASSPATH=$PICLIBDIR/exif/exifExtractor.jar $JAVA kawa.repl -xquery --debug-print-expr -f $scriptdir/pictures.xql
#CLASSPATH="$PICLIBDIR/exif:${KAWAJAR}:."
#export CLASSPATH
#echo CLASSPATH='"'$CLASSPATH'"'
#$JAVA kawa.repl -xquery --main -C $scriptdir/pictures.xql
#$JAVA pictures

rm -f *-info.txt
