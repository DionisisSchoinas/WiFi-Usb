# WiFi-Usb
Uses a Raspberry Pi Zero W to wirelessly connect USB devices to a Windows machine using USB/IP.
The RPI is used as a server that accepts connections from the Windows machine or machines.

**USB/IP for Linux:** https://derushadigital.com/other%20projects/2019/02/19/RPi-USBIP-ZWave.html

**USB/IP for Windows:** https://github.com/cezanne/usbip-win

# Table of Contents
1. [Requirements](#requirements)
2. [Connecting a USB device](#connecting-a-usb-device)
3. [Disconnecting a USB device](#disconnecting-a-usb-device)
4. [RPI Server Installation](#rpi-server-installation)
5. [Windows Client Installation](#windows-client-installation)
6. [RPI Zero W GPIO Pins Layout](#gpio-pins-layout)


# Requirements
* Required
  * Any Windows machine
  * Raspberry Pi Zero W
  * SD Card
* Optional
  * USB Hub for Raspberry Pi
  * Micro USB to Female USB adapter
  * LEDs
    * LED (x2)
    * 220 Ω resistor (x2)
  * Button (x2)


# Connecting a USB device

1. Plug a USB in the RPI
2. Update the `usbipd.service`, in order for the new USB device to be detected, by
   * Powering on the RPI
    
        OR
   * Restarting the `usbipd.service` (from command line OR button)
3. Run the `WirelessHub.bat` with Administrator access
4. Select the `Attach All` option
5. Done
 

# Disconnecting a USB device

Disconnecting a single USB device has not been implemented. However the `Attach All` option first detaches all connected USB devices and then reattaches what is left.
The `Detach All` option will simply detach all connected USB devices.


# RPI Server Installation

Assuming that the RPI has been setup and can connect to the WiFi network, now the USB/IP server must be setup.
You can setup the RPI using either the **setup script** or **set it up manually**

## 1.a Using the setup script

The setup script executes the same steps as the manual setup.

```bash
# Script needs sudo privileges to install USB IP and setup services
sudo -i
cd /script/location
wget https://raw.githubusercontent.com/DionisisSchoinas/WiFi-Usb/main/setup.sh && chmod +x setup.sh
# Install USB IP, Power controls and Reboot controls
./setup.sh -u -p --rbtn 17 --rled 23 --rhome /home
```

```bash
# Documentation for setup script
setup.sh [OPTIONS]

Options:
   -u                   Flag used to setup the UsbIP server
   -p                   Flag used to setup the RPI power controls
   --rbtn <number>      The GPIO Pin for the UsbIP service restart button
   --rled <number>      The GPIO Pin for the UsbIP service status led
   --rhome <directory>  The directory to save the UsbIP service restart script

Notes:
   If one of the --rbtn and --rled options is specified then the other MUST be specified as.
   The script will exit if only one of the specified options is specified.
```

## 1.b Manual setup

### 1. Install USB/IP
```bash
# Install usbip and setup the kernel module to load at startup
apt-get install usbip
modprobe usbip_host
echo 'usbip_host' >> /etc/modules
```

### 2. Create USB/IP service
These steps will create a service that on startup will find and expose all the connected USB devices

#### 2.1 Create start script
1. Copy the file `usbip_start.sh` from the `Raspberry Pi Zero W` folder into `/usr/sbin/`
2. Grant exec right `sudo chmod +x /usr/sbin/usbip_start.sh`
   
#### 2.2 Create stop script
1. Copy the file `usbip_stop.sh` from the `Raspberry Pi Zero W` folder into `/usr/sbin/`
2. Grant exec right `sudo chmod +x /usr/sbin/usbip_stop.sh`
   
#### 2.3 Create service
1. Copy the file `usbipd.service` from the `Raspberry Pi Zero W` folder into `/lib/systemd/system/`
   
#### 2.4 Restart systemctl services
   ```bash
   # reload systemd, enable, then start the service
   sudo systemctl --system daemon-reload
   sudo systemctl enable usbipd.service
   sudo systemctl start usbipd.service
   ```

### 3. *(Optional)* Create Python script to restart UsbIP service with button
This step is also not required but it is pretty useful if you want to plug or unplug USB devices on the go and simply restart the usbipd service instead of restarting the RPI for the changes to take effect.

The script has a button and a LED. The button is used to trigger the service restart and the LED displays the status of the service (**ON** if up, **OFF** if down).

#### 3.1 Wiring
* The button connects to a GPIO pin and GND
* The LED connects to a GPIO pin and to GND with a 220 Ω resistor

#### 3.2 Software
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

### 4. *(Optional)* Power Controls

#### 4.1. Power Button

Unplugging the RPI from power with the system still running is never a good idea since this can cause data corruption.

Adding a button to shutdown and reboot the RPI system without an SSH connection can be rather useful, if you want to reduce the power usage of the RPI and/or unplug it from power. 

To accomplish this you need the following:

1. **Enable gpio-shutdown**
   ```bash
   # Add the following line to /boot/config.txt
   # Any GPIO can be used for shutdown but only GPIO 3 supports shutdown AND reboot
   dtoverlay=gpio-shutdown,gpio_pin=3
   ```
2. Connect a Button to **GPIO 3**
3. Reboot the RPI for changes to take effect
4. After booting back up
   1. Press button for system shutdown
   2. Press button after shutdown for reboot

#### 4.2. Power LED

Adding a LED that displays the power state of the RPI can be pretty useful. To accomplish this you need the following:

1. **Enable UART** during boot
   ```bash
   # Add the following line to /boot/config.txt
   enable_uart=1
   ```
2. Connect a LED to the **TXD pin** (GPIO 14) and to GND with a 220 Ω resistor
3. Reboot the RPI and check the LED status

# Windows Client Installation

Following the instructions in this repository (https://github.com/cezanne/usbip-win#windows-usbip-client) completes the basic installation of the USB/IP driver.

**Only the client installation is needed.**

After the client installation:

1. Copy and paste the `WirelessHub.bat` from the `Windows` folder into any folder on the Windows machine. 
2. Update the installation folder of the USB/IP driver in the Windows machine
   ```bat
   SET usbIpInstallationFolder=C:\Example\Folder
   ```
   
The script requires **Administrator access** to run and complete the attaching and detaching operations since the USB?IP driver requires such access

The script is simply a batch file used to run commands automatically instead of the user running them directly, in order to speed up the process of attaching and detaching USB devices. The script attaches all the USB devices that have been exposed by the RPI server.

**The script should be executed after the server has been setup and started on the RPI**


# GPIO Pins Layout

![Image not rendered](https://github.com/DionisisSchoinas/WiFi-Usb/blob/f226d5165f6a19e7392058f4ccb53459dd516598/GPIO_Pins.png)