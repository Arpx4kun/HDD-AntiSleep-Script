@echo off
title HDD Anti-Sleep Tool
cls

echo ===============================
echo      HDD Anti-Sleep Tool
echo ===============================
echo.

echo Getting disk information...
echo.

:: 使用PowerShell获取详细的磁盘信息
powershell -Command ^
"try { ^
    $disks = Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType=3'; ^
    if ($disks) { ^
        Write-Host 'Available drives:' -ForegroundColor Cyan; ^
        Write-Host '----------------------'; ^
        foreach ($disk in $disks) { ^
            $sizeGB = [math]::Round($disk.Size / 1GB, 1); ^
            $freeGB = [math]::Round($disk.FreeSpace / 1GB, 1); ^
            $usedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 1); ^
            $percent = 0; ^
            if ($disk.Size -gt 0) { ^
                $percent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1); ^
            } ^
            $label = if ([string]::IsNullOrEmpty($disk.VolumeName)) { 'No Label' } else { $disk.VolumeName }; ^
            Write-Host ('Drive: ' + $disk.DeviceID + '  Label: ' + $label); ^
            Write-Host ('       Size: ' + $sizeGB + ' GB  Used: ' + $usedGB + ' GB  Free: ' + $freeGB + ' GB  Usage: ' + $percent + '%%'); ^
            Write-Host ''; ^
        } ^
    } else { ^
        Write-Host 'No fixed disks found!' -ForegroundColor Red; ^
    } ^
} catch { ^
    Write-Host 'Error getting disk information: ' + $_.Exception.Message -ForegroundColor Red; ^
}"

echo ----------------------
echo.

:getDrive
set /p driveLetter=Enter drive letter to monitor (e.g. D): 
if not defined driveLetter goto getDrive

:: 清理输入
set "driveLetter=%driveLetter::=%"
set "driveLetter=%driveLetter: =%"
set "driveLetter=%driveLetter:~0,1%"

:: 转换为大写
for %%i in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if /i "%%i"=="%driveLetter%" set "driveLetter=%%i"
)

:: 验证驱动器存在
if not exist %driveLetter%:\ (
    echo ERROR: Drive %driveLetter%:\ does not exist!
    goto getDrive
)

:: 显示选中驱动器的详细信息
powershell -Command ^
"try { ^
    $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter \"DeviceID='%driveLetter%:'\"; ^
    if ($disk) { ^
        $sizeGB = [math]::Round($disk.Size / 1GB, 1); ^
        $freeGB = [math]::Round($disk.FreeSpace / 1GB, 1); ^
        $usedGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 1); ^
        $percent = 0; ^
        if ($disk.Size -gt 0) { ^
            $percent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1); ^
        } ^
        $label = if ([string]::IsNullOrEmpty($disk.VolumeName)) { 'No Label' } else { $disk.VolumeName }; ^
        Write-Host ('================================'); ^
        Write-Host ('Selected drive: ' + $disk.DeviceID + '  Label: ' + $label); ^
        Write-Host ('Total size: ' + $sizeGB + ' GB'); ^
        Write-Host ('Used: ' + $usedGB + ' GB  (' + $percent + '%%)'); ^
        Write-Host ('Free: ' + $freeGB + ' GB'); ^
        Write-Host ('File system: ' + $disk.FileSystem); ^
        Write-Host ('================================'); ^
    } else { ^
        Write-Host 'ERROR: Could not get drive information'; ^
    } ^
} catch { ^
    Write-Host 'Error getting drive information'; ^
}"

echo.
echo Monitoring drive %driveLetter%:\ ...
echo Press Ctrl+C to stop
echo.

set timeCount=0

:start
:: 创建和删除临时文件防止硬盘休眠
echo Anti-sleep temporary file >%driveLetter%:\hddAntiSleepTemp.txt
del %driveLetter%:\hddAntiSleepTemp.txt >nul 2>&1

:: 显示运行时间
set /a timeCount+=1
set /a minutes=timeCount/2

if %minutes% equ 1 (
    echo Running for 1 minute, drive: %driveLetter%:\
) else (
    echo Running for %minutes% minutes, drive: %driveLetter%:\
)

:: 等待30秒
timeout /t 30 /nobreak >nul

goto start