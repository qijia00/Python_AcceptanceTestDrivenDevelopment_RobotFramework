@ECHO OFF

SET /A retval = 0

REM Installing RobotFramework
ECHO Installing RobotFramework
pip install robotframework

IF %ERRORLEVEL% NEQ 0 (
	SET /A retval = %ERRORLEVEL%
)

REM Installing Selenium
ECHO Installing Selenium
pip install selenium

IF %ERRORLEVEL% NEQ 0 (
	SET /A retval = %ERRORLEVEL%
)

REM Installing Lackey
ECHO Installing Lackey
pip install lackey

IF %ERRORLEVEL% NEQ 0 (
	SET /A retval = %ERRORLEVEL%
)

REM Installing Paho-MQTT
ECHO Installing Paho-MQTT
pip install paho-mqtt

IF %ERRORLEVEL% NEQ 0 (
	SET /A retval = %ERRORLEVEL%
)

REM Installing PySerial
ECHO Installing PySerial
pip install pyserial

IF %ERRORLEVEL% NEQ 0 (
	SET /A retval = %ERRORLEVEL%
)

REM Installing numpy
ECHO Installing numpy
pip install numpy

IF %ERRORLEVEL% NEQ 0 (
	SET /A retval = %ERRORLEVEL%
)

REM Installing Matplotlib
ECHO Installing Matplotlib
pip install matplotlib

IF %ERRORLEVEL% NEQ 0 (
	SET /A retval = %ERRORLEVEL%
)

REM Installing paramiko	
ECHO Installing paramiko
pip install paramiko

IF %ERRORLEVEL% NEQ 0 (
	SET /A retval = %ERRORLEVEL%
)

REM Installing wheel
ECHO Installing wheel
pip install wheel

IF %ERRORLEVEL% NEQ 0 (
	SET /A retval = %ERRORLEVEL%
)

REM Installing requests
ECHO Installing requests
pip install requests

IF %ERRORLEVEL% NEQ 0 (
	SET /A retval = %ERRORLEVEL%
)

REM Installing path.py
ECHO Installing path.py
pip install path.py

IF %ERRORLEVEL% NEQ 0 (
	SET /A retval = %ERRORLEVEL%
)
ECHO Adding required path to PYTHONPATH
SETX PYTHONPATH "%cd%;%cd%\src"

EXIT /B %retval%