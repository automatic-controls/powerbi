@echo off
setlocal EnableDelayedExpansion
call "%~dp0../env_vars.bat"
set "script=%root%mail-script.ps1"
(
  java -Djava.library.path="C:\Program Files (x86)\CLEARIFY\QQube Tool\SQL Anywhere 17\BIN64" -cp "%~dp0qqube-sync.jar;%lib%\*;C:\Program Files (x86)\CLEARIFY\QQube Tool\SQL Anywhere 17\Java\sajdbc4.jar" Main
  if !ERRORLEVEL! NEQ 0 call :email
) >> "%~dp0log.txt" 2>&1
exit

:email
  set "email_to=!error_email!"
  set "email_subject=QQube-PostgreSQL Sync Failure"
  set "email_body=This is an automated alert. The script which automatically syncs QQube to PostgreSQL failed to execute. See the log file for more details."
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