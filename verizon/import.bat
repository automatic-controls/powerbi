@echo off
title Verizon Import Script
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion

set "src=PBI_Sharepoint:\Avant-Garde\script-cache\verizon"
set "dst=%~dp0data"
set "reportMovements=%dst%\Scheduled Report Detailed Report*.csv"
set "reportSpeeding=%dst%\Scheduled Report Speeding Report*.csv"
set "reportIncidents=%dst%\Scheduled Report Harsh Driving Incident Report*.csv"
set "reportServices=%dst%\Scheduled Report Vehicle Maintenance Report*.csv"
set "reportMaintenance=%dst%\Maintenance History Report.csv"
set "script=%root%mail-script.ps1"

(
  set "err=Error source is unknown."
  call :main
  if !ErrorLevel! EQU 0 (
    echo !date!-!time! - Import succeeded.
    rmdir /S /Q "%dst%" >nul 2>nul
    rclone delete --retries 5 --retries-sleep 500ms "%src%"
  ) else (
    echo !err!
    echo !date!-!time! - Import failed.
    call :email
  )
) >> "%~dp0log.txt" 2>&1
exit /b

:main
  echo %date%-%time% - Attempting to import data.
  mkdir "%dst%" >nul 2>nul
  rclone sync --ignore-checksum --ignore-size --retries 5 --retries-sleep 500ms "%src%" "%dst%"
  for %%i in ("%reportServices%") do (
    set "processThisReport=%%~fi"
    pwsh -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%~dp0process.ps1"
  )
  set exists_movement_csv=0
  for %%i in ("%reportMovements%") do (
    set exists_movement_csv=1
  )
  set exists_speeding_csv=0
  for %%i in ("%reportSpeeding%") do (
    set exists_speeding_csv=1
  )
  set exists_incidents_csv=0
  for %%i in ("%reportIncidents%") do (
    set exists_incidents_csv=1
  )
  set exists_services_csv=0
  for %%i in ("%reportServices%") do (
    set exists_services_csv=1
  )
  set exists_maint_csv=0
  for %%i in ("%reportMaintenance%") do (
    set exists_maint_csv=1
  )
  if "!exists_movement_csv!" EQU "0" (
    set "err=Could not locate movement report."
    exit /b 1
  )
  if "!exists_speeding_csv!" EQU "0" (
    set "err=Could not locate speeding report."
    exit /b 1
  )
  if "!exists_incidents_csv!" EQU "0" (
    set "err=Could not locate incident report."
    exit /b 1
  )
  if "!exists_services_csv!" EQU "0" (
    set "err=Could not locate services report."
    exit /b 1
  )
  if "!exists_maint_csv!" EQU "0" (
    set "err=Could not locate maintenance report."
    exit /b 1
  )
  set "PGPASSWORD=!postgresql_pass!"
  for %%j in ("%reportMovements%") do (
    set suc=1
    for /l %%i in (1,1,%attempts%) do (
      if !suc! NEQ 0 (
        if %%i EQU 1 (
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy verizon.movements (vehicle_number, vehicle_name, registration_number, driver_number, driver_name, employee_id, datetime, timezone_offset, timezone, status, latitude, longitude, address, city, state, postal_code, speed, speed_limit, heading, odometer, delta_time_text, delta_time_seconds, delta_distance, accumulated_time_text, accumulated_time_seconds, accumulated_distance, place_id, place_name, ignition, daily_accumulated_distance, esn, is_asset, fuel_type) from '%%~fj' with DELIMITER ',' CSV HEADER"
          set "suc=!ErrorLevel!"
        ) else (
          timeout /nobreak /t 300 >nul
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy verizon.movements (vehicle_number, vehicle_name, registration_number, driver_number, driver_name, employee_id, datetime, timezone_offset, timezone, status, latitude, longitude, address, city, state, postal_code, speed, speed_limit, heading, odometer, delta_time_text, delta_time_seconds, delta_distance, accumulated_time_text, accumulated_time_seconds, accumulated_distance, place_id, place_name, ignition, daily_accumulated_distance, esn, is_asset, fuel_type) from '%%~fj' with DELIMITER ',' CSV HEADER" >nul 2>&1
          set "suc=!ErrorLevel!"
        )
      )
    )
    if !suc! NEQ 0 (
      set "err=Failed to import movement report into database."
      exit /b 1
    )
  )
  for %%j in ("%reportSpeeding%") do (
    set suc=1
    for /l %%i in (1,1,%attempts%) do (
      if !suc! NEQ 0 (
        if %%i EQU 1 (
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy verizon.speeding (date, time, driver, vehicle, speed_limit, limit_source, speed, percentage_over, location, latitude, longitude, timezone, driver_number) from '%%~fj' with DELIMITER ',' CSV HEADER"
          set "suc=!ErrorLevel!"
        ) else (
          timeout /nobreak /t 300 >nul
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy verizon.speeding (date, time, driver, vehicle, speed_limit, limit_source, speed, percentage_over, location, latitude, longitude, timezone, driver_number) from '%%~fj' with DELIMITER ',' CSV HEADER" >nul 2>&1
          set "suc=!ErrorLevel!"
        )
      )
    )
    if !suc! NEQ 0 (
      set "err=Failed to import speeding report into database."
      exit /b 1
    )
  )
  for %%j in ("%reportIncidents%") do (
    set suc=1
    for /l %%i in (1,1,%attempts%) do (
      if !suc! NEQ 0 (
        if %%i EQU 1 (
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy verizon.incidents (vehicle, driver, datetime, event, location, initial_speed, duration, severity) from '%%~fj' with DELIMITER ',' CSV HEADER"
          set "suc=!ErrorLevel!"
        ) else (
          timeout /nobreak /t 300 >nul
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy verizon.incidents (vehicle, driver, datetime, event, location, initial_speed, duration, severity) from '%%~fj' with DELIMITER ',' CSV HEADER" >nul 2>&1
          set "suc=!ErrorLevel!"
        )
      )
    )
    if !suc! NEQ 0 (
      set "err=Failed to import incident report into database."
      exit /b 1
    )
  )
  for %%j in ("%reportServices%") do (
    set suc=1
    for /l %%i in (1,1,%attempts%) do (
      if !suc! NEQ 0 (
        if %%i EQU 1 (
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy verizon.services (service_name, vehicle_name, odometer, days_left, due_date, distance_left, engine_hours_left) from '%%~fj' with DELIMITER ',' CSV HEADER"
          set "suc=!ErrorLevel!"
        ) else (
          timeout /nobreak /t 300 >nul
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy verizon.services (service_name, vehicle_name, odometer, days_left, due_date, distance_left, engine_hours_left) from '%%~fj' with DELIMITER ',' CSV HEADER" >nul 2>&1
          set "suc=!ErrorLevel!"
        )
      )
    )
    if !suc! NEQ 0 (
      set "err=Failed to import services report into database."
      exit /b 1
    )
  )
  for %%j in ("%reportMaintenance%") do (
    set suc=1
    for /l %%i in (1,1,%attempts%) do (
      if !suc! NEQ 0 (
        if %%i EQU 1 (
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy verizon.maintenance (service_name, vehicle_name, due_date, type, odometer, hours_of_use, cost, notes) from '%%~fj' with DELIMITER ',' CSV HEADER"
          set "suc=!ErrorLevel!"
        ) else (
          timeout /nobreak /t 300 >nul
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -c "\copy verizon.maintenance (service_name, vehicle_name, due_date, type, odometer, hours_of_use, cost, notes) from '%%~fj' with DELIMITER ',' CSV HEADER" >nul 2>&1
          set "suc=!ErrorLevel!"
        )
      )
    )
    if !suc! NEQ 0 (
      set "err=Failed to import maintenance report into database."
      exit /b 1
    )
  )
exit /b 0

:email
  set "email_to=!error_email!"
  set "email_subject=Verizon Import Failure"
  set "email_body=Verizon vehicle GPS data failure. %err% See the log file for more details."
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