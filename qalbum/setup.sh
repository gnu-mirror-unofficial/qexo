#! /bin/bash
scriptdir=$(dirname $(which $0))
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
#KAWAJAR=${KAWAJAR-/usr/local/lib/kawa.jar}
KAWAJAR=/Users/bothner/Kawa/build-head/kawa-1.7beta1.jar
KAWA="$JAVA -cp ${KAWAJAR} kawa.repl"

