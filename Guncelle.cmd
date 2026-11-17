@echo off
chcp 65001 >nul
setlocal
set "GT=%LOCALAPPDATA%\GameTranslator"
set "PKG=%~dp0GameTranslator-1.5.3-full.nupkg"

if not exist "%GT%\Update.exe" (
  echo GameTranslator bu bilgisayarda kurulu degil.
  echo Ilk kurulum icin Setup.exe'yi kullan; bu dosya sadece guncelleme icindir.
  pause
  exit /b 1
)
if not exist "%PKG%" (
  echo Guncelleme dosyasi bulunamadi: %PKG%
  pause
  exit /b 1
)

echo GameTranslator 1.5.3'ye guncelleniyor...

rem Ayarlar ve PS5 eslestirmesi yedeklenir (ne olur ne olmaz).
set "BK=%USERPROFILE%\Documents\GameTranslator-yedek"
if not exist "%BK%" mkdir "%BK%"
if exist "%GT%\secure.dat" copy /y "%GT%\secure.dat" "%BK%\" >nul
if exist "%GT%\settings.json" copy /y "%GT%\settings.json" "%BK%\" >nul
if exist "%GT%\samsung" xcopy /e /i /y /q "%GT%\samsung" "%BK%\samsung" >nul

rem Acik uygulamayi kapat.
taskkill /im GameTranslator.exe /f >nul 2>&1
timeout /t 2 /nobreak >nul

if not exist "%GT%\packages" mkdir "%GT%\packages"
copy /y "%PKG%" "%GT%\packages\" >nul
"%GT%\Update.exe" apply --norestart --silent --package "%GT%\packages\GameTranslator-1.5.3-full.nupkg"
if errorlevel 1 (
  echo Guncelleme basarisiz oldu. Ayarlarin yedegi: %BK%
  pause
  exit /b 1
)

start "" "%GT%\current\GameTranslator.exe"
echo Tamam! Ayarlarin ve PS5 eslestirmen yerinde. Yedek: %BK%
timeout /t 5 >nul
