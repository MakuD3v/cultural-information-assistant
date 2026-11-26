@echo off
title Seed Cultural Assistant Database
echo ========================================================
echo  Seeding PostgreSQL cultural_db with Exchange Data
echo ========================================================

cd /d "%~dp0"
python backend\seed_data.py

echo.
echo Database seeding finished.
pause
