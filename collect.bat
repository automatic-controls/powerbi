@echo off
title Dependency Collector
call "%~dp0env_vars.bat"
setlocal EnableDelayedExpansion
echo.
if not exist "%lib%" mkdir "%lib%"
call :collect "%~dp0DEPENDENCIES" "%lib%"
if %ERRORLEVEL% EQU 0 (
  echo.
  echo Collection successful.
) else (
  echo.
  echo Collection unsuccessful.
)
echo Press any key to exit.
pause >nul
exit

:: Collect dependencies from the WebCTRL installation or from external websites
:: Parameters: <dependency-file> <output-folder>
:collect
  setlocal
    set "err=0"
    for /F "usebackq tokens=* delims=" %%i in ("%~f1") do (
      if exist "%~f2\%%~nxi" (
        echo Checked: %%~ni
      ) else (
        curl --location --fail --silent --output-dir "%~f2" --remote-name %%i
        if !ErrorLevel! EQU 0 (
          echo Collected: %%~ni
        ) else (
          set "err=1"
          echo Failed to collect: %%~ni
        )
      )
    )
  endlocal & exit /b %err%