/*
 *  Copyright(C) 2000 EASTCOM-BUPT Inc.
 *
 *  Filename            : $RCSfile: xmlexpatparser.C,v $
 *  Last Revision       : $Revision: 1.1 $
 *  Last Revision Date  : $Date: 2012/07/19 09:07:51 $
 *  Description         :
 */
#include "xmlexpatparser.h"

#include <string>

XmlExpatParser::XmlExpatParser()
{
	start = false;
	end = false;
	data = false;

	posName = 0;
	posData = -1;

	for (int i = 0; i < ELECOUNT; i++)
	{
		posAttr[i] = 0;
		elementDepth[i] = 0;
		elementParent[i] = 0;
		realData[i] = -1;
	}
	depth = 0;

#ifndef _HP_UX_	
	for (int i = 0; i < ELECOUNT; i++)
#else
        for (i = 0; i < ELECOUNT; i++)
#endif
	{
		elementName[i] = NULL;
		elementData[i] = NULL;
	}

#ifndef _HP_UX_	
	for (int i = 0; i < ELECOUNT; i++)
#else
        for (i = 0; i < ELECOUNT; i++)
#endif
		for (int j = 0; j < ELECOUNT; j++)
		{
			attrName[i][j] = NULL;
			attrData[i][j] = NULL;
		}
}

XmlExpatParser::~XmlExpatParser()
{
	for (int i = 0; i < ELECOUNT; i++)
	{
		if (elementName[i] != NULL)
			delete elementName[i];
		if (elementData[i] != NULL)
			delete elementData[i];
	}

#ifndef _HP_UX_	
	for (int i = 0; i < ELECOUNT; i++)
#else
        for (i = 0; i < ELECOUNT; i++)
#endif
		for (int j = 0; j < ELECOUNT; j++)
		{
			if (attrName[i][j] != NULL)
				delete attrName[i][j];

			if (attrData[i][j] != NULL)
				delete attrData[i][j];
		}
}

bool XmlExpatParser::xmlParser(TCode1 code)
{
	char buf[BUFSIZE];
	int done;

	start = false;
	end = false;
	data = false;

	posName = 0;
	posData = -1;
	depth = 0;


	parser = XML_ParserCreate(NULL);
	XML_SetUserData(parser, this);
	XML_SetElementHandler(parser,
		(XML_StartElementHandler) startElement,
		endElement);
	XML_SetCharacterDataHandler(parser, dataHandler);


	if (!XML_Parse(parser, code.content, code.length, 0))
	{
		fprintf(stderr,
			"%s at line %d\n",
			XML_ErrorString(XML_GetErrorCode(parser)),
			XML_GetCurrentLineNumber(parser));
		return false;
	}

	eleNameCount = posName;

	for (int i = 0; i < posName; i++)
	{
		attrCount[i] = posAttr[i];
	}

#ifndef _HP_UX_	
	for (int i = 0; i < eleNameCount; i++)
#else
        for (i = 0; i < eleNameCount; i++)
#endif
	{
		if (realData[i] == -1)
		{
			if (elementData[i] != NULL)
			{
				delete elementData[i];
				elementData[i] = NULL;
			}
		}
	}

	XML_ParserFree(parser);
	return true;
}

void XmlExpatParser::startElement(void* userData, const char* name,
	const char** atts)
{
	XmlExpatParser* ParserTemp = (XmlExpatParser*) userData;

	ParserTemp->depth += 1;

	ParserTemp->start = true;
	ParserTemp->elementName[ParserTemp->posName] = new char[strlen(name) + 1];
	memcpy(ParserTemp->elementName[ParserTemp->posName],
		name,
		strlen(name) + 1);


	//printf("The ParserTemp->depth is %d; And The ParserTemp->elementName[ParserTemp->posName] is %s;\n",ParserTemp->depth,name);
	ParserTemp->elementDepth[ParserTemp->posName] = ParserTemp->depth;

	ParserTemp->judgeParent();
	bool attr = false;
	for (int i = 0; atts[i]; i += 2)
	{
		//printf("The atts[%d] is %s;\n",i,atts[i]);
		//printf("The atts[%d] is %s;\n",i+1,atts[i+1]);

		attr = true;
		ParserTemp->attrName[ParserTemp->posName][ParserTemp->posAttr[ParserTemp->posName]] = new char[strlen(atts[i])+1];
		ParserTemp->attrData[ParserTemp->posName][ParserTemp->posAttr[ParserTemp->posName]] = new char[strlen(atts[i + 1])+1];
		memcpy(ParserTemp->attrName[ParserTemp->posName][ParserTemp->posAttr[ParserTemp->posName]],
			atts[i],
			strlen(atts[i])+1);
		memcpy(ParserTemp->attrData[ParserTemp->posName][ParserTemp->posAttr[ParserTemp->posName]],
			atts[i + 1],
			strlen(atts[i + 1])+1);

		ParserTemp->posAttr[ParserTemp->posName]++;
	}

	ParserTemp->posName++;
}

void XmlExpatParser::endElement(void* userData, const char* name)
{
	XmlExpatParser* ParserTemp = (XmlExpatParser*) userData;

	ParserTemp->depth -= 1;

	if (ParserTemp->start && ParserTemp->data)
		ParserTemp->realData[ParserTemp->posName - 1] = 1;

	ParserTemp->end = false;
	ParserTemp->data = false;
}

void XmlExpatParser::dataHandler(void* userData, const char* s, int len)
{
	XmlExpatParser* ParserTemp = (XmlExpatParser*) userData;

	ParserTemp->data = true;

	if (ParserTemp->posName != ParserTemp->posData)
	{
		ParserTemp->elementData[ParserTemp->posName - 1] = new char[len];
		memcpy(ParserTemp->elementData[ParserTemp->posName - 1], s, len);
	}
	ParserTemp->posData = ParserTemp->posName;
}

char* XmlExpatParser::findDatabyName(char* ElementName)
{
	bool find = false;
	int j = 0;

	for (int i = 0; i < eleNameCount; i++)
	{
		if (strcmp(elementName[i], ElementName) == 0)
		{
			find = true;
			j = i;
			break;
		}
	}
	if (find)
	{
		return (char *) elementData[j];
	}
	else
	{
		return NULL;
	}
}

char* XmlExpatParser::findElementAttrbyName(char* ElementName, char* AttrName)
{
	bool find = false;
	int p = 0,q = 0;

	for (int i = 0; i < eleNameCount; i++)
	{
		if (strcmp(elementName[i], ElementName) == 0)
		{
			find = true;
			p = i;
			break;
		}
	}
	if (find)
	{
		find = false;
		for (int i = 0; i < attrCount[p]; i++)
		{
			if (strcmp(attrName[p][i], AttrName) == 0)
			{
				find = true;
				q = i;
				break;
			}
		}
	}

	if (find)
	{
		return attrData[p][q];
	}
	else
	{
		return NULL;
	}
}

void XmlExpatParser::judgeParent()
{
	if (posName == 0)
	{
		elementParent[posName] = -1;
		return;
	}
	for (int i = posName; i > 0; i--)
	{
		if ((depth - elementDepth[i]) == 1)
		{
			elementParent[posName] = i;
			break;
		}
	}
}

char* XmlExpatParser::findParent(char* ElementName)
{
	int q = 0,p = 0;
	bool find = false;

	for (int i = 0; i < eleNameCount; i++)
	{
		if (strcmp(elementName[i], ElementName) == 0)
		{
			find = true;
			q = i;
			break;
		}
	}

	if (find)
	{
		p = elementParent[q];
		return elementName[p];
	}
	else
	{
		return NULL;
	}
}
