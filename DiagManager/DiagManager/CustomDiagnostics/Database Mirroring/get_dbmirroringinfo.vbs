Option Explicit

' Expected Params: 
'    sql_server_name
'    output_dir

'Save params
Dim SqlServer 'As String
Dim SqlLogin 'As String
Dim SqlPassword 'As String
Dim OutputDir 'As String

Dim cn 'As ADODB.Connection
Dim cnstr 'As String
Dim rs 'As ADODB.Recordset

SqlServer = Replace (WScript.Arguments (0), """", "")
OutputDir = Replace (WScript.Arguments (1), """", "")

WScript.Echo "SqlServer = " & SqlServer
WScript.Echo "OutputDir = " & OutputDir
WScript.Echo ""



Set cn = CreateObject ("ADODB.Connection")
cnstr = "Provider=SQLOLEDB;APP=Get_DBMirroringInfo.VBS;Server=" & SqlServer _
  & ";Integrated Security=SSPI;Persist Security Info=False;Trusted_Connection=Yes;"
WScript.Echo "Using connection string: "
WScript.Echo "  " & cnstr
WScript.Echo ""

' First, dump mirroring info from the server we are connected to.
WScript.Echo "Dumping db mirroring config info from local server (" & SqlServer & ")..."
Call GetMirroringInfo (SqlServer, OutputDir)

cn.Open cnstr

Set rs = cn.Execute ("select mirroring_partner_instance,  [mirroring_witness_name]=case when isnumeric(substring(mirroring_witness_name,7,1)) = 1 or charindex('.',mirroring_witness_name) = 0  then  substring(mirroring_witness_name,7,charindex(':',mirroring_witness_name,5)-7)  else substring(mirroring_witness_name,7,charindex('.',mirroring_witness_name,5)-7) end  from sys.database_mirroring where mirroring_guid is not null")

Do While Not rs.EOF
  ' For each db mirroring pair, dump first the partner's db mirroring info
  WScript.Echo "Dumping db mirroring config info from mirroring_partner_instance (" & rs("mirroring_partner_instance") & ")..."
  Call GetMirroringInfo (rs("mirroring_partner_instance"), OutputDir)
  ' Then dump info from the witness (if one exists) 
  If Not rs("mirroring_witness_name")="" Then 
    WScript.Echo "Dumping db mirroring config info from mirroring_witness (" & rs("mirroring_witness_name") & ")..."
    Call GetMirroringInfo (rs("mirroring_witness_name"), OutputDir)
  End If
  rs.MoveNext
Loop
rs.Close
cn.Close




Sub GetMirroringInfo (SqlServer, OutputDir) 
Dim cmdline 'As String
Dim oWSHS 'As WScript.Shell
Dim o

cmdline = "cmd /Csqlcmd.exe -l60 -E -w3000 -S" & SqlServer & " -i get_dbmirroringinfo.sql > " _
  & """" & OutputDir & UCase (Replace (SqlServer, "\", "_")) & "_DB_MIRRORING_INFO.OUT"" 2>&1"
WScript.Echo "CmdLine: " & cmdline
Set oWSHS = CreateObject ("WScript.Shell")
o = oWSHS.Run (cmdline, 0, True)
'oWSHS.Exec cmdline
WScript.Echo ""
End Sub
