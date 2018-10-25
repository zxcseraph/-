/*
 *  Copyright(C) 2000 EASTCOM-BUPT Inc.
 *
 *  Filename            : $RCSfile: basestationstruct.C,v $
 *  Last Revision       : $Revision: 1.2 $
 *  Last Revision Date  : $Date: 2012/07/19 08:15:15 $
 *  Description         :
 */
#include "closecellall.h"

double max(double x, double y){
	return (x > y ? x : y);
}

//�� base_station_s���ݲ�����headΪͷ������
base_station_t insert_base_station(base_station_t head, base_station_t baseStation){
	base_station_t p = head->next;
	base_station_t pre = head;

	if(p == NULL){
		head->next = baseStation;
		return head;
	}
	while(p){
		if(baseStation->sum < p->sum)
			break;
		pre = p;
		p = p->next;
	}
	pre->next = baseStation;
	baseStation->next = p;
	return head;
}

//��ʼ�ж���һ����ΧС��������С��������
base_station_t first_find_base_station_closecell(base_station_t baseStation){
	base_station_t p = baseStation->next;
	base_station_t pre = p;

	double calValue;   
	double lgtValue = TClosecellConfig::getInstance()->getLgtValue();
	double latValue = TClosecellConfig::getInstance()->getLatValue();
	double refDistance = TClosecellConfig::getInstance()->getRefDistance();
	double stdValue = TClosecellConfig::getInstance()->getStdValue();
		
	//printf("first_find_base_station_closecell %lf %lf %lf %lf\n", lgtValue, latValue, refDistance, stdValue);

	calValue = stdValue / refDistance * max(lgtValue,latValue) * 2; //�ó�1����(����)���γ����ֵ�Ĳ��
	//printf("first_find_base_station_closecell %lf %lf %lf %lf calValue: %lf\n", lgtValue, latValue, refDistance, stdValue, calValue);
	while(p && pre){
		if((baseStation->sum - p->sum) > calValue)
			break; 
		pre = p;
		p = p->next;
	}
	return p;
}

//�ҳ�1����(����)��С��������
bool find_base_station_closecell(double lgtBase, double latBase, double lgtClose, double latClose){
	double latDistance;
	double lgtDistance;
	double calDistance;

	double lgtValue = TClosecellConfig::getInstance()->getLgtValue();
	double latValue = TClosecellConfig::getInstance()->getLatValue();
	double refDistance = TClosecellConfig::getInstance()->getRefDistance();
	double stdValue = TClosecellConfig::getInstance()->getStdValue();

  //printf("find_base_station_closecell %lf %lf %lf %lf\n", lgtValue, latValue, refDistance, stdValue);
	if(lgtBase > lgtClose)
		lgtDistance = lgtBase - lgtClose;
	else
		lgtDistance = lgtClose - lgtBase;

	if(latBase > latClose)
		latDistance = latBase - latClose;
	else
		latDistance = latClose - latBase;

	calDistance = sqrt(((lgtDistance / lgtValue) * (lgtDistance / lgtValue) + 
		(latDistance / latValue) * (latDistance /latValue)) * refDistance * refDistance);  

	if(calDistance < stdValue)
		return true;
	else
		return false;	
}


//�ͷ�base_station_s�ṹ�ڴ�
base_station_t free_base_station(base_station_t head){
	base_station_t p = head->next;
	base_station_t pLast;

	while(p){
		pLast = p->next;
		free(p);
		p = pLast;
	}
	return head;
}