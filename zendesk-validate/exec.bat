@echo off
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
set "script=%root%mail-script.ps1"
(
  java --enable-native-access=ALL-UNNAMED --sun-misc-unsafe-memory-access=allow -cp "%~dp0zendesk-validate.jar;%~dp0lib\*;%lib%\*;" Main
  if !ERRORLEVEL! NEQ 0 call :email
) >> "%~dp0log.txt" 2>&1
exit

:email
  set "email_to=!error_email!"
  set "email_subject=Zendesk Validation Failure"
  set "email_body=This is an automated alert. The script which validates Zendesk job numbers against Quickbooks has encountered an error. See the log file for more details."
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