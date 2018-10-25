/*
 *  Copyright(C) 2000 EASTCOM-BUPT Inc.
 *
 *  Filename            : $RCSfile: closecell.C,v $
 *  Last Revision       : $Revision: 1.1 $
 *  Last Revision Date  : $Date: 2012/07/19 08:36:05 $
 *  Description         :
 */
#include "closecell.h"
#include "operatestring.h"

using namespace	TLogFunction;
TCLOSECELL *TCLOSECELL::instance = 0;
string TCLOSECELL::closecellTD;
string TCLOSECELL::closecell2D;
string TCLOSECELL::closecellLBSTD;
string TCLOSECELL::closecellLBS2D;	
base_station_t TCLOSECELL::head;

TCLOSECELL *TCLOSECELL::getInstance()
{
	if (instance==0)
	{
		instance = new TCLOSECELL();
	}
	return instance;
}

/**
* 进程运行时第一个初始化动作。
*/
bool TCLOSECELL::startup()
{
	char *closeDir;
	int i;

	if (getenv("CLOSEDIR")==0)
	{
		logError("root directory CLOSEDIR not defined!");
		return false;
	}
	closeDir = getenv("CLOSEDIR"); 

	closecellTD = string(closeDir) + string("/tmp/closecellTD");
	closecell2D = string(closeDir) + string("/tmp/closecell2D");
	closecellLBSTD = string(closeDir) + string("/tmp/closecellLBSTD");
	closecellLBS2D = string(closeDir) + string("/tmp/closecellLBS2D");
	cellType[0] = 0;
	cellType[1] = 0;
	fNum = 0;
	fLogo = 0;
	newFileLine = 0;

	for(i = 0; i < 6; ++i)
		lineNum[i] = 0;


	head = (base_station_t)malloc(sizeof(struct base_station_s));
	if(!head)
	{
		logError("new head fail!");
		return false;
	}
	head->next = NULL;

}

TCLOSECELL::~TCLOSECELL()
{
	base_station_t p;
	if(head || head->next)
	{
		p = head;
		head = head->next;
		free(p);
	}
}

//处理cellid左边的0
bool TCLOSECELL::handle_zero(char *data){
	char *p = data;
	int len = strlen(data);
	int i;
	int j = 0;

	if(len <= 0 || len > 5){
		printf("TCLOSECELL::handle_zero the data %s is illegal.\n", data);
		logError("TCLOSECELL::handle_zero the data %s is illegal.\n", data);
		return false;
	}

	for(i = 0; i <= len; ++i){
		if(*p != '0')
			break;
		p++;
	}

	if(i == len){
		printf("TCLOSECELL::handle_zero the data cannot be %s\n", data);	
		logError("TCLOSECELL::handle_zero the data cannot be %s\n", data);	
		return false;
	}
	if(len < 3){
		return true;
	}  
	for(i; i <= len; ++i){
		data[j++] = *p;
		p++;
	}

	return true;
}

//处理LBS文件，找出LBS文件里所有小区的邻区
bool TCLOSECELL::handle_lbs(){
	// char data[16];
	int isDup = 1;

	FILE *foutLBSTD;
	FILE *foutLBS2D;

	if(!(foutLBSTD = fopen(closecellLBSTD.c_str(), "w"))){      
		fprintf(stderr, "open the output file closecellTD %s error\n", closecellLBSTD);
		logError("open the output file closecellTD %s", closecellLBSTD);
		return false;
	}

	if(!(foutLBS2D = fopen(closecellLBS2D.c_str(), "w"))){	   
		fprintf(stderr, "open the output file closecell2D %s error\n", closecellLBS2D);
		logError("open the output file closecell2D %s", closecellLBS2D);
		return false;
	}
	base_station_t baseStation;
	base_station_t baseClosecell;
	base_station_t pBase;

	baseStation = head->next; 

	while(baseStation){
		baseClosecell = first_find_base_station_closecell(baseStation);

		pBase = baseStation->next;
		while(pBase != baseClosecell){
			if(find_base_station_closecell(baseStation->lgt, baseStation->lat, pBase->lgt, pBase->lat)){

				//merge_string(data, baseStation->priCellid, baseStation->priLac, pBase->priCellid);

				if(pBase->cellType == 1){
					fprintf(foutLBS2D, "%s|%s|%s|%d|\n", baseStation->priCellid, baseStation->priLac,
						pBase->priCellid, pBase->cellType);
				}
				else{
					fprintf(foutLBSTD, "%s|%s|%s|%d|\n", baseStation->priCellid, baseStation->priLac,
						pBase->priCellid, pBase->cellType);
				}

				// merge_string(data, pBase->priCellid, pBase->priLac, baseStation->priCellid);

				if(baseStation->cellType == 1){
					fprintf(foutLBS2D, "%s|%s|%s|%d|\n", pBase->priCellid, pBase->priLac,
						baseStation->priCellid, baseStation->cellType);
				}
				else{
					fprintf(foutLBSTD, "%s|%s|%s|%d|\n", pBase->priCellid, pBase->priLac,
						baseStation->priCellid, baseStation->cellType);
				}


			}              
			pBase = pBase->next;
		}

		pBase = baseStation;
		baseStation = baseStation->next;
		free(pBase);
	}  

	return true;
}


//读取LBS文件里cellid、lac、经度和纬度，将这四个数据保存到base_station_s结构
bool TCLOSECELL::handle_lbs_data(char *line, char *fileName, int fileNum, TClosecellLocationRuleItem closeCellLoc){
	char priCellid[6];
	char priLac[6];
	double lgt;
	double lat;
	base_station_t baseStation;

	lineNum[fileNum]++;
	if(fLogo == 5){
		//读取2D LBS文件数据
		if(!hand_string_lbs_2d(line, priCellid, priLac, &lgt, &lat, closeCellLoc)){
			fprintf(stderr, "ERROR: NO.%d in %s has wrong the data\n", lineNum[fileNum], fileName);
			logError("NO.%d in %s has wrong the data\n", lineNum[fileNum], fileName);
			return false;
		}	
	} 
	if(fLogo == 6){
		//读取TD LBS文件数据
		if(!hand_string_lbs_td(line, priCellid, priLac, &lgt, &lat, closeCellLoc)){
			fprintf(stderr, "ERROR: NO.%d in %s has wrong the data\n", lineNum[fileNum], fileName);
			logError("NO.%d in %s has wrong the data\n", lineNum[fileNum], fileName);
			return true;
		}  
	}
	if(strlen(priLac) > 5 || strlen(priLac) <= 0){
		printf("the data %s is illegal.\n", priLac);
		logError("the data %s is illegal.\n", priLac);
		return false;
	}
	if(!handle_zero(priCellid))
		return false;

	if(lgt < 73.666 || lgt > 135.04167 || lat < 3.866 || lat > 53.549){
		return false;
	}

	if(!(baseStation = (base_station_t)malloc(sizeof(struct base_station_s)))){
		fprintf(stderr, "out of the pace\n");
		exit(1);
		return false;
	}

	strncpy(baseStation->priCellid, priCellid, strlen(priCellid) + 1);
	strncpy(baseStation->priLac, priLac, strlen(priLac) + 1);
	baseStation->lgt = lgt;
	baseStation->lat = lat;
	baseStation->sum = lat + lgt;

	if(fLogo == 5){
		baseStation->cellType = 1;
	}
	else{
		baseStation->cellType = 2;
	}

	baseStation->next = NULL;

	head = insert_base_station(head, baseStation);

	return true;

}

//读取4个邻区文件数据，根据文件名不同，以c2cell_closecell表格分别写到closecell2D和closecellTD文件
bool TCLOSECELL::handle_closecell(char *line, char *fileName, int fileNum, TClosecellRuleItem closeCellLoc){
	char priCellid[6];
	char priLac[6];
	char closeCellid[6];
	char closeLac[6];
	//char priData[16];
	//char closeData[16];
	int isDup = 1;

	lineNum[fileNum]++;

	if(!hand_string_closecell(line, priCellid, priLac, closeCellid, closeLac, closeCellLoc)){
		fprintf(stderr, "ERROR: NO.%d in %s has wrong the data\n", lineNum[fileNum], fileName);
		logError("NO.%d in %s has wrong the data\n", lineNum[fileNum], fileName);
		return false;
	}

	if(strlen(priLac) > 5 || strlen(priLac) <= 0){
		printf("the priLac data %s is illegal.\n", priLac);
		logError("the priLac data %s is illegal; length=%d.\n", priLac, strlen(priLac));
		logError("the line %s is illegal.\n", line);
		return false;
	}
	if(strlen(closeLac) > 5 || strlen(closeLac) <= 0){
		printf("the closeLac data %s is illegal.\n", closeLac);
		logError("the closeLac data %s is illegal.\n", closeLac);
		return false;
	}
	if(!handle_zero(priCellid)) return false;
	if(!handle_zero(closeCellid)) return false;

	//merge_string(priData, priCellid, priLac, closeCellid);
	//merge_string(closeData, closeCellid, closeLac, priCellid);
	//处理主小区的字符串

	if(cellType[1] == 1){
		fprintf(fout2D, "%s|%s|%s|%d|\n", priCellid, priLac, closeCellid, cellType[1]);              
	}
	else{
		fprintf(foutTD, "%s|%s|%s|%d|\n", priCellid, priLac, closeCellid, cellType[1]);
	}  

	if(cellType[0] == 1){
		fprintf(fout2D, "%s|%s|%s|%d|\n", closeCellid, closeLac, priCellid, cellType[0]);
	}
	else{
		fprintf(foutTD, "%s|%s|%s|%d|\n", closeCellid, closeLac, priCellid, cellType[0]);
	}

	return true;
}

//打开文件，一行一行读文件数据
bool TCLOSECELL::open_file(char *fileName, int fileNum){
	FILE *fin;
	char line[MAXLINE];

	if(!(fin = fopen(fileName, "r"))){
		return false;	
	}	

	fprintf(stdout, "open the file' name is %s\n", fileName);
	logInfo("open the file'name is %s", fileName);
	logInfo("start to handle the file %s", fileName);
	fprintf(stdout, "start to handle the file %s\n", fileName);
	TClosecellLocationRuleItem closeCellLoc;
	TClosecellRuleItem closeCell;
	if(fLogo == 1)
	{
		if(!TClosecellConfig::getInstance()->getClosecellRuleItem("GSM_A-adjacent", closeCell))
		{
			logError("TCLOSECELL::open_file cannot get TClosecellRuleItem");
			return false;
		}
	}
	else if(fLogo == 2)
	{
		//closeCell = TClosecellConfig::getInstance()->getClosecellRuleItem("GSM_RELA-gsmrelation");

		if(!TClosecellConfig::getInstance()->getClosecellRuleItem("GSM_RELA-gsmrelation", closeCell))
		{
			logError("TCLOSECELL::open_file cannot get TClosecellRuleItem");
			return false;
		}
	}
	else if(fLogo == 3)
	{
		//closeCell = TClosecellConfig::getInstance()->getClosecellRuleItem("TD_A-adjacent_td");
		if(!TClosecellConfig::getInstance()->getClosecellRuleItem("TD_A-adjacent_td", closeCell))
		{
			logError("TCLOSECELL::open_file cannot get TClosecellRuleItem");
			return false;
		}
	}
	else if(fLogo == 4)
	{
		//closeCell = TClosecellConfig::getInstance()->getClosecellRuleItem("TD_RELA-utranrelation");
		if(!TClosecellConfig::getInstance()->getClosecellRuleItem("TD_RELA-utranrelation", closeCell))
		{
			logError("TCLOSECELL::open_file cannot get TClosecellRuleItem");
			return false;
		}
	}
	else if(fLogo == 5)
	{
		//closeCellLoc = TClosecellConfig::getInstance()->getClosecellLocationRuleItem("LBS", closeCellLoc);
		if(!TClosecellConfig::getInstance()->getClosecellLocationRuleItem("LBS", closeCellLoc))
		{
			logError("TCLOSECELL::open_file cannot get TClosecellRuleItem");
			return false;
		}
	}
	else if(fLogo == 6)
	{
		//closeCellLoc = TClosecellConfig::getInstance()->getClosecellLocationRuleItem("TD_LBS");
		if(!TClosecellConfig::getInstance()->getClosecellLocationRuleItem("TD_LBS", closeCellLoc))
		{
			logError("TCLOSECELL::open_file cannot get TClosecellRuleItem");
			return false;
		}
	}
	else return false;

	//logError("closecell: %s, %d, %d, %d, %d", closeCell.name.c_str(), closeCell.primaryLac, closeCell.primaryCellid, closeCell.adjacentLac, closeCell.adjacentCellid);

	while(fgets(line, MAXLINE, fin)){

		if(fLogo > 0 && fLogo < 5){
			if(!handle_closecell(line, fileName, fileNum, closeCell)){
				logError("TCLOSECELL::open_file NO.%d in %s has wrong the data\n", lineNum[fileNum], fileName);
			}
		}
		else if(fLogo == 5 || fLogo == 6){

			if(!handle_lbs_data(line, fileName, fileNum, closeCellLoc)){
				logError("TCLOSECELL::open_file NO.%d in %s has wrong the data\n", lineNum[fileNum], fileName);
			} 	
		}	
	}
	fclose(fin);
	return true;
}

//识别文件名，作标记
bool TCLOSECELL::define_file(char *file[6], int _fNum){
	int i;	
	fNum = _fNum;
	if(!(fout2D = fopen(closecell2D.c_str(), "w"))){       //打开closecell2D文件
		fprintf(stderr, "open the output file closecell2D %s error\n", closecell2D);
		logError("open the output file closecell2D %s", closecell2D);
		return -1;
	}

	if(!(foutTD = fopen(closecellTD.c_str(), "w"))){      //打开closecellTD文件
		fprintf(stderr, "open the output file closecellTD %s error\n", closecellTD);
		logError("open the output file closecellTD %s", closecellTD);
		return false;
	}

	for(i = 0; i < fNum; i++){
		if(strcmp(file[i], "GSM_A-adjacent.unl") == 0){ 
			cellType[0] = 1;
			cellType[1] = 1;
			fLogo = 1;
		}
		else if(strcmp(file[i], "GSM_RELA-gsmrelation.unl") == 0){
			cellType[0] = 2;
			cellType[1] = 1;
			fLogo = 2;
		}
		else if(strcmp(file[i], "TD_A-adjacent_td.unl") ==0){
			cellType[0] = 1;
			cellType[1] = 2;
			fLogo = 3;
		}
		else if(strcmp(file[i], "TD_RELA-utranrelation.unl") ==0){
			cellType[0] = 2;
			cellType[1] = 2;
			fLogo = 4;
		}
		else if(file[i][0] == 'L' && file[i][1] == 'B' && file[i][2] == 'S'){
			fprintf(stdout, "open the lbs file\n");
			fLogo = 5;
		} 
		else if(file[i][0] == 'T' && file[i][1] == 'D' && file[i][2] == '_' &&
			file[i][3] == 'L' && file[i][4] == 'B' && file[i][5] == 'S'){
				fprintf(stdout, "open the td_lbs file\n");
				fLogo = 6;
		} 
		else{
			fprintf(stderr, "error the file name: %s\n", file[i]);
			logError("the file name %s is wrong", file[i]);
			return  false;	
		}
		if(!open_file(file[i], i)){
			fprintf(stderr, "ERROR: open the file %s\n", file[i]);
			logError("ERROR: open the file %s", file[i]);

		}
	}  

	fclose(fout2D);
	fclose(foutTD);

	if(!handle_lbs()){
		logError("The program cannot handle the lbs file.");
		fprintf(stderr, "the program handle the lbs file error.\n");
	}

	//输出文件名及文件的行数
	for(i = 0; i < fNum; ++i){
		fprintf(stdout, "the file %s handled has %d lines\n", file[i], lineNum[i]);
		logInfo("the file %s handled has %d lines\n", file[i], lineNum[i]);
	} 

	return true;
}

