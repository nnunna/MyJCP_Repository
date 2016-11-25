#!/bin/bash

####### Variables #########
EMAIL=SE-WAS-ADMIN-dl@jcp.com
#EMAIL=nnunna@jcp.com
#MMAIL=
TEMP=/tmp
DISK_SPACE_ALERT_THRESHOLD=85
MEMORY_THRESHOLD=90
SWAP_MEMORY_THRESHOLD=90
CONFIG=/root/naveen/conf/PROD.txt
DISK_SPACE_REPORT=$TEMP/consolidated_disk_alert_report.html
MEMORY_USAGE_REPORT=$TEMP/consolidated_memory_usage_report.html
SWAP_USAGE_REPORT=$TEMP/consolidated_swap_usage_report.html

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
for server in `cat $CONFIG`;
do
   ssh -q $server -l root -n "df -H | grep -w 'usr\|tmp' | awk '{print \$5, \$6}'" >> $TEMP/server_disk.txt
   #ssh -q $server -l root -n "df -H | grep -v Use | awk '{print \$5, \$6}'" >> $TEMP/$server_disk.txt
   while read usage filesystem;do
        use_percent=`cut -d '%' -f 1 <<< $usage`
        if [ $use_percent -gt $DISK_SPACE_ALERT_THRESHOLD ];
        then
           echo -e "<font color="blue">$filesystem on <font color="green">$server <font color="blue">is <font color="red">$use_percent%</font></font></font></font>" >>$DISK_SPACE_REPORT
        fi
   done < $TEMP/server_disk.txt
   rm -f $TEMP/server_disk.txt
done

if [ -f "$DISK_SPACE_REPORT" ];then
{
   ALERT="Disk Space"
   MAIL $EMAIL $DISK_SPACE_REPORT "$ALERT"
   rm -f $DISK_SPACE_REPORT
}
fi

##### Cleanup #####
rm -f $TEMP/server_disk.txt

###############################################################
###### MAIN : To gather Memory Utilization Statistics #########
###############################################################

for server in `cat $CONFIG`;
do
   ssh -q $server -l root -n "cat /proc/meminfo | grep 'MemTotal\|MemFree\|SwapTotal\|SwapFree'" >> $TEMP/server_disk.txt
   i=0	
   while read mem val junk;do
	mem_val[i]=$val
	i=`expr $i + 1`
   done < $TEMP/server_disk.txt
#	echo "Memory:" ${mem_val[@]}
   MEM_PERCENT_USAGE=`cut -d "." -f 1 <<< $(awk "BEGIN {printf \"%.2f\",((${mem_val[0]} - ${mem_val[1]})/${mem_val[0]})*100}")` 
	if [ $MEM_PERCENT_USAGE -gt $MEMORY_THRESHOLD ];then
           echo -e "<font color="blue">Memory on <font color="green">$server <font color="blue">is <font color="red">$MEM_PERCENT_USAGE%</font></font></font></font>" >>$MEMORY_USAGE_REPORT
	fi
   SWAP_PERCENT_USAGE=`cut -d "." -f 1 <<< $(awk "BEGIN {printf \"%.2f\",((${mem_val[2]} - ${mem_val[3]})/${mem_val[3]})*100}")`
	if [ $SWAP_PERCENT_USAGE -gt $SWAP_MEMORY_THRESHOLD ];then
           echo -e "<font color="blue">SWAP Memory on <font color="green">$server <font color="blue">is <font color="red">$MEM_PERCENT_USAGE%</font></font></font></font>" >>$SWAP_USAGE_REPORT
	fi

rm $TEMP/server_disk.txt  		
done

if [ -f "$MEMORY_USAGE_REPORT" ];then
{
   ALERT="Memory Usage"
   MAIL $EMAIL $MEMORY_USAGE_REPORT "$ALERT"
   rm -f $MEMORY_USAGE_REPORT
}
fi
	
if [ -f "$SWAP_USAGE_REPORT" ];then
{
   ALERT="SWAP Usage"
   MAIL $EMAIL $SWAP_USAGE_REPORT "$ALERT"
   rm -f $SWAP_USAGE_REPORT
}
fi


##### Cleanup #####
rm -f $TEMP/server_disk.txt
