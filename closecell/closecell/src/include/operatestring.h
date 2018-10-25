/*
 *  Copyright(C) 2000 EASTCOM-BUPT Inc.
 *
 *  Filename            : $RCSfile: operatestring.h,v $
 *  Last Revision       : $Revision: 1.2 $
 *  Last Revision Date  : $Date: 2012/07/19 08:15:17 $
 *  Description         :
 */
#ifndef _OPERATE_STRING_H
#define _OPERATE_STRING_H

#include "closecellconfig.h"

bool hand_string_lbs_td(char *, char *, char *, double *, double *, TClosecellLocationRuleItem closeCellLoc);
bool hand_string_lbs_2d(char *, char *, char *, double *, double *, TClosecellLocationRuleItem closeCellLoc);
bool hand_string_closecell(char *, char *, char *, char *, char *, TClosecellRuleItem closeCellLoc);
void hand_string_2DTD(char *, char *, char *, char *);
void merge_string(char *, char *, char *, char *);

#endif

