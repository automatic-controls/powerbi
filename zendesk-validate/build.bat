
@echo off
title Java Build Script
call "%~dp0../env_vars.bat"
echo.

:: To download dependencies in pom.xml
::mvn dependency:copy-dependencies

:: Main class name
set "mainClass=Main.java"
:: Source code
set "src=%~dp0src"
if not exist "%src%" mkdir "%src%"
:: Compiled classes
set "classes=%~dp0classes"
if not exist "%classes%" mkdir "%classes%"
:: Jar file
call :getFolder "name" "%~dp0."
set "jar=%~dp0%name%.jar"

:: Compilation
echo Compiling...
rmdir /Q /S "%classes%" >nul 2>nul
javac -d "%classes%" -cp "%src%;%~dp0lib\*;%lib%\*" "%src%\%mainClass%"
if %ERRORLEVEL% NEQ 0 (
  rmdir /Q /S "%classes%" >nul 2>nul
  goto :err
)

:: Packing
echo Packing...
jar -c -M -f "%jar%" -C "%classes%" .
if %ERRORLEVEL% NEQ 0 (
  rmdir /Q /S "%classes%" >nul 2>nul
  goto :err
)
rmdir /Q /S "%classes%" >nul 2>nul
exit

:: Gets the last named element of a path
:getFolder
  set "%~1=%~n2"
exit /b

:: Resolves relative paths to fully qualified path names.
:normalizePath
  set "%~1=%~f2"
exit /b

:err
  echo.
  echo Press any key to exit.
  pause >nul
exit