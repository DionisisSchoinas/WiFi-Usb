#!/bin/bash

echo 'Starting binding...'
readarray -t my_array < <(usbip list -p -l | cut '-d=' -f2 | cut '-d#' -f1)
for i in "${my_array[@]}"
do
        echo "Binding busid= $i"
        usbip bind --busid=$i
done

echo 'Starting usbipd...'
usbipd -D