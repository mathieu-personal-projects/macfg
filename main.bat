@echo off
chcp 65001 > NUL
echo .
echo ███╗   ███╗ █████╗  ██████╗███████╗ ██████╗ 
echo ████╗ ████║██╔══██╗██╔════╝██╔════╝██╔════╝ 
echo ██╔████╔██║███████║██║     █████╗  ██║  ███╗
echo ██║╚██╔╝██║██╔══██║██║     ██╔══╝  ██║   ██║
echo ██║ ╚═╝ ██║██║  ██║╚██████╗██║     ╚██████╔╝
echo ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝      ╚═════╝ 
echo desc: configure my env • version: 0.2.0

:: Find bash (Git Bash ships bash.exe in its usr\bin and bin directories)
set BASH_EXE=
for %%B in (bash.exe) do set BASH_EXE=%%~$PATH:B
if not defined BASH_EXE (
    if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" (
        set BASH_EXE=%LOCALAPPDATA%\Programs\Git\bin\bash.exe
    ) else if exist "%PROGRAMFILES%\Git\bin\bash.exe" (
        set BASH_EXE=%PROGRAMFILES%\Git\bin\bash.exe
    ) else (
        echo.
        echo  [ERROR] bash not found. Install Git for Windows first:
        echo  https://git-scm.com/download/win
        pause
        exit /b 1
    )
)

pushd "%~dp0"
"%BASH_EXE%" "./scripts/main.sh" %*
popd
pause
