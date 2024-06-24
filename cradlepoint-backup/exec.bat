@echo off
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
set "script=%~dp0mail_script.ps1"
set "data=%~dp0data"
set "zipFile=%~dp0%date:~-4%-%date:~-10,2%-%date:~-7,2%.zip"
set "remote=Dropbox:\Client WebCTRL Backups\Miscellaneous\Cradlepoint"
(
  echo !date! - !time! - Initialized.
  del /F "%zipFile%" >nul 2>nul
  rmdir /S /Q "%data%" >nul 2>nul
  mkdir "%data%" >nul
  mkdir "%data%\routers"
  mkdir "%data%\groups"
  rclone delete --min-age 365d "%remote%"
  "C:\Program Files\PowerShell\7\pwsh.exe" -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%~dp0backup.ps1"
  if !ERRORLEVEL! EQU 0 (
    jar -c -M -f "%zipFile%" -C "%data%" .
    rclone copy "%zipFile%" "%remote%"
    if !ERRORLEVEL! NEQ 0 (
      echo An error has occured with RClone.
      call :email
    )
    del /F "%zipFile%" >nul 2>nul
  ) else (
    echo An error has occurred in the PowerShell script.
    call :email
  )
  echo !date! - !time! - Terminated.
) >> "%~dp0log.txt" 2>&1
exit

:email
  (
    echo Send-MailMessage -From "!pbi_email!" -To "!error_email!".Split^(";"^) -Subject "Cradlepoint Backup Failure" -Body "This is an automated alert. The script which creates backups of Cradlepoint router configurations has failed. See the log file for more details." -SmtpServer "smtp-mail.outlook.com" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)
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