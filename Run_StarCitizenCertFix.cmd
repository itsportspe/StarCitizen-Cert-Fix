@echo off
setlocal

REM -- Ensure admin (UAC) --
NET SESSION >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo Requesting administrative privileges...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

REM -- Run the PS1 sitting next to this CMD, regardless of current folder --
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0get_and_import_cig_cert.ps1"

echo.
echo (If something failed, check: "%~dp0StarCitizenCertFix.log")
echo Output files are written next to this script: cacert.crt, StarCitizenCertFix.log
echo.
pause