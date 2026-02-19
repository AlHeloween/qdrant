@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Install Qdrant as a Windows service using NSSM.
rem Run this script from an elevated Administrator terminal.
rem
rem Usage:
rem   install-service.cmd [serviceName] [release|debug] [qdrant args...]
rem
rem Examples:
rem   install-service.cmd
rem   install-service.cmd qdrant release --disable-telemetry
rem   install-service.cmd qdrant release --config-path config\config.yaml --disable-telemetry

for %%I in ("%~dp0.") do set "ROOT=%%~fI"
pushd "%ROOT%" >nul

set "SERVICE_NAME=qdrant"
set "PROFILE=release"

if "%~1"=="" goto :after_name
set "SERVICE_NAME=%~1"
shift
:after_name

if /I "%~1"=="debug" goto :set_debug
if /I "%~1"=="release" goto :set_release
goto :after_profile
:set_debug
set "PROFILE=debug"
shift
goto :after_profile
:set_release
set "PROFILE=release"
shift
:after_profile

rem Default args: disable telemetry; rely on config/config + RUN_MODE + config/local by default.
set "PARAMS=--disable-telemetry"
if "%~1"=="" goto :params_done
set "PARAMS="
:params_loop
if "%~1"=="" goto :params_done
set "PARAMS=%PARAMS% %1"
shift
goto :params_loop
:params_done

rem Require admin for service install.
net session >nul 2>&1
if errorlevel 1 goto :not_admin

where nssm >nul 2>&1
if errorlevel 1 goto :no_nssm

where cargo >nul 2>&1
if errorlevel 1 goto :no_cargo

echo Building Qdrant (%PROFILE%)...
if /I "%PROFILE%"=="release" goto :do_build_release
cargo build
goto :build_done
:do_build_release
cargo build --release
:build_done
if errorlevel 1 goto :build_failed

if /I "%PROFILE%"=="release" goto :bin_release
set "BIN=%ROOT%\\target\\debug\\qdrant.exe"
set "BIN_REL=target\\debug\\qdrant.exe"
goto :bin_done
:bin_release
set "BIN=%ROOT%\\target\\release\\qdrant.exe"
set "BIN_REL=target\\release\\qdrant.exe"
:bin_done

if not exist "%BIN%" goto :bin_missing

if not exist "%ROOT%\\logs" mkdir "%ROOT%\\logs" >nul 2>&1

echo Installing service "%SERVICE_NAME%"...
rem Remove an existing service with the same name (if any) to keep this idempotent.
nssm stop "%SERVICE_NAME%" >nul 2>&1
nssm remove "%SERVICE_NAME%" confirm >nul 2>&1

nssm install "%SERVICE_NAME%" "%BIN%"
if errorlevel 1 goto :nssm_install_failed

nssm set "%SERVICE_NAME%" AppDirectory "%ROOT%"
nssm set "%SERVICE_NAME%" AppParameters %PARAMS%
nssm set "%SERVICE_NAME%" Start SERVICE_AUTO_START

rem Capture stdout/stderr to files (rotated by NSSM).
nssm set "%SERVICE_NAME%" AppStdout "%ROOT%\\logs\\%SERVICE_NAME%.stdout.log"
nssm set "%SERVICE_NAME%" AppStderr "%ROOT%\\logs\\%SERVICE_NAME%.stderr.log"
nssm set "%SERVICE_NAME%" AppRotateFiles 1
nssm set "%SERVICE_NAME%" AppRotateOnline 1
nssm set "%SERVICE_NAME%" AppRotateSeconds 86400
nssm set "%SERVICE_NAME%" AppRotateBytes 10485760

echo Starting service...
nssm start "%SERVICE_NAME%"
if errorlevel 1 goto :start_failed

echo Done.
echo - Service: %SERVICE_NAME%
echo - Binary:  %BIN_REL%
echo - Args:    %PARAMS%
echo - Logs:    logs\\%SERVICE_NAME%.stdout.log and logs\\%SERVICE_NAME%.stderr.log

popd >nul
exit /b 0

:not_admin
echo ERROR: Please run in an elevated Administrator terminal.
popd >nul
exit /b 1

:no_nssm
echo ERROR: NSSM not found in PATH.
echo Install NSSM and ensure nssm.exe is in PATH, then re-run this script.
popd >nul
exit /b 1

:no_cargo
echo ERROR: Rust/Cargo not found in PATH.
echo Install Rust from https://rustup.rs/ and reopen your terminal.
popd >nul
exit /b 1

:build_failed
echo ERROR: Build failed.
popd >nul
exit /b 1

:bin_missing
echo ERROR: Built binary not found: %BIN_REL%
popd >nul
exit /b 1

:nssm_install_failed
echo ERROR: NSSM install failed.
popd >nul
exit /b 1

:start_failed
echo ERROR: Service failed to start. Check logs in logs\\
popd >nul
exit /b 1
