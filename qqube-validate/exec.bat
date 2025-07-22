@echo off
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
set "script=%root%mail-script.ps1"
set "ret=0"
(
  java -Djava.library.path="C:\Program Files (x86)\CLEARIFY\QQube Tool\SQL Anywhere 17\BIN64" -cp "%~dp0qqube-validate.jar;%lib%\*;C:\Program Files (x86)\CLEARIFY\QQube Tool\SQL Anywhere 17\Java\sajdbc4.jar" Main
  set "ret=!ERRORLEVEL!"
) > "%~dp0log.txt" 2>&1
if "!ret!" NEQ "0" call :email
exit

:email
  set "email_to=!error_email!"
  set "email_subject=QQube Validation"
  set "email_body=This is an automated alert. Status=%ret%. See the attached log file for more details."
  set "email_attachment=%~dp0log.txt"
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