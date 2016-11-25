for server in lenldtwbsp1s01 lenldtwbsp1s02 colldtwbsp1s01 colldtwbsp1s02 colldtwblt1l01 colldtwblt1l02 lenldtwbdv1d01 lenldtwbte1t01 lenldtwbte2t01 colldtwblt1l01 colldtwblt1l02;
do    
	echo -e '\n\n #*************************************** START *****************************************#';    
	echo -e '\n'$i'. Server: ' $server '\n\a';    
	ssh $server chef-client;    
	echo -e '\n\n #**************************************** END ******************************************#';  
done
