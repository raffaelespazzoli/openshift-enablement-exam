#!/bin/bash
while : 
do
	echo ciao | nc $HOST $PORT
	sleep 2
done;