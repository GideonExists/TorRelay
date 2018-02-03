#!/bin/bash

#Script to hasten set up of tor relay boxes

read -p "We need to get the dependencies for TOR (y,n) " REPLY
echo "Installing necessary dependencies..."
if [ "${REPLY,,}" == "y" ]; then

	apt-get --force-yes install libevent-dev
	apt-get --force-yes install libssl-dev

fi

#Update/upgrade system
#read -p "We need to update/upgrade the system (y,n) " REPLY

if [ "${REPLY,,}" == "y" ]; then
	apt-get update

#Check for presence of dirauth.csv before installing tor and creating torrc
[ ! -f dirauth.csv ] && { echo "dirauth.csv not found in local directory"; exit 1; }

#Install Tor
read -p "Do you want to install Tor? (MAKE SURE YOU'RE 100% SURE ABOUT THIS! (y,n)" REPLY

if [ "${REPLY,,}" == "y" ]; then

	cd ~/home/Downloads/
	wget "https://www.torproject.org/dist/tor-0.3.2.9.tar.gz"
	tar -zxvf tor-0.3.2.9.tar.gz
	cd tor-0.3.2.9/
	./configure && make && make install
	mkdir /var/lib/tor
	touch /usr/local/etc/tor

fi

#Create router keys for unique identification by directories
tor --list-fingerprint --orport 1 --dirserver "x 127.0.0.1:1 ffffffffffffffffffffffffffffffffffffffff" --datadirectory /var/lib/tor/

#Set network as testing network and data directory
echo "TestingTorNetwork 1" >> /usr/local/etc/tor/torrc
echo "DataDirectory /var/lib/tor" >> /usr/local/etc/tor/torrc
echo "ConnLimit 60" >> /usr/local/etc/tor/torrc
#Customizing torrc to suit relay

#Nickname for Relay
read -p "Enter your desired nickname for your relay: " Name
echo "Nickname $Name" >> /usr/local/etc/tor/torrc

#Config lines and log files
echo "ShutdownWaitLength 0" >> /usr/local/etc/tor/torrc
echo "Log notice file /var/lib/tor/notice.log" >> /usr/local/etc/tor/torrc
echo "Log info file /var/lib/tor/info.log" >> /usr/local/etc/tor/torrc
echo "Log debug file /var/lib/tor/debug.log" >> /usr/local/etc/tor/torrc
echo "ProtocolWarnings 1" >> /usr/local/etc/tor/torrc
echo "SafeLogging 0" >> /usr/local/etc/tor/torrc
echo "DisableDebuggerAttachment 0" >> /usr/local/etc/tor/torrc

#Add directory authorities to torrc
OLDIFS=$IFS
IFS=,
while read nickname flags address fingerprint
do

	echo "DirAuthority $nickname $flags $address $fingerprint" >> /usr/local/etc/tor/torrc

done < dirauth.csv
IFS=$OLDIFS

#SOCKS port for Relay if being used to allow connection by SOCKS applications
read -p "Enter the port number for SOCKS application connections to the relay: " SocksPort
echo "SocksPort $SocksPort" >> /usr/local/etc/tor/torrc

#ORPORT for Relay
read -p "Enter the port number you want ORPort to look at: " ORPort
echo "ORPort $ORPort" >> /usr/local/etc/tor/torrc

#DirPort for Relay
read -p "Enter the port number you want DirPort to look at: " DirPort
echo "DirPort $DirPort" >> /usr/local/etc/tor/torrc

#Address for Relay
read -p "Enter the IP address of the relay: " Address
echo "Address $Address" >> /usr/local/etc/tor/torrc

#Exit policy for Relay
echo "By default we do not allow exit policies for relays (this content is static.)"
echo "Should this node be an exit node? (y,n)" REPLY

if [ "${REPLY,,}" == "y" ]; then

	echo "ExitPolicy accept 172.16.0.0/16:*" >> /usr/local/etc/tor/torrc
	echo "ExitPolicy accept 172.17.0.0/16:*" >> /usr/local/etc/tor/torrc
	echo "ExitPolicy accept 172.18.0.0/16:*" >> /usr/local/etc/tor/torrc
	echo "ExitPolicy accept 172.19.0.0/16:*" >> /usr/local/etc/tor/torrc
	echo "ExitPolicy accept [::1]:*" >> /usr/local/etc/tor/torrc
	echo "IPv6Exit 1" >> /usr/local/etc/tor/torrc

fi

if [ "${REPLY,,}" == "n" ]; then

	echo "ExitPolicy reject *:*" >> /usr/local/etc/tor/torrc

fi

#Contact info for Relay
read -p "Enter your contact info for your relay: " Info
echo "ContactInfo $Info" >> /usr/local/etc/tor/torrc
