@echo off

pushd 
cd /d %2
%1 >nul 2>&1
popd