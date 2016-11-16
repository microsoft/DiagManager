if (WScript.Arguments.Length <> 2) then
	WScript.Echo "Usage: rtrim.vbs infile outfile"
	WScript.Quit (-1)
end if
Set fso = CreateObject("Scripting.FileSystemObject")
set File = fso.OpenTextFile (WScript.Arguments (0), 1, False)
set OutFile = fso.OpenTextFile (WScript.Arguments(1), 2, True)

  While not File.AtEndOfStream

    OutFile.WriteLine (RTrim (File.ReadLine))

  WEnd

  File.Close
OutFile.Close
