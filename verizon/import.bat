@echo off
title Verizon Import Script
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion

set "src=PBI_Sharepoint:\Avant-Garde\script-cache\verizon"
set "reportMovements=Scheduled Report Detailed Report.csv"
set "reportSpeeding=Scheduled Report Speeding Report.csv"
set "reportIncidents=Scheduled Report Harsh Driving Incident Report.csv"
set "reportServices=Scheduled Report Vehicle Maintenance Report.csv"
set "script=%~dp0mail_script.ps1"

(
  if exist "%script%" del /F "%script%" >nul
  set "err=Error source is unknown."
  call :main
  if !ErrorLevel! EQU 0 (
    echo !date!-!time! - Import succeeded.
    if exist "%~dp0%reportMovements%" del /F "%~dp0%reportMovements%" >nul 2>nul
    if exist "%~dp0%reportSpeeding%" del /F "%~dp0%reportSpeeding%" >nul 2>nul
    if exist "%~dp0%reportIncidents%" del /F "%~dp0%reportIncidents%" >nul 2>nul
    if exist "%~dp0%reportServices%" del /F "%~dp0%reportServices%" >nul 2>nul
    rclone delete --retries 5 --retries-sleep 500ms "%src%\%reportMovements%"
    rclone delete --retries 5 --retries-sleep 500ms "%src%\%reportSpeeding%"
    rclone delete --retries 5 --retries-sleep 500ms "%src%\%reportIncidents%"
    rclone delete --retries 5 --retries-sleep 500ms "%src%\%reportServices%"
  ) else (
    echo !err!
    echo !date!-!time! - Import failed.
    call :email
  )
) >> "%~dp0log.txt" 2>&1
exit /b

:main
  echo %date%-%time% - Attempting to import data.
  rclone copyto --ignore-checksum --ignore-size --retries 5 --retries-sleep 500ms "%src%\%reportMovements%" "%~dp0%reportMovements%"
  rclone copyto --ignore-checksum --ignore-size --retries 5 --retries-sleep 500ms "%src%\%reportSpeeding%" "%~dp0%reportSpeeding%"
  rclone copyto --ignore-checksum --ignore-size --retries 5 --retries-sleep 500ms "%src%\%reportIncidents%" "%~dp0%reportIncidents%"
  rclone copyto --ignore-checksum --ignore-size --retries 5 --retries-sleep 500ms "%src%\%reportServices%" "%~dp0%reportServices%"
  if not exist "%~dp0%reportMovements%" (
    set "err=Could not locate movement report."
    exit /b 1
  )
  if not exist "%~dp0%reportSpeeding%" (
    set "err=Could not locate speeding report."
    exit /b 1
  )
  if not exist "%~dp0%reportIncidents%" (
    set "err=Could not locate incident report."
    exit /b 1
  )
  if not exist "%~dp0%reportServices%" (
    set "err=Could not locate maintenance report."
    exit /b 1
  )
  set "PGPASSWORD=!postgresql_pass!"
  set suc=1
  for /l %%i in (1,1,%attempts%) do (
    if !suc! NEQ 0 (
      if %%i EQU 1 (
        psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy verizon.movements (vehicle_number, vehicle_name, registration_number, driver_number, driver_name, employee_id, datetime, timezone_offset, timezone, status, latitude, longitude, address, city, state, postal_code, speed, speed_limit, heading, odometer, delta_time_text, delta_time_seconds, delta_distance, accumulated_time_text, accumulated_time_seconds, accumulated_distance, place_id, place_name, ignition, daily_accumulated_distance, esn, is_asset, fuel_type) from '%~dp0%reportMovements%' with DELIMITER ',' CSV HEADER"
        set "suc=!ErrorLevel!"
      ) else (
        timeout /nobreak /t 300 >nul
        psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy verizon.movements (vehicle_number, vehicle_name, registration_number, driver_number, driver_name, employee_id, datetime, timezone_offset, timezone, status, latitude, longitude, address, city, state, postal_code, speed, speed_limit, heading, odometer, delta_time_text, delta_time_seconds, delta_distance, accumulated_time_text, accumulated_time_seconds, accumulated_distance, place_id, place_name, ignition, daily_accumulated_distance, esn, is_asset, fuel_type) from '%~dp0%reportMovements%' with DELIMITER ',' CSV HEADER" >nul 2>&1
        set "suc=!ErrorLevel!"
      )
    )
  )
  if !suc! NEQ 0 (
    set "err=Failed to import movement report into database."
    exit /b 1
  )
  set suc=1
  for /l %%i in (1,1,%attempts%) do (
    if !suc! NEQ 0 (
      if %%i EQU 1 (
        psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy verizon.speeding (date, time, driver, vehicle, speed_limit, limit_source, speed, percentage_over, location, latitude, longitude, timezone, driver_number) from '%~dp0%reportSpeeding%' with DELIMITER ',' CSV HEADER"
        set "suc=!ErrorLevel!"
      ) else (
        timeout /nobreak /t 300 >nul
        psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy verizon.speeding (date, time, driver, vehicle, speed_limit, limit_source, speed, percentage_over, location, latitude, longitude, timezone, driver_number) from '%~dp0%reportSpeeding%' with DELIMITER ',' CSV HEADER" >nul 2>&1
        set "suc=!ErrorLevel!"
      )
    )
  )
  if !suc! NEQ 0 (
    set "err=Failed to import speeding report into database."
    exit /b 1
  )
  set suc=1
  for /l %%i in (1,1,%attempts%) do (
    if !suc! NEQ 0 (
      if %%i EQU 1 (
        psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy verizon.incidents (vehicle, driver, datetime, event, location, initial_speed, duration, severity) from '%~dp0%reportIncidents%' with DELIMITER ',' CSV HEADER"
        set "suc=!ErrorLevel!"
      ) else (
        timeout /nobreak /t 300 >nul
        psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy verizon.incidents (vehicle, driver, datetime, event, location, initial_speed, duration, severity) from '%~dp0%reportIncidents%' with DELIMITER ',' CSV HEADER" >nul 2>&1
        set "suc=!ErrorLevel!"
      )
    )
  )
  if !suc! NEQ 0 (
    set "err=Failed to import incident report into database."
    exit /b 1
  )
  set suc=1
  for /l %%i in (1,1,%attempts%) do (
    if !suc! NEQ 0 (
      if %%i EQU 1 (
        psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy verizon.services (service_name, vehicle_name, odometer, days_left, due_date, distance_left, engine_hours_left) from '%~dp0%reportServices%' with DELIMITER ',' CSV HEADER"
        set "suc=!ErrorLevel!"
      ) else (
        timeout /nobreak /t 300 >nul
        psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy verizon.services (service_name, vehicle_name, odometer, days_left, due_date, distance_left, engine_hours_left) from '%~dp0%reportServices%' with DELIMITER ',' CSV HEADER" >nul 2>&1
        set "suc=!ErrorLevel!"
      )
    )
  )
  if !suc! NEQ 0 (
    set "err=Failed to import maintenance report into database."
    exit /b 1
  )
exit /b 0

:email
  (
    echo Send-MailMessage -From "!pbi_email!" -To "!error_email!".Split^(";"^) -Subject "Verizon Import Failure" -Body "Verizon vehicle GPS data failure. %err% See the log file for more details." -SmtpServer "smtp-mail.outlook.com" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)
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