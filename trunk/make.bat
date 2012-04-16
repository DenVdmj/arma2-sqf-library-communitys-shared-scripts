@echo off
@setlocal enabledelayedexpansion

set binarize=1
set mask=*

call :RegRead "BinPBO" "HKLM\SOFTWARE\Bohemia Interactive\BinPBO Personal Edition" "MAIN" "\BinPBO.exe"
call :CanonizePath "targetAddonDir" "%~dp0..\..\addons"

if not exist %targetAddonDir% (
    mkdir "%targetAddonDir%"
)

copy "mod.cpp" "%targetAddonDir%/../mod.cpp"

call :CreateTempFile "*" "mask"

for /D %%i in ("%~dp0\css") do (
    if exist "%targetAddonDir%\%%~ni.pbo" (
        del "%targetAddonDir%\%%~ni.pbo"
    )
    if "%binarize%"=="0" (
        "%binpbo%" "%%~i" "%targetAddonDir%" -INCLUDE "%mask%"
    ) else (
        "%binpbo%" "%%~i" "%targetAddonDir%" -BINARIZE -TEMP "%temp%" -INCLUDE "%mask%"
    )
)

del "%mask%"

goto :eof

:RegRead
    for /F "tokens=1,2,*" %%i in ('reg query "%~2" /v "%~3"') do (
        if "%%i"=="%~3" (
            set %~1=%%k%~4
        )
    )
goto :eof

:CanonizePath
    for %%i in ("%~2\some") do (
        set ___%~1=%%~dpi\
        set %~1=!___%~1:\\=!
        set ___%~1=
    )
goto :eof

:CreateTempFile
    for /f "tokens=1,2,3,4,5,6,7 delims=:,. " %%i in ("%DATE%:%TIME%") do (
        set %~2=___%~2___%%i%%j%%k%%l%%m%%n_%%o___
    )
    echo %~1>%mask%
goto :eof
