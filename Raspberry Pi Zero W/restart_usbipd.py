#!/usr/bin/python

import os
from gpiozero import LED,Button
from time import sleep,time

led = LED({rled})
led.on()
button = Button({rbtn})

previous_state = 1
current_state = 0

while True:
        if button.is_pressed:
                if previous_state != current_state:
                        led.off()
                        current_state = 1
                        print(f'{time()}: Restarting USBIPD...')
                        os.system("sudo systemctl restart usbipd.service")
        elif current_state == 1:
                led.on()
                current_state = 0
                print(f'{time()}: Restarting USBIPD: Complete')