@echo off

time /t
for /f "tokens=1 delims=""" %%a in ( 'time /t' ) do set changetime=%%a

for /f "tokens=2 delims=\" %%a in ( 'whoami' ) do set me=%%a

echo Enter host to ping:
set /p targetmachine=

echo Enter user's name:
set /p usersname=

echo Enter correct IP:
set /p rightip=

set fulltitle=%usersname%, IP manually changed to %rightip%

:UntilRight
for /f "tokens=2 delims=[]" %%a in ('ping %targetmachine% -n 1 -i 1') do set currentip=%%a
title %fulltitle%, resolving %currentip% as of %changetime%.
echo %targetmachine% is currently resolving to IP address %currentip% as of %changetime%. Pinging...
if %rightip% equ %currentip% goto RightIP

:WrongIP
color 40
ping %currentip% -n 1 >nul && set doesitping=However, %currentip% does ping; it's possible this computer was actually moved. || set doesitping= 
echo IP for %usersname% (%targetmachine%) does not match what was entered; %rightip% was entered and %currentip% is being resolved. %doesitping%
ipconfig /flushdns>nul
timeout 15
echo.
goto UntilRight

:RightIP
echo IP for %usersname% (%targetmachine%) matches what was entered, waiting for it to change.
msg %me% IP for %usersname% (%targetmachine%) matches what was entered, waiting for it to change.
echo.
time /t
for /f "tokens=1 delims=""" %%a in ( 'time /t' ) do set changetime=%%a
title %fulltitle%, resolving %currentip% as of %changetime%.
echo.
goto UntilWrong


:UntilWrong
color 20
echo.
echo Pinging...
for /f "tokens=2 delims=[]" %%a in ('ping %targetmachine% -n 1 -i 1') do set currentip=%%a
echo %targetmachine% is currently resolving to IP address %currentip%.
if %rightip% equ %currentip% goto RightIP2
if %rightip% neq %currentip% goto WrongIP2

:RightIP2
echo IP for %targetmachine% still matches what was entered. Restarting...
timeout 15
echo.
goto UntilWrong

:WrongIP2
color 40
ping %currentip% -n 1 >nul && set doesitping=However, %currentip% does ping; it's possible this computer was actually moved. || set doesitping= 
echo IP for %usersname% (%targetmachine%) does not match what was entered; %rightip% was entered and %currentip% is being resolved. %doesitping%
msg %me% IP for %usersname% (%targetmachine%) does not match what was entered; %rightip% was entered and %currentip% is being resolved. %doesitping%
echo.
time /t
for /f "tokens=1 delims=""" %%a in ( 'time /t' ) do set changetime=%%a
title %fulltitle%, resolving %currentip% as of %changetime%.
echo.
goto UntilRight

pause