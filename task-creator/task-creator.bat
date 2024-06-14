@echo off
PowerShell -ExecutionPolicy Bypass -NoLogo -File "%~dp0helper.ps1"
echo Press any key to exit...
pause >nul
exit

REM You'll probably want to change the user that runs script-regfox, script-synchrony, and script-verizon so that they have access to the rclone profiles