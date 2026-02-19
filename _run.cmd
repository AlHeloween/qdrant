@echo off
setlocal EnableExtensions

rem Convenience wrapper for running local Qdrant with telemetry disabled.
rem You can pass extra Qdrant args and they will be forwarded.

call "%~dp0run-qdrant.cmd" release --disable-telemetry %*
exit /b %ERRORLEVEL%
