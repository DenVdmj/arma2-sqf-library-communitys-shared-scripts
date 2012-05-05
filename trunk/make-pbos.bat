@echo off
@setlocal enabledelayedexpansion

rem ----------------------------------------------------------------------------------------------
rem   Requires binarize
set   binarize=on
rem   Requires signing
set   sign=on
rem   Current path
set   thispath=%~dp0
rem   Directories of addons
set   dirlist="%~dp0css"
rem   Mask of added files
set   mask=*
rem ----------------------------------------------------------------------------------------------

call :RegRead "BinPBOPath" "HKLM\SOFTWARE\Bohemia Interactive\BinPBO Personal Edition" "MAIN" 
call :CanonizePath "targetAddonDir" "%~dp0..\..\addons"

if not exist %targetAddonDir% (
    mkdir "%targetAddonDir%"
)

copy "mod.cpp" "%targetAddonDir%/../mod.cpp"

call :MakePboProcess "%dirlist%"

goto :eof

rem ----------------------------------------------------------------------------------------------

:MakePboProcess
    
    call :CreateTempFile "*" "mask"

    echo --------------------------------
    echo -- START CREATE PBO
    echo --------------------------------

    for /D %%i in (%~1) do (
        if exist "%targetAddonDir%\%%~ni.pbo" (
            del "%targetAddonDir%\%%~ni.pbo"
        )
        if "%binarize%"=="on" (
            "%BinPBOPath%\BinPBO.exe" "%%~i" "%targetAddonDir%" -BINARIZE -TEMP "%temp%" -INCLUDE "%mask%"
        ) else (
            "%BinPBOPath%\BinPBO.exe" "%%~i" "%targetAddonDir%" -INCLUDE "%mask%"
        )
    )

    del "%mask%"

    echo --------------------------------
    echo -- START SIGN PBO
    echo --------------------------------

    if "%sign%"=="on" (
        call :ReadBiPrivateKey "biprivatekey.private" "biprivatekey"

        for %%i in ("%targetAddonDir%\*.pbo") do (
            echo Sign file "%%~i" by "!biprivatekey!"
            "%BinPBOPath%\DSSignFile\DSSignFile.exe" "!biprivatekey!" "%%~i"
        )

        if "!biprivatekey!"=="" (
            echo Error: variable "biprivatekey" is void
            echo Check your biprivatekey.private file
            pause
        )

    )

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

:ReadBiPrivateKey
    if exist "%~1" (
        for /f "tokens=*" %%i in (%~1) do (
            set %~2=%%~i
        )
    ) else (
        echo File "%~1" not found.
        echo Create in here direcory the "%~1" file that contains path to your biprivatekey key.
        echo ;create here path to your biprivatekey file>biprivatekey.private
        echo c:/path/to/your/your-key-name.biprivatekey>>biprivatekey.private
        pause
    )
goto :eof
