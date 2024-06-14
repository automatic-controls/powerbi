@echo off
title Bidtracer Import Script
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion

set "estimateFileRaw=%UserProfile%\Downloads\DCReportData.xlsx"
set "estimateFile=%UserProfile%\Downloads\DCReportData.csv"
set "script=%~dp0mail_script.ps1"
set "helper=%~dp0helper.ps1"

(
  if exist "%script%" del /F "%script%" >nul
  set "err=Error source is unknown."
  call :main
  if !ErrorLevel! EQU 0 (
    echo !date!-!time! - Import succeeded.
    if exist "%estimateFileRaw%" del /F "%estimateFileRaw%" >nul 2>nul
  ) else (
    echo !err!
    echo !date!-!time! - Import failed.
    call :email
  )
  if exist "%estimateFile%" del /F "%estimateFile%" >nul 2>nul
) >> "%~dp0log.txt" 2>&1
exit /b

:main
  echo %date%-%time% - Attempting to import data.
  if not exist "%estimateFileRaw%" (
    set "err=Could not locate raw estimates data file."
    exit /b 1
  )
  PowerShell -NoLogo -File "%helper%" "%estimateFileRaw%"
  if not exist "%estimateFile%" (
    set "err=Failed to convert raw estimates data file from XLSX to CSV."
    exit /b 1
  )
  set "PGPASSWORD=!postgresql_pass!"
  set suc=1
  for /l %%i in (1,1,%attempts%) do (
    if !suc! NEQ 0 (
      if %%i EQU 1 (
        psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy bidtracer.alloc (bid_id, bid_title, cost_code, cost_description, hours, amount) from '%estimateFile%' with DELIMITER ',' CSV HEADER"
        set "suc=!ErrorLevel!"
      ) else (
        timeout /nobreak /t 300 >nul
        psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy bidtracer.alloc (bid_id, bid_title, cost_code, cost_description, hours, amount) from '%estimateFile%' with DELIMITER ',' CSV HEADER" >nul 2>&1
        set "suc=!ErrorLevel!"
      )
    )
  )
  if !suc! NEQ 0 (
    set "err=Failed to import estimate data file into database."
    exit /b 1
  )
exit /b 0

:email
  (
    echo Send-MailMessage -From "!pbi_email!" -To "!error_email!".Split^(";"^) -Subject "Bidtracer Import Failure" -Body "Script triggered by Power Automate failed to update database. %err%" -SmtpServer "smtp-mail.outlook.com" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)
    echo if ^( $? ^){ exit 0 }else{ exit 1 }
  )>"%script%"
  PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%script%"
  if %ErrorLevel% NEQ 0 (
    echo [!date! - !time!] Failed to send email notification with 2 attempts left.>>"%~dp0log.txt"
    timeout /t 5 /nobreak >nul
    PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%script%"
    if !ErrorLevel! NEQ 0 (
      echo [!date! - !time!] Failed to send email notification with 1 attempt left.>>"%~dp0log.txt"
      timeout /t 5 /nobreak >nul
      PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%script%"
      if !ErrorLevel! NEQ 0 (
        echo [!date! - !time!] Failed to send email notification with 0 attempts left.>>"%~dp0log.txt"
      )
    )
  )
  if exist "%script%" del /F "%script%" >nul
exit /b 0