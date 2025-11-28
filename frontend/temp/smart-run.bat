@echo off
chcp 65001 > nul 2>&1
setlocal enabledelayedexpansion

echo ========================================
echo    Flutter 智能启动脚本
echo ========================================
echo.



REM 检测网络连接
echo [1/5] 正在检测网络环境...
ping -n 1 maven.aliyun.com > nul 2>&1
if errorlevel 1 (
    echo [警告] 网络连接可能有问题，但会继续尝试...
) else (
    echo [成功] 网络连接正常
)

REM 检测设备
echo [2/5] 正在检测连接的设备...
flutter devices > temp_devices.txt 2>&1

REM 解析设备列表
set DEVICE_COUNT=0
set DEVICE_ID=
for /f "tokens=*" %%a in (temp_devices.txt) do (
    set LINE=%%a
    REM 跳过标题行和无关行
    echo !LINE! | findstr /c:"Connected device" > nul && goto :continue
    echo !LINE! | findstr /c:"No devices" > nul && goto :continue
    echo !LINE! | findstr /c:"devices found" > nul && goto :continue
    echo !LINE! | findstr /c:"Run" > nul && goto :continue
    echo !LINE! | findstr /c:"Chrome" > nul && goto :continue
    echo !LINE! | findstr /c:"Windows" > nul && goto :continue
    echo !LINE! | findstr /c:"^$" > nul && goto :continue

    REM 提取设备ID（在括号中）
    for /f "tokens=2 delims=()" %%x in ("!LINE!") do (
        if "%%x" neq "" (
            set DEVICE_ID=%%x
            set /a DEVICE_COUNT+=1
            echo 找到设备: !LINE!
        )
    )
    :continue
)

del temp_devices.txt 2> nul

if !DEVICE_COUNT! equ 0 (
    echo [错误] 未检测到连接的设备！
    echo 请按照以下步骤操作：
    echo   1. 通过USB连接手机到电脑
    echo   2. 在手机上开启"开发者选项"
    echo   3. 开启"USB调试"
    echo   4. 当电脑弹出授权提示时，点击"确定"
    echo.
    echo 然后重新运行此脚本
    pause
    exit /b 1
)

if !DEVICE_COUNT! gtr 1 (
    echo [提示] 检测到多个设备，将使用第一个设备
)

echo [成功] 将使用设备: !DEVICE_ID!
echo.

echo [3/5] 正在检查是否需要清理缓存...
set NEED_CLEAN=0
if exist "android\.gradle" set NEED_CLEAN=1
if exist "build\app" (
    REM 检查上次构建是否超过1天
    forfiles /p build\app /m *.* /d -1 > nul 2>&1
    if errorlevel 1 set NEED_CLEAN=1
)

if !NEED_CLEAN! equ 1 (
    echo 正在清理过时的构建文件...
    flutter clean > nul 2>&1
    if exist "android\.gradle" rmdir /s /q "android\.gradle" 2> nul
    echo 清理完成
) else (
    echo 无需清理，使用现有缓存
)

echo.
echo [4/5] 正在获取依赖...
flutter pub get > nul 2>&1
echo 依赖获取完成

echo.
echo [5/5] 正在启动应用到设备 !DEVICE_ID!...
echo.
echo ================== 构建日志 ==================

REM 设置更详细的输出
set FLUTTER_LOG=true

REM 开始构建和运行
flutter run -d !DEVICE_ID! --verbose

if errorlevel 1 (
    echo.
    echo ================== 错误处理 ==================
    echo [错误] 应用启动失败！
    echo.
    echo 建议解决方案：
    echo   1. 检查手机是否仍然连接并已授权
    echo   2. 尝试重新连接USB线
    echo   3. 运行 'flutter doctor' 检查开发环境
    echo   4. 如果是网络问题，请检查代理设置
    echo.

    echo 正在运行环境检查...
    flutter doctor

    pause
    exit /b 1
)

echo.
echo ================== 启动成功 ==================
echo 应用已成功部署到设备！
echo 你现在可以在手机上看到应用正在运行
echo 按 Ctrl+C 可以停止应用

endlocal