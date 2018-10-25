/*
 *  Copyright(C) 2000 EASTCOM-BUPT Inc.
 *
 *  Filename            : $RCSfile: closecellconfig.h,v $
 *  Last Revision       : $Revision: 1.1 $
 *  Last Revision Date  : $Date: 2012/07/19 08:36:06 $
 *  Description         :
 */
#ifndef _CLOSECELL_CONFIG_H 
#define _CLOSECELL_CONFIG_H 

#include <stdio.h>
#include <string>
#include <vector>
using std::string;
using std::vector;

struct TClosecellRuleItem
{
	string name;
	int primaryLac;
	int primaryCellid;
	int adjacentLac;
	int adjacentCellid;
	TClosecellRuleItem(const char* _name, int _primaryLac, int _primaryCellid, int _adjacentLac, int _adjacentCellid)
	{
		name = string(_name);
		primaryLac = _primaryLac;
		primaryCellid = _primaryCellid;
		adjacentLac = _adjacentLac;
		adjacentCellid = _adjacentCellid;
	}
	TClosecellRuleItem()
	{
		name = " ";
		primaryLac = 0;
		primaryCellid = 0;
		adjacentLac = 0;
		adjacentCellid = 0;
	}
};

struct TClosecellLocationRuleItem
{
	string name;
	int primaryLac;
	int primaryCellid;
	int lgitudeDeg;
	int lgitudeMin;
	int lgitudeSec;
	int latitudeDeg;
	int latitudeMin;
	int latitudeSec;
	TClosecellLocationRuleItem(const char* _name, int _primaryLac, int _primaryCellid, 
		int _lgitudeDeg, int _lgitudeMin, int _lgitudeSec, int _latitudeDeg, int _latitudeMin, int _latitudeSec)
	{
		name = string(_name);
		primaryLac = _primaryLac;
		primaryCellid = _primaryCellid;
		lgitudeDeg = _lgitudeDeg;
		lgitudeMin = _lgitudeMin;
		lgitudeSec = _lgitudeSec;
		latitudeDeg = _latitudeDeg;
		latitudeMin = _latitudeMin;
		latitudeSec = _latitudeSec;
	}
	TClosecellLocationRuleItem()
	{
		name = " ";
		primaryLac = 0;
		primaryCellid = 0;
		lgitudeDeg = 0;
		lgitudeMin = 0;
		lgitudeSec = 0;
		latitudeDeg = 0;
		latitudeMin = 0;
		latitudeSec = 0;	
	}
};


class TClosecellConfig
{
public:
	//TClosecellConfig();
	//~TClosecellConfig();
	bool startup();
	static TClosecellConfig* getInstance();
	// ∂¡»°closecell ≈‰÷√Œƒº˛config.closecell
	bool loadConfigFile();
	double getLgtValue(){ return lgtValue; }
	double getLatValue(){ return latValue; }
	double getRefDistance(){ return refDistance; }
	double getStdValue(){ return stdValue; }
	const string & geLogFileName()const {return logFileName;}
	bool getClosecellRuleItem(const char* name, TClosecellRuleItem&);
	bool getClosecellLocationRuleItem(const char* name, TClosecellLocationRuleItem&);

private:
	static TClosecellConfig* instance;
	string closecellCfgFielName;
	static vector<TClosecellRuleItem> closecellRule;
	static vector<TClosecellLocationRuleItem> closecellLocationRule;
	static double lgtValue;
	static double latValue;
	static double refDistance;
	static double stdValue;
	static string logFileName;
};
#endif

