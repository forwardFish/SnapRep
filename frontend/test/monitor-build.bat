@echo off
chcp 65001 >nul
REM Build Monitor for Flutter/Gradle
echo ================================================
echo Flutter/Gradle Build Monitor
echo ================================================
echo.

:LOOP
cls
echo [%TIME%] Checking build progress...
echo.
echo === Gradle/Java Process Status ===
tasklist /FI "IMAGENAME eq java.exe" /FO TABLE 2>NUL | findstr /C:"java.exe" >NUL
if %ERRORLEVEL%==0 (
    echo [OK] Gradle/Java process is running
    tasklist /FI "IMAGENAME eq java.exe" /FO TABLE | findstr /C:"java.exe"
) else (
    echo [!] No Java process found
)

echo.
echo === Bundle Output Directory ===
if exist "frontend\build\app\outputs\bundle\release\" (
    echo [OK] Bundle output directory exists
    dir /B "frontend\build\app\outputs\bundle\release\" 2>NUL
    if exist "frontend\build\app\outputs\bundle\release\*.aab" (
        for %%F in (frontend\build\app\outputs\bundle\release\*.aab) do echo   Found: %%~nxF [%%~zF bytes]
    )
) else (
    echo [PENDING] Bundle output directory not created yet
)

echo.
echo === APK Output Directory ===
if exist "frontend\build\app\outputs\apk\release\" (
    echo [OK] APK output directory exists
    dir /B "frontend\build\app\outputs\apk\release\" 2>NUL
    if exist "frontend\build\app\outputs\apk\release\*.apk" (
        for %%F in (frontend\build\app\outputs\apk\release\*.apk) do echo   Found: %%~nxF [%%~zF bytes]
    )
) else (
    echo [PENDING] APK output directory not created yet
)

echo.
echo === Build Status ===
if exist "frontend\build\app\intermediates\" (
    echo [OK] Build intermediates directory exists
) else (
    echo [PENDING] Build not started yet
)

echo.
echo === Gradle Daemon Status ===
cd frontend\android >nul 2>&1
gradlew.bat --status 2>NUL
cd ..\.. >nul 2>&1

echo.
echo ================================================
echo Press Ctrl+C to exit, or wait 10 seconds to refresh
timeout /t 10 /nobreak > NUL
goto LOOP
