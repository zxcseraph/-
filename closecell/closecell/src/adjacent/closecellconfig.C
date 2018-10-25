/***********************************************************
*  Copyright(C) 2000 EASTCOM-BUPT Inc.
*
*  Filename             : $RCSfile: closecellconfig.C,v $
*  Last Revision        : $Revision: 1.1 $
*  Last Revision Date   : $Date: 2012/07/19 08:36:05 $
*  Author               : 
*  Description          : 
**********************************************************/

#include "closecellconfig.h"
#include "tinyxml.h"
#include "base.h"

using namespace	TLogFunction;
TClosecellConfig *TClosecellConfig::instance = 0;
vector<TClosecellRuleItem> TClosecellConfig::closecellRule;
vector<TClosecellLocationRuleItem> TClosecellConfig::closecellLocationRule;
double TClosecellConfig::lgtValue = 0;
double TClosecellConfig::latValue = 0;
double TClosecellConfig::refDistance = 0;
double TClosecellConfig::stdValue = 0;
string TClosecellConfig::logFileName;

TClosecellConfig *TClosecellConfig::getInstance()
{
	if (instance==0)
	{
		instance = new TClosecellConfig();
	}
	return instance;
}

/**
* 进程运行时第一个初始化动作。
* 打开config.closecell
* 配置文件，生成XML解析树。然后获得本进程的日志文件
* 名和配置文件名。
*/
bool TClosecellConfig::startup()
{
	char buf[99];
	char *ps;
	char *closeDir;


	if (getenv("CLOSEDIR")==0)
	{
		logError("root directory CINDIR not defined!");
		return false;
	}
	closeDir = getenv("CLOSEDIR");

	closecellCfgFielName = closeDir;
	closecellCfgFielName += "/etc/config.closecell";

	if(!loadConfigFile())
	{
		logError("TClosecellConfig::startup loadconfigfile fail");
		return false;
	}

	logFileName = closeDir;
	logFileName += "/log/closecell.log";


	return true;
}
/*
<?xml version=1.0 encoding=GB2312 ?>
<configuration>
<closecell>
<rule name="GSM_A-adjacent" primaryLac="1" primaryCellid="2" adjacentLac="3" adjacentCellid="4" />
<rule name="GSM_RELA-gsmrelation" primaryLac="1" primaryCellid="2" adjacentLac="3" adjacentCellid="4" />
<rule name="TD_A-adjacent_td" primaryLac="1" primaryCellid="2" adjacentLac="3" adjacentCellid="4" />
<rule name="TD_RELA-utranrelation" primaryLac="1" primaryCellid="2" adjacentLac="3" adjacentCellid="4" />
</closecell>
<closecellLocation>
<rule name="LBS" primaryLac="1" primaryCellid="2" lgitudeDeg="3" lgitudeMin="4" lgitudeSec="5" 
latitudeDeg="6" latitudeMin="7" latitudeSec="8" />
<rule name="TD_LBS" primaryLac="1" primaryCellid="2" lgitudeDeg="3" lgitudeMin="4" lgitudeSec="5"
latitudeDeg="6" latitudeMin="7" latitudeSec="8" />
</closecellLocation>
<closecellPlace>
<place  lgtValue="17.85" latValue="16.17" refDistance="500" stdValue="1000" />
</closecellPlace>
</configuration>
*/

bool TClosecellConfig::loadConfigFile()
{
	assert(!closecellCfgFielName.empty());

	TiXmlDocument* cfgtree;
	cfgtree = new TiXmlDocument(closecellCfgFielName.c_str());
	if(!cfgtree)
	{
		logError("out of memory when new TiXmlDocument.");
		return false;
	}
	bool ret=true;
	ret = cfgtree->LoadFile();
	if(!ret)
	{return ret;}
	TiXmlElement* root = cfgtree->RootElement();
	if(!root)
	{
		logError("no root element in %s", closecellCfgFielName.c_str());
		return false;
	}

	TiXmlElement* closecell = 0;
	TiXmlElement* closecellLocation = 0;
	TiXmlElement* closecellPlace = 0;

	closecell = root->FirstChildElement("closecell");
	if(!closecell)
	{
		logError("no closecell configeration in %s", closecellCfgFielName.c_str());
		return false;
	}

	closecellLocation = root->FirstChildElement("closecellLocation");
	if(!closecellLocation)
	{
		logError("no closecellLocation slpinvoke configeration in %s", closecellCfgFielName.c_str());
		return false;
	}

	closecellPlace = root->FirstChildElement("closecellPlace");
	if(!closecellPlace)
	{
		logError("no closecellPlace configeration in %s", closecellCfgFielName.c_str());
		return false;
	}

	TiXmlElement* element = 0;
	//<rule name="GSM_A-adjacent" primaryLac="1" primaryCellid="2" adjacentLac="3" adjacentCellid="4" />
	element = closecell->FirstChildElement("rule");
	if(!element)
	{
		logError("no <rule> item in <closecell>");
		return false;
	}
	closecellRule.clear();
	while(element)
	{
		const char* temp = 0;
		const char* _name;
		int _primaryLac = 0;
		int _primaryCellid = 0;
		int _adjacentLac = 0;
		int _adjacentCellid = 0;

		_name = element->Attribute("name");
		if(!_name)
		{
			logError("TClosecellConfig::loadConfigFile decode error!!!");
			return false;
		}


		if(!element->Attribute("primaryLac", &_primaryLac))
		{
			logError("TClosecellConfig::loadConfigFile decode error!!!");
			return false;
		}

		if(!element->Attribute("primaryCellid", &_primaryCellid))
		{
			logError("TClosecellConfig::loadConfigFile decode error!!!");
			return false;
		}

		if(!element->Attribute("adjacentLac", &_adjacentLac))
		{
			logError("TClosecellConfig::loadConfigFile decode error!!!");
			return false;
		}

		if(!element->Attribute("adjacentCellid", &_adjacentCellid))
		{
			logError("TClosecellConfig::loadConfigFile decode error!!!");
			return false;
		}

		//printf("statup: %s, %d, %d, %d, %d", _name, _primaryLac, _primaryCellid, _adjacentLac, _adjacentCellid);
		TClosecellRuleItem Rule(_name, _primaryLac, _primaryCellid, _adjacentLac, _adjacentCellid);
		closecellRule.push_back(Rule);

		element = element->NextSiblingElement("rule");
	}


	/*<rule name="LBS" primaryLac="1" primaryCellid="2" lgitudeDeg="3" lgitudeMin="4" lgitudeSec="5" 
	latitudeDeg="6" latitudeMin="7" latitudeSec="8" />
	*/
	element = closecellLocation->FirstChildElement("rule");
	if(!element)
	{
		logError("no <rule> item in <closecellLocation>");
		return false;
	}
	closecellLocationRule.clear();
	while(element)
	{
		const char* temp = 0;
		const char* _name;
		int _primaryLac = 0;
		int _primaryCellid = 0;
		int _lgitudeDeg = 0;
		int _lgitudeMin = 0;
		int _lgitudeSec = 0;
		int _latitudeDeg = 0;
		int _latitudeMin = 0;
		int _latitudeSec = 0;

		_name = element->Attribute("name");
		if(!_name)
		{
			logError("TClosecellConfig::loadConfigFile decode error!!!");
			return false;
		}


		if(!element->Attribute("primaryLac", &_primaryLac))
		{
			logError("TClosecellConfig::loadConfigFile decode error!!!");
			return false;
		}

		if(!element->Attribute("primaryCellid", &_primaryCellid))
		{
			logError("TClosecellConfig::loadConfigFile decode error!!!");
			return false;
		}

		if(!element->Attribute("lgitudeDeg", &_lgitudeDeg))
		{
			_lgitudeDeg = -1;
		}

		if(!element->Attribute("lgitudeMin", &_lgitudeMin))
		{
			_lgitudeMin = -1;
		}

		if(!element->Attribute("lgitudeSec", &_lgitudeSec))
		{
			_lgitudeSec = -1;
		}

		if(!element->Attribute("latitudeDeg", &_latitudeDeg))
		{
			_latitudeDeg = -1;
		}

		if(!element->Attribute("latitudeMin", &_latitudeMin))
		{
			_latitudeMin = -1;
		}

		if(!element->Attribute("latitudeSec", &_latitudeSec))
		{
			_latitudeSec = -1;
		}

		//logError("statup2: %s, %d, %d, %d, %d, %d, %d, %d, %d", _name, _primaryLac, _primaryCellid, _lgitudeDeg, _lgitudeMin, _lgitudeSec, _latitudeDeg, _latitudeMin, _latitudeSec);
		TClosecellLocationRuleItem Rule(_name, _primaryLac, _primaryCellid, _lgitudeDeg, _lgitudeMin, _lgitudeSec, _latitudeDeg, _latitudeMin, _latitudeSec);
		closecellLocationRule.push_back(Rule);

		element = element->NextSiblingElement("rule");
	}

	element = closecellPlace->FirstChildElement("place");
	if(!element)
	{
		logError("no <rule> item in <closecellPlace>");
		return false;
	}
	const char* s;
	s = element->Attribute("lgtValue");
	if(!s)
	{
		logError("TClosecellConfig::loadConfigFile decode lgtValue error!!!");
		return false;
	}
	lgtValue = atof(s)/3600;

	s = element->Attribute("latValue");
	if(!s)
	{
		logError("TClosecellConfig::loadConfigFile decode lgtValue error!!!");
		return false;
	}
	latValue = atof(s)/3600;

	s = element->Attribute("refDistance");
	if(!s)
	{
		logError("TClosecellConfig::loadConfigFile decode lgtValue error!!!");
		return false;
	}
	refDistance = atof(s);

	s = element->Attribute("stdValue");
	if(!s)
	{
		logError("TClosecellConfig::loadConfigFile decode lgtValue error!!!");
		return false;
	}
	stdValue = atof(s);
	
	//printf("TClosecellConfig::loadConfigFile %lf %lf %lf %lf\n", lgtValue, latValue, refDistance, stdValue);

	delete cfgtree;
	cfgtree = 0;
	return true;
}

bool TClosecellConfig::getClosecellRuleItem(const char* name, TClosecellRuleItem& retClosecell)
{
	vector<TClosecellRuleItem>::iterator iter = closecellRule.begin();

	while(iter != closecellRule.end())
	{

		if(strcmp((iter->name).c_str(), name) == 0){
			retClosecell = *iter;
			return true;
		}
		iter++;
	}

	logError("TClosecellConfig::getClosecellRuleItem cannot get closecellRule!!");
	return false;
}

bool TClosecellConfig::getClosecellLocationRuleItem(const char* name, TClosecellLocationRuleItem& retClosecell)
{
	vector<TClosecellLocationRuleItem>::iterator iter = closecellLocationRule.begin();

	while(iter != closecellLocationRule.end())
	{

		if(strcmp((iter->name).c_str(), name) == 0){
			retClosecell = *iter;
			return true;
		}
		iter++;
	}

	logError("TClosecellConfig::getClosecellLocationRuleItem cannot get closecellLocationRule!!");
	return false;
}




