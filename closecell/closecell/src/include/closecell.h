/*
 *  Copyright(C) 2000 EASTCOM-BUPT Inc.
 *
 *  Filename            : $RCSfile: closecell.h,v $
 *  Last Revision       : $Revision: 1.1 $
 *  Last Revision Date  : $Date: 2012/07/19 08:36:06 $
 *  Description         :
 */
#ifndef _CLOSE_CELL_H
#define _CLOSE_CELL_H

#include <stdio.h>
#include <string>
#include "closecellconfig.h"
#include "basestationstruct.h"
#include "base.h"
using std::string;

#define MAXLINE 4096


class TCLOSECELL
{
public:
	~TCLOSECELL();
	static TCLOSECELL* getInstance();
	bool startup();
	bool loadCfg(const char* fileName);
	bool define_file(char *file[6], int _fNum);
	bool open_file(char *fileName, int fileNum);
	bool handle_closecell(char *line, char *fileName, int fileNum, TClosecellRuleItem closeCellLoc);
	bool handle_lbs_data(char *line, char *fileName, int fileNum, TClosecellLocationRuleItem closeCellLoc);
	bool handle_lbs();
	bool handle_zero(char *data);
private:
	static TCLOSECELL* instance;
	static string closecellTD;
	static string closecell2D;
	static string closecellLBSTD;
	static string closecellLBS2D;
	int cellType[2];
	int fNum;
	int fLogo;
	int lineNum[6];
	int newFileLine;


	FILE* fout2D;
	FILE* foutTD;

	static base_station_t head;

};

#endif

