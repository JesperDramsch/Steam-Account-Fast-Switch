@echo off
SETLOCAL enabledelayedexpansion
goto license
The MIT License (MIT)

Copyright (c) 2014 Jesper S. Dramsch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated DOcumentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
:license

: Run Start Configuration
IF NOT EXIST config.cmd (
	echo Detected first run.
	echo Launchig Configuration
	copy /y NUL config.cmd > NUL
	echo @echo off > config.cmd
	echo set firstrun=0 >> config.cmd
	IF EXIST "%PROGRAMFILES(X86)%\Steam\Steam.exe" (
		:Automatically Detect Steam for 64 bit
		echo set "SteamLoc=%PROGRAMFILES(X86)%\Steam\Steam.exe" >> config.cmd
		echo Steam installation found!
	) else (
		IF EXIST "%PROGRAMFILES%\Steam\Steam.exe" (
			:Automagically Detect Steam for 32 bit
			echo set "SteamLoc=%PROGRAMFILES%\Steam\Steam.exe" >> config.cmd
			echo Steam installation found!
		) else (
			:Manually
			echo Your Steam installation could not be detected automatically.
			set /p "SteamLoc=Please input manually: "
			IF NOT EXIST "!SteamLoc!" ( 
				echo Not valid
				goto Manually
			)
			echo Location is valid
			echo set "SteamLoc=!SteamLoc!" >> config.cmd
		)
	)
	
	set i_idcount=0
	set i_appcount=0
	:AddLogins
	set /p id="Please input SteamID: "
	echo set "id[!i_idcount!]=!id!" >> config.cmd
	choice /T 3 /D N /M "Would you like to add another SteamID"
	set /A i_idcount=%i_idcount%+1
	if ERRORLEVEL == 2 (
		if !firstrun! == 0 (
			goto AddApp
		) else (
			goto Config
		)
	)
	if ERRORLEVEL == 1 (goto AddLogins)

	:AddApp
	set /p tmp="Please input Application Name: "
	echo set "appname[!i_appcount!]=!tmp!" >> config.cmd
	set "appurl=http://steamdb.info/search/?a=app&q=%tmp%"
	start "" "%appurl%"
	set /p tmp="Please input ID Application: "
	echo set "appid[!i_appcount!]=!tmp!" >> config.cmd
	choice /T 3 /D N /M "Would you like to add another Application"
	set /A i_appcount=%i_appcount%+1
	if ERRORLEVEL == 2 ( goto Applicationmanager )
	if ERRORLEVEL == 1 ( goto AddApp )
)
timeout /T 1 > nul

:Config Import
call config.cmd
:History Import
IF NOT EXIST history.cmd (
	copy /y NUL history.cmd > NUL
	echo @echo off > history.cmd
	echo set default_id=X >> history.cmd
	echo set default_app=X >> history.cmd
	echo set default_manager=N >> history.cmd
)
call history.cmd

echo.
echo The following options are available:
set i_idcount=0
:Read Array
IF [!id[%i_idcount%]!] == [] (
	echo X.^> Add another account
) else (
	echo %i_idcount%.^> !id[%i_idcount%]!
	set /A i_idcount=%i_idcount%+1
	goto Read Array
)
echo.

:Account picker
set proto=X0123456789
set /A i_choice=%i_idcount+1
set choices=!proto:~0,%i_choice%!
choice /N /T 5 /D %default_id% /C %choices% /M "Your choice: "
set /A pick=%ERRORLEVEL%-2
IF ERRORLEVEL == 2 ( goto ChosenOne )
IF ERRORLEVEL == 1 ( goto AddLogins )
:ChosenOne
set "login=!id[%pick%]!"
echo WIll now switch account to !login!
set default_id=%pick%

choice /T 4 /D %default_manager% /m "Start application manager"
IF ERRORLEVEL == 2 ( 
	set launchid=3 
	set default_manager=N
	goto KillSteam
)
IF ERRORLEVEL == 1 ( goto Applicationmanager )
echo.

:Applicationmanager
call config.cmd
echo You can choose one of the following applications:
set i_appcount=0
:Apparray
IF [!appname[%i_appcount%]!] == [] (
	echo X.^> Add another Application
) else (
	echo %i_appcount%.^> !appname[%i_appcount%]!
	set /A i_appcount=%i_appcount%+1
	goto Apparray
)
echo.

set /A i_appchoice=%i_appcount+1
set appchoices=!proto:~0,%i_appchoice%!
choice /N /T 5 /D %default_app% /C %appchoices% /M "Your choice: "
set /A pick=%ERRORLEVEL%-2
IF ERRORLEVEL == 2 ( goto ChosenApp)
IF ERRORLEVEL == 1 ( goto AddApp)
:ChosenApp	
set "launchid=!appid[%pick%]!"
set "launchname=!appname[%pick%]!"
echo !launchname! will be started now. 
set default_app=%pick%
set default_manager=J

:KillSteam
:Check if Program is running and shut down (first nice then rigorously)

tasklist /FI "IMAGENAME eq steam.exe" 2>NUL | find /I /N "steam.exe">NUL
IF "ERRORLEVEL"=="0" (
	echo Program is running
	set yup=1
	@"%SteamLoc%" -shutdown
	timeout /T 2  > nul
) 

tasklist /FI "IMAGENAME eq steam.exe" 2>NUL | find /I /N "steam.exe">NUL
IF "ERRORLEVEL"=="0" (
	echo Attempting force close
	taskkill /F /IM steam.exe
	echo Program shut down
) ELSE (
	IF "%yup%"=="1" (
		echo Program shut down
	) ELSE (
		echo Program not running
	)
)

:HistoryWrite
echo @echo off > history.cmd
echo set "default_id=%default_id%" >> history.cmd
echo set "default_app=%default_app%" >> history.cmd
echo set "default_manager=%default_manager%" >> history.cmd

:Password (secure)
set "psCommand=powershell -Command "$pword = read-host 'Enter Password' -AsSecureString ; ^
    $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pword); ^
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)""
FOR /f "usebackq delims=" %%p in (`%psCommand%`) DO set password=%%p

:Start Steam with direct Log in
echo Starting up
start "" "%SteamLoc%" -login "%login%" "%password%" -applaunch "%launchid%"

timeout /T 5  > nul
	
EXIT
