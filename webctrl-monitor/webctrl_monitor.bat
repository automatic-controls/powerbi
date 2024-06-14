@echo off
title Webserver Monitor
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
set "smtp_server=smtp-mail.outlook.com"
set "interval=120"
set "ping_timeout=5000"
set "retries=3"
set "mscript=%~dp0mail_script.ps1"
set "sites=%~dp0sites.txt"
set "log=%~dp0log.txt"
set "state=%~dp0state.txt"
echo ----- Webserver Monitor Started ----->>"%log%"
echo [%date% - %time%]>>"%log%"
set /a internet=1
:loop
ping -n 1 -w %ping_timeout% %smtp_server% | find "TTL=" >nul
if %ErrorLevel% NEQ 0 (
  if %internet% EQU 1 echo [!date! - !time!] Waiting for internet connection...>>"%log%"
  set /a internet=0
  timeout /t 10 /nobreak >nul
  goto loop
)
if %internet% EQU 0 echo [!date! - !time!] Reestablished internet connection.>>"%log%"
set /a internet=1
set /a len=0
for /f "usebackq eol=# tokens=1,2,3,* delims= " %%i in ("%sites%") do (
  if "%%i" NEQ "" (
    set /a len+=1
    set "dns[!len!]=%%i"
    set "ip[!len!]=%%j"
    set "email[!len!]=%%k"
    set "name[!len!]=%%l"
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
  curl --location --tlsv1.2 --ca-native --connect-timeout 4 --max-time 6 --fail --silent --output nul "!dns[%%i]!"
  if !ErrorLevel! EQU 0 (
    if !online[%%i]!==0 (
      echo [!date! - !time!] Acquired connection to !name[%%i]!>>"%log%"
      set "email_to=!email[%%i]!"
      set "email_subject=!name[%%i]! Alarm - ONLINE"
      set "email_body=!name[%%i]! is securely accessible at !dns[%%i]!"
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
      set "email_body=!name[%%i]! is no longer securely accessible from !dns[%%i]!"
      if "!ip[%%i]!" NEQ "null" (
        ping -n 1 -w %ping_timeout% !ip[%%i]! | find "TTL=" >nul
        if !ErrorLevel! EQU 0 (
          set "email_body=!email_body!`r`nRaw address !ip[%%i]! responds to pings."
        ) else (
          set "email_body=!email_body!`r`nRaw address !ip[%%i]! does not respond to pings."
        )
      )
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
  (
    echo Send-MailMessage -From "!pbi_email!" -To "!email_to!".Split^(";"^) -Subject "!email_subject!" -Body "!email_body!" -SmtpServer "%smtp_server%" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)
    echo if ^( $? ^){ exit 0 }else{ exit 1 }
  )>"%mscript%"
  PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
  if %ErrorLevel% NEQ 0 (
    echo [!date! - !time!] Failed to send email notification with 2 attempts left.>>"%~dp0log.txt"
    timeout /t 5 /nobreak >nul
    PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
    if !ErrorLevel! NEQ 0 (
      echo [!date! - !time!] Failed to send email notification with 1 attempt left.>>"%~dp0log.txt"
      timeout /t 5 /nobreak >nul
      PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
      if !ErrorLevel! NEQ 0 (
        echo [!date! - !time!] Failed to send email notification with 0 attempts left.>>"%~dp0log.txt"
      )
    )
  )
  if exist "%mscript%" del /F "%mscript%" >nul
exit /b 0