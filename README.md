# WiFi-Usb
Uses a Raspberry Pi Zero W to wirelessly connect USB devices to a Windows machine using USB/IP.
The RPI is used as a server that accepts connections from the Windows machine or machines.

**USB/IP for Linux:** https://derushadigital.com/other%20projects/2019/02/19/RPi-USBIP-ZWave.html
**USB/IP for Windows:** https://github.com/cezanne/usbip-win

# Table of Contents
1. [Connecting a USB device](#Connecting-a-USB-device)
2. [RPI Server Installation](#RPI-Server-Installation)
3. [Windows Client Installation](#Windows-Client-Installation)

## Connecting a USB device

1. Plug a USB in the RPI
2. Update `usbipd.service`
   * Power on the RPI
    
        OR
   * Restart the `usbipd.service` (from command line OR button)
3. Run the `WirelessHub.bat` with Administrator access
4. Select the `Attach All` option
5. Done

## RPI Server Installation

Assuming that the RPI has been setup and can connect to the WiFi network, now the USB/IP server must be setup.

### 1. *(Optional)* Change the WiFi configuration from DHCP to static ip 
This is not required but some issues might occur.

In the case this step is skipped the RPI hostname should be used instead of the RPI Ip address where that is needed. **The hostname is raspberrypi.local by default.**

### 2. Install USB/IP
```bash
# Install usbip and setup the kernel module to load at startup
apt-get install usbip
modprobe usbip_host
echo 'usbip_host' >> /etc/modules
```

### 3. Create USB/IP service
These steps will create a service that on startup will find and expose all the connected USB devices

#### 3.1 Create start script
1. Copy the file `usbip_start.sh` from the `Raspberry Pi Zero W` folder into `/usr/sbin/`
2. Grant exec right `sudo chmod +x /usr/sbin/usbip_start.sh`
   
#### 3.2 Create stop script
1. Copy the file `usbip_stop.sh` from the `Raspberry Pi Zero W` folder into `/usr/sbin/`
2. Grant exec right `sudo chmod +x /usr/sbin/usbip_stop.sh`
   
#### 3.3 Create service
1. Copy the file `usbipd.service` from the `Raspberry Pi Zero W` folder into `/lib/systemd/system/`
   
#### 3.4 Restart systemctl services
    ```bash
    # reload systemd, enable, then start the service
    sudo systemctl --system daemon-reload
    sudo systemctl enable usbipd.service
    sudo systemctl start usbipd.service
    ```

### 4. *(Optional)* Create Python script to restart service with button
This step is also not required but it is pretty useful if you want to plug or unplug USB devices on the go and simply restart the usbipd service instead of restarting the RPI for the changes to take effect.

The script has a button and a LED. The button is used to trigger the service restart and the LED displays the status of the service (**ON** if up, **OFF** if down).

#### 4.1 Wiring
* The button connects to a GPIO pin and GND
* The LED connects to a GPIO pin and GND with a 220 Ω resistor

#### 4.2 Software
1. Copy the file `restart_usbipd.py` from the `Raspberry Pi Zero W` folder into any folder you want
2. Grant exec right `sudo chmod +x /path/to/file/restart_usbipd.py`
3. Copy the file `restart_usbipd_script.service` from the `Raspberry Pi Zero W` folder into `/lib/systemd/system/`
4. Update the folder path if needed
   ```bash
   # Line 7 of restart_usbipd_script.service
   ExecStart=/usr/bin/python /path/to/script/restart_usbipd.py
   ```
5. Restart systemctl services
    ```bash
    # reload systemd, enable, then start the service
    sudo systemctl --system daemon-reload
    sudo systemctl enable restart_usbipd_script.service
    sudo systemctl start restart_usbipd_script.service
    ```

## Windows Client Installation

Following the instructions in this repository (https://github.com/cezanne/usbip-win) completes the basic installation of the USB/IP driver.

**Only the client installation is needed.**

After the client installation:

1. Copy and paste the `WirelessHub.bat` from the `Windows` folder into any folder on the Windows machine. 
2. Update the configuration inside the script

    2.1. Update the RPI IP address (either the static IP or the hostname)
    ```bat
    SET raspberryPiIp=192.168.xxx.xxx
    ```
    2.2. Update the installation folder of the USB/IP driver in the Windows machine
    ```bat
    SET usbIpInstallationFolder=C:\Example\Folder
    ```
   
The script requires **Administrator access** to run and complete the attaching and detaching operations since the USB?IP driver requires such access

The script is simply a batch file used to run commands automatically instead of the user running them directly, in order to speed up the process of attaching and detaching USB devices. The script attaches all the USB devices that have been exposed by the RPI server.

**The script should be executed after the server has been setup and started on the RPI**
