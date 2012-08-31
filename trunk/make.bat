@echo off
rem ----------------------------------------------------------------------------------------------
rem Relative (by Arma2 folder) path to mod folder
set RelativeModDir=@\$vdmj\css
rem Addons directories list, may be a mask, as %~dp0/*
set DirList="%~dp0css"
rem Requires binarize
set Binarize=on
rem Requires signing
set Sign=on
rem Set any value in MakeDistrib for make distrib
set MakeDistrib=1
rem Mask of added files (separated with ;), set void (as set Mask=) for use native filemask
set Mask=css;*.macro;
rem Current path
set ThisPath=%~dp0
rem ----------------------------------------------------------------------------------------------

call "make-pbos.bat"