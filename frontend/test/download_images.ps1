# PowerShell script to download all required images
# 下载所有需要的图片资源

# 设置目标目录
$targetDir = "frontend\assets\images"

# 确保目录存在
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force
}

Write-Host "开始下载图片..." -ForegroundColor Green

# 定义图片URL和文件名的映射
$images = @{
    "gym_workout.jpg" = "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80"
    "outdoor_workout.jpg" = "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80"
    "home_workout.jpg" = "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80"
    "office_workout.jpg" = "https://images.unsplash.com/photo-1497366216548-37526070297c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80"
    "hotel_workout.jpg" = "https://images.unsplash.com/photo-1488646953014-85cb44e25828?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80"
    "water_bottle_workout.jpg" = "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80"
    "chair_workout.jpg" = "https://images.unsplash.com/photo-1588286840104-8957b019727f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80"
    "backpack_workout.jpg" = "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80"
    "workout_mat.jpg" = "https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80"
    "challenge_header_bg.jpg" = "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80"
}

$successCount = 0
$failCount = 0

foreach ($filename in $images.Keys) {
    $url = $images[$filename]
    $outputPath = Join-Path $targetDir $filename

    Write-Host "正在下载: $filename" -ForegroundColor Cyan

    try {
        # 使用 Invoke-WebRequest 下载图片
        Invoke-WebRequest -Uri $url -OutFile $outputPath -UseBasicParsing

        if (Test-Path $outputPath) {
            $fileSize = (Get-Item $outputPath).Length / 1KB
            Write-Host "  ✓ 成功: $filename (${fileSize} KB)" -ForegroundColor Green
            $successCount++
        }
    }
    catch {
        Write-Host "  ✗ 失败: $filename" -ForegroundColor Red
        Write-Host "    错误: $($_.Exception.Message)" -ForegroundColor Yellow
        $failCount++
    }
}

Write-Host "`n下载完成!" -ForegroundColor Green
Write-Host "成功: $successCount 个文件" -ForegroundColor Green
Write-Host "失败: $failCount 个文件" -ForegroundColor Red

if ($failCount -gt 0) {
    Write-Host "`n注意: 如果下载失败,可能是网络问题或需要代理。" -ForegroundColor Yellow
    Write-Host "你可以手动从 Unsplash 网站下载失败的图片。" -ForegroundColor Yellow
}

Write-Host "`n按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
