@echo off
chcp 65001 >nul
echo ================================================
echo Clean Build Script for Flutter App Bundle
echo ================================================
echo.

echo [Step 1] Stopping all Gradle daemons...
cd frontend\android
call gradlew.bat --stop
cd ..\..

echo.
echo [Step 2] Killing any remaining Java processes...
powershell -Command "Get-Process -Name java -ErrorAction SilentlyContinue | Stop-Process -Force"
timeout /t 2 /nobreak >nul

echo.
echo [Step 3] Starting fresh build...
cd frontend
flutter build appbundle --release --target-platform android-arm64

echo.
echo ================================================
echo Build completed!
echo Check: frontend\build\app\outputs\bundle\release\
echo ================================================
pause
