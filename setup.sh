#!/bin/bash

restart_home='/home'
restart_script=0
restart_btn=-1
restart_led=-1

power_script=0
usbip_script=0

VALID_ARGS=$(getopt -o up --long rled:,rbtn:,rhome: -- "$@")
if [ $? -ne 0 ]; then
    exit 1;
fi

eval set -- "$VALID_ARGS"
while [ : ]; do
  case "$1" in
    -u)
        usbip_script=1
        shift
        ;;
    -p)
        power_script=1
        shift
        ;;
    --rbtn)
        restart_btn=$2
        shift 2
        ;;
    --rled)
        restart_led=$2
        shift 2
        ;;
    --rhome)
        restart_home=$2
        shift 2
        ;;
    --) shift;
        break
        ;;
  esac
done


#============== Validate aruments ==============

if [[ $restart_btn -gt -1 ]] && [[ $restart_led -gt -1 ]] then
    restart_script=1;
elif [[ $restart_btn -eq -1 ]] && [[ $restart_led -eq -1 ]] then
    restart_script=0;
else
    printf "\nEither both --rled and --rbtn must be specified or none, you cannot specify only 1 of them !!!\n\n";
    exit 1;
fi


#============== Printing information ==============
if [ $usbip_script -eq 1 ]
then
    printf "Install UsbIP scripts and services: Yes\n";
else
    printf "Install UsbIP scripts and services: No\n";
fi

if [ $restart_script -eq 1 ]
then
    printf "Install UsbIP services restart scripts for \n\tRestart script directory: $restart_home\n\tButton GPIO Pin: $restart_btn \n\tLED GPIO Pin: $restart_led\n";
else
    printf "Install UsbIP services restart scripts: No\n";
fi

if [ $power_script -eq 1 ]
then
    printf "Setup RPI power controls: Yes\n";
else
    printf "Setup RPI power controls: No\n";
fi


#============== Wait for user confirmation ==============
printf "\nWaiting for user input:\n\t- Press ESC or Q to exit \n\t- Press any other key to continue\n\n";
read -n1 -s key

# if input in [ESC, q, Q]
if [ "$key" = $'\e' ] || [ "$key" = 'q' ] || [ "$key" = 'Q' ];
then
    printf "Exit\n";
    exit 0;
fi


#============== Start execution information ==============
printf 'Starting RPI setup...\n';

# Install usbip and setup the kernel module to load at startup
if [ $usbip_script -eq 1 ]
then
    printf 'Installing USBIP...\n';

    apt-get -qq install usbip
    modprobe usbip_host
    echo 'usbip_host' >> /etc/modules

    printf 'Setting up services...\n';

    cd /usr/sbin/
    rm usbip_start.sh
    wget -q https://raw.githubusercontent.com/DionisisSchoinas/WiFi-Usb/main/Raspberry%20Pi%20Zero%20W/usbip_start.sh
    chmod +x /usr/sbin/usbip_start.sh
    rm usbip_stop.sh
    wget -q https://raw.githubusercontent.com/DionisisSchoinas/WiFi-Usb/main/Raspberry%20Pi%20Zero%20W/usbip_stop.sh
    chmod +x /usr/sbin/usbip_stop.sh

    cd  /lib/systemd/system/
    rm usbipd.service
    wget -q https://raw.githubusercontent.com/DionisisSchoinas/WiFi-Usb/main/Raspberry%20Pi%20Zero%20W/usbipd.service

    # reload systemd, enable, then start the service
    systemctl --system daemon-reload
    systemctl enable usbipd.service
    systemctl start usbipd.service
else
    printf "Skipping UsbIP scripts and services\n";
fi

if [ $restart_script -eq 1 ]
then
    printf 'Installing Restart scripts for UsbIP services...\n'

    cd $restart_home
    rm restart_usbipd.py
    rm restart_usbipd.py.tmp
    wget -q https://raw.githubusercontent.com/DionisisSchoinas/WiFi-Usb/main/Raspberry%20Pi%20Zero%20W/restart_usbipd.py
    chmod +x restart_usbipd.py
    sed "s/{rled}/$restart_led/" restart_usbipd.py > restart_usbipd.py.tmp
    sed "s/{rbtn}/$restart_btn/" restart_usbipd.py.tmp > restart_usbipd.py
    rm restart_usbipd.py.tmp
    
    cd  /lib/systemd/system/
    rm restart_usbipd_script.service
    wget -q https://raw.githubusercontent.com/DionisisSchoinas/WiFi-Usb/main/Raspberry%20Pi%20Zero%20W/restart_usbipd_script.service
    sed "s/{rhome}/$restart_home/" restart_usbipd_script.service > restart_usbipd_script.service.tmp && mv restart_usbipd_script.service.tmp restart_usbipd_script.service
   
    # reload systemd, enable, then start the service
    systemctl --system daemon-reload
    systemctl enable restart_usbipd_script.service
    systemctl start restart_usbipd_script.service
else
    printf "Skipping UsbIP scripts and services\n";
fi

if [ $power_script -eq 1 ]
then
    printf 'Setting up RPI power controls...\n';

    echo 'dtoverlay=gpio-shutdown,gpio_pin=3' >> /boot/config.txt;
    echo 'enable_uart=1' >> /boot/config.txt;
else
    printf "Skipping UsbIP scripts and services\n";
fi

printf 'RPI setup completed !\n';

#============== Await user input ==============

printf '\nRPI needs to be rebooted for everything to take effect\n';
printf "Waiting for user input:\n\t- Press ESC or Q to abort reboot (you SHOULD reboot later) \n\t- Press any other key to proceed with reboot\n\n";
read -n1 -s key

# if input in [ESC, q, Q]
if [ "$key" = $'\e' ] || [ "$key" = 'q' ] || [ "$key" = 'Q' ];
then
    printf "Reboot aborted...\n";
    exit 0;
fi

printf "\nDevice will reboot in 5 seconds...\n";
sleep 5;
printf "Reboot started\n";
reboot;

exit 0;