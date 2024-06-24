@echo off
PowerShell -ExecutionPolicy Bypass -NoLogo -File "%~dp0helper.ps1"
echo Press any key to exit...
pause >nul
exit

REM You'll probably want to change the user that runs the following scripts so that they have access to the appropriate rclone profiles
REM script-cradlepoint-backup
REM script-regfox
REM script-synchrony
REM script-verizon