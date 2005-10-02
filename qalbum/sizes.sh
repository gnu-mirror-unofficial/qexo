#! /bin/bash
# Updates the <image>, <full-image> and <small-image> tags in index.xml
# with width and height attributes extracted from the .jpg
# files listed in index.xml (using rdjpgcom to get the size).

index_file=${1-index}.xml
(for file in `sed -n  -e 's|<[^<>]*image[^>]*>\([^<]*\)</[^<>]*image>|\1|p' < $index_file` ; do
  echo -n \\%$file%s/'image[^>]*>/image'
  rdjpgcom -verbose $file | \
    sed -n -e 's#.* \([0-9][0-9]*\)w . \([0-9][0-9]*\)h.*# width="\1" height="\2">/#p'
done)>sizes.sed
sed -f sizes.sed <index.xml >/tmp/$$.index
#rm sizes.sed
mv /tmp/$$.index index.xml
