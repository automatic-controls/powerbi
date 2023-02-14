@echo off
title RegFox Import Script
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion

set "file=%~dp0body.html"
set "script=%~dp0mail_script.ps1"
set "parser=%~dp0parse.ps1"
set "dst=C:\Users\powerbi\Automatic Controls Equipment Systems, Inc\Power BI - Documents\2-Reference Data\Training Data\registrants.csv"

(
  if exist "%script%" del /F "%script%" >nul
  for /f "tokens=* delims=" %%i in ('hostname') do set "hostn=%%i"
  set "err=Error source is unknown."
  call :main
  if !ErrorLevel! EQU 0 (
    echo !date!-!time! - Processing succeeded.
    del /F "%file%" >nul 2>nul
  ) else (
    set "err=The scheduled RegFox data script failed on computer !hostn!. !err!"
    echo !date!-!time! - Processing failed.
    call :email
  )
) >> "%~dp0log.txt" 2>&1
exit /b

:main
  echo %date%-%time% - Attempting to parse URL.
  if not exist "%parser%" (
    set "err=Could not locate parse utilty script."
    echo !err!
    exit /b 1
  )
  if not exist "%file%" (
    set "err=Could not locate input file: body.html"
    echo !err!
    exit /b 1
  )
  set "url="
  for /f "tokens=* delims=" %%i in ('PowerShell -NoLogo -File "%parser%" 2^>nul') do (
    set "url=%%i"
  )
  if "%url%" EQU "" (
    set "err=Unable to parse URL."
    echo !err!
    exit /b 1
  )
  curl --fail --silent --output "%dst%" "%url%"
  if %ErrorLevel% NEQ 0 (
    set "err=Failed to download data from URL."
    echo !err!
    exit /b 1
  )
exit /b 0

:email
  echo Send-MailMessage -From "!pbi_email!" -To @^("!error_email!"^) -Subject "RegFox Import Failure" -Body "This is an automated alert. %err%" -SmtpServer "smtp-mail.outlook.com" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)>"%script%"
  PowerShell -NoLogo -File "%script%"
  if exist "%script%" del /F "%script%" >nul
exit /b 0