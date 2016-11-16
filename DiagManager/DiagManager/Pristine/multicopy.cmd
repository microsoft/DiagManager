@echo off

set mask=%1
set prefix=%2

rem Remove quotes since we supply them below
set mask=%mask:"=%
set prefix=%prefix:"=%


rem Copy multiple files and prefix each with the specified prefix

for %%i in ("%mask%") do copy /Y "%%i" "%prefix%%%~nxi" 

