@echo off
title RClone Monitor
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
set "smtp_server=smtp-mail.outlook.com"
set "mscript=%~dp0mail_script.ps1"
set "sites=%~dp0sites.txt"
set "log=%~dp0log.txt"
set "state=%~dp0state.txt"
echo ----- RClone Monitor ----->>"%log%"
echo [%date% - %time%]>>"%log%"
:loop
ping -n 1 -w 5000 %smtp_server% | find "TTL=" >nul
if %ErrorLevel% NEQ 0 (
  timeout /t 10 /nobreak >nul
  goto loop
)
set /a len=0
for /f "usebackq tokens=* delims=" %%i in ("%sites%") do (
  if "%%i" NEQ "" (
    set /a len+=1
    set "dir[!len!]=%%i"
    set /a online[!len!]=0
  )
)
for /f "usebackq tokens=1,* delims= " %%i in ("%state%") do (
  if "%%j" NEQ "" if "%%i" EQU "1" (
    for /l %%k in (1,1,%len%) do (
      if "%%j" EQU "!dir[%%k]!" (
        set /a online[%%k]=%%i
      )
    )
  )
)
set "send=0"
set "email_body="
for /l %%i in (1,1,%len%) do (
  for /f "tokens=1,2 delims=:, " %%j in ('rclone size --json --max-depth 1 --max-age 2d --include "*.zip" "!dir[%%i]!"') do (
    if "!online[%%i]!" EQU "1" (
      if "%%k" EQU "0" (
        set /a online[%%i]=0
        echo Cannot locate recent backup in !dir[%%i]!>>"%log%"
        set "send=1"
        set "email_body=!email_body!`r`n!dir[%%i]!"
      )
    ) else if "%%k" NEQ "0" (
      set /a online[%%i]=1
      echo Found recent backup in !dir[%%i]!>>"%log%"
    )
  )
)
(
  for /l %%i in (1,1,%len%) do (
    echo !online[%%i]! !dir[%%i]!
  )
)>"%state%"
if "%send%" EQU "1" (
  set "email_to=cvogt@automaticcontrols.net;epitts@automaticcontrols.net"
  set "email_subject=Dropbox Backup Failure"
  set "email_body=The following directories are missing recent backups:!email_body!"
  call :email
)
exit

:email
  (
    echo Send-MailMessage -From "!pbi_email!" -To "!email_to!".Split^(";"^) -Subject "!email_subject!" -Body "!email_body!" -SmtpServer "%smtp_server%" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)
    echo if ^( $? ^){ exit 0 }else{ exit 1 }
  )>"%mscript%"
  PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
  if %ErrorLevel% NEQ 0 (
    echo Failed to send email notification with 2 attempts left.>>"%~dp0log.txt"
    timeout /t 5 /nobreak >nul
    PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
    if !ErrorLevel! NEQ 0 (
      echo Failed to send email notification with 1 attempt left.>>"%~dp0log.txt"
      timeout /t 5 /nobreak >nul
      PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
      if !ErrorLevel! NEQ 0 (
        echo Failed to send email notification with 0 attempts left.>>"%~dp0log.txt"
      )
    )
  )
  if exist "%mscript%" del /F "%mscript%" >nul
exit /b 0