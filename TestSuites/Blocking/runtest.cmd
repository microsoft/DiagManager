set SQLName=%1
set Auth=%2 %3 
start sqlcmd -S%SQLName% %Auth% -iblocker.sql -oblocker.out
start ostress.exe -S%SQLName% %Auth% -Q"select * from tempdb.dbo.t" -n50 -r100 -ooutput1
start ostress.exe -S%SQLName% %Auth% -Q"waitfor delay '0:0:5' select * from notable" -n5 -r100 -ooutput2