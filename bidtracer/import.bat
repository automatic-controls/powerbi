@echo off
title Bidtracer Import Script
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion

set "estimateFileRaw=%UserProfile%\Downloads\DCReportData.xlsx"
set "estimateFile=%UserProfile%\Downloads\DCReportData.csv"
set "marginFileRaw=%UserProfile%\Downloads\Margin Report.xlsx"
set "marginFile=%UserProfile%\Downloads\Margin Report.csv"
set "script=%root%mail-script.ps1"
set "helper=%~dp0helper.ps1"

(
  set "err=Error source is unknown."
  call :main
  if !ErrorLevel! EQU 0 (
    echo !date!-!time! - Import succeeded.
    if exist "%estimateFileRaw%" del /F "%estimateFileRaw%" >nul 2>nul
    if exist "%marginFileRaw%" del /F "%marginFileRaw%" >nul 2>nul
  ) else (
    echo !err!
    echo !date!-!time! - Import failed.
    call :email
  )
  if exist "%estimateFile%" del /F "%estimateFile%" >nul 2>nul
  if exist "%marginFile%" del /F "%marginFile%" >nul 2>nul
) >> "%~dp0log.txt" 2>&1
exit /b

:main
  echo %date%-%time% - Attempting to import data.
  if not exist "%estimateFileRaw%" (
    set "err=Could not locate raw estimates data file."
    exit /b 1
  )
  if not exist "%marginFileRaw%" (
    set "err=Could not locate raw margin data file."
    exit /b 1
  )
  pwsh -NoLogo -File "%helper%" "%estimateFileRaw%"
  if not exist "%estimateFile%" (
    set "err=Failed to convert raw estimates data file from XLSX to CSV."
    exit /b 1
  )
  pwsh -NoLogo -File "%helper%" "%marginFileRaw%"
  if not exist "%marginFile%" (
    set "err=Failed to convert raw margin data file from XLSX to CSV."
    exit /b 1
  )
  set "PGPASSWORD=!postgresql_pass!"
  set suc=1
  for /l %%i in (1,1,%attempts%) do (
    if !suc! NEQ 0 (
      if %%i EQU 1 (
        psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy bidtracer.alloc (bid_id, bid_title, cost_code, cost_description, hours, amount) from '%estimateFile%' with DELIMITER ',' CSV HEADER"
        set "suc=!ErrorLevel!"
      ) else (
        timeout /nobreak /t 300 >nul
        psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy bidtracer.alloc (bid_id, bid_title, cost_code, cost_description, hours, amount) from '%estimateFile%' with DELIMITER ',' CSV HEADER" >nul 2>&1
        set "suc=!ErrorLevel!"
      )
    )
  )
  if !suc! NEQ 0 (
    set "err=Failed to import estimate data file into database."
    exit /b 1
  )
  set suc=1
  for /l %%i in (1,1,%attempts%) do (
    if !suc! NEQ 0 (
      if %%i EQU 1 (
        psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy bidtracer.margin (bid_id, margin, contract, cost) from '%marginFile%' with DELIMITER ',' CSV HEADER"
        set "suc=!ErrorLevel!"
      ) else (
        timeout /nobreak /t 300 >nul
        psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy bidtracer.margin (bid_id, margin, contract, cost) from '%marginFile%' with DELIMITER ',' CSV HEADER" >nul 2>&1
        set "suc=!ErrorLevel!"
      )
    )
  )
  if !suc! NEQ 0 (
    set "err=Failed to import margin data file into database."
    exit /b 1
  )
exit /b 0

:email
  set "email_to=!error_email!"
  set "email_subject=Bidtracer Import Failure"
  set "email_body=Script triggered by Power Automate failed to update database. %err%"
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