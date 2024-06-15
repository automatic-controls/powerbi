@echo off
call "%~dp0../env_vars.bat"
setlocal EnableDelayedExpansion

:: Maximum number of backups to keep
set /a max=5

:: List of tables to backup
set "table[1]=bidtracer.alloc"
set "table[2]=quickbooks.jobs"
set "table[3]=timestar.timesheets_processed"
set "table[4]=payroll.benefits"
set "table[5]=payroll.compensation"


set "stamp=%date:~-4%-%date:~-10,2%-%date:~-7,2%"
set "PGPASSWORD=!postgresql_pass!"
set "script=%~dp0mail_script.ps1"
set "tmpFile=%~dp0tmp.csv"
set /a len=0
:counter
  set /a len+=1
  if "!table[%len%]!" NEQ "" goto :counter
set /a len-=1
(
  echo %stamp%
  set "err=0"
  for /L %%i in (1,1,%len%) do (
    set "folder=%~dp0!table[%%i]!"
    if exist "!folder!" (
      set /a num=0
      for /f "usebackq tokens=* delims=" %%j in (`dir /B /O:-D /T:C "!folder!"`) do (
        set /a num+=1
        if !num! GTR %max% del /F "!folder!\%%j" >nul
      )
    ) else (
      mkdir "!folder!" >nul
    )
    if exist "%tmpFile%" del /F "%tmpFile%" >nul
    set suc=1
    for /l %%j in (1,1,%attempts%) do (
      if !suc! NEQ 0 (
        if %%j EQU 1 (
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q --csv -o "%tmpFile%" -c "SELECT * FROM !table[%%i]!"
          set "suc=!ErrorLevel!"
        ) else (
          timeout /nobreak /t 300 >nul
          psql -h "!postgresql_url!" -p !postgresql_port! -U "!postgresql_user!" -d "!postgresql_database!" -q --csv -o "%tmpFile%" -c "SELECT * FROM !table[%%i]!" >nul 2>&1
          set "suc=!ErrorLevel!"
        )
      )
    )
    if !suc! EQU 0 (
      if exist "%tmpFile%" (
        move /Y "%tmpFile%" "!folder!/%stamp%.csv" >nul
      )
      echo Successful backup: !table[%%i]!
    ) else (
      set "err=1"
      echo Failed backup: !table[%%i]!
    )
  )
  if !err! EQU 1 (
    call :email
  )
) >> "%~dp0log.txt" 2>&1
exit

:email
  (
    echo Send-MailMessage -From "!pbi_email!" -To "!error_email!".Split^(";"^) -Subject "Database Backup Failure" -Body "This is an automated alert. Failed to backup tables in the PostgreSQL database See the log file for more details." -SmtpServer "smtp-mail.outlook.com" -Port 587 -UseSsl -Credential ^(New-Object PSCredential^("!pbi_email!", ^(ConvertTo-SecureString "!pbi_password!" -AsPlainText -Force^)^)^)
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