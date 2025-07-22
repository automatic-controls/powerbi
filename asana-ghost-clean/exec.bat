@echo off
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
set "script=%root%mail-script.ps1"
(
  set suc=1
  for /l %%i in (1,1,%attempts%) do (
    if !suc! NEQ 0 (
      java -cp "%~dp0asana-ghost-clean.jar;%lib%\*;" Main
      set "suc=!ErrorLevel!"
      if !suc! NEQ 0 (
        echo Attempt %%i of %attempts% failed.
        timeout /nobreak /t 300 >nul
      )
    )
  )
  if !suc! NEQ 0 call :email
) >> "%~dp0log.txt" 2>&1
exit

:email
  set "email_subject=Asana Database Clean Failure"
  set "email_body=This is an automated alert. The script which deletes ghost Asana projects and tasks from the PostgreSQL database failed to execute. See the log file for more details."
  set "email_to=%error_email%"
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