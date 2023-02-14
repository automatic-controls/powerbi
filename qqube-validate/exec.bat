@echo off
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
set "script=%~dp0mail_script.ps1"
set "ret=0"
(
  java -Djava.library.path="C:\Program Files (x86)\CLEARIFY\QQube Tool\SQL Anywhere 17\BIN64" -cp "%~dp0qqube-validate.jar;%lib%\*;C:\Program Files (x86)\CLEARIFY\QQube Tool\SQL Anywhere 17\Java\sajdbc4.jar" Main
  set "ret=!ERRORLEVEL!"
) > "%~dp0log.txt" 2>&1
if "!ret!" NEQ "0" call :email

exit

:email
  echo Send-MailMessage -From "!pbi_email!" -To "!error_email!" -Subject "QQube Validation" -Body "This is an automated alert. Status=%ret%. See the attached log file for more details." -Attachments "%~dp0log.txt" -SmtpServer "smtp-mail.outlook.com" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)>"%script%"
  PowerShell -NoLogo -File "%script%"
  if exist "%script%" del /F "%script%" >nul
exit /b 0