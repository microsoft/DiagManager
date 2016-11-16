set nocount on
PRINT 'Errorlogs'
PRINT '---------'

declare @i tinyint, @res int
set @i=0
while (@i<255) begin
	if (0=@i) begin
		print 'ERRORLOG'
		exec @res=master.dbo.xp_readerrorlog 
	end	else begin
		print 'ERRORLOG.'+cast(@i as varchar(3))
		exec @res=master.dbo.xp_readerrorlog @i
	end
	if (@@error<>0) OR (@res<>0) break
	set @i=@i+1
end