@echo off
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
set "script=%root%mail-script.ps1"
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
  pwsh -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%~dp0backup.ps1"
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
  set "email_to=!error_email!"
  set "email_subject=Cradlepoint Backup Failure"
  set "email_body=This is an automated alert. The script which creates backups of Cradlepoint router configurations has failed. See the log file for more details."
  pwsh -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%script%"
  if %ErrorLevel% NEQ 0 (
    echo [!date! - !time!] Failed to send email notification with 2 attempts left.>>"%~dp0log.txt"
    timeout /t 5 /nobreak >nul
    pwsh -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%script%"
    if !ErrorLevel! NEQ 0 (
      echo [!date! - !time!] Failed to send email notification with 1 attempt left.>>"%~dp0log.txt"
      timeout /t 5 /nobreak >nul
      pwsh -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%script%"
      if !ErrorLevel! NEQ 0 (
        echo [!date! - !time!] Failed to send email notification with 0 attempts left.>>"%~dp0log.txt"
      )
    )
  )
exit /b 0