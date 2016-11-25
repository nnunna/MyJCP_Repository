#!/bin/bash

set -xvf
####### Variables #########
EMAIL='SE-WAS-ADMIN-dl@jcp.com,OracleRMS-EnvironmentTeam-dl@jcp.com'
#EMAIL=nnunna@jcp.com
CONFIG=/root/naveen/RMS_Scripts/conf/servers_list.txt
WL_STATUS_REPORT=/root/naveen/RMS_Scripts/tmp/wl_status.html
STATUS=/root/naveen/RMS_Scripts/tmp/netstats.txt

####### Mail Function(uses SENDMAIL) ######
MAIL()
{
MAILTO="$1"
REPORT_FILE="$2"
SUBJECT="$3"
   (
     echo "From: JMonitor"
     echo "To: $MAILTO"
     echo "Subject: $SUBJECT Alerts!!"
     echo "MIME-Version: 1.0"
     echo "Content-Type: text/html"
     awk 'BEGIN{print "<html><body><table border=1 cellspacing=0 cellpadding=3>"} {print "<tr>""<td>" $1"</td>""<td>"$2"</td>""<td>"$3"</td>""<td>"$4"</td>""<td>""<font color=red>""<b>"$5"</b>""</font>""</td>""</tr>"} END{print "</table></body></html>"}' $REPORT_FILE 
     echo
    ) | /usr/sbin/sendmail -t
}

#############################################################
###### MAIN : To check WL status                    #########
#############################################################

while read env server port wl; do
   ssh -q $server -n "netstat -an | grep ":"$port | grep LISTEN " >> $STATUS
   if [ ! -s $STATUS ];then
      echo -e "$env $server $wl $port DOWN" >> $WL_STATUS_REPORT
	### Delete
	cat $WL_STATUS_REPORT
      rm -f $STATUS
   fi	
      rm -f $STATUS
done < $CONFIG

if [ -f "$WL_STATUS_REPORT" ];then
   ALERT="Weblogic Health Status"
   MAIL $EMAIL $WL_STATUS_REPORT "$ALERT"
fi
### Delete
cat $WL_STATUS_REPORT

rm -f $WL_STATUS_REPORT
