@echo off
setlocal EnableDelayedExpansion
call "%~dp0../env_vars.bat"
set "script=%root%mail-script.ps1"
(
  java -Djava.library.path="C:\Program Files (x86)\CLEARIFY\QQube Tool\SQL Anywhere 17\BIN64" -cp "%~dp0qqube-checker.jar;%lib%\*;C:\Program Files (x86)\CLEARIFY\QQube Tool\SQL Anywhere 17\Java\sajdbc4.jar" Main
  set "err=!ERRORLEVEL!"
  if !err! EQU 0 (
    set "recipients=epitts@automaticcontrols.net"
    set "subject=QQube Sync Successful"
    set "message=QQube synced successfully this morning."
  ) else (
    set "recipients=!error_email!;epitts@automaticcontrols.net"
    set "subject=QQube Sync Failure"
    if !err! EQU 1978 (
      set "message=The QQube sync has failed. Please remote into ACES-PowerBI as apps_admin and initiate a manual sync."
    ) else (
      set "message=The status of the QQube sync could not be determined. Please remote into ACES-PowerBI as apps_admin and check for yourself."
    )
  )
  call :email
) >> "%~dp0log.txt" 2>&1
exit

:email
  set "email_to=!recipients!"
  set "email_subject=!subject!"
  set "email_body=This is an automated alert. !message! See the log file for more details."
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