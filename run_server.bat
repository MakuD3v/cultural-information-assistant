@echo off
title SorSU x CTU Cultural Assistant - Backend Server
echo ========================================================
echo  SorSU x CTU Can Tho Exchange Program Assistant
echo  Starting FastAPI Backend & Database Connection...
echo ========================================================

cd /d "%~dp0"

:: Check if PostgreSQL database is reachable
echo Checking PostgreSQL status...
python -c "import psycopg2; psycopg2.connect(dbname='cultural_db', user='postgres', host='localhost', port=5432).close(); print('PostgreSQL cultural_db is connected!')" 2>nul
if %errorlevel% neq 0 (
    echo [WARNING] Could not connect directly to cultural_db.
    echo Initializing database schema and seeding data...
    python backend\seed_data.py
)

echo.
echo Starting FastAPI server at http://localhost:8000
echo - Mobile App URL:   http://localhost:8000/app/
echo - Admin Console:    http://localhost:8000/admin/
echo - Interactive Docs: http://localhost:8000/docs
echo.

:: Open browser automatically
start http://localhost:8000/app/

:: Run uvicorn server
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
pause
