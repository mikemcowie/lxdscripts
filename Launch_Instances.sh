#!/bin/bash

#Format: Launch_Instances.sh -h (lxd host) -N (name of image) -b (base hostname)  -n (number of instances) -i (firsr 3 parts of IP Address ending with a dot) -I (Last digit of ip address for first instance)

#as part of the script the file at relative path config/<base hostname> will be  copied to the container and executed inside of it  (e.g. for common configuration tasks for all containers in group)

#Uncomment below section for interactive program 

#echo "This program launches and configures a set number of similar instances"
#echo "What host do you want to launch on?"
#read lxdHost
#echo "What image do you want to start with (e.g. ubuntu-daily:zesty or images:centos/7"
#read imageName
#echo "What is your hostname base for these instances?"
#read hostNameBase
#echo "how many instances do you want to launch?"
#read instanceNumber
#echo "Instance names will be '$hostNameBase'01 '$hostNameBase'02 etc"
#echo "What are the first 3 parts of the IP address, ending with a dot?) (e.g. 10.0.0.)"
#read ipAddressBase
#echo "What is the final part of the IP address (starting between 1 and 254)"
#read ipAddressEnd
#subnetMask=255.255.252.0

while getopts h:N:b:n:i:I: option
do
 	case "${option}"
 		in
 		h) lxdHost=${OPTARG};;
		N) imageName=${OPTARG};;
		b) hostNameBase=${OPTARG};;
		n) instanceNumber=${OPTARG};;
		i) ipAddressBase=${OPTARG};;
		I) ipAddressEnd=$OPTARG;;
 	esac
done


for i in $(seq -w 01 $instanceNumber)  
	do  
	echo provisioning host $lxdHost:$hostNameBase$i with IP Address $ipAddressBase.$ipAddressEnd
	lxc init $imageName $lxdHost:$hostNameBase$i
	cp ./interfaces /tmp/interfaces-tmp-$i
	sed -i "s/ipaddress/$ipAddressBase.$ipAddressEnd/g" /tmp/interfaces-tmp-$i
	lxc file push /tmp/interfaces-tmp-$i $lxdHost:$hostNameBase$i/etc/network/interfaces
	ipAddressEnd=$((ipAddressEnd+1))
done


echo "instances created, starting them"

for i in $(seq -w 01 $instanceNumber) 
	do
	lxc start $lxdHost:$hostNameBase$i
done

echo "done!"

sleep 5s

echo  Time to apply specific script at config/$hostNameBase



for i in $(seq -w 01 $instanceNumber) 
        do
        lxc file push config/$hostNameBase $lxdHost:$hostNameBase$i/root/deploy.sh
	lxc exec  $lxdHost:$hostNameBase$i chmod +x /root/deploy.sh
#below line commented for speeding up testing
#	lxc exec  $lxdHost:$hostNameBase$i /root/deploy.sh 
	lxc file push ~/.ssh/id_rsa.pub $lxdHost:$hostNameBase$i/home/ubuntu/.ssh/authorized_keys
	lxc exec  $lxdHost:$hostNameBase$i chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
	lxc exec  $lxdHost:$hostNameBase$i chmod 600 /home/ubuntu/.ssh/authorized_keys
#	lxc exec  $lxdHost:$hostNameBase$i rm -f /tmp/id_rsa.pub &
done





sleep 5s

#echo "ready to delete?"
#read blah
#for i in $(seq -w 01 $instanceNumber)  
#	do  
#	lxc delete --force $lxdHost:$hostNameBase$i
#done

echo "exiting"
