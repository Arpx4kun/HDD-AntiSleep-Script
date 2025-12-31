@echo off
title HDD Anti-Sleep Tool
cls

:: 初始化写入计数器
set writeCount=0

echo ===============================
echo      HDD Anti-Sleep Tool
echo ===============================
echo.

echo Getting disk information...
echo.

:: 使用PowerShell获取详细的磁盘信息，包括物理设备名
powershell -Command ^
"try { ^
    $logicalDisks = Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType=3'; ^
    if ($logicalDisks) { ^
        Write-Host 'Available drives (with physical device info):' -ForegroundColor Cyan; ^
        Write-Host '----------------------------------------------------------'; ^
        Write-Host ''; ^
        ^
        foreach ($logicalDisk in $logicalDisks) { ^
            $sizeGB = [math]::Round($logicalDisk.Size / 1GB, 1); ^
            $freeGB = [math]::Round($logicalDisk.FreeSpace / 1GB, 1); ^
            $usedGB = [math]::Round(($logicalDisk.Size - $logicalDisk.FreeSpace) / 1GB, 1); ^
            $percent = 0; ^
            if ($logicalDisk.Size -gt 0) { ^
                $percent = [math]::Round((($logicalDisk.Size - $logicalDisk.FreeSpace) / $logicalDisk.Size) * 100, 1); ^
            } ^
            ^
            if ([string]::IsNullOrEmpty($logicalDisk.VolumeName)) { ^
                $label = 'No Label'; ^
            } else { ^
                $label = $logicalDisk.VolumeName; ^
            } ^
            ^
            $physicalInfo = ''; ^
            try { ^
                $diskPart = Get-WmiObject -Query (\"ASSOCIATORS OF {Win32_LogicalDisk.DeviceID='\" + $logicalDisk.DeviceID + \"'} WHERE ResultClass=Win32_DiskPartition\"); ^
                if ($diskPart) { ^
                    $diskDrive = Get-WmiObject -Query (\"ASSOCIATORS OF {Win32_DiskPartition.DeviceID='\" + $diskPart.DeviceID + \"'} WHERE ResultClass=Win32_DiskDrive\"); ^
                    if ($diskDrive) { ^
                        $driveSize = [math]::Round($diskDrive.Size / 1GB, 1); ^
                        $physicalInfo = ' (Physical Device: ' + $diskDrive.Model.Trim() + ' - ' + $driveSize + ' GB)'; ^
                    } else { ^
                        $physicalInfo = ' (Physical Device: Unknown)'; ^
                    } ^
                } else { ^
                    $physicalInfo = ' (Physical Device: N/A)'; ^
                } ^
            } catch { ^
                $physicalInfo = ' (Physical Device: Error)'; ^
            } ^
            ^
            Write-Host ('Drive: ' + $logicalDisk.DeviceID + '  Label: ' + $label + $physicalInfo); ^
            Write-Host ('       Size: ' + $sizeGB + ' GB  Used: ' + $usedGB + ' GB  Free: ' + $freeGB + ' GB  Usage: ' + $percent + '%%'); ^
            Write-Host ''; ^
        } ^
    } else { ^
        Write-Host 'No fixed disks found!' -ForegroundColor Red; ^
    } ^
} catch { ^
    Write-Host ('Error getting disk information: ' + $_.Exception.Message) -ForegroundColor Red; ^
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
        ^
        if ([string]::IsNullOrEmpty($disk.VolumeName)) { ^
            $label = 'No Label'; ^
        } else { ^
            $label = $disk.VolumeName; ^
        } ^
        ^
        $physicalInfo = ''; ^
        try { ^
            $diskPart = Get-WmiObject -Query (\"ASSOCIATORS OF {Win32_LogicalDisk.DeviceID='\" + $disk.DeviceID + \"'} WHERE ResultClass=Win32_DiskPartition\"); ^
            if ($diskPart) { ^
                $diskDrive = Get-WmiObject -Query (\"ASSOCIATORS OF {Win32_DiskPartition.DeviceID='\" + $diskPart.DeviceID + \"'} WHERE ResultClass=Win32_DiskDrive\"); ^
                if ($diskDrive) { ^
                    $driveSize = [math]::Round($diskDrive.Size / 1GB, 1); ^
                    $physicalInfo = 'Physical device: ' + $diskDrive.Model.Trim() + ' (' + $driveSize + ' GB)'; ^
                } else { ^
                    $physicalInfo = 'Physical device: Unknown'; ^
                } ^
            } else { ^
                $physicalInfo = 'Physical device: N/A'; ^
            } ^
        } catch { ^
            $physicalInfo = 'Physical device: Error retrieving info'; ^
        } ^
        ^
        Write-Host ('================================'); ^
        Write-Host ('Selected drive: ' + $disk.DeviceID + '  Label: ' + $label); ^
        Write-Host ($physicalInfo); ^
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

:: 增加写入计数器
set /a writeCount+=1

:: 显示运行时间和写入次数
set /a timeCount+=1
set /a minutes=timeCount/2

if %minutes% equ 1 (
    echo Running for 1 minute, drive: %driveLetter%:\ - File writes: %writeCount%
) else (
    echo Running for %minutes% minutes, drive: %driveLetter%:\ - File writes: %writeCount%
)

:: 等待30秒
timeout /t 30 /nobreak >nul

goto start