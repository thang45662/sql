@echo off
setlocal enabledelayedexpansion

:: --- Connection ---
set SERVER=10.24.113.1
set DATABASE=KV_TimeSheet_Booking_Dev2
set USER=kiotvietdev
set "PASSWORD=C1t1g000$6162"

:: --- Path ---
set "ROOT_FOLDER=%~dp0"
set "SQL_FOLDER_RELATIVE=sql_for_salon_dev_v10"
set "SQL_FOLDER=%ROOT_FOLDER%%SQL_FOLDER_RELATIVE%"
set "LOG_FOLDER=%SQL_FOLDER%\Logs"
set "LOG_FILE=%LOG_FOLDER%\combined_sql_log.txt"
set "MERGED_FILE=%LOG_FOLDER%\temp_combined_transaction.sql"

if not exist "%LOG_FOLDER%" mkdir "%LOG_FOLDER%"

:: --- Clear old logs/temp ---
if exist "!LOG_FILE!" del /f /q "!LOG_FILE!"
if exist "!MERGED_FILE!" del /f /q "!MERGED_FILE!"

:: --- Check folder ---
echo === Verifying SQL folder ===
if not exist "!SQL_FOLDER!" (
    echo Folder not found: !SQL_FOLDER!
    pause
    exit /b 1
)

:: --- Check connection ---
echo Checking SQL Server connection...
sqlcmd -S %SERVER% -U %USER% -P %PASSWORD% -d %DATABASE% -Q "SELECT 1" >nul 2>&1
if errorlevel 1 (
    echo Connection failed!
    pause
    exit /b 1
)
echo Connection successful.
echo.

:: --- Build merged SQL file with transaction ---
(
    echo BEGIN TRANSACTION;
    echo GO
    for %%F in ("%SQL_FOLDER%\*.sql") do (
        echo -- ========================
        echo -- File: %%~nxF
        echo -- ========================
        type "%%F"
 
        echo.
    )
    echo COMMIT;
) > "!MERGED_FILE!"

:: --- Run the merged SQL file ---
echo === Executing merged SQL file ===
sqlcmd -S %SERVER% -U %USER% -P %PASSWORD% -d %DATABASE% -i "!MERGED_FILE!" -f 65001 >> "!LOG_FILE!" 2>&1

if errorlevel 1 (
    echo *** ERROR occurred during execution ***
    echo See log: !LOG_FILE!
    pause
    exit /b 1
)

echo.
echo All SQL files merged and executed successfully in one transaction.
echo Log saved at: !LOG_FILE!
pause
