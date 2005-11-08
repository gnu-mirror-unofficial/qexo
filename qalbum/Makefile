KAWALIB = /home/bothner/kawa-bin
JAVA = java
JAVAC = javac
KAWA = CLASSPATH=$${KAWAJAR-$(KAWALIB)}:. $(JAVA) kawa.repl
QEXO = $(KAWA) --xquery
QALBUM_PACKAGE_DIR = ../qalbum
QALBUM_PACKAGE_ROOT = ..

all: sizes.class pictures.class

sizes.class: sizes.xql
	$(QEXO) --main -C sizes.xql

$(QALBUM_PACKAGE_DIR)/create.class: $(QALBUM_PACKAGE_DIR)/create.java
	$(JAVAC) -d $(QALBUM_PACKAGE_ROOT) $(QALBUM_PACKAGE_DIR)/create.java

pictures.class: pictures.xql
	scriptdir=`pwd`; \
	. ./setup.sh; \
	$(KAWA) --xquery --main -C pictures.xql
