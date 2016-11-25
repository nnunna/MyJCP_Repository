#!/bin/bash -xvf

####### Variables #########
#EMAIL=SE-WAS-ADMIN-dl@jcp.com
EMAIL=nnunna@jcp.com
CONFIG=/root/naveen/SOMA_Scripts/config/servers_list.txt
PORT_STATUS=/tmp/port_status.txt
JVM_STATUS=/tmp/jvm_status_report.txt

####### Mail Function(uses SENDMAIL) ######
MAIL()
{
MAILTO="$1"
REPORT_FILE="$2"
SUBJECT="$3"
        (
         echo "From: Jspy"
         echo "To: Team <$MAILTO>"
         echo "Subject: $SUBJECT!!"
         echo "MIME-Version: 1.0"
         echo "Content-Type: text/html"
         echo "<html>"
         cat $REPORT_FILE | sed -e 's/^/<br>/g'
         echo "</html>"
         echo
        ) | /usr/sbin/sendmail -t
}

#############################################################
###### MAIN : Monitor the JVM status                #########
#############################################################

while read host app jvm port;do
	ssh -q $host -l wlsoper -n "netstat -an | grep $port | grep LISTEN" >> $PORT_STATUS 
	if [ ! -s "$PORT_STATUS" ]
	then
		echo -e "<font color="blue">$app $jvm on <font color="green">$host</font> is <font color="red">DOWN!!!</font></font>" >> $JVM_STATUS
		if [ "$jvm" = "AdminServer" ]; then
			echo -e "<font color="blue"> Attempting to start the $jvm on $host....,</font><font color="red">If you see this alert again Please contact WL Team</font>" >> $JVM_STATUS
			ssh -q $host -l wlsoper -n "cd /usr/wls/user_projects/domains/"$app"_domain/bin;. ./startWebLogic.sh &" &
		elif [ "$jvm" = "NodeManager" ]; then
                        echo -e "<font color="blue"> Attempting to start the $jvm on $host....,</font><font color="red">If you see this alert again Please contact WL Team</font>" >> $JVM_STATUS
                        ssh -q $host -l wlsoper -n "cd /usr/wls/user_projects/domains/"$app"_domain/bin;. ./setDomainEnv.sh;nohup /usr/wls/user_projects/domains/"$app"_domain/bin/startNodeManager.sh &"
		else
			echo -e "<font color="red">Please contact WL Team if this not a planned maintenance</font>" >> $JVM_STATUS 
		fi
	fi
	rm -f $PORT_STATUS	
done < $CONFIG

if [ -f "$JVM_STATUS" ];then
{
  ALERT="SOMA PROD JVM's Status Report"
  MAIL $EMAIL $JVM_STATUS "$ALERT"
  rm -f $JVM_STATUS
}
fi
