
@echo off
echo *****************************************************
echo * Stopping XPERF tracing                            *
echo * After stopping, you should have a file            *
echo * trace file name is in -d parameter below          *
echo *****************************************************

@echo on

xperf -d %1