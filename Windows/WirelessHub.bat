@ECHO OFF

SET raspberryPiIp=192.168.xxx.xxx
SET usbIpInstallationFolder=C:\Example\Folder

::-------------------------------------
:: Start of check for Admin Privilages
::-------------------------------------

::REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

::REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
    


::-------------------------------------
::          Start of options
::-------------------------------------
:: Print list of options
CLS
ECHO.
ECHO Options:
ECHO   1. Attach All
ECHO   2. Detach All
ECHO   3. Cancel
ECHO.

CHOICE /C 123 /M "Enter your choice: "
SET choice=%ERRORLEVEL%

:: Jump to END
IF %choice% == 3 GOTO END


::-------------------------------------
::        Print Configurations
::-------------------------------------
ECHO ============= CONFIG =============
ECHO  RaspberryPi IP: %raspberryPiIp%
ECHO  UsbIp drivers folder: %usbIpInstallationFolder%
ECHO ==================================
ECHO:


::-------------------------------------
::          Detach from ports
::-------------------------------------
ECHO ============= DETACH =============
cd %usbIpInstallationFolder%
for /F "skip=2 delims=:" %%a in ('usbip.exe port') do (
    for /F "tokens=2" %%b in ("%%a") do (
        for /f "tokens=1 delims=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#$&*()-=<>" %%c in ("%%b") do (
            ECHO Detaching Port: %%c
            usbip.exe detach -p %%c
        )
    )
)
ECHO ==================================
ECHO.

:: Skip Attach part
IF %choice% == 2 GOTO DETACHALL


::-------------------------------------
::          Attach to ports
::-------------------------------------
ECHO ============= ATTACH =============
cd %usbIpInstallationFolder%
for /F "skip=3" %%a in ('usbip.exe list -r %raspberryPiIp%') do (
    for /F "tokens=1 delims=:" %%b in ("%%a") do (
        ECHO Attaching BusId: %%b
        usbip.exe attach -r %raspberryPiIp% -b %%b
    )
)
ECHO ==================================
ECHO.

:DETACHALL

PAUSE

:END