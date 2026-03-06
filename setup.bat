@echo off
echo [1/2] Getting Git (basic env)
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/MinGit-2.44.0-64-bit.zip' -OutFile 'git.zip'"
powershell -Command "Expand-Archive -Path 'git.zip' -DestinationPath './bin/git' -Force"
del git.zip

echo [2/2] Using bash
"./bin/git/usr/bin/sh.exe" ./scripts/main.sh
pause