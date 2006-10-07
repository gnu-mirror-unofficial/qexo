#KAWALIB = /home/bothner/kawa-bin
KAWALIB = /home/bothner/Kawa/unmodified
JAVA = java
JAVAC = javac
KAWA = CLASSPATH=$${KAWAJAR-$(KAWALIB)}:.. $(JAVA) kawa.repl
QEXO = $(KAWA) --xquery
QALBUM_PACKAGE_DIR = ../qalbum
QALBUM_PACKAGE_ROOT = ..
ExifExtractor_JAR = metadata-extractor-2.3.0.jar

all: \
  $(QALBUM_PACKAGE_DIR)/ImageInfo.class \
  $(QALBUM_PACKAGE_DIR)/PictureInfo.class \
  $(QALBUM_PACKAGE_DIR)/pictures.class \
  $(QALBUM_PACKAGE_DIR)/create.class \
  $(QALBUM_PACKAGE_DIR)/Thumbnail.class

sizes.class: sizes.xql
	scriptdir=`pwd`; ./setup.sh; \
	$(KAWA) --xquery --main -d .. -P qalbum. -C sizes.xql

$(QALBUM_PACKAGE_DIR)/create.class: $(QALBUM_PACKAGE_DIR)/create.java
	CLASSPATH="..:$(ExifExtractor_JAR)" $(JAVAC) -d $(QALBUM_PACKAGE_ROOT) $(QALBUM_PACKAGE_DIR)/create.java

$(QALBUM_PACKAGE_DIR)/Thumbnail.class: $(QALBUM_PACKAGE_DIR)/Thumbnail.java
	$(JAVAC) -d $(QALBUM_PACKAGE_ROOT) $(QALBUM_PACKAGE_DIR)/Thumbnail.java

$(QALBUM_PACKAGE_DIR)/ImageInfo.class: $(QALBUM_PACKAGE_DIR)/ImageInfo.java
	CLASSPATH="..:$(ExifExtractor_JAR)" $(JAVAC) -d $(QALBUM_PACKAGE_ROOT) $(QALBUM_PACKAGE_DIR)/ImageInfo.java

$(QALBUM_PACKAGE_DIR)/PictureInfo.class: $(QALBUM_PACKAGE_DIR)/PictureInfo.java
	CLASSPATH="..:$(ExifExtractor_JAR)" $(JAVAC) -d $(QALBUM_PACKAGE_ROOT) $(QALBUM_PACKAGE_DIR)/PictureInfo.java

$(QALBUM_PACKAGE_DIR)/pictures.class: pictures.xql
	scriptdir=`pwd`; ./setup.sh; \
	CLASSPATH=$${KAWAJAR-$(KAWALIB)}:..:$(ExifExtractor_JAR) \
	$(JAVA) kawa.repl --xquery --main -d .. -P qalbum. -C pictures.xql
