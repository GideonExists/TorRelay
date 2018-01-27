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

#	apt-get dist-upgrade
#fi

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
echo "Adding private directory authorities..."
echo "DirAuthority AlphaAuthority orport=5000 v3ident=2EF7C664175169357F94D8EC43C1309ABF38DC2E 172.16.0.104:7000 908261E3EE00136095B176611317D25441FB65A0" >> /usr/local/etc/tor/torrc
echo "DirAuthority BravoAuthority orport=5001 v3ident=EA1091EE800157C15E54D94207721DAB6B975EA2 172.17.0.101:7001 D2FC20D645D392E2F930899BE0DDB370F735A04A" >> /usr/local/etc/tor/torrc
echo "DirAuthority CharlieAuthority orport=5002 v3ident=DF9F0F13D1C88E69C17E4956D5306D9246B15999 172.18.0.101:7002 E848FCF17605E4238716F13CC90EF26338330CF1" >> /usr/local/etc/tor/torrc
echo "DirAuthority DeltaAuthority bridge orport=5003 v3ident=808E16F28AA1EA7F7203863A8245364E4436CB37 172.19.0.101:7003 22449978C1AE15D0B40C0036AB33CCA2C6C1609A" >> /usr/local/etc/tor/torrc

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
