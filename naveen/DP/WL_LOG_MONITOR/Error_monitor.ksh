#!/bin/bash

ERROR_DEF=/root/naveen/DP/WL_LOG_MONITOR/conf/Error_List.txt
SERVER_LIST=/root/naveen/DP/WL_LOG_MONITOR/conf/mac_list.txt
TMP=/root/naveen/DP/WL_LOG_MONITOR/tmp
TDATE=`date | awk '{print $2, $3 ",",$6}'`
TFRAME=$1
#EMAIL=nnunna@jcp.com
EMAIL="nnunna@jcp.com,vramanik@jcp.com"
#EMAIL=SE-WAS-ADMIN-dl@jcp.com


####### Mail Function(uses SENDMAIL) ######
MAIL()
{
   (
	echo "From: JMonitor"
	echo "To: $EMAIL"
	echo "Subject: WL Alerts!! 12"$TFRAME" - 12"$TFRAME""
	echo "MIME-Version: 1.0"
	echo "Content-Type: text/html charset=iso-8859-1' . "\r\n""
	echo "<html><body><table border=1 cellspacing=0 cellpadding=3>"
	echo "<td><font color="black"><b>Server Name</font></b></td>"
	echo "<td><font color="black"><b>JVM Name</font></b></td>"
	echo "<td><font color="black"><b>Error Message</font></b></td>"
	echo "<td><font color="black"><b>Count</font></b></td>"
	while read mac jvm count junk;do
		echo "<tr>"
		echo "<td><font color="black">$mac</font></td>"
		echo "<td><font color="green">$jvm</font></td>"
		echo "<td><font color="red">$junk</font></td>"
		echo "<td><font color="blue">$count</font></td>"
                echo "</tr>"
	done < $TMP/Reports
	echo "</html>"
	echo
    ) | /usr/sbin/sendmail -t
}

#############
## Get FIle #
#############

if [ -z $1 ];then
   echo "Enter AM/PM to get the report"
   exit
fi

while read mac jvm;do
	scp -qp "$mac":/usr/wls/wlserver_12.1.3/user_projects/domains/dt*_domain/servers/"$jvm"/logs/"$jvm"*.out $TMP/"$jvm".out
	for ERR in `cat $ERROR_DEF`;do
		#grep -i $ERR $TMP/"$jvm".out | grep '[0-9][0-9]:[0-9][0-9]:[0-9][0-9] '${TFRAME}'\|[0-9]:[0-9][0-9]:[0-9][0-9] '${TFRAME}'' | grep "$TDATE" > $TMP/"$jvm"_"$ERR"_list
		#grep -i $ERR $TMP/"$jvm".out | grep "$TDATE" > $TMP/"$jvm"_"$ERR"_list
		grep -i $ERR $TMP/"$jvm".out > $TMP/"$jvm"_"$ERR"_list
 		if [ -s $TMP/"$jvm"_"$ERR"_list ];then
	    		echo -e "$mac " " $jvm " "`wc -l $TMP/"$jvm"_"$ERR"_list | cut -f 1 -d " "` " " `cat $TMP/"$jvm"_"$ERR"_list | head -1 | cut -d ">" -f 2- | perl -i -pe 's/</&lt;/g;' -pe 's/>/&gt;/g'`" >> $TMP/Reports
 		else
    			sed -n '/\'${TDATE}'\ [0-9][0-9]:[0-9][0-9]:[0-9][0-9] '${TFRAME}'/,/\'${TDATE}'\ [0-9][0-9]:[0-9][0-9]:[0-9][0-9] '${TFRAME}'/p' | grep -i $ERR $TMP/"$jvm".out > $TMP/"$jvm"_"$ERR"_list
			if [ -s $TMP/"$jvm"_"$ERR"_list ];then
	    			echo -e "$mac " " $jvm " "`wc -l $TMP/"$jvm"_"$ERR"_list | cut -f 1 -d " "` " " `cat $TMP/"$jvm"_"$ERR"_list | head -1 | cut -d ">" -f 2- | perl -i -pe 's/</&lt;/g;' -pe 's/>/&gt;/g'`" >> $TMP/Reports
			fi
 		fi
	done
done < $SERVER_LIST 

if [ -f $TMP/Reports ];then
	sort -k 3 $TMP/Reports >> $TMP/Reports1
	mv $TMP/Reports1 $TMP/Reports
	MAIL
fi

rm -f /root/naveen/DP/WL_LOG_MONITOR/tmp/*
