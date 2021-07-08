set SQLName=%1
set Auth=%2 %3 

start ostress.exe -S%SQLName% %Auth% -Q"select count_big(*) from sys.messages m1 cross join sys.messages m2" -n50 -r1000 -ooutput1
