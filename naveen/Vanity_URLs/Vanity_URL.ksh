#!/bin/bash 

#set -xvf

USER=`who -m | awk '{print $1}'`
#DATE=`date | awk '{print $2$3$6}'`
DATE=`date | awk '{print $2$3$6"_"$4}'`
TSTAMP=$DATE"_"$USER

propogate()
{
	echo -e "\e[0;32m Taking back up of previous redirect_rules directory under "$mac":/usr/wls/apache2/redirect_rules_$TSTAMP \e[0m" 
	ssh -q $mac -n "cd /usr/wls/apache2/; cp -r redirect_rules redirect_rules_$TSTAMP"
	echo -e "\e[1;33m Transferring files from Chef Server to "$mac":/usr/wls/apache2/redirect_rules \e[0m"
	scp -q -p /mediamnt/templateFiles/ohs/dt/redirect_rules/dtpr1/*.txt $mac:/usr/wls/apache2/redirect_rules
	echo -e "\e[0;32m File transfer compelted!!! \e[0m"
	for conf in $(ssh -q $mac -n "ps -ef | grep httpd | awk 'FS=\" -f \" {print \$NF}'| awk '{print \$1}'| grep conf | sort -u | grep -v start")
	do
		echo -e "\e[0;31m Gracefully bouncing webserver `echo $conf | awk -F/ '{print $(NF-1)}'` \e[0m"
		ssh -q $mac -n "/usr/wls/apache2/bin/apachectl -k graceful -f $conf"
		echo -e "\e[0;32m \t\t ===> Successful!! \e[0m"
	done
}

validate()
{
	while read mac pid;do
		if [ "$DC" = "len" ] || [ "$DC" = "col" ];then
			dc=`echo $mac | cut -c1-3`	
			if [ "$DC" = "$dc" ];then
				echo "Will run only for the servers starting with $dc for $pid"
				propogate
			else
				echo -e "\e[0;31m Not Running for $mac \e[0m"
			fi
		else
			propogate
		fi
	done < /root/naveen/Vanity_URLs/conf/"$ENV".txt
}

choose()
{
	if [ -z $ans ];then
		echo -e "Arguments expected: [y/n], BYE!!!!"
		exit
	elif [[ ( "$ans" = "y" || "$ans" = "n" ) ]];then
		if [ "$ans" = "n" ]; then
			echo -e "BYE!!!"
		else
			echo "Vanity URL's propogating to $1 $2"
			validate
		fi
	else
		echo -e "Arguments expected: [y/n], BYE!!!!"
	fi
}


if [ -z $1 ];then
	echo -e "Usage: ./Vanity_URL.ksh <Environment> <DataCenter>"
	echo -e "Usage: ./Vanity_URL.ksh [prod]/[nprod] [len]/[col]/[Default]"
	echo -e "Eg: ./Vanity_URL.ksh prod len ==> Will propogate only to PROD LENA"
	echo -e "Eg: ./Vanity_URL.ksh prod ==> Will propogate to both LENA & COLA"
	echo -e "Eg: ./Vanity_URL.ksh nprod ==> Will propogate to all Non-PROD envs"
	exit
fi
if [[ ( "$1" = "prod" || "$1" = "nprod" ) && ( "$2" = "len" || "$2" = "col" || "$2" = "" ) ]];then
	if [ "$1" = "prod" ] && [ "$2" = "" ];then
		ENV=$1
		echo -n "Are you sure you want to propogate to both LEN & COL for PROD? [y/n]:"
		read ans
		choose
	elif [ "$1" = "nprod" ] && [ "$2" = "" ];then
		ENV=$1
			#echo "Non-PROD config is still in progress... please check back later!!!!"
                echo "Vanity URL's propogating to $1 $2"
		validate		
		exit	
		echo "Are you sure you want to propogate to ALL NON-PROD envs? [y/n]:"
		read ans
		choose
	elif [[ ( "$1" = "nprod" ) && ( "$2" = "len" || "$2" = "col" ) ]];then
		echo "nprod will be propogated to all NON-PROD envs regardless of the DataCenter"
		exit		 
	else
		ENV=$1
		DC=$2
                echo "Vanity URL's propogating to $1 $2"
#                echo "Write the propogation function for "$ENV" here"
		validate
	fi
else
	echo -e "Argument expected: [prod/nprod] [len/col]"	
	exit
fi
