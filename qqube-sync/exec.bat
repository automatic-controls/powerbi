@echo off
setlocal EnableDelayedExpansion
call "%~dp0../env_vars.bat"
set "script=%~dp0mail_script.ps1"
(
  java -Djava.library.path="C:\Program Files (x86)\CLEARIFY\QQube Tool\SQL Anywhere 17\BIN64" -cp "%~dp0qqube-sync.jar;%lib%\*;C:\Program Files (x86)\CLEARIFY\QQube Tool\SQL Anywhere 17\Java\sajdbc4.jar" Main
  if !ERRORLEVEL! NEQ 0 call :email
) >> "%~dp0log.txt" 2>&1
exit

:email
  echo Send-MailMessage -From "!pbi_email!" -To "!error_email!".Split^(";"^) -Subject "QQube-PostgreSQL Sync Failure" -Body "This is an automated alert. The script which automatically syncs QQube to PostgreSQL failed to execute. See the log file for more details." -SmtpServer "smtp-mail.outlook.com" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)>"%script%"
  PowerShell -NoLogo -File "%script%"
  if exist "%script%" del /F "%script%" >nul
exit /b 0