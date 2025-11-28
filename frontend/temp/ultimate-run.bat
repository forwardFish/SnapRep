@echo off
chcp 65001 > nul 2>&1
setlocal enabledelayedexpansion

echo =======================================
echo   Flutter 终极快速启动脚本
echo =======================================
echo.

cd /d "%~dp0frontend"

REM 检测设备
echo [1/4] 检测连接的设备...
set DEVICE_ID=
for /f "tokens=*" %%a in ('flutter devices 2^>nul ^| findstr /v "Chrome" ^| findstr /v "Windows" ^| findstr /v "Connected" ^| findstr /v "devices found"') do (
    for /f "tokens=2 delims=()" %%x in ("%%a") do (
        if not "%%x"=="" (
            set DEVICE_ID=%%x
            goto :found_device
        )
    )
)

echo [错误] 未找到设备
echo 请确保：
echo - 手机已连接并开启USB调试
echo - 已授权该电脑进行调试
pause
exit /b 1

:found_device
echo [成功] 找到设备: !DEVICE_ID!

echo [2/4] 设置环境变量（绕过网络问题）...
set GRADLE_OPTS=-Dorg.gradle.daemon=false -Dorg.gradle.parallel=false
set JAVA_OPTS=-Djava.net.useSystemProxies=true

echo [3/4] 清理过期缓存...
if exist "android\.gradle" rmdir /s /q "android\.gradle" 2>nul
if exist "build" rmdir /s /q "build" 2>nul

echo [4/4] 启动应用...
echo 注意：首次运行可能需要5-10分钟，请耐心等待
echo.

flutter run -d !DEVICE_ID! --verbose

if errorlevel 1 (
    echo.
    echo ==========================================
    echo   构建失败，尝试备用方案
    echo ==========================================
    echo.
    echo 正在尝试使用简化构建...
    flutter run -d !DEVICE_ID! --debug --no-sound-null-safety
)

endlocal