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
  (
    echo Send-MailMessage -From "!pbi_email!" -To "!error_email!".Split^(";"^) -Subject "TimeWorksPlus API Failure" -Body "This is an automated alert. The script which populates the timestar.timesheets_processed database table has failed. See the log file for more details." -SmtpServer "smtp-mail.outlook.com" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)
    echo if ^( $? ^){ exit 0 }else{ exit 1 }
  )>"%script%"
  PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%script%"
  if %ErrorLevel% NEQ 0 (
    echo [!date! - !time!] Failed to send email notification with 2 attempts left.>>"%~dp0log.txt"
    timeout /t 5 /nobreak >nul
    PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%script%"
    if !ErrorLevel! NEQ 0 (
      echo [!date! - !time!] Failed to send email notification with 1 attempt left.>>"%~dp0log.txt"
      timeout /t 5 /nobreak >nul
      PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%script%"
      if !ErrorLevel! NEQ 0 (
        echo [!date! - !time!] Failed to send email notification with 0 attempts left.>>"%~dp0log.txt"
      )
    )
  )
  if exist "%script%" del /F "%script%" >nul
exit /b 0