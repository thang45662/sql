@echo off
setlocal enabledelayedexpansion

:: --- SQL Server connection info ---
set SERVER=10.24.113.1
set DATABASE=KV_TimeSheet_Booking_Dev2
set USER=kiotvietdev
set PASSWORD=C1t1g000$6162

:: --- Define folder paths ---
set "ROOT_FOLDER=%~dp0"
set "SQL_FOLDER_RELATIVE=sql_for_salon_dev_v10"
set "SQL_FOLDER=%ROOT_FOLDER%%SQL_FOLDER_RELATIVE%"

:: --- Check if folder exists ---
echo.
echo === Verifying SQL folder path ===
if not exist "!SQL_FOLDER!" (
    echo  Folder not found: !SQL_FOLDER!
    pause
    exit /b 1
)

:: --- Check SQL Server connection ---
echo.
echo  Checking connection to SQL Server...
sqlcmd -S %SERVER% -U %USER% -P %PASSWORD% -d %DATABASE% -Q "SELECT 1" >nul 2>&1

if errorlevel 1 (
    echo  Connection failed! Please verify SERVER, USERNAME or PASSWORD.
    pause
    exit /b 1
)

echo  Connection successful.
echo.

:: --- Execute each SQL file ---
pushd "!SQL_FOLDER!"
echo === Executing all .sql files in: !SQL_FOLDER!
echo.

for %%F in (*.sql) do (
    echo  Running: %%F ...
    sqlcmd -S %SERVER% -U %USER% -P %PASSWORD% -d %DATABASE% -i "%%F" -f 65001
)

popd

echo.
echo  All SQL files executed successfully.
pause

