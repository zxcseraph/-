/*
 *  Copyright(C) 2000 EASTCOM-BUPT Inc.
 *
 *  Filename            : $RCSfile: operatestring.C,v $
 *  Last Revision       : $Revision: 1.2 $
 *  Last Revision Date  : $Date: 2012/07/19 08:15:16 $
 *  Description         :
 */
#include "closecellall.h"

//读取TD LBS文件数据: cellid, lac, 经度,纬度
bool hand_string_lbs_td(char *line, char *priCellid, char *priLac,
	double *lgt, double *lat, TClosecellLocationRuleItem closeCellLoc){

		char *p1 = priCellid;
		char *p2 = priLac;
		int num = 1;

		int i = 0;
		int j = 0;


		if(closeCellLoc.lgitudeMin < 1 && closeCellLoc.latitudeMin < 1)
		{
			char lgtChar[20];
			char latChar[20]; 

			bool lsAlt = false;

			while(*line != '\0'){

				if(num == closeCellLoc.latitudeDeg && *line != 9){
					latChar[i++] = *line;
					if(*(line + 1) == 9){
						latChar[i] = '\0';
						i = 0;	
					}
				}
				else if(num == closeCellLoc.lgitudeDeg && *line != 9){
					lgtChar[i++] = *line;
					if(*(line + 1) == 9){
						lgtChar[i] = '\0';
						i = 0;	
					}
				}
				else if(num == 9 && *line > 47 && *line < 58)
					lsAlt = true;
				else if((num == closeCellLoc.primaryLac && *line != 9 && !lsAlt) || (lsAlt && num == closeCellLoc.primaryLac + 1 && *line != 9 )){ 
					if(*line >= '0' && *line <= '9')
						*p2++ = *line;
					else
						return false;
				}

				else if((num == closeCellLoc.primaryCellid && *line != 9 && !lsAlt) || (lsAlt && num == closeCellLoc.primaryCellid + 1 && *line != 9 )){ 
					if(*line >= '0' && *line <= '9')
						*p1++ = *line;
					else
						return false;            
				}

				if(*line == 9 && *(line + 1) != 9)
					num++;

				if(num == 16)
					break;

				line++;
			}

			*p1 = '\0';
			*p2 = '\0';

			*lgt = atof(lgtChar);
			*lat = atof(latChar);
		}

		else
		{
			char lgtLat[6][6];
			while(*line != '\0'){

				if(num == closeCellLoc.primaryLac && *line != 9 && *line != '|'){
					if(*line >= '0' && *line <= '9')
						*p2++ = *line;
					else
						return false;
				}
				else if(num == closeCellLoc.primaryCellid && *line != 9 && *line != '|'){
					if(*line >= '0' && *line <= '9')
						*p1++ = *line;
					else
						return false;
				}
				else if((num == closeCellLoc.lgitudeDeg || num == closeCellLoc.lgitudeMin || num == closeCellLoc.lgitudeSec ||
					num == closeCellLoc.latitudeDeg || num == closeCellLoc.latitudeMin || num == closeCellLoc.latitudeSec) && *line != 9 && *line != '|'){ 
						lgtLat[j][i++] = *line;
						if(*(line + 1) == 9 || *(line + 1) == '|'){
							lgtLat[j][i] = '\0';
							i = 0;
							j++;
						}
				}
				if((*line == 9 && *(line + 1) != 9) || *line == '|')
					num++;
				if(num == 15)
					break;

				line++;
			}

			*p1 = '\0';
			*p2 = '\0';

			//printf("TD_LBS: %s %s %lf %lf\n", priLac, priCellid, *lgt, *lat);
			*lgt = atoi(lgtLat[0]) + atof(lgtLat[1]) / 60 + atof(lgtLat[2]) / 3600;
			*lat = atoi(lgtLat[3]) + atof(lgtLat[4]) / 60 + atof(lgtLat[5]) / 3600;
			//printf("TD_LBS: %s %s %lf %lf\n", priLac, priCellid, *lgt, *lat);
		}


		if(*lgt < 0 || *lgt > 180)
			return false;
		if(*lat < 0 || *lat > 90)
			return false;

		return true;
}



//读取2D LBS文件数据: cellid, lac, 经度,纬度

bool hand_string_lbs_2d(char *line, char *priCellid, char *priLac,
	double *lgt, double *lat, TClosecellLocationRuleItem closeCellLoc){

		char *p1 = priCellid;
		char *p2 = priLac;
		char lgtLat[6][6];
		int num = 1;
		int i = 0;
		int j = 0;

		while(*line != '\0'){

			if(num == closeCellLoc.primaryLac && *line != 9 && *line != '|'){
				if(*line >= '0' && *line <= '9')
					*p2++ = *line;
				else
					return false;
			}
			else if(num == closeCellLoc.primaryCellid && *line != 9 && *line != '|'){
				if(*line >= '0' && *line <= '9')
					*p1++ = *line;
				else
					return false;
			}
			else if((num == closeCellLoc.lgitudeDeg || num == closeCellLoc.lgitudeMin || num == closeCellLoc.lgitudeSec ||
				num == closeCellLoc.latitudeDeg || num == closeCellLoc.latitudeMin || num == closeCellLoc.latitudeSec) && *line != 9 && *line != '|'){ 
					lgtLat[j][i++] = *line;
					if(*(line + 1) == 9 || *(line + 1) == '|'){
						lgtLat[j][i] = '\0';
						i = 0;
						j++;
					}
			}
			if((*line == 9 && *(line + 1) != 9) || *line == '|')
				num++;
			if(num == 15)
				break;

			line++;
		}

		*p1 = '\0';
		*p2 = '\0';


		*lgt = atoi(lgtLat[0]) + atof(lgtLat[1]) / 60 + atof(lgtLat[2]) / 3600;
		*lat = atoi(lgtLat[3]) + atof(lgtLat[4]) / 60 + atof(lgtLat[5]) / 3600;

		//printf("LBS: %s %s %lf %lf\n", priLac, priCellid, *lgt, *lat);
		if(*lgt < 0 || *lgt > 180)
			return false;
		if(*lat < 0 || *lat > 90)
			return false;

		return true;
}


//读取closecell 文件数:cellid, lac
bool hand_string_closecell(char *line, char *priCellid, char *priLac,
	char *closeCellid, char *closeLac, TClosecellRuleItem closeCellLoc){

		char *p2 = priCellid;
		char *p1 = priLac;
		char *p4 = closeCellid;
		char *p3 = closeLac;
		int num = 1;
	
                

		while(*line != '\0'){
			if(*line >= '0' && *line <= '9'){
				if(num == closeCellLoc.primaryLac){
					*p1++ = *line;
					 
				}
				else if(num == closeCellLoc.primaryCellid){
					*p2++ = *line;
					 
				}
				else if(num == closeCellLoc.adjacentLac){
					*p3++ = *line;
					 
				}
				else if(num == closeCellLoc.adjacentCellid){
					*p4++ = *line;
					
				}
			}
		  else if(*line != '|' && num != 1 && num !=4){
                            break;
			}
			if(*line == '|' )
				num++;
			line++;
		}

		*p1 = '\0';
		*p2 = '\0';
		*p3 = '\0';
		*p4 = '\0';

		return true;
}


//合并字符串,以cellid->lac->cellid格式合并
void merge_string(char *priData, char *priCellid, char *priLac, char *closeCellid){

	char *p1 = priCellid;
	char *p2 = priLac;
	char *p3 = closeCellid;


	strncpy(priData, p1, strlen(p1) + 1);
	strncat(priData, p2, strlen(p2) + 1);
	strncat(priData, p3, strlen(p3) + 1);

}


