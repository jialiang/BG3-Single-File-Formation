@echo off
setlocal

set DIVINE=%~dp0LSLib\Packed\Tools\Divine.exe
set TEMP_DIR=%~dp0Temp
set SOURCE=%~dp0Temp
set OUTPUT=%~dp0SingleFileFormation.pak

if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
xcopy /e /i /q "%~dp0Mods" "%TEMP_DIR%\Mods"

if errorlevel 1 (
    echo Copy failed
    goto cleanup
)

"%DIVINE%" --action create-package --source "%SOURCE%" --destination "%OUTPUT%" --game bg3

if errorlevel 1 (
    echo Build failed
) else (
    echo Build successful: %OUTPUT%
)

:cleanup

rmdir /s /q "%TEMP_DIR%"
pause
