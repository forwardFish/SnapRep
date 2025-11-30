# Flutter/Gradle Build Progress Monitor
# UTF-8 encoding support

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Flutter/Gradle Build Monitor" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

while ($true) {
    Clear-Host
    $timestamp = Get-Date -Format "HH:mm:ss"

    Write-Host "[$timestamp] Checking build progress..." -ForegroundColor Yellow
    Write-Host ""

    # Check Java/Gradle processes
    Write-Host "=== Gradle/Java Process Status ===" -ForegroundColor Green
    $javaProcesses = Get-Process -Name java -ErrorAction SilentlyContinue
    if ($javaProcesses) {
        Write-Host "[OK] Gradle/Java process is running" -ForegroundColor Green
        $javaProcesses | Format-Table -Property Id, ProcessName, CPU, WS -AutoSize
    } else {
        Write-Host "[!] No Java process found" -ForegroundColor Red
    }

    Write-Host ""

    # Check Bundle output
    Write-Host "=== Bundle Output Directory ===" -ForegroundColor Green
    $bundlePath = "frontend\build\app\outputs\bundle\release"
    if (Test-Path $bundlePath) {
        Write-Host "[OK] Bundle output directory exists" -ForegroundColor Green
        Get-ChildItem $bundlePath -Filter *.aab -ErrorAction SilentlyContinue | ForEach-Object {
            $sizeMB = [math]::Round($_.Length / 1MB, 2)
            Write-Host "  Found: $($_.Name) [$sizeMB MB]" -ForegroundColor Cyan
        }
    } else {
        Write-Host "[PENDING] Bundle output directory not created yet" -ForegroundColor Yellow
    }

    Write-Host ""

    # Check APK output
    Write-Host "=== APK Output Directory ===" -ForegroundColor Green
    $apkPath = "frontend\build\app\outputs\apk\release"
    if (Test-Path $apkPath) {
        Write-Host "[OK] APK output directory exists" -ForegroundColor Green
        Get-ChildItem $apkPath -Filter *.apk -ErrorAction SilentlyContinue | ForEach-Object {
            $sizeMB = [math]::Round($_.Length / 1MB, 2)
            Write-Host "  Found: $($_.Name) [$sizeMB MB]" -ForegroundColor Cyan
        }
    } else {
        Write-Host "[PENDING] APK output directory not created yet" -ForegroundColor Yellow
    }

    Write-Host ""

    # Check build intermediates
    Write-Host "=== Build Status ===" -ForegroundColor Green
    $intermediatesPath = "frontend\build\app\intermediates"
    if (Test-Path $intermediatesPath) {
        Write-Host "[OK] Build intermediates directory exists" -ForegroundColor Green
        $folderCount = (Get-ChildItem $intermediatesPath -Directory -ErrorAction SilentlyContinue).Count
        Write-Host "  $folderCount intermediate folders created" -ForegroundColor Cyan
    } else {
        Write-Host "[PENDING] Build not started yet" -ForegroundColor Yellow
    }

    Write-Host ""

    # Check Gradle daemon
    Write-Host "=== Gradle Daemon Status ===" -ForegroundColor Green
    Push-Location "frontend\android"
    try {
        $gradleStatus = & .\gradlew.bat --status 2>&1 | Out-String
        if ($gradleStatus -match "IDLE|BUSY") {
            Write-Host $gradleStatus -ForegroundColor Cyan
        } else {
            Write-Host "No Gradle daemon running" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Could not check Gradle status" -ForegroundColor Yellow
    }
    Pop-Location

    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to exit, or wait 10 seconds to refresh" -ForegroundColor Gray
    Write-Host "================================================" -ForegroundColor Cyan

    Start-Sleep -Seconds 10
}
