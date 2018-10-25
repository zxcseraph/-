/***********************************************************
*  Copyright(C) 2000 EASTCOM-BUPT Inc.
*
*  Filename             : $RCSfile: base.C,v $
*  Last Revision        : $Revision: 1.1 $
*  Last Revision Date   : $Date: 2012/07/19 08:36:04 $
*  Author               : 
*  Description          : 
**********************************************************/
/** \file 
* \brief 通用消息平台一些基本功能的实现
* 
*/
#include "base.h"
#include "string.h"
#include "closecellconfig.h"
#include <string>
using std::string;
	
int g_logFileCount = 0;
pthread_mutex_t g_commLogMutex = PTHREAD_MUTEX_INITIALIZER;

void TLogFunction::logInfo(const char *format, ...)
{
	va_list arg_ptr;
	va_start(arg_ptr, format);
	/*added by ligy for linux64 (CR000896) begin*/
#ifdef _LINUX64_
	va_list arg_ptrtmp;
	va_copy(arg_ptrtmp, arg_ptr);
	logToFile(format, arg_ptr, "INFO", 1);
	logToStdOut(format, arg_ptrtmp, "INFO", 1);
#else
	logToFile(format, arg_ptr, "INFO", 1);
	//logToStdOut(format, arg_ptr, "INFO", 1);
#endif
	/*added by ligy for linux64 (CR000896) end*/
	va_end(arg_ptr);
}

void TLogFunction::logError(const char *format, ...)
{
	va_list arg_ptr;
	va_start(arg_ptr, format);
	/*added by ligy for linux64 (CR000896) begin*/
#ifdef _LINUX64_
	va_list arg_ptrtmp;
	va_copy(arg_ptrtmp, arg_ptr);
	logToFile(format, arg_ptr, "ERROR", 1);
	logToStdOut(format, arg_ptrtmp, "ERROR", 1);
#else
	logToFile(format, arg_ptr, "ERROR", 1);
	//logToStdOut(format, arg_ptr, "ERROR", 1);
#endif
	/*added by ligy for linux64 (CR000896) end*/
	va_end(arg_ptr);
}

void TLogFunction::logInfo2(const char *format, ...)
{

	va_list arg_ptr;
	va_start(arg_ptr, format);
	/*added by ligy for linux64 (CR000896) begin*/
#ifdef _LINUX64_
	va_list arg_ptrtmp;
	va_copy(arg_ptrtmp, arg_ptr);
	logToFile(format, arg_ptr, "INFO", 2);
	logToStdOut(format, arg_ptrtmp, "INFO", 2);
#else
	logToFile(format, arg_ptr, "INFO", 2);
	logToStdOut(format, arg_ptr, "INFO", 2);
#endif
	/*added by ligy for linux64 (CR000896) end*/
	va_end(arg_ptr);
}

void TLogFunction::logError2(const char *format, ...)
{

	va_list arg_ptr;
	va_start(arg_ptr, format);
	/*added by ligy for linux64 (CR000896) begin*/
#ifdef _LINUX64_
	va_list arg_ptrtmp;
	va_copy(arg_ptrtmp, arg_ptr);
	logToFile(format, arg_ptr, "ERROR", 2);
	logToStdOut(format, arg_ptrtmp, "ERROR", 2);
#else
	logToFile(format, arg_ptr, "ERROR", 2);
	logToStdOut(format, arg_ptr, "ERROR", 2);
#endif
	/*added by ligy for linux64 (CR000896) end*/
	va_end(arg_ptr);
}

void TLogFunction::logInfo3(const char *format, ...)
{

	va_list arg_ptr;
	va_start(arg_ptr, format);
	logToStdOut(format, arg_ptr, "INFO", 3);
	va_end(arg_ptr);
}

void TLogFunction::logError3(const char *format, ...)
{

	va_list arg_ptr;
	va_start(arg_ptr, format);
	logToStdOut(format, arg_ptr, "ERROR", 3);
	va_end(arg_ptr);
}

void TLogFunction::logInfo4(const char *format, ...)
{

	va_list arg_ptr;
	va_start(arg_ptr, format);
	logToStdOut(format, arg_ptr, "INFO", 4);
	va_end(arg_ptr);
}

void TLogFunction::logStr(const char *s, int len, int level)
{

	int i;
	for (i=0; i<len; i++)
	{
		if (((unsigned char)s[i] >= (unsigned char)32)
			&& ((unsigned char)s[i] <= (unsigned char)126))
		{
			printf("%c", s[i]);
		}
		else
		{
			printf("\\x%02x", (unsigned char)s[i]);
		}
	}
	printf("\n");
	fflush(stdout);
}

void TLogFunction::logHex(const char *s, int len, int level)
{

	char line[32];
	int i;
	for (i=0; i<len; i++)
	{
		if ((i%16)==0)
		{
			printf("\n%06d ", i);
			memset(line, 0, sizeof(line));
		}
		printf(" %02X", (unsigned char)s[i]);
		line[i%16] = (s[i]<' ' && s[i]>='\0') ? '.' : s[i];
		if ((i%16)==15)
		{
			printf("  %s", line);
		}
	}
	if ((len%16)!=0)
	{
		printf("%*s  %s", 3*(16-(len%16)), "", line);
	}
	printf("\n\n");
	fflush(stdout);
}

/**
* 打开日志文件，先计算时间戳，再写入信息。
* \note 在Unix下打开的文件可以被删除而且进程无法获知，
* 所以需要在每次写文件之前都重新打开文件
*
*/
void TLogFunction::logToFile(const char *format, va_list arg_ptr,
	const char *prefix, int level)
{
	pthread_mutex_lock(&g_commLogMutex);
	static FILE	*fp = 0;
	static bool needOpen = true;
	if (needOpen)
	{
		if (fp)
		{
			fclose(fp);
		}
		const string &logFileName = TClosecellConfig::getInstance()->geLogFileName();
		fp = fopen(logFileName.c_str(), "a+");
		if (fp == 0)
		{
			printf("Cannot open log file %s!\n", logFileName);
			logToStdOut(format, arg_ptr, prefix, level);
			pthread_mutex_unlock(&g_commLogMutex);
			return;
		}
		needOpen = false;
	}

	int nwrite = 0;
	static int oldYday = 9999;
	time_t		timer;
	struct tm	*tblock;
	timer = time(0);
	tblock = localtime(&timer);
	if (oldYday != tblock->tm_yday)
	{
		nwrite = fprintf(fp, "\n%s\n", ctime(&timer));
		needOpen = needOpen || (nwrite<0);
		oldYday = tblock->tm_yday;
	}
	nwrite = fprintf(fp,
		"%02d:%02d:%02d:%5s%1d ",
		(int)tblock->tm_hour,
		(int)tblock->tm_min,
		(int)tblock->tm_sec,
		prefix,
		level);
	needOpen = needOpen || (nwrite<0);
	nwrite = vfprintf(fp, format, arg_ptr);
	needOpen = needOpen || (nwrite<0);
	nwrite = fprintf(fp, "\n");
	needOpen = needOpen || (nwrite<0);
	nwrite = fflush(fp);
	needOpen = needOpen || (nwrite==EOF);
	/* 在Unix下打开的文件可以被删除而且进程无法获知，
	所以需要在每次写文件之前都重新打开文件。*/
	needOpen = true;

	if (!(++g_logFileCount % 500000))
	{
		oldYday = 9999;
		needOpen = true;
		char xxx[256];
		time_t timer;
		struct tm block;
		struct tm *tblock = &block;

		timer = time( NULL );
		localtime_r( &timer ,tblock);
		sprintf(xxx,".%04d%02d%02d%02d%02d", (int)tblock->tm_year+1900,(int)tblock->tm_mon+1,(int)tblock->tm_mday,
			(int)tblock->tm_hour,(int)tblock->tm_min);
		const string &logFileName = TClosecellConfig::getInstance()->geLogFileName();;
		string bakFileName = logFileName + string(xxx);
		unlink(bakFileName.c_str());
		rename(logFileName.c_str(), bakFileName.c_str());
	}
	pthread_mutex_unlock(&g_commLogMutex);
}

void TLogFunction::logToStdOut(const char *format, va_list arg_ptr,
	const char *prefix, int level)
{
	//const string &processName = TConfig::getInstance()->get_processName();
	printf("%5s%1d ", prefix, level);
	vprintf(format, arg_ptr);
	printf("\n");
	fflush(stdout);
}

