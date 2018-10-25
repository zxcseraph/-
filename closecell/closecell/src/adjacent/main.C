/*
 *  Copyright(C) 2000 EASTCOM-BUPT Inc.
 *
 *  Filename            : $RCSfile: main.C,v $
 *  Last Revision       : $Revision: 1.2 $
 *  Last Revision Date  : $Date: 2012/07/19 08:15:16 $
 *  Description         :
 */
#include "closecellall.h"


static const char const_tag_id[] = "$Name: Rel_5_00_20120719_closecell $"; 
char tag_id[] = "$Name: Rel_5_00_20120719_closecell $";

using namespace	TLogFunction; 

//初始化程序
bool init()
{
	if(!TCLOSECELL::getInstance()->startup())
	{
		logError("init TClosecell failed");
		return false;
	}
	if(!TClosecellConfig::getInstance()->startup())
	{
		logError("init TClosecellConfig failed");
		return false;
	}
	return true;
}

int main(int argc, char **argv){
	char ch;
	char *file[6];
	int fNum = 0;

	if(!init()){
		fprintf(stderr, "inialize failed\n");
		return -1;
	}       

	opterr = 0;
	//读取参数
	if((ch = getopt(argc,argv,"hf:"))!= -1){ 
		switch(ch) {
		case 'h':
			fprintf(stderr,"please input \"-f file\"\n");
			return -1;
			break;
		case 'f':
			break;
		default:
			fprintf(stderr,"ERROR: input the data 4from file\n");
			logError("input the data from file");
			return -1;
		}
	}
	else{
		fprintf(stderr, "getopt error\n");
		return -1;
	}

	//保存文件名
	file[fNum++] = optarg;
	for(optind; optind < argc; optind++)
		file[fNum++] = argv[optind];

	TCLOSECELL::getInstance()->define_file(file, fNum);

	return -1;
}
