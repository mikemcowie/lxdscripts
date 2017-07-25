#!/bin/bash


echo "This program launches and configures a set number of similar instances"
echo "What host do you want to launch on?"
read lxdHost
echo "What image do you want to start with (e.g. ubuntu-daily:zesty or images:centos/7"
read imageName
echo "What is your hostname base for these instances?"
read hostNameBase
echo "how many instances do you want to launch?"
read instanceNumber
echo "Instance names will be '$hostNameBase'01 '$hostNameBase'02 etc"
echo "What are the first 3 parts of the IP address, ending with a dot?) (e.g. 10.0.0.)"
read ipAddressBase
echo "What is the final part of the IP address (starting between 1 and 254)"
read ipAddressEnd
subnetMask=255.255.252.0


for i in $(seq -w 01 $instanceNumber)  
	do  
	echo provisioning host $lxdHost:$hostNameBase$i with IP Address $ipAddressBase$ipAddressEnd
	lxc init $imageName $lxdHost:$hostNameBase$i
	cp ./config/interfaces ./config/interfaces-tmp
	sed -i "s/ipaddress/$ipAddressBase$ipAddressEnd/g" ./config/interfaces-tmp
	lxc file push ./config/interfaces-tmp $lxdHost:$hostNameBase$i/etc/network/interfaces
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
	lxc exec  $lxdHost:$hostNameBase$i /root/deploy.sh &
done



sleep 5s

echo "ready to delete?"
read blah
for i in $(seq -w 01 $instanceNumber)  
	do  
	lxc delete --force $lxdHost:$hostNameBase$i
done

echo "exiting"
