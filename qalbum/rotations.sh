#! /bin/bash
# Usage: rotations.sh index
# Look though the picture description file index.xml for
# <original rotated="left"> or <original rotated="right">.
# If such an image PIC.jpg, if there is no corresponding PICt.jpg,
# generate it (using jpegtran to rotate it).
# Also update <full-image> in index.xml to use the rotated name.
# (Can also be invoked as: rotations.sh index PIC PIC.jpg ROT
# where ROT is 90 or 270;  however, this is only mean for internal use.)

group=${1:-index}
tmp=/tmp/$$
if test $# -ge 2 ;
then
  key=$2
  img=$3
  rot=$4
  rotimg=`echo $img | sed -e 's/\([^r]\)[.]j/\1r.j/'`
  if test ! -f $img ; then
    echo "$0: No such file:" $img ; exit -1
  else
echo img: $img rot: $rot rotimg: $rotimg
    if test -f $rotimg ; then
      echo $0: rotated image file $rotimg already exists
    else
      echo rotating $img by $rotdegrees yielding $rotimg
      jpegtran -rotate $rot -trim $img > $rotimg
    fi
    sed -e 's|<\([a-z-]*\)image[^>]*>'$img'</|<\1image>'$rotimg'</|' \
      <$group.xml >$tmp.tmp
    cat <$tmp.tmp >$group.xml
    rm $tmp.tmp
  fi
else
echo scanning to $tmp.xml
  scriptdir=$(dirname $(which $0))
  . $scriptdir/setup.sh
  xsltproc $scriptdir/rotations.xsl $group.xml \
    | grep rotated= \
    | sed -e 's|rotated="left"/>| 90|' -e 's|rotated="right"/>| 270|' \
      -e "s|<picture key=|$scriptdir/rotations.sh $group |" \
      -e "s|img=| |" >$tmp.sh
  sh $tmp.sh
#  rm $tmp.xml $tmp.sh
  $scriptdir/sizes.sh
fi


