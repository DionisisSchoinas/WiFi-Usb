#!/bin/bash

echo 'Stopping usbipd...'
#sudo kill $(ps -A | grep usbipd | cut '-d ' -f2)

readarray -t my_array < <(usbip list -p -l | cut '-d=' -f2 | cut '-d#' -f1)
for i in "${my_array[@]}"
do
        echo "Unbinding busid= $i"
        usbip unbind --busid=$i
done