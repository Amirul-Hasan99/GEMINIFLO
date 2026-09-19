@echo off
setlocal enabledelayedexpansion

title GEMINIFLO - Git Auto Push
cls

echo =====================================================================
echo                GEMINIFLO - GIT AUTO PUSH TOOL
echo        Target Repo: https://github.com/Amirul-Hasan99/GEMINIFLO
echo =====================================================================
echo.

:: Check Git installation
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Git tidak terdeteksi di komputer Anda!
    echo Silakan install Git terlebih dahulu dari https://git-scm.com/
    pause
    exit /b 1
)

:: Check if repository is initialized
if not exist ".git" (
    echo [INFO] Inisialisasi Git repository lokal...
    git init
    git branch -M main
)

:: Ensure remote origin is configured
git remote | findstr /I "origin" >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Menambahkan remote origin ke https://github.com/Amirul-Hasan99/GEMINIFLO.git ...
    git remote add origin https://github.com/Amirul-Hasan99/GEMINIFLO.git
) else (
    echo [INFO] Mengatur URL remote origin...
    git remote set-url origin https://github.com/Amirul-Hasan99/GEMINIFLO.git
)

echo.
echo [STATUS] Status file yang dimodifikasi:
echo ---------------------------------------------------------------------
git status -s
echo ---------------------------------------------------------------------
echo.

set default_msg=feat: integrate Neon PostgreSQL, PRD, DESIGN, SKILLS and zero-issue code stabilization
set /p commit_msg="Masukkan pesan commit [Enter untuk default]: "

if "%commit_msg%"=="" (
    set commit_msg=%default_msg%
)

echo.
echo [1/3] Menambahkan file (git add .)...
git add .

echo [2/3] Membuat commit ("%commit_msg%")...
git commit -m "%commit_msg%"

echo [3/3] Mendorong perubahan ke GitHub (git push -u origin main)...
git push -u origin main

if %errorlevel% neq 0 (
    echo.
    echo [PERHATIAN] Push gagal atau terjadi conflict.
    echo Mencoba pull dengan rebase sebelum push kembali...
    git pull origin main --rebase
    git push -u origin main
)

if %errorlevel% equ 0 (
    echo.
    echo =====================================================================
    echo [BERHASIL] Seluruh kode berhasil di-push ke GitHub!
    echo URL: https://github.com/Amirul-Hasan99/GEMINIFLO
    echo =====================================================================
) else (
    echo.
    echo =====================================================================
    echo [GAGAL] Terjadi kesalahan saat push.
    echo Pastikan Anda sudah login akun GitHub di komputer ini.
    echo =====================================================================
)

echo.
pause
