@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Flutter 快速启动脚本
echo ========================================
echo.

REM 检测设备
echo [1/3] 正在检测连接的设备...
flutter devices > devices.txt 2>&1

REM 读取设备列表，找到第一个真实设备（非chrome/windows）
set DEVICE_ID=
for /f "tokens=1,2,3,4,5* delims= " %%a in ('flutter devices ^| findstr /v "Chrome" ^| findstr /v "Windows" ^| findstr /v "Connected" ^| findstr /v "devices found" ^| findstr /v "chrome" ^| findstr /v "No devices"') do (
    if "!DEVICE_ID!"=="" (
        set TEMP_LINE=%%a %%b %%c %%d %%e
        REM 提取设备ID（通常是括号中的内容或第二列）
        for /f "tokens=2 delims=()" %%x in ("!TEMP_LINE!") do (
            set DEVICE_ID=%%x
        )
    )
)

if "!DEVICE_ID!"=="" (
    echo [错误] 未检测到连接的设备！
    echo 请确保：
    echo   1. 手机已通过USB连接到电脑
    echo   2. 手机已开启USB调试
    echo   3. 手机已授权此电脑进行调试
    echo.
    pause
    exit /b 1
)

echo [成功] 检测到设备: !DEVICE_ID!
echo.

echo [2/3] 正在清理缓存...
REM 只在必要时清理
if exist "build\" (
    echo 清理 Flutter 构建缓存...
    flutter clean > nul 2>&1
)

echo.
echo [3/3] 正在启动应用到设备 !DEVICE_ID!...
echo 提示：首次运行可能需要3-5分钟下载依赖...
echo.

REM 运行 Flutter 应用
flutter run -d !DEVICE_ID!

if errorlevel 1 (
    echo.
    echo [错误] 应用启动失败！
    echo 常见解决方案：
    echo   1. 检查网络连接
    echo   2. 重新连接设备并授权调试
    echo   3. 运行 flutter doctor 检查环境
    echo.
    pause
    exit /b 1
)

endlocal
