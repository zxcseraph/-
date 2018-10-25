/*
 *  Copyright(C) 2000 EASTCOM-BUPT Inc.
 *
 *  Filename            : $RCSfile: base.h,v $
 *  Last Revision       : $Revision: 1.1 $
 *  Last Revision Date  : $Date: 2012/07/19 08:36:06 $
 *  Description         :
 */
#ifndef _BASE_H
#define _BASE_H
#include "stdio.h"
#include "stdarg.h"
#include<pthread.h> 

/// ʵ����־���ܵ����ֿռ�
namespace		TLogFunction
{
	/// ��¼һ����Ϣ����Ҫģ�鼶�ͽ��̼��¼���
	void	logInfo(const char *format, ...);
	/// ��¼������Ϣ����Ҫ��������ģ�鼶�¼���
	void	logInfo2(const char *format, ...);
	/// ��¼������Ϣ���������¼�����Ҫ���̡�
	void	logInfo3(const char *format, ...);
	/// ��¼�ļ���Ϣ��������ϸ��Ϣ��
	void	logInfo4(const char *format, ...);

	/// ��¼һ��������Ҫģ�鼶�ͽ��̼�����
	void	logError(const char *format, ...);
	/// ��¼����������Ҫ��������ģ�鼶����
	void	logError2(const char *format, ...);
	/// ��¼�������󣬺�������������̴���
	void	logError3(const char *format, ...);

	/// ���ַ���д���ļ�
	void logToFile(const char *format, va_list arg_ptr, 
			const char *prefix, int level);
	/// ���ַ���д���׼���
	void logToStdOut(const char *format, va_list arg_ptr, 
			const char *prefix, int level);

	/// ��¼�ַ������ݣ������趨��¼����
	void	logStr(const char *s, int len, int level=3);
	/// ��¼���������ݣ������趨��¼����
	void	logHex(const char *s, int len, int level=3);
};


#endif

