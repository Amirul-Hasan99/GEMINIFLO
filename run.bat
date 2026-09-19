@echo off
setlocal enabledelayedexpansion

title GEMINIFLO - Local Runner
cls

echo =====================================================================
echo                 GEMINIFLO - FLORIST BOOKING APP
echo              Database: Neon Serverless PostgreSQL
echo =====================================================================
echo.

:: Check Flutter installation
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter SDK tidak ditemukan di PATH sistem Anda!
    echo Pastikan Flutter sudah terinstal dan ditambahkan ke System Environment Variables.
    pause
    exit /b 1
)

echo [INFO] Memeriksa status device yang tersedia...
echo.
flutter devices
echo.
echo =====================================================================
echo  Pilih target platform untuk menjalankan GEMINIFLO:
echo =====================================================================
echo  [1] Chrome (Web Browser)
echo  [2] Windows Desktop
echo  [3] Android Device / Emulator
echo  [4] Auto Detect (Perangkat yang aktif pertama)
echo  [5] Cek Analisis & Test (flutter analyze ^& test)
echo  [6] Keluar
echo =====================================================================
echo.

set /p choice="Masukkan nomor pilihan Anda (1-6) [Default: 1]: "
if "%choice%"=="" set choice=1

if "%choice%"=="1" (
    echo.
    echo [INFO] Menjalankan GEMINIFLO di Google Chrome...
    flutter run -d chrome
    goto end
)

if "%choice%"=="2" (
    echo.
    echo [INFO] Menjalankan GEMINIFLO di Windows Desktop...
    flutter run -d windows
    goto end
)

if "%choice%"=="3" (
    echo.
    echo [INFO] Menjalankan GEMINIFLO di Android Device / Emulator...
    flutter run -d android
    goto end
)

if "%choice%"=="4" (
    echo.
    echo [INFO] Menjalankan GEMINIFLO di target default...
    flutter run
    goto end
)

if "%choice%"=="5" (
    echo.
    echo [INFO] Menjalankan flutter analyze...
    call flutter analyze
    echo.
    echo [INFO] Menjalankan flutter test...
    call flutter test
    goto end
)

if "%choice%"=="6" (
    echo Keluar.
    exit /b 0
)

echo Pilihan tidak valid!
pause

:end
echo.
echo Selesai.
pause
