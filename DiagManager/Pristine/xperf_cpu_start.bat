
@echo off
echo ******************************************************************
echo * starting xperf capturing                                       *
echo * when pssdiag is stopped, you should have a file called  *.etl  *
echo ******************************************************************
 
@echo on
rem recommended by platform
rem xperf.exe –on Latency –stackWalk Profile
rem the following is the old one 
rem xperf -on PROC_THREAD+LOADER+INTERRUPT+DPC+PROFILE -stackwalk profile -minbuffers 16 -maxbuffers 1024  
rem xperf -d profile.etl 
rem perf rdorr
xperf -on latency -stackwalk profile