#!/bin/bash 

red='\e[0;31m'
green='\e[0;32m'
nc='\e[0m'
yellow='\e[1;33m'

UsageMSG()
{
	echo -e "${red}Usage: NodeManager.ksh <PROJ> <PROD/NPROD> <Data Center> <start|stop|status>${nc}"
        echo -e "${green}Eg: NodeManager.ksh DP PROD LENA status${nc}"
	echo -e "${yellow} Existing PROJ's: DP/SOM/SAM"
	echo -e "${yellow} Existing ENV's: PROD/NPROD; Data Center's: LENA/COLA ${nc}"
        exit
}

startNM()
{
	echo "Starting the Node Manager....."
	ssh wlsoper@$server -n "cd /usr/wls/wlserver/server/bin; nohup ./startNodeManager.sh > /dev/null 2>&1 &" 
	sleep 5
}

statusNM()
{
NMPID=`ssh -q root@$server -n "ps -ef | grep weblogic.NodeManager | grep -v grep | awk '{print \$2}'"`
NMPORT=`ssh -q root@$server -n "netstat -an | grep 5556 | grep LISTEN | awk '{print \$1}'"`
	if [ -z "$NMPID" ] && [ -z "$NMPORT" ];then
		echo -e "${yellow}$server Status: ${red}NodeManager is DOWN!!!${nc}"
		NMSTATUS=0
	elif [ -z "$NMPID" ] || [ -z "$NMPORT" ];then
		echo -e "${yellow}$server Status: ${red}Somethings not right... please check the NodeManager manually on $server${nc}"
	else
		echo -e "${yellow}$server Status: ${green}NodeManager is Up & Running!!!${nc}"
		NMSTATUS=1	
	fi
}

stopNM()
{
	NMPID=`ssh wlsoper@$server -n "ps -ef | grep weblogic.NodeManager | grep -v grep | awk '{print $2}'"`
	echo "Stopping....."
	ssh wlsoper@$server -n "kill -9 $NMPID"
}	

#########################################
# Main Function 			#
#########################################

### Validate the Inputs
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ];
then
	UsageMSG	
elif [ ! -f /root/naveen/config/$1_$2_$3.txt ];
then
	echo -e "${red} File does not exists!!! Please make sure the file exists under /root/naveen/config/ directory!!${nc}"
        exit
fi

if [ "$2" != "PROD" ] && [ "$2" != "NPROD" ];
then
	UsageMSG
elif [ "$3" != "COLA" ] && [ "$3" != "LENA" ];then
	UsageMSG
elif [ "$4" != "start" ] && [ "$4" != "stop" ] && [ "$4" != "status" ];then
	UsageMSG
fi
### End Validation

while read server type; do
    if [ "$type" = "App" ]; then
		#echo -e "${yellow}$server Status"
	if [ $4 = "start" ];then
		statusNM
		if [ "$NMSTATUS" = "0" ];then
			startNM
		fi	
		statusNM
	elif [ $4 = "stop" ];then
		stopNM
		statusNM	
	elif [ $4 = "status" ];then
		statusNM
	fi
     fi
done < /root/naveen/config/$1_$2_$3.txt		
