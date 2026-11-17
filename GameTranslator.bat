@echo off
chcp 65001 >nul
title 🎮 GameTranslator v1.0 Pro - Sefflex Edition (Windows)
cd /d "%~dp0"
cls
echo ======================================================================
echo   🎮 GameTranslator v1.0 Pro - Sefflex Edition (Windows)
echo   Konsol Oyunları İçin Gerçek Zamanlı Türkçe Altyazı Sistemi
echo ======================================================================
echo.

:: 1. .NET SDK Kontrolü
set "DOTNET_CMD=dotnet"
where dotnet >nul 2>nul
if %ERRORLEVEL% neq 0 (
    if exist "%LOCALAPPDATA%\Microsoft\dotnet\dotnet.exe" (
        set "DOTNET_CMD=%LOCALAPPDATA%\Microsoft\dotnet\dotnet.exe"
    )
)

:: 2. Hazır GameTranslator paketi kontrolü
if exist "bin\GameTranslator.dll" (
    echo [BİLGİ] Hazır GameTranslator paketi başlatılıyor...
    start "" "%DOTNET_CMD%" "bin\GameTranslator.dll"
    exit /b 0
)

if exist "bin\GameTranslator.exe" (
    echo [BİLGİ] Hazır GameTranslator ikilisi başlatılıyor...
    start "" "bin\GameTranslator.exe"
    exit /b 0
)

:: 3. Proje Dosyası Kontrolü ve Başlatma
if exist "windows\src\GameTranslator.App\GameTranslator.App.csproj" (
    echo [MOTOR] Windows Masaüstü Arayüzü başlatılıyor (.NET 10 / WPF / DirectML)...
    echo Lütfen ilk açılışta paketlerin yüklenmesi için birkaç saniye bekleyin...
    echo.
    "%DOTNET_CMD%" run --project "windows\src\GameTranslator.App\GameTranslator.App.csproj"
    if %ERRORLEVEL% neq 0 (
        echo.
        echo [HATA] Uygulama çalışırken bir sorun oluştu. Hata kodunu yukarıdan inceleyebilirsiniz.
        pause
    )
) else (
    echo.
    echo [HATA] windows\src\GameTranslator.App\GameTranslator.App.csproj bulunamadı!
    echo Lütfen ZIP dosyasını klasöre eksiksiz çıkarttığınızdan emin olun.
    echo.
    pause
)
