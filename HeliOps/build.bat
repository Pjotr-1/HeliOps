@echo off
setlocal
cd /d "%~dp0"

dotnet restore
if errorlevel 1 exit /b 1

dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:PublishTrimmed=false
if errorlevel 1 exit /b 1

echo.
echo Build complete:
echo %CD%\bin\Release\net8.0\win-x64\publish\HeliOpsBridge.exe
pause
