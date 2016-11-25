#!/bin/bash

#set -xvf

####### Variables #########
#EMAIL=SE-WAS-ADMIN-dl@jcp.com
EMAIL=nnunna@jcp.com
TEMP=/root/naveen/DP/GRID/DMP_Alert/tmp
CONFIG=/root/naveen/DP/GRID/DMP_Alert/conf/PROD.txt
FILE_PATH=/DT/goldenGateJavaAdapter
DMP_REPORT=$TEMP/consolidated_dmp_file_report.html
DATE=`date | awk '{print $2$3$6"_"$4}'`

####### Mail(uses SENDMAIL) ######
MAIL()
{
MAILTO="$1"
REPORT_FILE="$2"
SUBJECT="$3"
        (
         echo "From: iSpy"
         echo "To: Team <$MAILTO>"
         echo "Subject: $SUBJECT Alerts!!"
         echo "MIME-Version: 1.0"
         echo "Content-Type: text/html"
         echo "<html>"
         cat $REPORT_FILE | sed -e 's/^/<br>/g'
         echo "</html>"
         echo
        ) | /usr/sbin/sendmail -t
}

#############################################################
###### MAIN : To gather Disk Utilization Statistics #########
#############################################################
### Log into each server and get the FileSystem Usage

for server in `cat $CONFIG`;
do
  ssh -q $server -l root -n "ls $FILE_PATH/gglog*.dmp" >> $TEMP/${server}_File_list.txt	
  if [ -s $TEMP/${server}_File_list.txt ] && [ -f $TEMP/${server}_File_list.txt ];then
     echo -e "<font color="blue">${server}</font> have the below files:\n<font color="red">`cat $TEMP/${server}_File_list.txt`</font>" >> $DMP_REPORT 
	if [ -s $TEMP/${server}_File_list.txt ];then
		for x in `cat $TEMP/${server}_File_list.txt`;do
			fname=`echo $x |cut -d'/' -f 4`"."$DATE
			ssh -q $server -l root -n "mv $x $FILE_PATH/Archive/$fname"
		done
	fi 
  fi
rm -f $TEMP/${server}_File_list.txt
done

if [ -f "$DMP_REPORT" ];then
{
  ALERT="File exist Alert"
  MAIL $EMAIL $DMP_REPORT "$ALERT"
  rm -f $DMP_REPORT
}
fi


##### Cleanup #####
