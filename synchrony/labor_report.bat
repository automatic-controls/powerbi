@echo off
title Synchrony Import Script
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
cd "%~dp0"

set "dataFolder=%~dp0data"
set "script=%~dp0script.sql"
set "mscript=%~dp0mail_script.ps1"
set "PGPASSWORD=!postgresql_pass!"

(
  if exist "%script%" del /F "%script%" >nul
  if exist "%mscript%" del /F "%mscript%" >nul
  set "err="
  echo %date%-%time% - Attempting to import data.
  call :main
  if !ErrorLevel! EQU 0 (
    echo !date!-!time! - Import succeeded.
  ) else (
    echo !date!-!time! - Import failed.
    call :email
  )
  if exist "%script%" del /F "%script%" >nul
  if exist "%mscript%" del /F "%mscript%" >nul
) >> "%~dp0labor_log.txt" 2>&1
exit /b

:main
  for %%i in ("%dataFolder%\*.csv") do (
    (
      echo DELETE FROM timestar.timesheets_processed WHERE "date" = '%%~ni'::DATE;
      echo \copy timestar.timesheets_processed ^(pay_type, job, work_category, employee_number, employee_name, hours^) from '%%~fi' with DELIMITER ',' CSV HEADER;
      echo DELETE FROM timestar.timesheets_processed WHERE "pay_type" = 'Totals:';
      echo UPDATE timestar.timesheets_processed SET "date"='%%~ni'::DATE, "regular_flag"=^("pay_type"^<^>'Overtime'^), "overtime_flag"=^("pay_type"='Overtime'^), "work_category"=REGEXP_REPLACE^("work_category",'[^^[:ascii:]]','','g'^), "job"=REGEXP_REPLACE^("job",'[^^[:ascii:]]','','g'^) WHERE "date" IS NULL;
    ) > "%script%"
    set suc=1
    for /l %%j in (1,1,%attempts%) do (
      if !suc! NEQ 0 (
        if %%j EQU 1 (
          psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -1 -c "\ir script.sql"
          set "suc=!ErrorLevel!"
        ) else (
          timeout /nobreak /t 5 >nul
          psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -1 -c "\ir script.sql" >nul 2>&1
          set "suc=!ErrorLevel!"
        )
      )
    )
    if !suc! EQU 0 (
      if exist "%%~fi" del /F "%%~fi" >nul
    ) else (
      set "x=Failed to import %%~ni."
      echo !x!
      set "err=!err!!x! "
    )
  )
  if "%err%" NEQ "" exit /b 1
exit /b 0

:email
  echo Send-MailMessage -From "!pbi_email!" -To "!error_email!".Split^(";"^) -Subject "Synchrony Labor Report Failure" -Body "%err%See the log file for more details." -SmtpServer "smtp-mail.outlook.com" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)>"%mscript%"
  PowerShell -NoLogo -File "%mscript%"
  if exist "%mscript%" del /F "%mscript%" >nul
exit /b 0