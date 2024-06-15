@echo off
title Synchrony Import Script
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion
cd "%~dp0"

set "src=PBI_Sharepoint:\Avant-Garde\script-cache\synchrony"
set "dst=%~dp0data"
set "benefits_csv=%dst%\ACES - Benefits Billing Detail Report*.csv"
set "timesheet_csv=%dst%\ACES - Time Sheet Report*.csv"
set "alloc_csv=%dst%\ACES - Scheduled Payments*.csv"
set "script=%~dp0script.sql"
set "mscript=%~dp0mail_script.ps1"
set "stamps=%~dp0stamps.bat"
set "PGPASSWORD=!postgresql_pass!"
set /a error_days=14

rclone sync --ignore-checksum --ignore-size --retries 5 --retries-sleep 500ms "%src%" "%dst%"
set exists_benefits_csv=0
set exists_timesheet_csv=0
set exists_alloc_csv=0
for %%i in ("%benefits_csv%") do (
  set exists_benefits_csv=1
)
for %%i in ("%timesheet_csv%") do (
  set exists_timesheet_csv=1
)
for %%i in ("%alloc_csv%") do (
  set exists_alloc_csv=1
)

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
    for %%i in ("%benefits_csv%") do (
      set x=1
      del /F "%%~fi" >nul 2>nul
    )
    for %%i in ("%timesheet_csv%") do (
      set x=1
      del /F "%%~fi" >nul 2>nul
    )
    for %%i in ("%alloc_csv%") do (
      set x=1
      del /F "%%~fi" >nul 2>nul
    )
    rclone delete --retries 5 --retries-sleep 500ms "%src%"
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
  if "%exists_alloc_csv%" EQU "1" (
    set alloc_days=%days%
    (
      echo \set ON_ERROR_STOP true
      for %%i in ("%alloc_csv%") do (
        echo \copy payroll.compensation ^(payroll_number, employee_id, employee_name, charge_date, location, position, pay_code, pay_description, shift, hours_units_paid, hourly_rate, hours_worked, pay_amount^) from '%%~fi' with DELIMITER ',' CSV HEADER;
      )
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
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -1 -c "\ir script.sql"
          set "suc=!ErrorLevel!"
        ) else (
          timeout /nobreak /t 300 >nul
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -1 -c "\ir script.sql" >nul 2>&1
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
  if "%exists_timesheet_csv%" EQU "1" (
    set timesheet_days=%days%
    for %%i in ("%timesheet_csv%") do (
      PowerShell -NoLogo -File "%~dp0preprocess.ps1" -file "%%~fi"
    )
    (
      echo \set ON_ERROR_STOP true
      for %%i in ("%timesheet_csv%") do (
        echo \copy payroll.compensation ^(payroll_number, employee_id, employee_name, charge_date, location, position, pay_code, pay_description, shift, hours_units_paid, hourly_rate, hours_worked, pay_amount^) from '%%~fi' with DELIMITER ',' CSV HEADER;
      )
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
      echo -- Ensure non-null data
      echo UPDATE payroll.compensation SET
      echo "location" = COALESCE^("location",'MAIN'^),
      echo "shift" = COALESCE^(CASE WHEN "shift"='' THEN '0' ELSE "shift" END,'0'^),
      echo "hours_units_paid" = COALESCE^("hours_units_paid",0^),
      echo "hourly_rate" = COALESCE^("hourly_rate",0::MONEY^),
      echo "hours_worked" = COALESCE^("hours_worked",0^),
      echo "pay_amount" = COALESCE^("pay_amount",0::MONEY^);
      echo -- Ensure employee names match for the same ID
      echo UPDATE payroll.compensation "comp"
      echo SET "employee_name" = "names"."employee_name"
      echo FROM ^(
      echo   SELECT DISTINCT ON ^("employee_id"^)
      echo     "employee_id", "employee_name"
      echo   FROM payroll.compensation
      echo   ORDER BY "employee_id", "charge_date" DESC
      echo ^) "names"
      echo WHERE "comp"."employee_id" = "names"."employee_id";
      echo -- Ensure pay descriptions match for the same pay code
      echo UPDATE payroll.compensation "comp"
      echo SET "pay_description" = "names"."pay_description"
      echo FROM ^(
      echo   SELECT DISTINCT ON ^("pay_code"^)
      echo     "pay_code", "pay_description"
      echo   FROM payroll.compensation
      echo   ORDER BY "pay_code", "charge_date" DESC
      echo ^) "names"
      echo WHERE "comp"."pay_code" = "names"."pay_code";
      echo -- Delete duplicate allocation rows
      echo WITH "data" AS ^(
      echo   SELECT
      echo     "employee_id",
      echo     "charge_date",
      echo     "pay_code",
      echo     "hourly_rate",
      echo     "pay_amount",
      echo     "allocation"
      echo   FROM payroll.compensation
      echo ^),
      echo "timesheet" AS ^(
      echo   SELECT * FROM "data"
      echo   WHERE NOT "allocation"
      echo ^),
      echo "dupes" AS ^(
      echo   SELECT "a".* FROM ^(
      echo     SELECT * FROM "data"
      echo     WHERE "allocation"
      echo   ^) "a" CROSS JOIN LATERAL ^(
      echo     SELECT * FROM "timesheet" "t"
      echo     WHERE "a"."employee_id"="t"."employee_id"
      echo     AND "a"."charge_date"="t"."charge_date"
      echo     AND "a"."pay_code"="t"."pay_code"
      echo     AND "a"."hourly_rate"="t"."hourly_rate"
      echo     AND "a"."pay_amount"="t"."pay_amount"
      echo     LIMIT 1
      echo   ^) "b"
      echo ^)
      echo DELETE FROM payroll.compensation "c" USING "dupes" "d"
      echo WHERE NOT "c"."allocation"
      echo AND "c"."employee_id"="d"."employee_id"
      echo AND "c"."charge_date"="d"."charge_date"
      echo AND "c"."pay_code"="d"."pay_code"
      echo AND "c"."hourly_rate"="d"."hourly_rate"
      echo AND "c"."pay_amount"="d"."pay_amount";
      echo -- Make allocation true for all relevant pay codes
      echo UPDATE payroll.compensation "comp"
      echo SET "allocation" = TRUE
      echo FROM ^(
      echo   SELECT DISTINCT "pay_code"
      echo   FROM payroll.compensation
      echo   WHERE "allocation"
      echo ^) "allocs"
      echo WHERE "comp"."pay_code" = "allocs"."pay_code";
      echo -- Merge identical entries into the same row
      echo WITH "merged" AS ^(
      echo   SELECT
      echo     "payroll_number",
      echo     "employee_id",
      echo     "employee_name",
      echo     "charge_date",
      echo     "location",
      echo     "position",
      echo     "pay_code",
      echo     "pay_description",
      echo     "shift",
      echo     SUM^("hours_units_paid"^) AS "hours_units_paid",
      echo     "hourly_rate",
      echo     SUM^("hours_worked"^) AS "hours_worked",
      echo     SUM^("pay_amount"^) AS "pay_amount",
      echo     MAX^("last_modified"^) AS "last_modified",
      echo     "allocation",
      echo     MAX^("ctid"^) AS "index"
      echo   FROM payroll.compensation GROUP BY
      echo     "payroll_number",
      echo     "employee_id",
      echo     "employee_name",
      echo     "charge_date",
      echo     "location",
      echo     "position",
      echo     "pay_code",
      echo     "pay_description",
      echo     "shift",
      echo     "hourly_rate",
      echo     "allocation"
      echo   HAVING COUNT^(*^)^>1
      echo ^) UPDATE payroll.compensation "c" SET
      echo   "hours_units_paid" = "m"."hours_units_paid",
      echo   "hours_worked" = "m"."hours_worked",
      echo   "pay_amount" = "m"."pay_amount",
      echo   "last_modified" = "m"."last_modified"
      echo FROM "merged" "m" WHERE
      echo   "c"."payroll_number" = "m"."payroll_number" AND
      echo   "c"."employee_id" = "m"."employee_id" AND
      echo   "c"."employee_name" = "m"."employee_name" AND
      echo   "c"."charge_date" = "m"."charge_date" AND
      echo   "c"."location" = "m"."location" AND
      echo   "c"."position" = "m"."position" AND
      echo   "c"."pay_code" = "m"."pay_code" AND
      echo   "c"."pay_description" = "m"."pay_description" AND
      echo   "c"."shift" = "m"."shift" AND
      echo   "c"."hourly_rate" = "m"."hourly_rate" AND
      echo "c"."allocation" = "m"."allocation";
      echo WITH "dupes" AS ^(
      echo   SELECT
      echo     "payroll_number",
      echo     "employee_id",
      echo     "employee_name",
      echo     "charge_date",
      echo     "location",
      echo     "position",
      echo     "pay_code",
      echo     "pay_description",
      echo     "shift",
      echo     "hours_units_paid",
      echo     "hourly_rate",
      echo     "hours_worked",
      echo     "pay_amount",
      echo     "last_modified",
      echo     "allocation",
      echo     MAX^("ctid"^) AS "index"
      echo   FROM payroll.compensation GROUP BY
      echo     "payroll_number",
      echo     "employee_id",
      echo     "employee_name",
      echo     "charge_date",
      echo     "location",
      echo     "position",
      echo     "pay_code",
      echo     "pay_description",
      echo     "shift",
      echo     "hours_units_paid",
      echo     "hourly_rate",
      echo     "hours_worked",
      echo     "pay_amount",
      echo     "last_modified",
      echo   "allocation"
      echo ^) DELETE FROM payroll.compensation "c" USING "dupes" "m" WHERE
      echo   "c"."payroll_number" = "m"."payroll_number" AND
      echo   "c"."employee_id" = "m"."employee_id" AND
      echo   "c"."employee_name" = "m"."employee_name" AND
      echo   "c"."charge_date" = "m"."charge_date" AND
      echo   "c"."location" = "m"."location" AND
      echo   "c"."position" = "m"."position" AND
      echo   "c"."pay_code" = "m"."pay_code" AND
      echo   "c"."pay_description" = "m"."pay_description" AND
      echo   "c"."shift" = "m"."shift" AND
      echo   "c"."hours_units_paid" = "m"."hours_units_paid" AND
      echo   "c"."hourly_rate" = "m"."hourly_rate" AND
      echo   "c"."hours_worked" = "m"."hours_worked" AND
      echo   "c"."pay_amount" = "m"."pay_amount" AND
      echo   "c"."last_modified" = "m"."last_modified" AND
      echo   "c"."allocation" = "m"."allocation" AND
      echo "c"."ctid" ^< "m"."index";
    ) > "%script%"
    set suc=1
    for /l %%i in (1,1,%attempts%) do (
      if !suc! NEQ 0 (
        if %%i EQU 1 (
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -1 -c "\ir script.sql"
          set "suc=!ErrorLevel!"
        ) else (
          timeout /nobreak /t 300 >nul
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -1 -c "\ir script.sql" >nul 2>&1
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
  if "%exists_benefits_csv%" EQU "1" (
    set benefits_days=%days%
    (
      echo \set ON_ERROR_STOP true
      for %%i in ("%benefits_csv%") do (
        echo \copy payroll.benefits ^(pay_date, employee_id, employee_name, plan_id, plan_description, amount_billed, employee_contribution, net_amount_billed^) from '%%~fi' with DELIMITER ',' CSV HEADER;
      )
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
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -1 -c "\ir script.sql"
          set "suc=!ErrorLevel!"
        ) else (
          timeout /nobreak /t 300 >nul
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q -1 -c "\ir script.sql" >nul 2>&1
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
  (
    echo Send-MailMessage -From "!pbi_email!" -To "!error_email!".Split^(";"^) -Subject "Synchrony Import Failure" -Body "%err%See the log file for more details." -SmtpServer "smtp-mail.outlook.com" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)
    echo if ^( $? ^){ exit 0 }else{ exit 1 }
  )>"%mscript%"
  PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
  if %ErrorLevel% NEQ 0 (
    echo [!date! - !time!] Failed to send email notification with 2 attempts left.>>"%~dp0log.txt"
    timeout /t 5 /nobreak >nul
    PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
    if !ErrorLevel! NEQ 0 (
      echo [!date! - !time!] Failed to send email notification with 1 attempt left.>>"%~dp0log.txt"
      timeout /t 5 /nobreak >nul
      PowerShell -ExecutionPolicy Bypass -NoLogo -NonInteractive -File "%mscript%"
      if !ErrorLevel! NEQ 0 (
        echo [!date! - !time!] Failed to send email notification with 0 attempts left.>>"%~dp0log.txt"
      )
    )
  )
  if exist "%mscript%" del /F "%mscript%" >nul
exit /b 0