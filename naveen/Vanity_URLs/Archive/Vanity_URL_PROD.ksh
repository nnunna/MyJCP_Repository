#cd /mediamnt/templateFiles/ohs/dt/redirect_rules
#rm -rf *
#scp -prd lenldtwbpr1p01:/tmp/redirect_rules/* .
for server in lenldtwbpr1p01 lenldtwbpr1p02 colldtwbpr1p01 colldtwbpr1p02;  
do    
	echo -e '\n\n #*************************************** START *****************************************#';    
	echo -e '\n'$i'. Server: ' $server '\n\a';    
	ssh $server chef-client;    
	echo -e '\n\n #**************************************** END ******************************************#';  
done
