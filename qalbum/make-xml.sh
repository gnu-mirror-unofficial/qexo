#! /bin/bash
# Usage make-xml.sh title file.jpg ...
scriptdir=$(dirname $(which $0))
. $scriptdir/setup.sh
exec $JAVA -cp $scriptdir:${KAWAJAR}:$scriptdir/.. qalbum.create "$@"
exit -1
