#
#  Copyright(C) 2000 EASTCOM-BUPT Inc.
#
#  Filename            : $RCSfile: makefile,v $
#  Last Revision       : $Revision: 1.4 $
#  Last Revision Date  : $Date: 2012/07/19 09:18:29 $
#  Description         :
#
###########################################################
#wing lines for AIX
.SUFFIXES:.c .C .cxx .cpp
CC=xlC_r
cc=xlC_r
#DEWARNING=+W829,749
CFLAGS= -q64 -qthreaded -O2 -g -w -I${INFDIR}/incl/esql -Iinclude  -Ixml_closecell -D_AIX -D_REENTRANT ${TMNREL} -DTRACE_LEVEL=1 -D_H_LOCALEDE -qrtti
CCFLAGS= ${CFLAGS} 
SYSNLIB= -lpthread -ltli  -lm -lrt -lc -ldl -brtl
LIB= -L${SYSNLIB}
LOCAL_PLACE=${HOME}/closecell/bin
#############################################################

SRC_C_XML =\
	xml_closecell/tinystr.C xml_closecell/tinyxml.C\
        xml_closecell/tinyxmlerror.C xml_closecell/tinyxmlparser.C

SRCCLOSECELL = \
          adjacent/main.C adjacent/operatestring.C  adjacent/base.C adjacent/closecell.C\
          adjacent/basestationstruct.C adjacent/closecellconfig.C

OBJXML = \
        $(SRC_C_XML:.C=.o)

OBJCLOSECELL = \
        $(SRCCLOSECELL:.C=.o) 

EXE = ${LOCAL_PLACE}/run

target:: ${EXE} 
	@echo "bep compile OK!"

${EXE}:: ${OBJXML} ${OBJCLOSECELL}
	${CC} -o ${EXE} ${CCFLAGS}  ${OBJXML} ${OBJCLOSECELL} ${LIB} 

clean:
	rm -f $(OBJXML) $(OBJCLOSECELL)  $(EXE)

all:
	rm -f $(OBJXML) $(OBJCLOSECELL)  $(EXE)
	@make

.cpp.o:
	$(CC) -o $@ -c $(CCFLAGS) $<
.C.o:
	$(CC) -o $@ -c $(CCFLAGS) $<

