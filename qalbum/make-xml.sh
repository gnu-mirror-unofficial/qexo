#! /bin/bash
# Usage make-xml.sh title file.jpg ...

if [ -f index.xml ] ; then
  echo "index.xml already exists"
  echo "manually do 'rm index.xml' if you don't want it"
  exit -1
fi

echo '<?xml version="1.0"?>' >index.xml
echo "<group>" >>index.xml
echo "<title>"${1}'</title>' >>index.xml
shift

for file ; do
  base=`basename $file .jpg`
  width=`rdjpgcom -verbose $file|sed -n -e 's#.* \([0-9][0-9]*\)w .*#\1#p'`
  height=`rdjpgcom -verbose $file|sed -n -e 's#.* \([0-9][0-9]*\)h,.*#\1#p'`
  echo >>index.xml
  echo '<picture id="'$base'">' >>index.xml
  if test '(' "$width" -le 700 ')' -a '(' "$height" -le 700 ')'
  then
    tag=image
  else
   tag=full-image
  fi
  echo file: $file width: $width height: $height tag: $tag
  echo "<$tag>$file</$tag>" >>index.xml
  echo "</picture>" >>index.xml
done

echo "</group>" >>index.xml

case "$0" in
  */*) scriptprefix=`dirname $0`/ ;;
  *) scriptprefix="" ;;
esac
${scriptprefix}sizes.sh


