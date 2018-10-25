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

/// 实现日志功能的名字空间
namespace		TLogFunction
{
	/// 记录一级信息，重要模块级和进程级事件。
	void	logInfo(const char *format, ...);
	/// 记录二级信息，重要函数级和模块级事件。
	void	logInfo2(const char *format, ...);
	/// 记录三级信息，函数级事件和主要流程。
	void	logInfo3(const char *format, ...);
	/// 记录四级信息，流程详细信息。
	void	logInfo4(const char *format, ...);

	/// 记录一级错误，重要模块级和进程级错误。
	void	logError(const char *format, ...);
	/// 记录二级错误，重要函数级和模块级错误。
	void	logError2(const char *format, ...);
	/// 记录三级错误，函数级错误和流程错误。
	void	logError3(const char *format, ...);

	/// 将字符串写入文件
	void logToFile(const char *format, va_list arg_ptr, 
			const char *prefix, int level);
	/// 将字符串写入标准输出
	void logToStdOut(const char *format, va_list arg_ptr, 
			const char *prefix, int level);

	/// 记录字符串数据，可以设定记录级别。
	void	logStr(const char *s, int len, int level=3);
	/// 记录二进制数据，可以设定记录级别。
	void	logHex(const char *s, int len, int level=3);
};


#endif

