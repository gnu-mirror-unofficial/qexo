#! /bin/bash
if test -z "$1"
then cmd="$0"
else cmd="$1"
fi
scriptdir=$(dirname $(which $cmd))
#JAVA_HOME=/opt/jdk1.3.1
JAVA_HOME=/opt/j2sdk1.4.1
PICLIBDIR=${scriptdir}
#JAVA=${JAVA_HOME}/bin/java
JAVA=${JAVA-java}
JAVAC=${JAVAC-javac}
#CLASSPATH=/home/bothner/Java/xalan_0_19_3D03/xalan.jar:/home/bothner/Java/xerces-1_0_1/xerces.jar:$CLASSPATH
#export CLASSPATH
#XSL="${JAVA} org.apache.xalan.xslt.Process"
JHEAD=jhead
#KAWAJAR=/Users/bothner/Kawa/build-head/kawa-1.7beta2.jar
KAWAJAR=${KAWAJAR-${scriptdir}/kawa.jar}
KAWA="$JAVA -cp ${KAWAJAR} kawa.repl"

