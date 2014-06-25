@echo off
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
set SteamLoc=C:\Program Files (x86)\Steam\Steam.exe

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
set /p id="Enter SteamID: "
set "psCommand=powershell -Command "$pword = read-host 'Enter Password' -AsSecureString ; ^
    $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pword); ^
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)""
FOR /f "usebackq delims=" %%p in (`%psCommand%`) DO set password=%%p
echo Starting up
start "" "%SteamLoc%" -login "%id%" "%password%"
EXIT
