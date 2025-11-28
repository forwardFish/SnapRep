@echo off
chcp 65001 > nul 2>&1
setlocal enabledelayedexpansion

echo =======================================
echo   Flutter 强制本地构建脚本
echo =======================================
echo.

cd /d "%~dp0frontend"

REM 检测设备
echo [1/4] 检测设备...
set DEVICE_ID=
for /f "tokens=*" %%a in ('flutter devices 2^>nul') do (
    echo %%a | findstr "PQY0220C26003745" > nul
    if !errorlevel! equ 0 (
        for /f "tokens=2 delims=()" %%x in ("%%a") do (
            set DEVICE_ID=%%x
        )
    )
)

if "!DEVICE_ID!"=="" (
    echo [错误] 未找到设备 PQY0220C26003745
    pause
    exit /b 1
)

echo [成功] 找到设备: !DEVICE_ID!

echo [2/4] 强制使用本地模式...
REM 禁用网络验证
set GRADLE_OPTS=-Dorg.gradle.daemon=false -Dorg.gradle.parallel=false -Dgradle.wrapperUser= -Dgradle.wrapperPassword=
set JAVA_OPTS=-Djava.net.useSystemProxies=false

echo [3/4] 清理并准备...
if exist "android\.gradle" rmdir /s /q "android\.gradle" 2>nul
if exist "build" rmdir /s /q "build" 2>nul

echo [4/4] 尝试离线构建...

REM 尝试方法1：强制离线模式
echo 尝试离线构建...
flutter build apk --debug --target-platform=android-arm64 > build_log.txt 2>&1

if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo [成功] APK构建完成！
    echo 正在安装到设备...

    adb -s !DEVICE_ID! install "build\app\outputs\flutter-apk\app-debug.apk"

    if !errorlevel! equ 0 (
        echo [成功] 应用已安装！
        echo 可以在手机上查看应用了。
        pause
        exit /b 0
    )
)

REM 尝试方法2：使用profile模式
echo 尝试profile模式构建...
flutter build apk --profile --target-platform=android-arm64 >> build_log.txt 2>&1

if exist "build\app\outputs\flutter-apk\app-profile.apk" (
    echo [成功] Profile APK构建完成！
    adb -s !DEVICE_ID! install "build\app\outputs\flutter-apk\app-profile.apk"
    echo 应用已安装！
    pause
    exit /b 0
)

echo [失败] 无法完成离线构建
echo.
echo 构建日志已保存到 build_log.txt
echo.
echo ===== 最终建议 =====
echo 1. 使用手机热点网络
echo 2. 使用VPN/代理
echo 3. 在有外网的地方完成首次构建
echo 4. 请朋友帮忙构建APK文件
echo.
type build_log.txt
pause

endlocal