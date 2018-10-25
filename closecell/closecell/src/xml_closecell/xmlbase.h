/*
 *  Copyright(C) 2000 EASTCOM-BUPT Inc.
 *
 *  Filename            : $RCSfile: xmlbase.h,v $
 *  Last Revision       : $Revision: 1.1 $
 *  Last Revision Date  : $Date: 2012/07/19 09:07:51 $
 *  Description         :
 */
/**************************************************************************
	FileName: xmlbase.h
	Description: The file provides the functions of pack XML information
	Created Date: 12/09/02
	Modified History:
****************************************************************************/
#ifndef _XMLBASE_H
#define _XMLBASE_H

#include <stdio.h>
#include <stdlib.h>
#include "dfp.hpp"
#include "inap.h"
#include "basic.h"

#define	  TagBegin		'<'
#define   TagEnd		'>'
#define	  TagValueTag		'='
#define	  TagInterval		' '
#define	  ValueLN		'\''
#define   ValueRN		'\''
#define   SpecialC		'/'


enum  XML_MessageType
{
	XMLRequest=1,
	XMLRespond,
	XMLNotify
};

#define  MsgMaxTagItemLength 	48
#define  MsgMaxContentLength    160
typedef  char			TXMLMsgTagItem[MsgMaxTagItemLength];
typedef  char			TXMLContentItem[MsgMaxContentLength+1];

#define  MaxRequestXMLNum     50 //20->50 added by ligy for ocs3.0 (4040)
#define  MaxRespondXMLNum     50 //20->50 added by ligy for ocs3.0 (4040)

_CLASSDEF(TXMLRespondMessageItem);
struct TXMLRespondMessageItem
{
	TXMLMsgTagItem		Tag;
	TXMLContentItem		Content;
};

_CLASSDEF(TXMLRespondMessage);
class TXMLRespondMessage : public TMsgPacket
{
   public:
	TXMLRespondMessageItem	xmlResItem[MaxRespondXMLNum];
	char			xmlMessageIND[2];
	int			xmlCSeqID;
        TCode Encode();
        TBool Decode(char*,int);
        void printcontent();//added by ligy for ocs3.0 (4040)
};

#endif
