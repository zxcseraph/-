/*
 *  Copyright(C) 2000 EASTCOM-BUPT Inc.
 *
 *  Filename            : $RCSfile: xmlinterface.hpp,v $
 *  Last Revision       : $Revision: 1.1 $
 *  Last Revision Date  : $Date: 2012/07/19 09:07:51 $
 *  Description         :
 */
/**************************************************************************
	FileName: xmlinterface.hpp
	Description: The file is created to define the structure of xmlinterface SIB
	Created Date: 12/09/02
	Modified History:
****************************************************************************/
#ifndef _XMLINTERFACE_HPP
#define _XMLINTERFACE_HPP

#include <stdio.h>
#include <stdlib.h>

#ifndef _SIBSSD_HPP
    #include "sibssd.hpp"
#endif

#ifndef _XMLBASE_H
    #include "xmlbase.h"
#endif

#define  MaxTagItemLength 	48
typedef  char			TXMLTagItem[MaxTagItemLength];

struct TXMLLinkTab
{
	int			child;
	int			brother;
	int			layer;
};


struct TXMLTag
{
	TXMLTagItem		TagItem;
	int			cid_TagItem;
};

struct TXMLAttr
{
	int			cid_AttrTag;
	int			cid_AttrValue;
};

#define MaxXMLAttrNum	10
struct TXMLItem
{
	TXMLTag 		Tag;
	int			cid_MiscType;
	int			MiscType;
	TXMLAttr		xmlattr[MaxXMLAttrNum];
	int 			cid_Content;
};

struct TXMLItem1
{	
	TXMLTag                 tag;
	int 			cid_Content;
};


_CLASSDEF(TXMLInterface);
class TXMLInterface : public TSIBSSD
{
    public:
	TXMLInterface(FILE *fp,RTNomatch nomatch);
	~TXMLInterface();

	int 	toDo(PTSCSM,PTMsg);
	void 	list();
	int 	PackItem(PTSCSM pfsm,int ItemIndex,int Type);
	int	PackXML(PTSCSM pfsm,int ItemIndex);

	void* operator new(size_t sz);
	void  operator delete( void* );

    private:
    	char                    c_xmlsmscresult;
    	int                     cid_xmlsmscresult;
    	int                     xmlsmscresult;
    	int                     cid_messageID;    	
    	//added by ligy for ocs3.0 (4040) begin
    	int                     cid_notifymode;
    	char                    notifymode;
    	int                     cid_cseq;
    	int                     cid_msgtype; 
    	int                     cid_servicekey; 
    	//added by ligy for ocs3.0 (4040) end 
    	char			XMLSendingType;
    	int			requestItemNum;
    	TXMLItem		requestMessage[MaxRequestXMLNum];
    	int			respondItemNum;
    	TXMLItem1		respondMessage[MaxRespondXMLNum];
};


#endif

