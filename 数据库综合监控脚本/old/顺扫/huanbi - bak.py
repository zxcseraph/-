# -*- coding: UTF-8 -*- 
#接受5个参数
#如果单文件对比，则第一个是输入文件，第二个是输出文件，第三个是排除个数，第四个是基准字段，最后一个参数为signle
#如果是两文件对比，则第一个参数是旧文件，第二个是新文件，第三个是输出文件，第四个是排除个数，第五个是基准字段
import linecache;
import sys;
def huanbi(str1,str2,paichu1,jizhun1):
		#第一二个参数是要环比的行，第三个参数是排除的个数，且是从第一个开始算，第四个是需要比较的基准字段
    str1=str1[:-1];
    str2=str2[:-1];
    list1=str1.split('|');
    list2=str2.split('|');
    int1=int(paichu1);
    jizhun1=int(jizhun1)-1;
    if list1[jizhun1] != list2[jizhun1]:
        print("多行文件环比中，两个文件相同行的基准字段不同，请重新确认");
        exit(1);
    result=str('');
    it=0;
    while (it<int1):
        result=result+list2[it]+'|';
        it=it+1;
    if len(list1) == len(list2):
        i=int1;
        while (i<len(list1)):
            t=round(float(list2[i]),5)-round(float(list1[i]),5);
            result=result+str(t)+'|';
            i+=1
        return result
    else:
        return "error";

if __name__ == '__main__':
    argcount=len(sys.argv[1:]);
    if argcount == 5:
        if sys.argv[5] == "signle":
            inputfile=sys.argv[1];
            outputfile=sys.argv[2];
            paichu=int(sys.argv[3]);
            jizhun=int(sys.argv[4]);
            linecount = len(open(inputfile,'rU').readlines());
            hang=int(0);
            while hang<linecount-1:
                lasthang=int(hang);
                newhang=int(hang)+1;
                str1=str(linecache.getlines(inputfile)[lasthang]);
                str1=str1.strip('\n');
                str2=str(linecache.getlines(inputfile)[newhang]);
                str2=str2.strip('\n');
                outfile=open(outputfile,"a");
                newstr=huanbi(str1,str2,paichu,jizhun);
                outfile.write(newstr+"\n");
                outfile.close();
                hang=hang+1;
            exit(0);
        else:
            lastfile=sys.argv[1];
            newfile=sys.argv[2];
            outputfile=sys.argv[3];
            paichu=int(sys.argv[4]);
            jizhun=int(sys.argv[5]);
            count1 = len(open(lastfile,'rU').readlines());
            count2 = len(open(newfile,'rU').readlines());
            if count1 != count2:
                print("多行文件环比操作的两个文件，行数不同");
                exit(1);
            hang=int(0);
            while hang<count2:
                str1=str(linecache.getlines(lastfile)[hang]);
                str1=str1.strip('\n');
                str2=str(linecache.getlines(newfile)[hang]);
                str2=str2.strip('\n');
                outfile=open(outputfile,"a");
                newstr=huanbi(str1,str2,paichu,jizhun);
                outfile.write(newstr+"\n");
                outfile.close();
                hang=hang+1;
            exit(0);
    else:
        print("python程序环比计算huanbi，收到的参数个数不为5个");
        exit(1);

