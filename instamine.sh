#!/bin/bash
user=`whoami`

coinarg=$1

if [ "$user" == "root" ]; then
	#Perform OS update and basic software installation
	if [ "0" == "1" ]; then
		apt-get update
	fi
	
	apt-get install yasm -y git make g++ build-essential libminiupnpc-dev
	apt-get install -y libboost-all-dev libdb++-dev libgmp-dev libssl-dev dos2unix automake pkg-config autoconf libminiupnpc-dev
	apt-get install -y libdb-dev libdb++-dev
	apt-get install -y autoconf automake libcurl3 libcurl3-dev screen pkg-config

	#Check for presence of swapfile, create one if not present
	if [ ! -e /swapfile ]; then
		dd if=/dev/zero of=/swapfile bs=64M count=16
		mkswap /swapfile
		swapon /swapfile
	fi

	#Make this script callable by other users too
	chmod 777 $0
	cp $0 /tmp

	#Ask which coin is to be mined
	echo "-------------------------------------------------"
	echo "Which coin do you want to mine? [number + ENTER]"
	echo "NAME - ALGO"
	echo "-------------------------------------------------"
	echo "1) Bitcoin - SHA256"
	echo "2) Litecoin - SCRYPT"
	echo "3) Quarkcoin - QUARK"
	echo "4) Dogecoin - SCRYPT"
	echo "q) Setup system only"
	echo "-------------------------------------------------"
	echo "Default is Bitcoin"
	read coin

	case "$coin" in 
	"1") coinname="bitcoin"
	;;
	"2") coinname="litecoin"
	;;
	"3") coinname="quarkcoin"
	;;
	"4") coinname="dogecoin"
	;;
	"q") exit 0
	;;
	*) coinname="bitcoin"
	esac

	#Create the mining user                                          
	username="vminer$coinname"
	adduser --disabled-password --disabled-login -gecos "" $username
	
	usercall="/tmp/`basename $0`  $coinname"
	sudo -u $username   -i $usercall

fi

if [ "$user" == "vminer$coinarg" ]; then
	coinname=$coinarg
	echo "Running Coin setup as user vminer$coinname"
	case $coinname in
	"bitcoin") wallet="https://github.com/bitcoin/bitcoin.git"
		repodir="bitcoin"
		extrastep=""
		configureextra="--with-incompatible-bdb"
	;;
	"litecoin") wallet="https://github.com/litecoin-project/litecoin.git"
		repodir="litecoin"
		extrastep=""
		configureextra=""
	;;
	"quarkcoin") wallet="https://github.com/MaxGuevara/quark.git"
		repodir="quark"
		extrastep=""
		configureextra=""
	;;
	"dogecoin") wallet"https://github.com/dogecoin/dogecoin.git"
		repodir="dogecoin"
		extrastep=""
		configureextra=""
	;;
	*) echo "Coin not available for automatic build, exiting"
	exit -1
	esac

	cd
	echo "Installing $coinname Wallet from GIT repository"
	git clone $wallet
	echo "Building $coinname Wallet - This may take some time"
	cd $repodir
	./autogen.sh
	./configure $configureextra
	if [ ! -e ./src/makefile.unix ]; then
		if [ ! -e ./Makefile ]; then
			echo "No makefile, exiting"
			exit -2
		else
			make
		fi
	else
		cd src
		make -f makefile.unix
		cd ..
	fi
	
	echo "Setting up wallet configuration"
	mkdir -p ./$coinname
	echo "rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)" > ./$coinname/$coinnamed.conf
	echo "rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)" >> ./$coinname/$coinnamed.conf
	echo "server=1" >>   ./$coinname/$coinnamed.conf
	echo "listen=1" >> ./$coinname/$coinnamed.conf
	echo "gen=1" >> ./$coinname/$coinnamed.conf
	echo "daemon=1" >> ./$coinname/$coinnamed.conf
	#Starting wallet
	echo "Starting $coinname wallet"
	src/$coinnamed

fi

