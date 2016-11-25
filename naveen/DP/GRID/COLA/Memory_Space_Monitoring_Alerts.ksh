#!/bin/bash 

####### Variables #########
EMAIL=SE-WAS-ADMIN-dl@jcp.com
#EMAIL="SE-WAS-ADMIN-dl@jcp.com;2192085653@txt.att.net"
#EMAIL="nnunna@jcp.com, 2192085653@txt.att.net"
TEMP=/root/naveen/DP/GRID/COLA/tmp
DISK_SPACE_ALERT_THRESHOLD=78
MEMORY_THRESHOLD=80
SWAP_MEMORY_THRESHOLD=50
CONFIG=/root/naveen/DP/GRID/COLA/conf/PROD.txt
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

	 if [ -f $TEMP/uniq_server_count.txt ];then
         	echo "<html><body><table border=1 cellspacing=0 cellpadding=3>"
	 	 while read count uniq_mac; do
 			echo "<tr>"
		 	repeat_counter=1
	 	 	while read mac fs percent;do
				if [ "$uniq_mac" == "$mac" ] && [ $repeat_counter -eq 1 ];then
					echo "<th rowspan="$count"><font color="green">$uniq_mac</font></th>"
					echo "<td><font color="blue">$fs</font></td>"
					echo "<td><font color="red">$percent</font></td>"	
		 			echo "</tr>"
					repeat_counter=`expr $repeat_counter + 1`
				elif [ "$uniq_mac" == "$mac" ] && [ $repeat_counter -le $count ];then
					echo "<td><font color="blue">$fs</font></td>"
					echo "<td><font color="red">$percent</font></td>"	
		 			echo "</tr>"
					repeat_counter=`expr $repeat_counter + 1`
				fi

	 		 done < $REPORT_FILE
			 echo "</tr>"
		 done < $TEMP/uniq_server_count.txt
		 rm -f $TEMP/uniq_server_count.txt
        	 echo "</table></body></html>"
	 else
	         echo "<html>"
        	 cat $REPORT_FILE | sed -e 's/^/<br>/g'
         	 echo "</html>"
		 touch $TEMP/mem_inc1
	 fi
         echo
        ) | /usr/sbin/sendmail -t
#mailx -s "$SUBJECT Alerts!!" 2192085653@txt.att.net
}

#############################################################
###### MAIN : To gather Disk Utilization Statistics #########
#############################################################
### Log into each server and get the FileSystem Usage

#set -xvf

for server in `cat $CONFIG`;
do
  ssh -q $server -l root -n "df -PH | grep -w 'usr\|tmp\|var\|home\|opt' | awk '{print \$5, \$6}'" >> $TEMP/server_disk.txt
  #ssh -q $server -l root -n "df -PH | grep -v Use | awk '{print \$5, \$6}'" >> $TEMP/$server_disk.txt
  while read usage filesystem;do
    use_percent=`cut -d '%' -f 1 <<< $usage`
    if [ $use_percent -gt $DISK_SPACE_ALERT_THRESHOLD ];
      then
#        echo -e "<font color="green">$server <font color="blue">$filesystem <font color="red">$use_percent%</font></font></font>" >>$DISK_SPACE_REPORT
	 echo -e "$server $filesystem $use_percent%" >>$DISK_SPACE_REPORT
    fi
  done < $TEMP/server_disk.txt
  rm -f $TEMP/server_disk.txt
done

### If report file exists, send an alert email and remove the report file
if [ -f "$DISK_SPACE_REPORT" ];then
{
   ALERT="Disk Space"
   cat $DISK_SPACE_REPORT | awk '{print $1}' | uniq -c >> $TEMP/uniq_server_count.txt
   MAIL $EMAIL $DISK_SPACE_REPORT "$ALERT"
   rm -f $DISK_SPACE_REPORT
}
fi

##### Cleanup #####
rm -f $TEMP/server_disk.txt

###############################################################
###### MAIN : To gather Memory Utilization Statistics #########
###############################################################

### Log into each server and get the Memory & SWAP Usage
for server in `cat $CONFIG`;
do
	ssh -q $server -l root -n "cat /proc/meminfo | grep 'MemTotal\|MemFree\|SwapTotal\|SwapFree'" >> $TEMP/server_memory.txt
	i=0
 
	while read mem val junk;do
		mem_val[i]=$val
		i=`expr $i + 1`
	done < $TEMP/server_memory.txt

### If memory usage % is more than the threshold, then report
	MEM_PERCENT_USAGE=`cut -d "." -f 1 <<< $(awk "BEGIN {printf \"%.2f\",((${mem_val[0]} - ${mem_val[1]})/${mem_val[0]})*100}")`
	SWAP_PERCENT_USAGE=`cut -d "." -f 1 <<< $(awk "BEGIN {printf \"%.2f\",((${mem_val[2]} - ${mem_val[3]})/${mem_val[3]})*100}")`
    	if [ $MEM_PERCENT_USAGE -gt $MEMORY_THRESHOLD ] && [ $SWAP_PERCENT_USAGE -gt $SWAP_MEMORY_THRESHOLD ];then
      		echo -e "<font color="blue">Memory on <font color="green">$server <font color="blue">is <font color="red">$MEM_PERCENT_USAGE%<font color="blue"> and SWAP is at <font color="red">$SWAP_PERCENT_USAGE%</font></font></font></font></font></font>" >>$MEMORY_USAGE_REPORT
    	fi

	rm $TEMP/server_memory.txt
done

### If report file exists, send an alert email and remove the report file
if [ -f "$MEMORY_USAGE_REPORT" ];then
{
	ALERT="Memory Usage"
	MAIL $EMAIL $MEMORY_USAGE_REPORT "$ALERT"
	rm -f $MEMORY_USAGE_REPORT
}
fi

##### Cleanup #####
rm -f $TEMP/server_memory.txt

