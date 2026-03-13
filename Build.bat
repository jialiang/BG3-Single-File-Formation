@echo off
setlocal

set DIVINE=%~dp0LSLib\Packed\Tools\Divine.exe
set SOURCE=%~dp0Mods
set OUTPUT=%~dp0SingleFileFormation.pak

"%DIVINE%" --action create-package --source "%SOURCE%" --destination "%OUTPUT%" --game bg3

if errorlevel 1 (
    echo Build failed
) else (
    echo Build successful: %OUTPUT%
)
