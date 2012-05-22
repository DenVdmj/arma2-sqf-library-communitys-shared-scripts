setlocal

    echo --------------------------------
    echo -- START CREATE DISTRIBUTION PACK
    echo --------------------------------
    
    set DistribDir=%ThisPath%..\..\distrib\SQF-Library Community`s Shared Scripts\ArmA2
    set DistribDir_modDir=%DistribDir%\@\css

    rd /S /Q "%DistribDir%"
    md "%DistribDir%"
    md "%DistribDir_modDir%\addons"

    xcopy /E /Y "%TargetAddonDir%" "%DistribDir_modDir%\addons"

    echo Copy mission-version folder to distrib
    md "%DistribDir%\..\mission-version\css"
    xcopy /E /Y "%ThisPath%\mission-version\css" "%DistribDir%\..\mission-version\css"
    
    echo Copy doc folder to distrib
    md "%DistribDir%\..\doc"
    xcopy /E /Y "%ThisPath%doc" "%DistribDir%\..\doc"

    echo "%DistribDir_modDir%\addons\*.log"
    del "%DistribDir_modDir%\addons\*.log"

    copy "mod.cpp" "%DistribDir_modDir%\mod.cpp"

