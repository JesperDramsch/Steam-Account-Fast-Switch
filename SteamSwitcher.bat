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
	set i_count=0
	:Add Logins
	set /p id="Please input SteamID: "
	echo set "id[!i_count!]=!id!" >> config.cmd
	set /p "another=Would you like to add another SteamID (y/n): "
	set /A i_count=%i_count%+1
	if "!another!"=="y" (goto Add Logins )
	
	:Default Choices
	set default_id=X
)
timeout /T 1 > nul
:Import Config
call config.cmd
echo.
echo The following options are available:
set i_count=0
:Read Array
IF [!id[%i_count%]!] == [] (
	echo X.^> Add another account
) else (
	echo %i_count%.^> !id[%i_count%]!
	set /A i_count=%i_count%+1
	goto Read Array
)
echo.
:Account picker

set proto=X0123456789
set /A i_choice=%i_count+1
set choices=!proto:~0,%i_choice%!
choice /N /T 5 /D %default_id% /C %choices% /M "Your choice: "
IF %ERRORLEVEL% == 1 ( goto Add Logins )
set /A pick=%ERRORLEVEL%-2
IF %ERRORLEVEL% GEQ 2 (
	set "login=!id[%pick%]!"
	echo Will now switch account to !login! 
	echo set "default_id=!pick!" >> config.cmd
)

timeout /T 5  > nul
echo.

:Check if Program is running and shut down (first nice then rigorously)
tasklist /FI "IMAGENAME eq steam.exe" 2>NUL | find /I /N "steam.exe">NUL
IF "%ERRORLEVEL%"=="0" (
	echo Program is running
	set yup=1
	@"%SteamLoc%" -shutdown
	timeout /T 2  > nul
) 
tasklist /FI "IMAGENAME eq steam.exe" 2>NUL | find /I /N "steam.exe">NUL
IF "%ERRORLEVEL%"=="0" (
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

:Password (secure)
set "psCommand=powershell -Command "$pword = read-host 'Enter Password' -AsSecureString ; ^
    $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pword); ^
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)""
FOR /f "usebackq delims=" %%p in (`%psCommand%`) DO set password=%%p

:Start Steam with direct Log in
echo Starting up
start "" "%SteamLoc%" -login "%login%" "%password%"

EXIT
