@echo off
REM Windows runner (Docker Desktop required)
cd /d "%~dp0"
if not exist output mkdir output
docker compose up -d
echo Waiting for HiveServer2 (first start can take 1-2 minutes)...
set /a tries=0
:wait
docker exec hive4 beeline -u jdbc:hive2://localhost:10000/ -e "SHOW DATABASES;" >nul 2>&1
if %errorlevel%==0 goto ready
set /a tries+=1
if %tries% GEQ 60 goto failed
timeout /t 5 /nobreak >nul
goto wait
:failed
echo HiveServer2 did not start. Check: docker logs hive4
exit /b 1
:ready
docker exec hive4 beeline -u jdbc:hive2://localhost:10000/ -f /hql/01_create_tables.hql
docker exec hive4 beeline -u jdbc:hive2://localhost:10000/ -f /hql/02_analysis.hql > output\console_output.txt
type output\console_output.txt
docker exec hive4 beeline -u jdbc:hive2://localhost:10000/ -f /hql/03_export.hql
echo Done. Console output: output\console_output.txt
