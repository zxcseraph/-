/*
 *  Copyright(C) 2000 EASTCOM-BUPT Inc.
 *
 *  Filename            : $RCSfile: xmlinterface.C,v $
 *  Last Revision       : $Revision: 1.1 $
 *  Last Revision Date  : $Date: 2012/07/19 09:07:51 $
 *  Description         :
 */
static const char rcs_id[] = "$Id: xmlinterface.C,v 1.1 2012/07/19 09:07:51 scf Exp $";
/**************************************************************************
	FileName: xmlinterface.C
	Description: The file is defined to provide the SIB for SLP
	Created Date: 12/09/02
	Modified History:
****************************************************************************/
#include "xmlinterface.hpp"
#include "scsm.hpp"
#include "base.hpp"
#include "func.h"
//#include "feam.hpp"
#include "newfeam.h"
#include "smppmsg.hpp"
#include "command.h" //added by ligy for ocs3.0 (4040)

extern TCommandTable* cmdManageTable;//added by ligy for ocs3.0 (4040)

TXMLInterface::TXMLInterface(FILE *fp,RTNomatch nomatch)
{
   fread((char*)(&c_xmlsmscresult),sizeof(char),1,fp);
   if (c_xmlsmscresult!=0)
   {
	fread((char*)(&cid_xmlsmscresult),sizeof(int),1,fp);
	fread((char*)(&xmlsmscresult),sizeof(int),1,fp);
	fread((char*)(&cid_notifymode),sizeof(int),1,fp); //added by ligy for ocs3.0 (4040)
	fread((char*)(&notifymode),sizeof(char),1,fp); //added by ligy for ocs3.0 (4040)
	fread((char*)(&cid_cseq),sizeof(int),1,fp); //added by ligy for ocs3.0 (4040)
	fread((char*)(&cid_msgtype),sizeof(int),1,fp); //added by ligy for ocs3.0 (4040)
	fread((char*)(&cid_servicekey),sizeof(int),1,fp); //added by ligy for ocs3.0 (4040)
   }
   fread((char*)(&cid_messageID),sizeof(int),1,fp);
   fread((char*)(&XMLSendingType),sizeof(char),1,fp);
   fread((char*)(&requestItemNum),sizeof(int),1,fp);
   if (requestItemNum>MaxRequestXMLNum)
   {
	nomatch=DATAERR;
	return;
   }
   int i;
   for (i=0;i<requestItemNum;i++)
	fread((char*)(&requestMessage[i]),sizeof(TXMLItem),1,fp);

   fread((char*)(&respondItemNum),sizeof(int),1,fp);
   //if (requestItemNum>MaxRespondXMLNum)
   if (respondItemNum>MaxRespondXMLNum)
   {
	nomatch=DATAERR;
	return;
   }
   for (i=0;i<respondItemNum;i++)
       fread((char*)&(respondMessage[i]),sizeof(TXMLItem1),1,fp);


   //list();
   nomatch=RET_SUCCESS;
   return;
}

TXMLInterface::~TXMLInterface()
{
}

char Content[128],XMLITEM[1024];
#define WHOLE 0
#define BEGIN 1
#define END   2
#define CIC   1
#define MPP   2


TXMLLinkTab	xmllink[MaxRequestXMLNum];

int TXMLInterface::PackItem(PTSCSM pfsm,int ItemIndex,int Type)
{
   char tempTagItem[MaxTagItemLength+1];
   PTDFPData pdfpItem;
   TDFPDataElement ItemContent;
   memset(tempTagItem,0,sizeof(tempTagItem));

   if (requestMessage[ItemIndex].Tag.cid_TagItem!=InvalidCCB)
   {
   	pdfpItem=pfsm->getCCBValue(requestMessage[ItemIndex].Tag.cid_TagItem,0,0);
	if(pdfpItem==NULL)
	{
		pfsm->errorLog("XML SIB Error, Tag.cid_TagItem's Value==NULL");
		return CCBError;
	}
	memcpy(tempTagItem,&(pdfpItem->dfpDataElement.octetElement),sizeof(TXMLTagItem));
	delete pdfpItem;
   }
   else memcpy(tempTagItem,requestMessage[ItemIndex].Tag.TagItem,sizeof(TXMLTagItem));

   pdfpItem=pfsm->getCCBValue(requestMessage[ItemIndex].cid_Content,0,0);
   if(pdfpItem==NULL)
   {
	pfsm->errorLog("XML SIB Error, cid_Content's Value==NULL");
	return CCBError;
   }
   strcpy(ItemContent.octet161Element,pdfpItem->dfpDataElement.octet161Element);
   delete pdfpItem;

   int AttrNum=0,ItemCount;
   switch (Type)
   {
   	case WHOLE:
   	     for (ItemCount=xmllink[0].layer;ItemCount<xmllink[ItemIndex].layer;ItemCount++) strcat(XMLITEM,"\t");
   	     sprintf(Content,"<%s",tempTagItem);
   	     strcat(XMLITEM,Content);
   	     while (AttrNum<MaxAttrNum)
   	     {
   	     	if (requestMessage[ItemIndex].xmlattr[AttrNum].cid_AttrTag==InvalidCCB) break;
   	     	pdfpItem=pfsm->getCCBValue(requestMessage[ItemIndex].xmlattr[AttrNum].cid_AttrTag,0,0);
   		if(pdfpItem==NULL)
   		{
			pfsm->errorLog("XML SIB Error, cid_AttrTag's Value==NULL");
			return CCBError;
   		}
   		sprintf(Content," %s = ",pdfpItem->dfpDataElement.octet161Element);
   		//printf("The AttrNum is %d;The AttrTag is %s;\n",AttrNum,pdfpItem->dfpDataElement.octet161Element);
   	        strcat(XMLITEM,Content);
   		delete pdfpItem;

   		pdfpItem=pfsm->getCCBValue(requestMessage[ItemIndex].xmlattr[AttrNum].cid_AttrValue,0,0);
   		if(pdfpItem==NULL)
   		{
			pfsm->errorLog("XML SIB Error, cid_AttrValue's Value==NULL");
			return CCBError;
   		}
   		sprintf(Content,"'%s\'",pdfpItem->dfpDataElement.octet161Element);
   		//printf("The AttrContent is %s;\n",pdfpItem->dfpDataElement.octet161Element);
   	        strcat(XMLITEM,Content);
   		delete pdfpItem;
   		AttrNum++;
   	     }
   	     if (strcmp(ItemContent.octet161Element,"")==0) sprintf(Content,"/>\n");
   	     else sprintf(Content,">%s</%s>\n",ItemContent.octet161Element,tempTagItem);
   	     strcat(XMLITEM,Content);
   	     break;

   	case BEGIN:
   	     for (ItemCount=xmllink[0].layer;ItemCount<xmllink[ItemIndex].layer;ItemCount++) strcat(XMLITEM,"\t");
   	     sprintf(Content,"<%s",tempTagItem);
   	     strcat(XMLITEM,Content);
   	     while (AttrNum<MaxAttrNum)
   	     {
   	     	if (requestMessage[ItemIndex].xmlattr[AttrNum].cid_AttrTag==InvalidCCB) break;
   	     	pdfpItem=pfsm->getCCBValue(requestMessage[ItemIndex].xmlattr[AttrNum].cid_AttrTag,0,0);
   		if(pdfpItem==NULL)
   		{
			pfsm->errorLog("XML SIB Error, cid_AttrTag's Value==NULL");
			return CCBError;
   		}
   		sprintf(Content," %s = ",pdfpItem->dfpDataElement.octet161Element);
   	        strcat(XMLITEM,Content);
   		delete pdfpItem;

   		pdfpItem=pfsm->getCCBValue(requestMessage[ItemIndex].xmlattr[AttrNum].cid_AttrValue,0,0);
   		if(pdfpItem==NULL)
   		{
			pfsm->errorLog("XML SIB Error, cid_AttrValue's Value==NULL");
			return CCBError;
   		}
   		sprintf(Content,"'%s'",pdfpItem->dfpDataElement.octet161Element);
   	        strcat(XMLITEM,Content);
   		delete pdfpItem;
   		AttrNum++;
   	     }
   	     strcat(XMLITEM,">\n");
   	     break;

   	case END:
   	     for (ItemCount=xmllink[0].layer;ItemCount<xmllink[ItemIndex].layer;ItemCount++) strcat(XMLITEM,"\t");
   	     sprintf(Content,"</%s>\n",tempTagItem);
   	     strcat(XMLITEM,Content);
   	     break;

	default:
	     SCFERROR("XML SIB:When Packing XML Item,The Type Is Unknown");
	     break;
   }
   return 0;
}

int TXMLInterface::PackXML(PTSCSM pfsm,int ItemIndex)
{
   if (xmllink[ItemIndex].child==-1)
     {
     	//printf("The Content is %d&&       &&%d;\n",ItemIndex,ItemIndex);
     	if (PackItem(pfsm,ItemIndex,WHOLE)<0) return CCBError;
     	if (xmllink[ItemIndex].brother!=-1)
     		  PackXML(pfsm,xmllink[ItemIndex].brother);
     }
   else
   {
     //printf("The Content is %d;\n",ItemIndex);
     if (PackItem(pfsm,ItemIndex,BEGIN)<0) return CCBError;
     PackXML(pfsm,xmllink[ItemIndex].child);
     //printf("The Content is %d;\n",ItemIndex);
     if (PackItem(pfsm,ItemIndex,END)<0) return CCBError;
     if (xmllink[ItemIndex].brother!=-1)
     		  PackXML(pfsm,xmllink[ItemIndex].brother);
   }
   return 0;
}

//extern  TFEAM 	*scfFEAM;
extern TNEWFEAM* scfFEAM;
extern  int 	scfID;


#define WaitingForRespond -1
#define SendRespondingMes -2
#define WaitingForRespondTimer  30

int TXMLInterface::toDo(PTSCSM pfsm,PTMsg pmsg)
{

   if (((pmsg->msgID==inter_XMLRequest)||(pmsg->msgID==inter_smsctrigger))&&(pmsg->msgType==Internal))
   {
   	    if(pmsg->pMsgPara==NULL)
              	return CCBError;

	    PTXMLRespondMessage pArg;
	    pArg=(PTXMLRespondMessage)(pmsg->pMsgPara);

	    int itemnum,itemcycle,memcmplen,copylen;
	    TDFPDataElement dfpDE0,dfpDE1;
	    PTDFPData pdfp;
	    char tempTag[sizeof(TXMLMsgTagItem)+1],tempTag1[sizeof(TDFPDataElement)+1];

	    pfsm->xmlCSeqID=pArg->xmlCSeqID;
	    pfsm->xmlEntityID=pArg->xmlMessageIND[0];
	    //printf("The xmlCSeqID is %d;The xmlEntityID is %d;\n",pfsm->xmlCSeqID,pfsm->xmlEntityID);
	    
	    int  notnull[MaxRespondXMLNum]; 
	    for (itemnum = 0; itemnum < MaxRespondXMLNum; itemnum++)  notnull[itemnum] = 0;		    
	    for (itemnum=0;itemnum<MaxRespondXMLNum;itemnum++)
	    {
	      if (pArg->xmlResItem[itemnum].Tag[0]==NULL) break;

	      if (strlen(pArg->xmlResItem[itemnum].Tag)<sizeof(TXMLMsgTagItem))
	     	   strcpy(tempTag,pArg->xmlResItem[itemnum].Tag);
	      else 
	      {
	     	   memcpy(tempTag,pArg->xmlResItem[itemnum].Tag,sizeof(TXMLMsgTagItem));
	     	   tempTag[sizeof(TXMLMsgTagItem)]=0;
	      }

	      for (itemcycle = 0; itemcycle < respondItemNum; itemcycle++)
	      {
		  if (respondMessage[itemcycle].tag.cid_TagItem != InvalidCCB)
		  {
		 	pdfp = pfsm->getCCBValue(respondMessage[itemcycle].tag.cid_TagItem,0, 0);
			if (pdfp == NULL)
			{
			   pfsm->errorLog("XML SIB Error, Respond.cid_Tag's Value==NULL");
			   return CCBError;
			}
			memcpy(tempTag1, pdfp->dfpDataElement.digitsElement,sizeof(TDFPDataElement));
			tempTag1[sizeof(TDFPDataElement)] = 0;
			delete pdfp;
		   }
		   else
		   {
			strcpy(tempTag1, respondMessage[itemcycle].tag.TagItem);
		   }
		   //printf("The respondMessage[%d].Tag.TagItem is %s;\n",itemcycle,respondMessage[itemcycle].Tag.TagItem);
		   //printf("The respondMessage[%d].Tag.TagItem is %s;The tempTag is %s;The tempTag1 is %s;\n",itemcycle,respondMessage[itemcycle].Tag.TagItem,tempTag,tempTag1);
		   if ((strcmp(tempTag, tempTag1) == 0) &&
			(respondMessage[itemcycle].cid_Content != InvalidCCB) &&
			(notnull[itemcycle] == 0))
		   {
			notnull[itemcycle]++;		
			memcpy(dfpDE1.digitsElement,pArg->xmlResItem[itemnum].Content,copylen = sizeof(TXMLContentItem));
			//printf("The equal respondMessage[%d].tag.TagItem is %s;\n",itemcycle, respondMessage[itemcycle].tag.TagItem);
			if (strlen(pArg->xmlResItem[itemnum].Content) <sizeof(TXMLContentItem))
			   copylen = strlen(pArg->xmlResItem[itemnum].Content);
	//		printf("respondMessage[%d] Content is %s\n", itemcycle,dfpDE1.digitsElement); 
			if (pfsm->putCCBValue(dfpDE1,respondMessage[itemcycle].cid_Content, 0,0, 0) == Wrong)
			{
			     pfsm->errorLog("XML SIB PutCCBValue Error: respondMessage's cid_Content");
			     return CCBError;
			}
			break;
		    }				
		}
	    }
	pfsm->putSIBState(SIBIdle);
    	delete pmsg;
    	return SIBExit1;
   }

   int sibState=pfsm->getSIBState();

   TCode		finalCode;
   switch (sibState)
   {
    case SIBIdle:
	 delete pmsg;

	 PTDFPData 	pdfp;
	 
	 int 		i,j;

	 if (c_xmlsmscresult!=0)
	 {
	    TSMPPMsg *pMsg;
            pMsg=new TSMPPMsg(DELEVER_SM_XML_RESP);
            //pMsg->header->command_id=DELEVER_SM_XML_RESP;
            //pMsg->header->dlg_headbyte=pfsm->dlg_headbyte;
            pMsg->header->smsc_id=pfsm->smsc_id;
            pMsg->header->sequence_no=pfsm->sequence_no;
            
            TDELIVER_SM_XML_RESP_Body *pBody;
   	    pBody=( TDELIVER_SM_XML_RESP_Body*)pMsg->body;
   	    
	    if (cid_xmlsmscresult==InvalidCCB)
	    {	                 
               pMsg->header->command_status=xmlsmscresult;              
	    }
	    else
	    {
	       pdfp=pfsm->getCCBValue(cid_xmlsmscresult,0,0);
	       if(pdfp==NULL)
	       {
		  pfsm->errorLog("XML SIB Error, xmlsmscresult's Value==NULL");
		  return CCBError;
	       }
	       pMsg->header->command_status=pdfp->dfpDataElement.integerElement;
	       delete pdfp;
	    }	  
	    
	    if (cid_messageID!=InvalidCCB)
	    {
	        pdfp=pfsm->getCCBValue(cid_messageID,0,0);
	        if(pdfp==NULL)
	        {
		  pfsm->errorLog("XML SIB Error, messageID's Value==NULL");
		  return CCBError;
	        }
	        sscanf(pdfp->dfpDataElement.octet20Element,"%llx",&(pBody->Msg_Id));
	        delete pdfp;//for 1396+
	    }
	    else   pBody->Msg_Id=0;
	    //added by ligy for ocs3.0 (4040) begin
	    if (cid_notifymode==InvalidCCB)
	    {
	    	pBody->notify_mode=notifymode;
	    }
	    else
	    {
	    	pdfp=pfsm->getCCBValue(cid_notifymode,0,0);
	        if(pdfp==NULL)
	        {
		   pfsm->errorLog("XML SIB Error, notifymode's Value==NULL");
		   return CCBError;
	        }
	        memcpy(&(pBody->notify_mode),&(pdfp->dfpDataElement.octetElement),1);
	        delete pdfp;	    	
	    }
	    if (cid_cseq!=InvalidCCB)
	    {
	        pdfp=pfsm->getCCBValue(cid_cseq,0,0);
	        if(pdfp==NULL)
	        {
		  pfsm->errorLog("XML SIB Error, cseq's Value==NULL");
		  return CCBError;
	        }
	        pBody->cseq=pdfp->dfpDataElement.integerElement;
	        delete pdfp;
	    }
	    if (cid_msgtype!=InvalidCCB)
	    {
	        pdfp=pfsm->getCCBValue(cid_msgtype,0,0);
	        if(pdfp==NULL)
	        {
		  pfsm->errorLog("XML SIB Error, msgtype's Value==NULL");
		  return CCBError;
	        }
	        memcpy(&(pBody->msgtype),&(pdfp->dfpDataElement.octetElement),1);
	        delete pdfp;
	    }
	    if (cid_servicekey!=InvalidCCB)
	    {
	        pdfp=pfsm->getCCBValue(cid_servicekey,0,0);
	        if(pdfp==NULL)
	        {
		  pfsm->errorLog("XML SIB Error, servicekey's Value==NULL");
		  return CCBError;
	        }
	        memcpy(pBody->servicekey,&(pdfp->dfpDataElement.octetElement),2);
	        delete pdfp;
	    }
	    if(cmdManageTable->displaySMMsg==Right)
	    	pBody->printcontent();   	    
	    //added by ligy for ocs3.0 (4040) end
	    scfFEAM->sendToSMSC(pMsg->Encode());
            delete pMsg;   
	 }
	 
	 if (requestItemNum!=0)
	 {
	     for (i=0;i<requestItemNum;i++)
	     {
	 	xmllink[i].child=-1;
	 	xmllink[i].brother=-1;
	 	if (requestMessage[i].cid_MiscType!=InvalidCCB)
	        {
	          pdfp=pfsm->getCCBValue(requestMessage[i].cid_MiscType,0,0);
	     	  if(pdfp==NULL)
		   {
			pfsm->errorLog("XML SIB Error, Tag.cid_TagItem's Value==NULL");
			return CCBError;
		    }
	     	  xmllink[i].layer=pdfp->dfpDataElement.integer4Element/10000;
	     	  delete pdfp;
	     	}
	     	else xmllink[i].layer=requestMessage[i].MiscType/10000;
	     }

	     for (i=0;i<requestItemNum-1;i++)
	     {
	        if (xmllink[i+1].layer>xmllink[i].layer)
	     		xmllink[i].child=i+1;
	        else if (xmllink[i+1].layer==xmllink[i].layer)
	     		xmllink[i].brother=i+1;
	        else {
	     	   if (i==0) { SCFERROR("XML SIB The Layer Depth Of No.%d Tag Is InCorrect",i); return CCBError;}
	     	   for (j=i-1;j>=0;j--)
	     		{
	     			//printf("The xmllink[%d]'s Layer is %d;\n",j,xmllink[j].layer);
	     			if (xmllink[j].layer==xmllink[i+1].layer)
	     			{
	     			  xmllink[j].brother=i+1;
	     			  break;
	     			}
	     			else if (xmllink[j].layer<xmllink[i+1].layer)
	     			{
	     			  SCFERROR("XML SIB Error:The Structure Of The XML Items Is Disordered");
	     			  return CCBError;
	     			 }
	     		}

	     	   if (j==-1){
	     	   	 SCFERROR("Can not Find The Tag In Same Layer Depth ;The Number Of Tag is %d Since 0;And The Depth is %d;",i+1,xmllink[i+1].layer);
	     	   	 return CCBError;
	     	   	}
	     	   }
	     //printf("The xmllink[%d]'s child and brother is Child:%d\tBrother:%d;\n",i,xmllink[i].child,xmllink[i].brother);
	     }
	     
   //for (i=0;i<requestItemNum;i++)
     //printf("The xmllink[%d]'s Layer, child and brother is Layer:%d\tChild:%d\tBrother:%d;\n",i,xmllink[i].layer,xmllink[i].child,xmllink[i].brother);

   //XMLITEM.rdbuf()->freeze(0);//For Initiation
             XMLITEM[0]=0;
             if ((j=PackXML(pfsm,0))<0) return j;
   //XMLITEM<<ends;
             printf("The XML DTD is \n%s\n",XMLITEM);


   //for (i=0;i<requestItemNum;i++)
   //printf("The xmllink[%d]'s child and brother is Child:%d\tBrother:%d;\n",i,xmllink[i].child,xmllink[i].brother);



	 /**********************************************************************************************/
	     char tempchar[12];
	     //printf("The scfID is %d;\n",scfID);
	     if ((unsigned char)XMLSendingType%100==XMLRespond)
	     {
	 	sprintf(tempchar,"%d",(unsigned)(pfsm->xmlCSeqID));
	 	finalCode.length=3+strlen(tempchar)+strlen(XMLITEM);
	 	finalCode.content=new char[finalCode.length+1];
	 	finalCode.content[0]=pfsm->xmlEntityID;
	 	finalCode.content[1]=(unsigned char)(XMLSendingType)%100;
	 	//printf("The finalCode.content[0] is %X;\n",(char)(finalCode.content[0]));
	 	memcpy(&(finalCode.content[2]),tempchar,strlen(tempchar));
	 	finalCode.content[strlen(tempchar)+2]=0;
	 	//printf("The finalCode.length is %d;The finalCode.content is %s;\n",finalCode.length,finalCode.content);

	 	memcpy(&(finalCode.content[2])+strlen(tempchar)+1,XMLITEM,strlen(XMLITEM));
	     }
	     else
	     {
	 	sprintf(tempchar,"%d",(unsigned)(pfsm->getDialogueID()));
	 	//printf("The tempchar is %s;The strlen is %d\n",tempchar,strlen(tempchar));
	 	//printf("The finalCode.length is %d;The finalCode.content is %s;\n",finalCode.length,finalCode.content);

	 	finalCode.length=4+strlen(tempchar)+strlen(XMLITEM);;
	 	finalCode.content=new char[finalCode.length+1];
	 	finalCode.content[0]=(unsigned char)XMLSendingType/100;
	 	finalCode.content[1]=(unsigned char)XMLSendingType%100;
	 	finalCode.content[2]=(unsigned char)(scfID+0x30);
	 	//printf("The finalCode.content[0] is %X;\n",(char)(finalCode.content[0]));
	 	memcpy(&(finalCode.content[2])+1,tempchar,strlen(tempchar));
	 	finalCode.content[strlen(tempchar)+3]=0;
	 	//printf("The finalCode.length is %d;The finalCode.content is %s;\n",finalCode.length,finalCode.content);

	 	memcpy(&(finalCode.content[2])+strlen(tempchar)+2,XMLITEM,strlen(XMLITEM));
	      }
	     finalCode.content[finalCode.length]=0;

	     //scfFEAM->sendToMPP(finalCode);
	  }
	  
	  if  (respondItemNum)
	  {
	    pfsm->setTimer(SCSMStateTimer,WaitingForRespondTimer,SecTimer);
	    pfsm->putSIBState(WaitingForRespond);
            return SIBNoComplete;
          }
          else return SIBExit1;

    case WaitingForRespond:
	 if (pmsg->msgType==Internal && pmsg->msgID==inter_timeOut)
         {
            pfsm->errorLog("XML SIB TimerExpire: not received responding message");
            delete pmsg;
            return TimerExpire;
         }
         if (pmsg->msgType==Internal && pmsg->msgID==inter_XMLRespond)
	 {
	    if(pmsg->pMsgPara==NULL)
              return CCBError;

	    PTXMLRespondMessage pArg;
	    pArg=(PTXMLRespondMessage)(pmsg->pMsgPara);

	    int itemnum,itemcycle,memcmplen,copylen;
	    TDFPDataElement dfpDE;
	    PTDFPData pdfp;
	    char tempTag[sizeof(TXMLMsgTagItem)+1],tempTag1[sizeof(TDFPDataElement)+1];
	    char setted[MaxRespondXMLNum];

	    for (itemnum=0;itemnum<MaxRespondXMLNum;itemnum++) setted[itemnum]=0;

	    for (itemnum=0;itemnum<MaxRespondXMLNum;itemnum++)
	    {
	     if (pArg->xmlResItem[itemnum].Tag[0]==NULL) break;

	     if (strlen(pArg->xmlResItem[itemnum].Tag)<sizeof(TXMLMsgTagItem))
	     	   strcpy(tempTag,pArg->xmlResItem[itemnum].Tag);
	     else {
	     	   memcpy(tempTag,pArg->xmlResItem[itemnum].Tag,sizeof(TXMLMsgTagItem));
	     	   tempTag[sizeof(TXMLMsgTagItem)]=0;
	     	   }

      	     //printf("The pArg->xmlResItem[%d].Tag is %s;\n",itemnum,tempTag);
      	     if (pArg->xmlResItem[itemnum].Content[0]!=NULL)
	     	for (itemcycle=0;itemcycle<respondItemNum;itemcycle++)
	     	 {
	     	   if (respondMessage[itemcycle].tag.cid_TagItem==InvalidCCB || respondMessage[itemcycle].cid_Content==InvalidCCB)
	     	      {
	     	       pfsm->errorLog("XML SIB Error,respondMessage.cid_Tag==InvalidCCB or respondMessage[itemnum].cid_Content=InvalidCCB");
	     	       return CCBError;
	     	      }
	     	   pdfp=pfsm->getCCBValue(respondMessage[itemcycle].tag.cid_TagItem,0,0);
	     	   if(pdfp==NULL)
		   {
		     pfsm->errorLog("XML SIB Error, Respond.cid_Tag's Value==NULL");
		     return CCBError;
		   }
	     	   memcpy(tempTag1,pdfp->dfpDataElement.digitsElement,sizeof(TDFPDataElement));
	     	   tempTag1[sizeof(TDFPDataElement)]=0;
	     	   delete pdfp;

	           //printf("The respondMessage[%d].Tag is %s;\n",itemcycle,tempTag1);
	           if (strcmp(tempTag1,tempTag)==0 && !setted[itemcycle] )
	           {
	     	    memcpy(dfpDE.digitsElement,pArg->xmlResItem[itemnum].Content,copylen=sizeof(TXMLContentItem));
      	     	    //printf("The pArg->xmlResItem[%d].Content is %s;\n",itemnum,pArg->xmlResItem[itemnum].Content);
      	     	    if (strlen(pArg->xmlResItem[itemnum].Content)<sizeof(TXMLContentItem))
      	     	   		copylen=strlen(pArg->xmlResItem[itemnum].Content);
      	     	    if (pfsm->putCCBValue(dfpDE,respondMessage[itemcycle].cid_Content,0,0,0)==Wrong)
      	     	   	{
      	     	   	 pfsm->errorLog("XML SIB PutCCBValue Error: respondMessage's cid_Content");
            	   	 delete pmsg;
            	   	 return CCBError;
            	   	}
            	   setted[itemcycle]=1;
            	   break;
            	  }
             	 }
	    }
    	    delete pmsg;
    	    return SIBExit1;
	}
	else
	{
	  delete pmsg;
	  return NoMatchIF;
	}

    default:
    	 delete pmsg;
    	 return NoMatchIF;
    }
}

void TXMLInterface::list()
{

	printf("The Size Of The TXMLInterface is %d;The requestItemNum is %d;And The respondItemNum is %d;\n",sizeof(TXMLInterface),requestItemNum,respondItemNum);

	int tempint,j;
	for (tempint=0;tempint<requestItemNum;tempint++)
	{
	   printf("The Item[%d] Content As Follows:\n",tempint);
	   printf("The requestMessage[%d].Tag.cid_TagItem is %d;\n",tempint,requestMessage[tempint].Tag.cid_TagItem);
	   printf("The requestMessage[%d].Tag.TagItem is %s;\n",tempint,requestMessage[tempint].Tag.TagItem);
	   printf("The requestMessage[%d].cid_MiscType is %d;\n",tempint,requestMessage[tempint].cid_MiscType);
	   printf("The requestMessage[%d].MiscType is %d;\n",tempint,requestMessage[tempint].MiscType);
	   printf("The requestMessage[%d].cid_Content is %d;\n",tempint,requestMessage[tempint].cid_Content);
	}
	/*for (tempint=0;tempint<respondItemNum;tempint++)
	{
	   printf("The RespondItem[%d] Content As Follows:\n",tempint);
	   printf("The respondMessage[%d].cid_Tag is %d;\n",tempint,respondMessage[tempint].cid_Tag);
	   printf("The respondMessage[%d].cid_Content is %d;\n",tempint,respondMessage[tempint].cid_Content);
	}*/
}
