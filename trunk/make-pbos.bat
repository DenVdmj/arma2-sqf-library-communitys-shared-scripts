@echo off
@setlocal enabledelayedexpansion

rem Read install path of BinPBO.exe programm
call :RegRead "BinPBOPath" "HKLM\SOFTWARE\Bohemia Interactive\BinPBO Personal Edition" "MAIN"

rem Read install path of ArmA2 game
call :RegRead "ArmA2Path" "HKLM\SOFTWARE\Bohemia Interactive Studio\ArmA 2" "MAIN"

rem Relative path of addon folder
call :CanonizePath "TargetAddonDir" "%ArmA2Path%\%RelativeModDir%\addons"
call :GetRevisionNumber "RevisionNumber"

if not exist %TargetAddonDir% (
    mkdir "%TargetAddonDir%"
)

if exist "mod.cpp" (
    copy "mod.cpp" "%TargetAddonDir%/../mod.cpp"
)

call :MakePboProcess "%DirList%"

if not "%MakeDistrib%"=="" (
    if exist "make-distrib.bat" (
        call "make-distrib.bat"
    )
)

goto :eof

rem ==============================================================================================

:MakePboProcess

    if not "%Mask%"=="" (
        call :CreateTempFile "%Mask%" "MASKFILE"
        set includeMaskfile= -INCLUDE "!MASKFILE!"
    )
    call :CreateTempDir "temp_binarize_pbos" "%temp%"

    echo --------------------------------
    echo --      START CREATE PBO      --
    echo --------------------------------

    for /D %%i in (%~1) do (
        if exist "%TargetAddonDir%\%%~ni.pbo" (
            echo del "%TargetAddonDir%\%%~ni.*"
            del "%TargetAddonDir%\%%~ni.*"
        )
        if "%Binarize%"=="on" (
            "%BinPBOPath%\BinPBO.exe" "%%~i" "%TargetAddonDir%" -BINARIZE %USEPREFIX% -TEMP "%temp_binarize_pbos%" %includeMaskfile%
        ) else (
            "%BinPBOPath%\BinPBO.exe" "%%~i" "%TargetAddonDir%" %includeMaskfile%
        )
    )

    if exist "%MASKFILE%" del "%MASKFILE%"
    rmdir /S /Q "%temp_binarize_pbos%"
    mkdir "%TargetAddonDir%\log"
    for %%i in ("%TargetAddonDir%\*.log") do (
        move "%%~i" "%TargetAddonDir%\log\%%~nxi"
    )

    echo --------------------------------
    echo --       START SIGN PBO      --
    echo --------------------------------

    if "%Sign%"=="on" (
        call :ReadBiPrivateKey "biprivatekey.private" "biprivatekey"

        for /D %%i in (%~1) do (
            echo Sign file "%TargetAddonDir%\%%~ni.pbo" by "!biprivatekey!"
            "%BinPBOPath%\DSSignFile\DSSignFile.exe" "!biprivatekey!" "%TargetAddonDir%\%%~ni.pbo"
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
        echo %~1>___%~2___%%i%%j%%k%%l%%m%%n_%%o___
    )
goto :eof

:CreateTempDir
    for /f "tokens=1,2,3,4,5,6,7 delims=:,. " %%i in ("%DATE%:%TIME%") do (
        set %~1=%~2/___%~1___%%i%%j%%k%%l%%m%%n_%%o___
        mkdir "%~2/___%~1___%%i%%j%%k%%l%%m%%n_%%o___"
    )
goto :eof

:GetRevisionNumber
    if exist "%~dp0..\.hg\cache\tags" (
        for /F "usebackq tokens=1,2" %%i in ("%~dp0..\.hg\cache\tags") do (
            echo Revision number: %%j
            set %~1=%%j
        )
    ) else (
        echo Fails to identify the revision number. Folder not found: "%~dp0..\.hg\cache\tags"
    )
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
        echo c:/this/is/default/path/to/your-key-name.biprivatekey>>biprivatekey.private
        pause
    )
goto :eof
