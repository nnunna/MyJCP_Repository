for server in lenldtwbdv1d01 lenldtwbdm1d01 lenldtwbte1t01 lenldtwbte2t01 colldtwbte3t01 colldtwblt1l01 colldtwblt1l02 lenldtwblt2l01 lenldtwblt2l02;
do    
	echo -e '\n\n #*************************************** START *****************************************#';    
	echo -e '\n'$i'. Server: ' $server '\n\a';    
	ssh $server chef-client;    
	echo -e '\n\n #**************************************** END ******************************************#';  
done
