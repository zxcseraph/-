/*
 *  Copyright(C) 2000 EASTCOM-BUPT Inc.
 *
 *  Filename            : $RCSfile: xmlexpatparser.h,v $
 *  Last Revision       : $Revision: 1.1 $
 *  Last Revision Date  : $Date: 2012/07/19 09:07:51 $
 *  Description         :
 */
/*********************************************************************
	FileName: xmlexpatparser.h
	Created Date: 12/09/02
	Modified History:

**********************************************************************/

#include <stdio.h>
#include "expat.h"

#define BUFSIZE 	   1024
#define ELECOUNT	   30
#define ATTRCOUNT      10
#define DATALENGTH     30

//using namespace std;

struct TCode1
{
public :
	TCode1()
	{
		length = 0;
		content = 0L;
	}
	int length;
	char* content;
};

class XmlExpatParser
{
public:

	~XmlExpatParser();
	XmlExpatParser();
	bool xmlParser(TCode1);
	char* findDatabyName(char* ElementName);
	char* findElementAttrbyName(char* ElementName, char* AttrName);
	char* findParent(char* ElementName);
	char* elementName[ELECOUNT];
	char* elementData[ELECOUNT];
	int elementParent[ELECOUNT];
	char* attrName[ELECOUNT][ELECOUNT];
	char* attrData[ELECOUNT][ELECOUNT];
	int eleNameCount,attrCount[ELECOUNT];

private:
	static void startElement(void* userData, const char* name,
		const char** atts);
	static void endElement(void* userData, const char* name);
	static void dataHandler(void* userData, const char* s, int len);
	void judgeParent();
	XML_Parser parser;
	int posName,posData,posAttr[ELECOUNT],elementDepth[ELECOUNT];
	int realData[ELECOUNT];
	bool start,data,end;
	int depth;
};
