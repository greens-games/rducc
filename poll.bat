@echo off
setlocal enabledelayedexpansion

:: Specify the directory to monitor
set "directory=C:\Development\rducc\src"
set "target_dir=game"
set EXE=game.exe

:: Get the initial timestamp
for /f "tokens=2,3,4" %%A in ('forfiles /P "%directory%" /C "cmd /c echo @file @ftime @fdate"  ^| findstr "%target_dir%"') do (
    set "initial_date=%%A"
    set "initial_am_pm=%%B"
    set "initial_time=%%C"
)

echo Initial timestamp: !initial_date! !initial_am_pm! !initial_time!

:monitor
:: Get the current timestamp
for /f "tokens=2,3,4" %%A in ('forfiles /P "%directory%" /C "cmd /c echo @file @ftime @fdate"  ^| findstr "%target_dir%"') do (
    set "current_date=%%A"
    set "current_am_pm=%%B"
    set "current_time=%%C"
)
echo Current timestamp: !current_date! !current_am_pm! !current_time!
:: Compare timestamps
if not "!current_date!!current_am_pm!!current_time!"=="!initial_date!!initial_am_pm!!initial_time!" (
    echo Directory timestamp changed!
    set "initial_date=!current_date!"
    set "initial_am_pm=!current_am_pm!"
    set "initial_time=!current_time!"

	call odin build src/game -define:RAYLIB_SHARED=true -build-mode:dll -out:game.dll
) else (
    echo No change in directory timestamp.
)

:: Wait for a while before checking again (optional)
timeout /t 2 >nul


:: Check if game is running
FOR /F %%x IN ('tasklist /NH /FI "IMAGENAME eq %EXE%"') DO IF %%x == %EXE% set GAME_RUNNING=true

if %GAME_RUNNING% == true (
	goto monitor
)
:end
