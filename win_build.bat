@echo off
set GAME_RUNNING=false

:: OUT_DIR is for everything except the exe. The exe needs to stay in root
:: folder so it sees the assets folder, without having to copy it.

set EXE=game.exe
:: Check if game is running
call odin build src/game -define:RAYLIB_SHARED=true -build-mode:dll -out:game.dll -debug
FOR /F %%x IN ('tasklist /NH /FI "IMAGENAME eq %EXE%"') DO IF %%x == %EXE% set GAME_RUNNING=true

start cmd /c poll.bat
if %GAME_RUNNING% == false (
	echo DELETING
	del /q /s build 
	::start cmd /k odin run . -out:%EXE% -debug
	call odin run . -out:%EXE% -debug
)



