#! /bin/bash
if test -z "$1"
then cmd="$0"
else cmd="$1"
fi
scriptdir=$(dirname $(which $cmd))
PICLIBDIR=${scriptdir}

JAVA=${JAVA-java}
JAVAC=${JAVAC-javac}
if test -z "$JAVA_HOME"
then
  java_bindir=$(dirname $(type -p java))
  case "$java_bindir"
  */bin) JAVA_HOME=$(echo $java_bindir|sed sed 's|/bin$||')
  *) JAVA_HOME=/opt/JavaHome
  esac
fi
PATH=$JAVA_HOME/bin:$PATH

JHEAD=jhead
KAWAJAR=${KAWAJAR-${scriptdir}/kawa.jar}
KAWA="$JAVA -cp ${KAWAJAR} kawa.repl"

