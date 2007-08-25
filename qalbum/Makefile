#KAWALIB = /home/bothner/kawa-bin
#KAWALIB = /home/bothner/Kawa/unmodified
KAWALIB = /home/pics/scripts/kawa.jar
JAVA = java
JAVAC = javac
KAWA = CLASSPATH=$${KAWAJAR-$(KAWALIB)}:.. $(JAVA) kawa.repl
JAR = jar
QEXO = $(KAWA) --xquery
QALBUM_PACKAGE_DIR = ../qalbum
QALBUM_PACKAGE_ROOT = ..
QALBUM_VERSION = 1.2
ExifExtractor_JAR = metadata-extractor-2.3.1.jar

all: qalbum qalbum-$(QALBUM_VERSION).jar qalbum-$(QALBUM_VERSION).tgz

qalbum-$(QALBUM_VERSION).jar: \
  $(QALBUM_PACKAGE_DIR)/ImageInfo.class \
  $(QALBUM_PACKAGE_DIR)/PictureInfo.class \
  $(QALBUM_PACKAGE_DIR)/pictures.class \
  $(QALBUM_PACKAGE_DIR)/create.class \
  $(QALBUM_PACKAGE_DIR)/qalbum.class \
  $(QALBUM_PACKAGE_DIR)/Thumbnail.class
	cd .. && $(JAR) cmf qalbum/jar-manifest qalbum/qalbum-$(QALBUM_VERSION).jar \
	  qalbum/ImageInfo.class \
	  qalbum/PictureInfo.class \
	  qalbum/pictures.class \
	  qalbum/create.class \
	  qalbum/qalbum.class \
	  qalbum/Thumbnail.class

CLASSPATH = "..:$(ExifExtractor_JAR):$(KAWALIB)"

DIST_FILES = index.html Makefile qalbum-$(QALBUM_VERSION).jar \
  $(ExifExtractor_JAR) \
  ImageInfo.java PictureInfo.java create.java Thumbnail.java \
  pictures.xql qalbum.in qalbum picture.js group.js help.html README

qalbum-$(QALBUM_VERSION).tgz: qalbum-$(QALBUM_VERSION).jar $(DIST_FILES)
	cd .. && tar czf qalbum/qalbum-$(QALBUM_VERSION).tgz \
          `for f in $(DIST_FILES); do echo qalbum/$$f; done`

$(QALBUM_PACKAGE_DIR)/qalbum.class: $(QALBUM_PACKAGE_DIR)/qalbum.java
	CLASSPATH=$(CLASSPATH) $(JAVAC) -d $(QALBUM_PACKAGE_ROOT) $(QALBUM_PACKAGE_DIR)/qalbum.java

$(QALBUM_PACKAGE_DIR)/create.class: $(QALBUM_PACKAGE_DIR)/create.java
	CLASSPATH=$(CLASSPATH) $(JAVAC) -d $(QALBUM_PACKAGE_ROOT) $(QALBUM_PACKAGE_DIR)/create.java

$(QALBUM_PACKAGE_DIR)/Thumbnail.class: $(QALBUM_PACKAGE_DIR)/Thumbnail.java
	CLASSPATH=$(CLASSPATH) $(JAVAC) -d $(QALBUM_PACKAGE_ROOT) $(QALBUM_PACKAGE_DIR)/Thumbnail.java

$(QALBUM_PACKAGE_DIR)/ImageInfo.class: $(QALBUM_PACKAGE_DIR)/ImageInfo.java
	CLASSPATH=$(CLASSPATH) $(JAVAC) -d $(QALBUM_PACKAGE_ROOT) $(QALBUM_PACKAGE_DIR)/ImageInfo.java

$(QALBUM_PACKAGE_DIR)/PictureInfo.class: $(QALBUM_PACKAGE_DIR)/PictureInfo.java
	CLASSPATH=$(CLASSPATH) $(JAVAC) -d $(QALBUM_PACKAGE_ROOT) $(QALBUM_PACKAGE_DIR)/PictureInfo.java

$(QALBUM_PACKAGE_DIR)/pictures.class: pictures.xql
	scriptdir=`pwd`; \
	CLASSPATH=$(CLASSPATH) \
	$(JAVA) kawa.repl --xquery --main -d .. -P qalbum. -C pictures.xql

qalbum: qalbum.in
	sed -e 's/@QALBUM_VERSION@/$(QALBUM_VERSION)/g' \
	  -e 's/@KAWA_JAR@/kawa.jar/g' <qalbum.in >qalbum
	chmod +x qalbum

clean:
	rm -f *.class qalbum*.jar qalbum*.tgz qalbum
