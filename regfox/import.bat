@echo off
title RegFox Import Script
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion

set "file=%~dp0body.html"
set "script=%root%mail-script.ps1"
set "parser=%~dp0parse.ps1"
set "localDST=%~dp0registrants.csv"
set "src=PBI_Sharepoint:\Avant-Garde\script-cache\regfox\body.html"
set "dst=PBI_Sharepoint:\2-Reference Data\Training Data\registrants.csv"

(
  if exist "%localDST%" del /F "%localDST%" >nul 2>nul
  for /f "tokens=* delims=" %%i in ('hostname') do set "hostn=%%i"
  set "err=Error source is unknown."
  call :main
  if !ErrorLevel! EQU 0 (
    echo !date!-!time! - Processing succeeded.
    del /F "%file%" >nul 2>nul
    rclone delete --retries 5 --retries-sleep 500ms "%src%"
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
  rclone copyto --ignore-checksum --ignore-size --retries 5 --retries-sleep 500ms "%src%" "%file%"
  if not exist "%file%" (
    set "err=Could not download or locate input file: body.html"
    echo !err!
    exit /b 1
  )
  set "url="
  for /f "tokens=* delims=" %%i in ('pwsh -NoLogo -File "%parser%" 2^>nul') do (
    set "url=%%i"
  )
  if "%url%" EQU "" (
    set "err=Unable to parse URL."
    echo !err!
    exit /b 1
  )
  curl --location --fail --silent --output "%localDST%" "%url%"
  if %ErrorLevel% NEQ 0 (
    if exist "%localDST%" del /F "%localDST%" >nul 2>nul
    set "err=Failed to download data from URL."
    echo !err!
    exit /b 1
  )
  rclone copyto --ignore-checksum --ignore-size --retries 5 --retries-sleep 500ms "%localDST%" "%dst%"
  if %ErrorLevel% NEQ 0 (
    set "err=Failed to upload registrants.csv to Sharepoint site."
    echo !err!
    exit /b 1
  )
  if exist "%localDST%" del /F "%localDST%" >nul 2>nul
exit /b 0

:email
  set "email_to=!error_email!"
  set "email_subject=RegFox Import Failure"
  set "email_body=This is an automated alert. %err%"
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