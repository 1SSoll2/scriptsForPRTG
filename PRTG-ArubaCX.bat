@echo off
PowerShell -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\PRTG-ArubaCX_210.ps1"
exit /b %errorlevel%
pause