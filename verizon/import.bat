@echo off
title Bidtracer Import Script
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion

set "reportMovements=%~dp0Scheduled Report Detailed Report.csv"
set "reportSpeeding=%~dp0Scheduled Report Speeding Report.csv"
set "reportIncidents=%~dp0Scheduled Report Harsh Driving Incident Report.csv"
set "script=%~dp0mail_script.ps1"

(
  if exist "%script%" del /F "%script%" >nul
  set "err=Error source is unknown."
  call :main
  if !ErrorLevel! EQU 0 (
    echo !date!-!time! - Import succeeded.
    if exist "%reportMovements%" del /F "%reportMovements%" >nul 2>nul
    if exist "%reportSpeeding%" del /F "%reportSpeeding%" >nul 2>nul
    if exist "%reportIncidents%" del /F "%reportIncidents%" >nul 2>nul
  ) else (
    echo !err!
    echo !date!-!time! - Import failed.
    call :email
  )
) >> "%~dp0log.txt" 2>&1
exit /b

:main
  echo %date%-%time% - Attempting to import data.
  if not exist "%reportMovements%" (
    set "err=Could not locate movement report."
    exit /b 1
  )
  if not exist "%reportSpeeding%" (
    set "err=Could not locate speeding report."
    exit /b 1
  )
  if not exist "%reportIncidents%" (
    set "err=Could not locate incident report."
    exit /b 1
  )
  set "PGPASSWORD=!postgresql_pass!"
  psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy verizon.movements (vehicle_number, vehicle_name, registration_number, driver_number, driver_name, employee_id, datetime, timezone_offset, timezone, status, latitude, longitude, address, city, state, postal_code, speed, speed_limit, heading, odometer, delta_time_text, delta_time_seconds, delta_distance, accumulated_time_text, accumulated_time_seconds, accumulated_distance, place_id, place_name, ignition, daily_accumulated_distance, esn, is_asset, fuel_type) from '%reportMovements%' with DELIMITER ',' CSV HEADER"
  if "%ERRORLEVEL%" NEQ "0" (
    set "err=Failed to import movement report into database."
    exit /b 1
  )
  psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy verizon.speeding (date, time, driver, vehicle, speed_limit, limit_source, speed, percentage_over, location, latitude, longitude, timezone, driver_number) from '%reportSpeeding%' with DELIMITER ',' CSV HEADER"
  if "%ERRORLEVEL%" NEQ "0" (
    set "err=Failed to import speeding report into database."
    exit /b 1
  )
  psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy verizon.incidents (vehicle, driver, datetime, event, location, initial_speed, duration, severity) from '%reportIncidents%' with DELIMITER ',' CSV HEADER"
  if "%ERRORLEVEL%" NEQ "0" (
    set "err=Failed to import incident report into database."
    exit /b 1
  )
exit /b 0

:email
  echo Send-MailMessage -From "!pbi_email!" -To "!error_email!".Split^(";"^) -Subject "Verizon Import Failure" -Body "Verizon vehicle GPS data failure. %err% See the log file for more details." -SmtpServer "smtp-mail.outlook.com" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)>"%script%"
  PowerShell -NoLogo -File "%script%"
  if exist "%script%" del /F "%script%" >nul
exit /b 0