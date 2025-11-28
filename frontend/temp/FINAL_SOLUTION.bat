@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

echo =======================================
echo   Flutter 引擎文件手动下载解决方案
echo =======================================
echo.

REM Flutter引擎版本
set ENGINE_VERSION=1ac611c64eadbd93c5f5aba5494b8fc3b35ee952

echo 您的网络无法访问Google服务器，需要手动下载Flutter引擎文件。
echo.
echo 解决方案有以下几种：
echo.
echo ==========================================
echo   方案1：使用手机热点（最简单）
echo ==========================================
echo 1. 用手机开启热点
echo 2. 电脑连接手机热点
echo 3. 运行命令：cd frontend && flutter run -d PQY0220C26003745
echo.
echo 手机移动网络通常可以访问Google服务！
echo.
echo ==========================================
echo   方案2：使用VPN/代理
echo ==========================================
echo 1. 启动您的VPN或代理工具
echo 2. 确保代理正常工作
echo 3. 运行命令：cd frontend && flutter run -d PQY0220C26003745
echo.
echo ==========================================
echo   方案3：请朋友帮忙下载
echo ==========================================
echo 需要下载的文件：
echo.
echo 1. flutter_embedding_debug-%ENGINE_VERSION%.pom
echo 2. flutter_embedding_debug-%ENGINE_VERSION%.jar
echo 3. arm64_v8a_debug-%ENGINE_VERSION%.pom
echo 4. arm64_v8a_debug-%ENGINE_VERSION%.jar
echo.
echo 下载地址：
echo https://dl.google.com/dl/android/maven2/io/flutter/
echo.
echo 保存到目录：
echo %USERPROFILE%\.gradle\caches\modules-2\files-2.1\io.flutter\
echo.
echo ==========================================
echo   方案4：在公司/咖啡厅网络构建
echo ==========================================
echo 找一个可以访问国际网络的地方完成首次构建
echo 之后所有依赖都会被缓存，后续开发不再需要
echo.
pause

echo.
echo 是否要测试网络连接？(Y/N)
set /p test_network=

if /i "%test_network%"=="Y" (
    echo.
    echo 测试连接 Google...
    ping -n 1 dl.google.com

    if errorlevel 1 (
        echo [失败] 无法连接Google服务器
        echo 请使用手机热点或VPN
    ) else (
        echo [成功] 可以连接Google！
        echo.
        echo 正在启动Flutter构建...
        cd frontend
        flutter run -d PQY0220C26003745
    )
)

endlocal
