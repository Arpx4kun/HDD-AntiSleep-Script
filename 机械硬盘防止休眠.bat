@echo off  

:: set /A timeCount=0

:start

::  echo This batch program has been running since %timeCount% minutes ago.
echo This batch program is used to prevent mechanical hard disk drive sleep.

echo This temporary file is used to prevent mechanical hard disk drive sleep, it will disappear and reappear periodically. >D:\hddAntiSleepTemp.txt
del D:\hddAntiSleepTemp.txt

timeout /t 30 /nobreak

::  set /a timeCount= %timeCount% + 0.5
::在批处理中变量自增没法打印出来。。。

goto start  

