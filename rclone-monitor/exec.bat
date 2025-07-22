@echo off
title RClone Monitor
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
set "smtp_server=smtp-mail.outlook.com"
set "mscript=%root%mail-script.ps1"
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
  for /f "tokens=1,2,3,4 delims=:, " %%j in ('rclone size --json --max-depth 1 --max-age 2d --include "*.zip" "!dir[%%i]!"') do (
    if "%%k" EQU "0" (
      set /a online[%%i]=0
      echo Cannot locate recent backup in '!dir[%%i]!'>>"%log%"
      set "send=1"
      set "email_body=!email_body!`r`nCannot locate recent backup in '!dir[%%i]!'"
    ) else (
      if "!online[%%i]!" NEQ "1" (
        set /a online[%%i]=1
        echo Found recent backup in '!dir[%%i]!'>>"%log%"
      )
      set mb=%%m
      set mb=!mb:~0,-6!
      if "!mb!" EQU "" (
        set mb=0
      )
      set /a mb=!mb!*155
      set /a mb=!mb!/163
      set /a avg_mb=!mb!/%%k
      if !avg_mb! GTR 5120 (
        echo Backup size in '!dir[%%i]!' exceeds 5GB>>"%log%"
        set "send=1"
        set "email_body=!email_body!`r`nBackup size in '!dir[%%i]!' exceeds 5GB"
      )
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
  set "email_subject=Dropbox Backup Alert"
  call :email
)
exit

:email
  pwsh -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
  if %ErrorLevel% NEQ 0 (
    echo Failed to send email notification with 2 attempts left.>>"%~dp0log.txt"
    timeout /t 5 /nobreak >nul
    pwsh -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
    if !ErrorLevel! NEQ 0 (
      echo Failed to send email notification with 1 attempt left.>>"%~dp0log.txt"
      timeout /t 5 /nobreak >nul
      pwsh -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
      if !ErrorLevel! NEQ 0 (
        echo Failed to send email notification with 0 attempts left.>>"%~dp0log.txt"
      )
    )
  )
exit /b 0