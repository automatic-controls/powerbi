@echo off
title Synchrony Import Script
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
cd "%~dp0"

set "benefits_csv=%~dp0ACES - Benefits Billing Detail Report.csv"
set "timesheet_csv=%~dp0ACES - Time Sheet Report.csv"
set "alloc_csv=%~dp0ACES - Scheduled Payments.csv"
set "script=%~dp0script.sql"
set "mscript=%~dp0mail_script.ps1"
set "stamps=%~dp0stamps.bat"
set "PGPASSWORD=!postgresql_pass!"
set /a error_days=10

for /f "delims=" %%i in ('PowerShell -NoLogo -Command "[Math]::Round((Get-Date).ToFileTime()/864000000000)"') do set /a days=%%i
set benefits_days=0
set timesheet_days=0
set alloc_days=0
if exist "%stamps%" call "%stamps%"

(
  if exist "%script%" del /F "%script%" >nul
  if exist "%mscript%" del /F "%mscript%" >nul
  set "err="
  call :main
  if !ErrorLevel! EQU 0 (
    set x=0
    if exist "%benefits_csv%" set x=1& del /F "%benefits_csv%" >nul 2>nul
    if exist "%timesheet_csv%" set x=1& del /F "%timesheet_csv%" >nul 2>nul
    if exist "%alloc_csv%" set x=1& del /F "%alloc_csv%" >nul 2>nul
    if !x! EQU 1 (
      echo !date!-!time! - Import succeeded.
    ) else (
      echo !date!-!time! - Nothing to import.
    )
  ) else (
    echo !date!-!time! - Import failed.
    call :email
  )
  if exist "%script%" del /F "%script%" >nul
  if exist "%mscript%" del /F "%mscript%" >nul
) >> "%~dp0log.txt" 2>&1
exit /b

:main
  echo %date%-%time% - Attempting to import data.
  if exist "%timesheet_csv%" (
    set timesheet_days=%days%
    (
      echo \copy payroll.compensation ^(payroll_number, employee_id, employee_name, charge_date, location, position, pay_code, pay_description, shift, hours_units_paid, hourly_rate, hours_worked, pay_amount^) from '%timesheet_csv%' with DELIMITER ',' CSV HEADER;
      echo DO $$
      echo     DECLARE
      echo         min_date DATE;
      echo         max_date DATE;
      echo     BEGIN
      echo         SELECT MIN^("charge_date"^) INTO "min_date"
      echo         FROM payroll.compensation
      echo         WHERE "last_modified" IS NULL;
      echo         SELECT MAX^("charge_date"^) INTO "max_date"
      echo         FROM payroll.compensation
      echo         WHERE "last_modified" IS NULL;
      echo         DELETE FROM payroll.compensation
      echo         WHERE "charge_date"^>="min_date"
      echo         AND "charge_date"^<="max_date"
      echo         AND "last_modified" IS NOT NULL
      echo         AND NOT "allocation";
      echo         UPDATE payroll.compensation
      echo         SET "last_modified" = CURRENT_TIMESTAMP,
      echo         "allocation" = FALSE
      echo         WHERE "last_modified" IS NULL;
      echo     END;
      echo $$;
    ) > "%script%"
    set suc=1
    for /l %%i in (1,1,%attempts%) do (
      if !suc! NEQ 0 (
        if %%i EQU 1 (
          psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -1 -c "\ir script.sql"
          set "suc=!ErrorLevel!"
        ) else (
          timeout /nobreak /t 5 >nul
          psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -1 -c "\ir script.sql" >nul 2>&1
          set "suc=!ErrorLevel!"
        )
      )
    )
    if !suc! NEQ 0 (
      set "x=Failed to import '%timesheet_csv%'."
      echo !x!
      set "err=!err!!x! "
    )
  )
  if exist "%alloc_csv%" (
    set alloc_days=%days%
    (
      echo \copy payroll.compensation ^(payroll_number, employee_id, employee_name, charge_date, location, position, pay_code, pay_description, shift, hours_units_paid, hourly_rate, hours_worked, pay_amount^) from '%alloc_csv%' with DELIMITER ',' CSV HEADER;
      echo DO $$
      echo     DECLARE
      echo         min_date DATE;
      echo         max_date DATE;
      echo     BEGIN
      echo         SELECT MIN^("charge_date"^) INTO "min_date"
      echo         FROM payroll.compensation
      echo         WHERE "last_modified" IS NULL;
      echo         SELECT MAX^("charge_date"^) INTO "max_date"
      echo         FROM payroll.compensation
      echo         WHERE "last_modified" IS NULL;
      echo         DELETE FROM payroll.compensation
      echo         WHERE "charge_date"^>="min_date"
      echo         AND "charge_date"^<="max_date"
      echo         AND "last_modified" IS NOT NULL
      echo         AND "allocation";
      echo         UPDATE payroll.compensation
      echo         SET "last_modified" = CURRENT_TIMESTAMP,
      echo         "allocation" = TRUE
      echo         WHERE "last_modified" IS NULL;
      echo     END;
      echo $$;
    ) > "%script%"
    set suc=1
    for /l %%i in (1,1,%attempts%) do (
      if !suc! NEQ 0 (
        if %%i EQU 1 (
          psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -1 -c "\ir script.sql"
          set "suc=!ErrorLevel!"
        ) else (
          timeout /nobreak /t 5 >nul
          psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -1 -c "\ir script.sql" >nul 2>&1
          set "suc=!ErrorLevel!"
        )
      )
    )
    if !suc! NEQ 0 (
      set "x=Failed to import '%alloc_csv%'."
      echo !x!
      set "err=!err!!x! "
    )
  )
  if exist "%benefits_csv%" (
    set benefits_days=%days%
    (
      echo \copy payroll.benefits ^(pay_date, employee_id, employee_name, plan_id, plan_description, amount_billed, employee_contribution, net_amount_billed^) from '%benefits_csv%' with DELIMITER ',' CSV HEADER;
      echo DO $$
      echo     DECLARE
      echo         min_date DATE;
      echo         max_date DATE;
      echo     BEGIN
      echo         SELECT MIN^("pay_date"^) INTO "min_date"
      echo         FROM payroll.benefits
      echo         WHERE "last_modified" IS NULL;
      echo         SELECT MAX^("pay_date"^) INTO "max_date"
      echo         FROM payroll.benefits
      echo         WHERE "last_modified" IS NULL;
      echo         DELETE FROM payroll.benefits
      echo         WHERE "pay_date"^>="min_date"
      echo         AND "pay_date"^<="max_date"
      echo         AND "last_modified" IS NOT NULL;
      echo         UPDATE payroll.benefits
      echo         SET "last_modified" = CURRENT_TIMESTAMP
      echo         WHERE "last_modified" IS NULL;
      echo     END;
      echo $$;
    ) > "%script%"
    set suc=1
    for /l %%i in (1,1,%attempts%) do (
      if !suc! NEQ 0 (
        if %%i EQU 1 (
          psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -1 -c "\ir script.sql"
          set "suc=!ErrorLevel!"
        ) else (
          timeout /nobreak /t 5 >nul
          psql -h "!postgresql_url!" -p 5432 -U "!postgresql_user!" -d "analytics" -q -1 -c "\ir script.sql" >nul 2>&1
          set "suc=!ErrorLevel!"
        )
      )
    )
    if !suc! NEQ 0 (
      set "x=Failed to import '%benefits_csv%'."
      echo !x!
      set "err=!err!!x! "
    )
  )
  if exist "%script%" del /F "%script%" >nul
  set /a dif=%days%-%timesheet_days%
  if !dif! GTR %error_days% (
    set "x='%timesheet_csv%' not imported for !dif! consecutive days."
    echo !x!
    set "err=!err!!x! "
  )
  set /a dif=%days%-%alloc_days%
  if !dif! GTR %error_days% (
    set "x='%alloc_csv%' not imported for !dif! consecutive days."
    echo !x!
    set "err=!err!!x! "
  )
  set /a dif=%days%-%benefits_days%
  if !dif! GTR %error_days% (
    set "x='%benefits_csv%' not imported for !dif! consecutive days."
    echo !x!
    set "err=!err!!x! "
  )
  (
    echo set timesheet_days=%timesheet_days%
    echo set alloc_days=%alloc_days%
    echo set benefits_days=%benefits_days%
  ) > "%stamps%"
  if "%err%" NEQ "" exit /b 1
exit /b 0

:email
  echo Send-MailMessage -From "!pbi_email!" -To "!error_email!".Split^(";"^) -Subject "Synchrony Import Failure" -Body "%err%See the log file for more details." -SmtpServer "smtp-mail.outlook.com" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)>"%mscript%"
  PowerShell -NoLogo -File "%mscript%"
  if exist "%mscript%" del /F "%mscript%" >nul
exit /b 0