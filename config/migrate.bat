@echo off
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
echo !date! - !time! - Initialized.
rmdir /S /Q "%~dp0dumps" >nul 2>nul
mkdir "%~dp0dumps" >nul 2>nul
set "PGPASSWORD=!postgresql_pass!"
for /F "usebackq tokens=1,* delims= " %%i in ("%~dp0tables.txt") do (
  if "%%j" EQU "" (
    if not exist "%~dp0dumps/%%i.dump" (
      echo Dumping schema from Azure: %%i...
      pg_dump -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -n "%%i" -f "%~dp0dumps\%%i.dump" -F c
    )
  ) else (
    if not exist "%~dp0dumps/%%i_%%j.dump" (
      echo Dumping table from Azure: %%i.%%j...
      pg_dump -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -t "%%i.%%j" -f "%~dp0dumps\%%i_%%j.dump" -F c
    )
  )
)
set "PGPASSWORD=!_postgresql_pass!"
echo Preparing AWS database...
psql -h "!_postgresql_url!" -p !_postgresql_port! -U "!_postgresql_user!" -d "!_postgresql_database!" -q -1 -c "\ir setup.sql"
for /F "usebackq tokens=1,* eol=; delims= " %%i in ("%~dp0tables.txt") do (
  if "%%j" EQU "" (
    if exist "%~dp0dumps/%%i.dump" (
      echo Restoring schema to AWS: %%i...
      pg_restore -h "!_postgresql_url!" -p !_postgresql_port! -U "!_postgresql_user!" -d "!_postgresql_database!" -n "%%i" -O -1 -F c "%~dp0dumps\%%i.dump"
    )
  ) else (
    if exist "%~dp0dumps/%%i_%%j.dump" (
      echo Restoring table to AWS: %%i.%%j...
      pg_restore -h "!_postgresql_url!" -p !_postgresql_port! -U "!_postgresql_user!" -d "!_postgresql_database!" -a -O --disable-triggers -1 -F c "%~dp0dumps\%%i_%%j.dump"
    )
  )
)
echo !date! - !time! - Terminated.
pause >nul
exit