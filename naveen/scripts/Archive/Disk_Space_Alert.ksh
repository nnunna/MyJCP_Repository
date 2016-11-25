#!/bin/bash

####### Variables #########
EMAIL=SE-WAS-ADMIN-dl@jcp.com
#EMAIL=nnunna@jcp.com
#MMAIL=
TEMP=/tmp
CPU_THRESHOLD=35
CONFIG=/root/naveen/conf/PROD.txt
PROCESS_CPU_UTLIZATION=$TEMP/consolidated_user_cpu_report.html
SYSTEM_CPU_UTLIZATION=$TEMP/consolidated_system_cpu_report.html
IO_CPU_UTLIZATION=$TEMP/consolidated_io_cpu_report.html

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
###### MAIN : To gather CPU Utilization Statistics #########
#############################################################
for server in `cat $CONFIG`;
do
   ssh -q $server -l root -n "sar -u 5 4 | grep -i all | grep -v Average | awk '{print \$1\$2, \$4, \$6, \$7}'" >> $TEMP/server_cpu.txt
      i=0
   while read time_p user_p sys_p io_p; do
      time[$i]=$time_p
      user[$i]=`cut -d "." -f 1 <<< $user_p`
      sys[$i]=`cut -d "." -f 1 <<< $sys_p` 	
      io[$i]=`cut -d "." -f 1 <<< $io_p`

      i=`expr $i + 1`
   done < $TEMP/server_cpu.txt
	if [ ${user[3]} -gt ${user[2]} ] && [ ${user[2]} -gt ${user[1]} ] || [ ${user[1]} -gt ${user[0]} ];then
	   if [ ${user[3]} -gt $CPU_THRESHOLD ] && [ ${user[2]} -gt $CPU_THRESHOLD ];then
		echo -e "${time[3]}: <font color="blue">PROCESS CPU utilization on <font color="green">$server is <font color="red">${user[3]}%</font></font></font>" >> $PROCESS_CPU_UTLIZATION
		echo -e "\t\tTop 3 CPU Monster's:\n" >> $PROCESS_CPU_UTLIZATION
   		ssh -q $server -l root -n "ps -eo pcpu,pid,user | sort -k 1 -r | head -4" >> $PROCESS_CPU_UTLIZATION
	   fi
	fi
	if [ ${sys[3]} -gt ${sys[2]} ] && [ ${sys[2]} -gt ${sys[1]} ] || [ ${sys[1]} -gt ${sys[0]} ];then
	   if [ ${sys[3]} -gt $CPU_THRESHOLD ] && [ ${sys[2]} -gt $CPU_THRESHOLD ];then
		echo -e "${time[3]}: <font color="blue">SYSTEM CPU utilization on <font color="green">$server is <font color="red">${sys[3]}%</font></font></font>" >> $SYSTEM_CPU_UTLIZATION
	   fi
	fi
	if [ ${io[3]} -gt ${io[2]} ] && [ ${io[2]} -gt ${io[1]} ] || [ ${io[1]} -gt ${io[0]} ];then
	   if [ ${io[3]} -gt $CPU_THRESHOLD ] && [ ${io[2]} -gt $CPU_THRESHOLD ];then
		echo -e "${time[3]}: <font color="blue">SYSTEM CPU utilization on <font color="green">$server is <font color="red">${io[3]}%</font></font></font>" >> $IO_CPU_UTLIZATION
	   fi
	fi
	rm -f $TEMP/server_cpu.txt
	rm -f $TEMP/top_process.txt
	unset time user sys io
done

if [ -f "$PROCESS_CPU_UTLIZATION" ];then
{
   ALERT="CPU Utilization: USER/PROCESS"
   MAIL $EMAIL $PROCESS_CPU_UTLIZATION "$ALERT"	
   rm -f $PROCESS_CPU_UTLIZATION
}
fi
if [ -f "$SYSTEM_CPU_UTLIZATION" ];then
{
   ALERT="CPU Utilization: SYSTEM"
   MAIL $EMAIL $SYSTEM_CPU_UTLIZATION "$ALERT"	
   rm -f $SYSTEM_CPU_UTLIZATION
}
fi
if [ -f "$IO_CPU_UTLIZATION" ];then
{
   ALERT="CPU Utilization: IO"
   MAIL $EMAIL $IO_CPU_UTLIZATION "$ALERT"	
   rm -f $IO_CPU_UTLIZATION
}
fi

###### Clean Up ########
rm -f $TEMP/server_cpu.txt

