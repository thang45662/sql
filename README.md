:: RunAllSqlFiles.bat
@echo off
setlocal

set SERVER=10.24.113.1
set DATABASE=KV_TimeSheet_Booking_Dev2
set USER=kiotvietdev
set PASSWORD=C1t1g000$6162

for %%F in (*.sql) do (
    echo Running %%F ...
    sqlcmd -S %SERVER% -U %USER% -P %PASSWORD% -d %DATABASE% -i "%%F"
)

echo Done!
pause
