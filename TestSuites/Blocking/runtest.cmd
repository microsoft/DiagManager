set SQLName=.\sql16a
start sqlcmd -S%SQLName% -E -iblocker.sql -oblocker.out
start ostress.exe -S%SQLName% -E -Q"select * from tempdb.dbo.t" -n50 -r100 -ooutput1
start ostress.exe -S%SQLName% -E -Q"waitfor delay '0:0:5' select * from notable" -n5 -r100 -ooutput2