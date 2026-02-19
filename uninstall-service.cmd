@echo off
setlocal EnableExtensions

rem Uninstall Qdrant Windows service created by install-service.cmd (uses NSSM).
rem Run this script from an elevated (Administrator) terminal.
rem
rem Usage:
rem   uninstall-service.cmd [serviceName]
rem
rem Example:
rem   uninstall-service.cmd

set "SERVICE_NAME=qdrant"
if not "%~1"=="" set "SERVICE_NAME=%~1"

net session >nul 2>&1
if errorlevel 1 (
  echo ERROR: Please run in an elevated ^(Administrator^) terminal.
  exit /b 1
)

where nssm >nul 2>&1
if errorlevel 1 (
  echo ERROR: NSSM not found in PATH.
  exit /b 1
)

echo Stopping service "%SERVICE_NAME%"...
nssm stop "%SERVICE_NAME%" >nul 2>&1

echo Removing service "%SERVICE_NAME%"...
nssm remove "%SERVICE_NAME%" confirm

echo Done.
exit /b 0

