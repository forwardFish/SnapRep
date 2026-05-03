@echo off
echo ========================================
echo 清理并重启 SnapRep 项目
echo ========================================
echo.

echo [1/5] 正在停止所有 Node.js 进程...
taskkill /F /IM node.exe /T 2>nul
if %errorlevel% == 0 (
    echo ✓ Node.js 进程已停止
) else (
    echo ℹ 没有找到运行中的 Node.js 进程
)
echo.

echo [2/5] 正在停止所有 Flutter/SnapRep 进程...
taskkill /F /IM snaprep.exe /T 2>nul
taskkill /F /IM flutter.exe /T 2>nul
if %errorlevel% == 0 (
    echo ✓ Flutter 进程已停止
) else (
    echo ℹ 没有找到运行中的 Flutter 进程
)
echo.

echo [3/5] 等待进程完全释放资源...
timeout /t 3 /nobreak >nul
echo ✓ 资源已释放
echo.

echo [4/5] 正在启动后端服务器...
cd /d "%~dp0backend"
start "SnapRep Backend" cmd /k "npm run start:dev"
echo ✓ 后端服务器正在启动（新窗口）
echo ℹ 请等待看到 "Nest application successfully started" 消息
echo.

echo [5/5] 等待后端完全启动...
timeout /t 10 /nobreak >nul
echo.

echo [完成] 后端已启动，现在可以手动启动前端
echo.
echo 📋 下一步操作：
echo    1. 等待后端窗口显示 "Nest application successfully started"
echo    2. 检查后端日志中是否有 "Using Prisma Direct Connection" 字样
echo    3. 打开新的命令行窗口，执行以下命令启动前端：
echo       cd frontend
echo       flutter run -d windows
echo.
echo ========================================
pause
