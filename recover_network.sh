#! /usr/bin/env bash

ping 8.8.8.8 -c 1
EXIT=$?

if [ ${EXIT} -ne 0 ]; then
	echo "nmcli con down nings"
	nmcli con down nings
	sleep 5s
	echo "nmcli con up nings"
	nmcli con up nings
fi
