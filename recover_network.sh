#! /usr/bin/env bash

WAIT=1

ping 8.8.8.8 -c 1
TRY1=$?

sleep "${WAIT}s"

ping 8.8.8.8 -c 1
TRY2=$?

sleep "${WAIT}s"

ping 8.8.8.8 -c 1
TRY3=$?

sleep "${WAIT}s"

ping 8.8.8.8 -c 1
TRY4=$?

echo $((TRY1 + TRY2 + TRY3 + TRY4))

if [ $((TRY1 + TRY2 + TRY3 + TRY4)) -ne 0 ]; then
	nmcli con down NUS_STU
	sleep 5s
	nmcli con up NUS_STU
fi
