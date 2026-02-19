@echo off
setlocal EnableExtensions

rem Build and run Qdrant locally (Windows).
rem Usage:
rem   run-qdrant.cmd [release|debug] [configPathOrName] [qdrant args...]
rem Examples:
rem   run-qdrant.cmd
rem   run-qdrant.cmd debug
rem   run-qdrant.cmd release development.yaml
rem   run-qdrant.cmd release config\config.yaml --disable-telemetry

if /I "%~1"=="-h"  goto :help
if /I "%~1"=="--help" goto :help
if /I "%~1"=="/?"  goto :help
if /I "%~1"=="help" goto :help

set "ROOT=%~dp0"
pushd "%ROOT%" >nul

set "PROFILE=release"
set "CONFIG=config\config.yaml"
set "CONFIG_SPECIFIED=0"

if /I "%~1"=="debug" (
  set "PROFILE=debug"
  shift
) else if /I "%~1"=="release" (
  set "PROFILE=release"
  shift
)

if not "%~1"=="" (
  if exist "%~1" (
    set "CONFIG=%~1"
    set "CONFIG_SPECIFIED=1"
    shift
  ) else if exist "config\%~1" (
    set "CONFIG=config\%~1"
    set "CONFIG_SPECIFIED=1"
    shift
  )
)

set "FORWARD_ARGS="
:collect_args
if "%~1"=="" goto :args_done
set "FORWARD_ARGS=%FORWARD_ARGS% %1"
shift
goto :collect_args
:args_done

where cargo >nul 2>&1
if errorlevel 1 (
  echo ERROR: Rust/Cargo not found in PATH.
  echo Install Rust from https://rustup.rs/ and reopen your terminal.
  popd >nul
  exit /b 1
)

echo Building Qdrant (%PROFILE%)...
if /I "%PROFILE%"=="release" (
  cargo build --release
) else (
  cargo build
)
if errorlevel 1 (
  echo ERROR: Build failed.
  popd >nul
  exit /b 1
)

if /I "%PROFILE%"=="release" (
  set "BIN=target\release\qdrant.exe"
) else (
  set "BIN=target\debug\qdrant.exe"
)

if not exist "%BIN%" (
  echo ERROR: Built binary not found: %BIN%
  popd >nul
  exit /b 1
)

echo Starting Qdrant...
echo   binary: %BIN%
if /I "%CONFIG_SPECIFIED%"=="1" (
  echo   config: %CONFIG%
) else (
  echo   config: (default config/config + RUN_MODE + local)
)
echo.

if /I "%CONFIG_SPECIFIED%"=="1" (
  "%BIN%" --config-path "%CONFIG%" %FORWARD_ARGS%
) else (
  "%BIN%" %FORWARD_ARGS%
)
set "EXITCODE=%ERRORLEVEL%"
popd >nul
exit /b %EXITCODE%

:help
echo Build and run Qdrant locally (Windows).
echo.
echo Usage:
echo   run-qdrant.cmd [release^|debug] [configPathOrName] [qdrant args...]
echo.
echo Defaults:
echo   profile: release
echo   config:  config\config.yaml
echo.
echo Examples:
echo   run-qdrant.cmd
echo   run-qdrant.cmd debug
echo   run-qdrant.cmd release development.yaml
echo   run-qdrant.cmd release config\config.yaml --disable-telemetry
exit /b 0
