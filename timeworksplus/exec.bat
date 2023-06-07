@echo off
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
set "script=%~dp0mail_script.ps1"
(
  java -cp "%~dp0timeworksplus.jar;%lib%\*;" Main
  if !ERRORLEVEL! NEQ 0 call :email
) >> "%~dp0log.txt" 2>&1
exit

:email
  echo Send-MailMessage -From "!pbi_email!" -To "!error_email!".Split^(";"^) -Subject "TimeWorksPlus API Failure" -Body "This is an automated alert. The script which populates the timestar.timesheets_processed database table has failed. See the log file for more details." -SmtpServer "smtp-mail.outlook.com" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)>"%script%"
  PowerShell -NoLogo -File "%script%"
  if exist "%script%" del /F "%script%" >nul
exit /b 0