@echo off
title Bidtracer Materials Import Script
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
:main
echo.
echo Enter the job number below.
set /p "job=>"
echo.
echo Waiting for file selection...
set "file="
for /f "tokens=* delims=" %%i in ('PowerShell -File "%~dp0selector.ps1"') do (
  set "file=%%i"
)
if not exist "%file%" (
  echo The selected file could not be located.
  goto :end
)
echo Uploading data...
set "PGPASSWORD=!postgresql_pass!"
psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "\copy bidtracer.materials (name, part, description, list_price, cost, quantity, total_cost, manufacturer, cost_code, ordering) from '%file%' with DELIMITER ',' CSV HEADER"
psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "DELETE FROM bidtracer.materials WHERE bid_id='%job%';"
psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -c "UPDATE bidtracer.materials SET bid_id='%job%' WHERE bid_id IS NULL;"
del /F "%file%" >nul 2>nul
echo Operation completed.
echo.
goto :main