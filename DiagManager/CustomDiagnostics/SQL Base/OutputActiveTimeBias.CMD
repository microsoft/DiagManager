@ECHO OFF
SETLOCAL
SET SRV=%1
IF "%SRV%"=="" SET SRV=%COMPUTERNAME%
ECHO TimeZoneInformation for %SRV%
ECHO Property          Value
ECHO ----------------- -------------------------------------------------
CALL GetRegValue.CMD "\\%SRV%\HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" "StandardName" > NUL
ECHO StandardName      %GETREG_RESULT%
CALL GetRegValue.CMD "\\%SRV%\HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" "DaylightName" > NUL
ECHO DaylightName      %GETREG_RESULT%
CALL GetRegValue.CMD "\\%SRV%\HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" "ActiveTimeBias" > NUL
SET /A ATB=%GETREG_RESULT% 
ECHO ActiveTimeBias    %ATB% (minutes prior to GMT)
ENDLOCAL
