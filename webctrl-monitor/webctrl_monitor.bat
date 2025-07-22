@echo off
title Webserver Monitor
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
set "interval=120"
set "ping_timeout=5000"
set "retries=3"
set "mscript=%root%mail-script.ps1"
set "sites=%~dp0sites.txt"
set "log=%~dp0log.txt"
set "state=%~dp0state.txt"
set "ntfy_msg=%~dp0ntfy.txt"
echo ----- Webserver Monitor Started ----->>"%log%"
echo [%date% - %time%]>>"%log%"
set /a internet=1
:loop
ping -n 1 -w %ping_timeout% 8.8.8.8 | find "TTL=" >nul
if %ErrorLevel% NEQ 0 (
  if %internet% EQU 1 echo [!date! - !time!] Waiting for internet connection...>>"%log%"
  set /a internet=0
  timeout /t 10 /nobreak >nul
  goto loop
)
if %internet% EQU 0 echo [!date! - !time!] Reestablished internet connection.>>"%log%"
set /a internet=1
set /a len=0
for /f "usebackq eol=# tokens=1,2,3,4,5,* delims= " %%i in ("%sites%") do (
  if "%%i" NEQ "" (
    set /a len+=1
    set "dns[!len!]=%%i"
    set "ssl[!len!]=%%j"
    set "ip[!len!]=%%k"
    set "email[!len!]=%%l"
    set "ntfy[!len!]=%%m"
    set "name[!len!]=%%n"
    set /a online[!len!]=-1
  )
)
for /f "usebackq tokens=1,2 delims= " %%i in ("%state%") do (
  if "%%i" NEQ "" (
    for /l %%k in (1,1,%len%) do (
      if "%%i" EQU "!dns[%%k]!" (
        set /a online[%%k]=%%j
      )
    )
  )
)
for /l %%i in (1,1,%len%) do (
  if "!ssl[%%i]!" EQU "ssl" (
    set "param=--ca-native"
    set "secureText= securely"
  ) else (
    set "param=--insecure"
    set "secureText="
  )
  curl --location --tlsv1.2 !param! --connect-timeout 5 --max-time 8 --fail --silent --output nul "!dns[%%i]!"
  if !ErrorLevel! EQU 0 (
    if !online[%%i]!==0 (
      echo [!date! - !time!] Acquired connection to !name[%%i]!>>"%log%"
      set "email_to=!email[%%i]!"
      set "email_subject=!name[%%i]! Alarm - ONLINE"
      set "email_body=!name[%%i]! is!secureText! accessible at !dns[%%i]!"
      echo !email_body!>"%ntfy_msg%"
      set "topic=!ntfy[%%i]!"
      call :email
    ) else if !online[%%i]! LSS %retries% if !online[%%i]! NEQ -1 (
      echo [!date! - !time!] Successfully pinged !name[%%i]!>>"%log%"
    )
    set /a online[%%i]=retries
  ) else if !online[%%i]!==-1 (
    set /a online[%%i]=0
  ) else if !online[%%i]! NEQ 0 (
    set /a online[%%i]-=1
    if !online[%%i]!==0 (
      echo [!date! - !time!] Lost connection to !name[%%i]!>>"%log%"
      set "email_to=!email[%%i]!"
      set "email_subject=!name[%%i]! Alarm - OFFLINE"
      set "email_body=!name[%%i]! is no longer!secureText! accessible from !dns[%%i]!"
      echo !email_body!>"%ntfy_msg%"
      if "!ip[%%i]!" NEQ "null" (
        ping -n 1 -w %ping_timeout% !ip[%%i]! | find "TTL=" >nul
        if !ErrorLevel! EQU 0 (
          set "email_body=!email_body!. Raw address !ip[%%i]! responds to pings."
          echo Raw address !ip[%%i]! responds to pings.>>"%ntfy_msg%"
        ) else (
          set "email_body=!email_body!. Raw address !ip[%%i]! does not respond to pings."
          echo Raw address !ip[%%i]! does not respond to pings.>>"%ntfy_msg%"
        )
      )
      set "topic=!ntfy[%%i]!"
      call :email
    ) else (
      echo [!date! - !time!] Failed to ping !name[%%i]! with !online[%%i]! attempts left>>"%log%"
    )
  )
)
(
  for /l %%i in (1,1,%len%) do (
    echo !dns[%%i]! !online[%%i]!
  )
)>"%state%"
timeout /t %interval% /nobreak >nul
goto loop

:email
  if "!topic!" NEQ "null" (
    curl --location --tlsv1.2 --connect-timeout 5 --max-time 8 --fail --silent --output nul --data-binary "@%ntfy_msg%" -H "Title: !email_subject!" "%ntfy_server%!topic!?auth=!ntfy_auth!"
  )
  pwsh -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
  if %ErrorLevel% NEQ 0 (
    echo [!date! - !time!] Failed to send email notification with 2 attempts left.>>"%~dp0log.txt"
    timeout /t 5 /nobreak >nul
    pwsh -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
    if !ErrorLevel! NEQ 0 (
      echo [!date! - !time!] Failed to send email notification with 1 attempt left.>>"%~dp0log.txt"
      timeout /t 5 /nobreak >nul
      pwsh -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
      if !ErrorLevel! NEQ 0 (
        echo [!date! - !time!] Failed to send email notification with 0 attempts left.>>"%~dp0log.txt"
      )
    )
  )
exit /b 0