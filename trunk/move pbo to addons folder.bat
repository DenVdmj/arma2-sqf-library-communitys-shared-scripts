@echo off

for %%f in (*.pbo) do move /Y "%%f" "%~dp0..\..\addons\"
