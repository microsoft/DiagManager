// class defintions have to happen earlier
function CHeader()
{
    this.C = padString ("", 2, "-");
    this.LogDate = padString("", 23, "-");
    this.ProcessInfo=padString("", 15, "-");
    this.Text = padString("",2048, "-");
}

CHeader.prototype.PrintHeader = function()
{
   
    WriteLine ( padString ("C", this.C.length, " " ) + " " +
                padString ("LogDate", this.LogDate.length, " ") + " " + 
                padString ("ProcessInfo" ,this.ProcessInfo.length, " ") + " " +
                padString ("Text", this.Text.length, " ")
                );
   WriteLine (this.C + " " + this.LogDate + " " + this.ProcessInfo + " " + this.Text);
                
}



var objArgs = WScript.Arguments;
var ServerName, AuthMode, UserName, Password;



//printArgs(objArgs)

if (objArgs.length == 4)  //sql authentication mode
{
	ServerName= objArgs(0);
	AuthMode=parseInt(objArgs(1));
	UserName=objArgs(2);
	Password=objArgs(3);
	

}
else  // windows authentication
{
	ServerName= objArgs(0);
	AuthMode=parseInt(objArgs(1));
	

}

if (AuthMode != 1 && objArgs.length<4)
{
	WriteLine ("you provided sql authentication but didn't provide enough login info");
	WScript.quit(-1);
}





var objConn= WScript.CreateObject("ADODB.Connection");
var connString = "Provider=sqloledb; Data Source=" + ServerName + ";";
if (AuthMode == 1)
	connString += "Integrated Security=SSPI;";
else
	connString += "USER ID=" + UserName + ";Password=" + Password;







var ver = getVersion(connString);

for (var eCount=0;eCount <7;eCount++)
{
	try
	{
		objConn.Open (connString); 
		WriteLine("");
		WriteLine("");
		WriteLine("Exporting Errorlog: " + eCount);
		WriteLine ( "errorlog" + (eCount>0?"."+eCount : "") + "            -- ERRORLOG ROWSET --" );
		var sql = "exec master.dbo.xp_readerrorlog ";
		if (eCount > 0)
		    sql += eCount;
		    
		var RS = objConn.Execute (  sql );
		
		var arr;
		if (ver >= 9)
			 process2005ErrorLog(RS);
		else
			 Split2000ErrorLog(RS);	

	}
	catch (ex)
	{
		WriteLine (" ");
		WriteLine (GetExceptionInfo (ex));
	
	}

	finally
	{
		objConn.close();
	}
	


}






function getVersion(conString)
{
	var objMyConn = WScript.CreateObject("ADODB.Connection");
	objMyConn.Open(conString);
	var rs = objMyConn.Execute ("select serverproperty ('ProductVersion')");
	rs.MoveFirst();
	var strVersion = rs(0) + "";
	var re = /^[0-9]+/;
	
	var intVersion=parseInt(	strVersion.match(re)  + "");
	
	
	rs.close();
	objMyConn.close();
	return intVersion;
}

function printArray(arrErrorLog)
{
	var myArr = arrErrorLog;
	var lDateLength = myArr[1][0].length;
	var lProcessInfoLength=myArr[1][1].length;
	var j=0;
	for ( j = 0; j<arrErrorLog.length; j++)
	{
		WScript.echo (padString (myArr[j][0],lDateLength, " ")  + " " +  padString (myArr[j][1],lProcessInfoLength, " ") + " " +  myArr[j][2] );
	}

	WriteLine ("");
	var msg = "(" + j + " row(s) affected)";
	WriteLine(msg );
}

function process2005ErrorLog(objRS)
{
	var RS = objRS;
    var header = new CHeader();
	var curDateTime = "1900-01-01 12:00:00.01";
	var i = 0;

    header.PrintHeader();
    var curProcessInfo="";

	RS.MoveFirst();
	while (!RS.EOF)
	{

		/*
		var dt =Date.parse(RS(0)  );
		var dt2 = new Date(dt);

		col[0] = FormatDate(dt2)  + "";
		*/
		
        curDateTime = FormatDate_Ex (RS(0));
		curProcessInfo = RS(1) + "";
		var ErrorText =trim(RS(2) + "");
        printRecord (ErrorText, curDateTime, curProcessInfo, "");
		
		RS.MoveNext();
	
	}


	RS.close();
    return;


	
}

function FormatDate_Ex (obj)
{
    var myObj = obj ;
    var ticks =Date.parse(obj  );
	var dt = new Date(ticks );
    var milliseconds = ticks % 1000;
	return FormatDate (dt); //+ "." + milliseconds;

    
}
function FormatDate(dt)
{

	var myDate = dt;
	var year = myDate.getFullYear();
	var month = myDate.getMonth();
	var day	 = myDate.getDay();
	var hour = myDate.getHours();
	var min = myDate.getMinutes();
	var sec = myDate.getSeconds();
//	var mill = myDate.getMilliseconds();

	return year + "-" + (month>=10? month : "0" + month) + "-" + (day>=10? day : "0" + day) + " " +
		(hour >= 10? ""+hour : "0" + hour ) +":" + (min >= 10 ? ""+min: "0" + min) + ":"+ (sec >= 10 ? ""+sec : "0" + sec) ;
		
}
function Split2000ErrorLog(objRS)
{

	var header = new CHeader;
	header.PrintHeader();
	
	var RS = objRS;
	var arrRows = new Array();
	var curDateTime = "1900-01-01 12:00:00.01";
	var curProcessInfo = "server";
	var i = 0;
	var maxTextLength=0;


	


	RS.MoveFirst();
	while (!RS.EOF)
	{
		var strDateTime, strProcessInfo, strErrorText;
		var str= (RS(0)) +"";
		var arrColumns = new Array();
	
		var re_datetime= /^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{2}/;
		var re_datetime_serverspid=/^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{2}\s+\w+\s+/;

		strDateTime = str.match (re_datetime) ;

		//handle some lines that don't have datetime
		var cont = "";
		if (strDateTime == null || strDateTime == "")
		{
			strDateTime = curDateTime;
			strProcessInfo = curProcessInfo;
			strErrorText = str;
			cont="1";

		}
		else
		{
			strDateTime = strDateTime + "";
			strErrorText = str.replace(re_datetime_serverspid, RegExp.$1, "") + "";
			strErrorText = trim (strErrorText);
			var strTemp = trim(str.match(re_datetime_serverspid) + "");
			strProcessInfo = trim(strTemp.replace(re_datetime, RegExp.$1, "") + "");
			curDateTime = strDateTime;
			curProcessInfo=strProcessInfo;
			
	
		}
	

		printRecord (strErrorText, curDateTime, curProcessInfo, cont);
		
		RS.MoveNext();


	}
	
	
	RS.close();
	return arrRows;

}

function printRecord(strText, curDateTime, curProcessInfo, continuation)
{
    var head = new CHeader();
    var strTemp = strText + "";//change it to string
    var re=/%0D|%0A/g;
    var esc = escape (strTemp) + "";
    var arr = esc.split (re);
    for (var i = 0; i< arr.length; i++)
    {
        var cont = continuation;
        if (i > 0)
            cont = "1";
        WriteLine (padString (cont, head.C.length, " " ) + " " +
                    padString (curDateTime, head.LogDate.length, " ") + " " +
                    padString (curProcessInfo, head.ProcessInfo.length, " ") + " " +
                    padString (unescape (arr[i]) )
                    );
        
    }
}

function cleanup(str)
{
	var strTemp =  str + "";
	var re=/%0D|%0A/g;
	var esc = escape (strTemp) + "";

	return unescape (esc.replace(re, ""));

}
function padString(str, fixedlength, strChar)
{
	var strTemp = str + "";
	var paddedString;
	if (strTemp.length== fixedlength)
	{
		paddedString=str;
	}
	else if (strTemp.length > fixedlength)
	{
		paddedString = strTemp.substring (0,fixedlength); 		
	}
	else
	{
		var spaces="";
		for (var i = 0; i<(fixedlength-strTemp.length) ; i++)
		{
			spaces += strChar;
		}		
		paddedString = strTemp + spaces;
	}

	return paddedString ;
}
//returns a trimmed function

function trim(strOriginal)
{

	return strOriginal.replace(/^\s+|\s+$/g,"") + "";
}

function WriteLine (strMsg) {

    //igore 0 rows affected affected message
    if (strMsg.toString().indexOf("0 rows affected") >= 0) {
        return;
    }
    
	WScript.echo (strMsg);
}



function GetExceptionInfo(ex)
{
	var r = "";
	for (var p in ex)
				r += p + ": "  + ex[p] + "\t" ;
	return r;

	
}

function printArgs(objArgs)
{
	for (var i=0; i< objArgs.length; i++)
	{
		WriteLine ("arg: " + objArgs(i));		
	}
}






