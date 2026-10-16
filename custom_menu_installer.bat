@echo off
setlocal enabledelayedexpansion

chcp 65001 >nul
color 0A

echo ===================================================
echo   Идёт установка Custom Menu.
echo ===================================================
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ПРЕДУПРЕЖДЕНИЕ] Бантик может работать некорректно не от прав администратора.
    echo.
)

set "GITHUB_URL=https://github.com/Nexeonenn/custom_menu/archive/refs/heads/dev.zip"
set "TEMP_ZIP=%TEMP%\custom_menu_dev.zip"
set "TEMP_EXTRACT=%TEMP%\custom_menu_extract"

echo [ПОИСК] Ищу установленный Garry's Mod...
for /f "usebackq tokens=*" %%I in (`powershell -NoProfile -Command "(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 4000' -ErrorAction SilentlyContinue).InstallLocation"`) do set "GMOD_PATH=%%I"

if not defined GMOD_PATH (
    echo [ОШИБКА] Не удалось найти Garry's Mod в реестре.
    echo Убедитесь, что игра установлена через Steam.
    echo.
    pause
    exit /b 1
)

if not exist "%GMOD_PATH%" (
    echo [ОШИБКА] Путь к Garry's Mod найден, но папка не существует:
    echo %GMOD_PATH%
    echo.
    pause
    exit /b 1
)

echo [OK] Garry's Mod найден: %GMOD_PATH%
echo [ИНФО] Перехожу в папку игры...
cd /d "%GMOD_PATH%"
echo.
if not exist "garrysmod" (
    echo [ОШИБКА] Папка garrysmod не найдена в %GMOD_PATH%!
    echo.
    pause
    exit /b 1
)

if exist "garrysmod\html" (
    echo [БЭКАП] Найдена папка html, создаю бэкап...
    
    for /f "usebackq tokens=*" %%I in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"`) do set "datetime=%%I"
    set "BACKUP_NAME=html_backup_!datetime!"
    set "BACKUP_PATH=garrysmod\html_backups\!BACKUP_NAME!"

    if not exist "garrysmod\html_backups" mkdir "garrysmod\html_backups"

    echo Копирование: garrysmod\html -^> !BACKUP_PATH!
    xcopy "garrysmod\html" "!BACKUP_PATH!\" /E /I /Q /Y
    
    if !errorlevel! equ 0 (
        echo [OK] Бэкап создан: !BACKUP_PATH!
    ) else (
        echo [ПРЕДУПРЕЖДЕНИЕ] Ошибка при создании бэкапа! Продолжаем...
    )
    echo.
) else (
    echo [ИНФО] Папка html не найдена, бэкап не требуется.
    echo.
)

echo [ЗАГРУЗКА] Скачивание архива с GitHub...
echo URL: %GITHUB_URL%
echo.

powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%GITHUB_URL%' -OutFile '%TEMP_ZIP%'}"

if %errorlevel% neq 0 (
    echo [ОШИБКА] Не удалось скачать архив!
    echo Проверьте интернет-соединение.
    pause
    exit /b 1
)

echo [OK] Архив скачан: %TEMP_ZIP%
echo.

if exist "%TEMP_EXTRACT%" rmdir /s /q "%TEMP_EXTRACT%"
mkdir "%TEMP_EXTRACT%"

echo [РАСПАКОВКА] Распаковка архива...
powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%TEMP_ZIP%', '%TEMP_EXTRACT%')}"

if %errorlevel% neq 0 (
    echo [ОШИБКА] Не удалось распаковать архив!
    pause
    exit /b 1
)

echo [OK] Архив распакован.
echo.

set "SOURCE_FOLDER="
for /d %%i in ("%TEMP_EXTRACT%\custom_menu-dev*") do set "SOURCE_FOLDER=%%i"

if not defined SOURCE_FOLDER (
    echo [ОШИБКА] Не найдена папка custom_menu-dev в архиве!
    pause
    exit /b 1
)

echo [ИНФО] Найдена папка: %SOURCE_FOLDER%
echo.

if not exist "%SOURCE_FOLDER%\garrysmod" (
    echo [ОШИБКА] В архиве отсутствует папка garrysmod!
    pause
    exit /b 1
)

if exist "garrysmod\html" (
    echo [УДАЛЕНИЕ] Удаляем старую папку html...
    rmdir /s /q "garrysmod\html"
    echo [OK] Старая папка html удалена.
    echo.
)

echo [КОПИРОВАНИЕ] Копирование новых файлов...

if exist "%SOURCE_FOLDER%\garrysmod\html" (
    echo   - Копирование html...
    xcopy "%SOURCE_FOLDER%\garrysmod\html" "garrysmod\html\" /E /I /Q /Y
    if !errorlevel! equ 0 (
        echo     [OK] html скопирован
    ) else (
        echo     [ОШИБКА] Ошибка при копировании html!
    )
) else (
    echo   [ИНФО] Папка html не найдена в архиве, пропускаем.
)

if exist "%SOURCE_FOLDER%\garrysmod\resource" (
    echo   - Копирование resource...
    xcopy "%SOURCE_FOLDER%\garrysmod\resource" "garrysmod\resource\" /E /I /Q /Y
    if !errorlevel! equ 0 (
        echo     [OK] resource скопирован
    ) else (
        echo     [ОШИБКА] Ошибка при копировании resource!
    )
) else (
    echo   [ИНФО] Папка resource не найдена в архиве, пропускаем.
)

if exist "%SOURCE_FOLDER%\garrysmod\workshop" (
    echo   - Копирование workshop...
    xcopy "%SOURCE_FOLDER%\garrysmod\workshop" "garrysmod\workshop\" /E /I /Q /Y
    if !errorlevel! equ 0 (
        echo     [OK] materials скопирован
    ) else (
        echo     [ОШИБКА] Ошибка при копировании materials!
    )
) else (
    echo   [ИНФО] Папка materials не найдена в архиве, пропускаем.
)

echo.

echo [ОЧИСТКА] Удаление временных файлов...
del /q "%TEMP_ZIP%" 2>nul
rmdir /s /q "%TEMP_EXTRACT%" 2>nul
echo [OK] Временные файлы удалены.
echo.

echo ===================================================
echo   ГОТОВО! Установка успешно завершена!
echo ===================================================
echo.
echo Бэкап старой папки html сохранён в:
echo garrysmod\html_backups\%BACKUP_NAME%
echo.

pause