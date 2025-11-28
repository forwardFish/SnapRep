@echo off
chcp 65001 > nul 2>&1
setlocal enabledelayedexpansion

echo =======================================
echo   Flutter 快速运行脚本
echo =======================================
echo.



REM 检测设备
echo [检测设备...]
for /f "tokens=*" %%a in ('flutter devices ^| findstr /v "Chrome" ^| findstr /v "Windows" ^| findstr /v "Connected" ^| findstr /v "devices found"') do (
    for /f "tokens=2 delims=()" %%x in ("%%a") do (
        if not "%%x"=="" (
            set DEVICE_ID=%%x
            goto :found_device
        )
    )
)

echo [错误] 未找到设备，请连接手机并开启USB调试
pause
exit /b 1

:found_device
echo [成功] 找到设备: !DEVICE_ID!
echo.

REM 快速启动
echo [启动应用...]
flutter run -d !DEVICE_ID! --no-pub --no-build-ios

endlocal
