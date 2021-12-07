/**************************************************
Microsoft Public License (Ms-PL)

This license governs use of the accompanying software. If you use the software, you accept this license. If you do not accept the license, do not use the software.

1. Definitions

The terms "reproduce," "reproduction," "derivative works," and "distribution" have the same meaning here as under U.S. copyright law.

A "contribution" is the original software, or any additions or changes to the software.

A "contributor" is any person that distributes its contribution under this license.

"Licensed patents" are a contributor's patent claims that read directly on its contribution.

2. Grant of Rights

(A) Copyright Grant- Subject to the terms of this license, including the license conditions and limitations in section 3, each contributor grants you a non-exclusive, worldwide, royalty-free copyright license to reproduce its contribution, prepare derivative works of its contribution, and distribute its contribution or any derivative works that you create.

(B) Patent Grant- Subject to the terms of this license, including the license conditions and limitations in section 3, each contributor grants you a non-exclusive, worldwide, royalty-free license under its licensed patents to make, have made, use, sell, offer for sale, import, and/or otherwise dispose of its contribution in the software or derivative works of the contribution in the software.

3. Conditions and Limitations

(A) No Trademark License- This license does not grant you rights to use any contributors' name, logo, or trademarks.

(B) If you bring a patent claim against any contributor over patents that you claim are infringed by the software, your patent license from such contributor to the software ends automatically.

(C) If you distribute any portion of the software, you must retain all copyright, patent, trademark, and attribution notices that are present in the software.

(D) If you distribute any portion of the software in source code form, you may do so only under this license by including a complete copy of this license with your distribution. If you distribute any portion of the software in compiled or object code form, you may only do so under a license that complies with this license.

(E) The software is licensed "as-is." You bear the risk of using it. The contributors give no express warranties, guarantees or conditions. You may have additional consumer rights under your local laws which this license cannot change. To the extent permitted under your local laws, the contributors exclude the implied warranties of merchantability, fitness for a particular purpose and non-infringement. 

**************************************************/


using System;
using System.Collections.Generic;
using System.Text;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;
namespace PssdiagConfig
{
    public enum LogLevel
    {
        ERROR = 1,
        WARNING = 2,
        INFO = 3

    }


    public class Logger
    {
        //initialize log file
        static Logger()
        {
            DateTime dtNow = DateTime.Now;
//            string Suffix = string.Format("{0}_{1}_{2}_{3}_{4}_{5}", dtNow.Year, dtNow.Month, dtNow.Day, dtNow.Hour, dtNow.Minute, dtNow.Second);

  //          Suffix = Process.GetCurrentProcess().Id.ToString();

            Process[] localByName = Process.GetProcessesByName("DiagManager");

            string Suffix = localByName.Length.ToString();

            //File.Delete (string.Format ("{0}\\DiagManager*.log", Environment.ExpandEnvironmentVariables("%TEMP%")));
            string LogFileName = string.Format ("{0}\\DiagManager{1}.log", Globals.LogDir, Suffix);
            //MessageBox.Show(LogFileName);
            FileMode mode = FileMode.OpenOrCreate | FileMode.Append;
            if (System.IO.File.Exists(LogFileName))
            {
                System.IO.FileInfo fileInfo = new System.IO.FileInfo(LogFileName);
                if (fileInfo.Length > 1024 * 1024)
                {

                    mode = System.IO.FileMode.OpenOrCreate | System.IO.FileMode.Truncate;
                }
            }

            FileStream diagFS = new FileStream(LogFileName, mode, FileAccess.Write, FileShare.Read);

            TextWriterTraceListener myListener = new TextWriterTraceListener(diagFS);
            Trace.Listeners.Add(myListener);
            Trace.AutoFlush = true;
            Trace.WriteLine("Trace started");
            LogAppInfo();


        }
        public static void LogAppInfo()
        {
            string ProductVerNoBuildNo = Application.ProductVersion.Substring (0, Application.ProductVersion.LastIndexOf("."));

            String msg = Environment.NewLine;
            
            msg += "****************************************************************************************" + Environment.NewLine;
            msg += "*   Production Version: " + Application.ProductVersion + Environment.NewLine;
            msg += "*   Production Version without build#: " + ProductVerNoBuildNo + Environment.NewLine;
            msg += "*   Exe Path: " + Path.GetDirectoryName(Application.ExecutablePath) + Environment.NewLine;
            msg += "*   User Name: " + Environment.UserName + Environment.NewLine;
            msg += "*   User Machine: " + Environment.MachineName + Environment.NewLine;
            msg += "*   OS Version: " + Environment.OSVersion + Environment.NewLine;
            msg += "****************************************************************************************";
            LogMessage(msg, LogLevel.INFO);
        }
        public static void LogException(Exception excep)
        {
            //don't handle null parameter
            if (excep == null)
                return;

            String ExceptionMessage = String.Empty;

            Exception innerexception = excep.InnerException;
            while (innerexception != null)
            {
                ExceptionMessage += innerexception.ToString() + Environment.NewLine;
                if (innerexception.StackTrace != null)
                    ExceptionMessage += innerexception.StackTrace;
                innerexception = innerexception.InnerException;

            }
            ExceptionMessage += excep.ToString();

            if (excep.StackTrace != null)
                ExceptionMessage += excep.StackTrace;
            LogMessage(ExceptionMessage, LogLevel.ERROR);

        }
        public static void LogError(string errorMsg)
        {
            LogMessage(errorMsg, LogLevel.ERROR);
        }
        public static void LogInfo(string msg)
        {
            LogMessage(msg, LogLevel.INFO);
        }
        public static void LogMessage(String msg, LogLevel level)
        {

            Trace.WriteLine(DateTime.Now.ToString() + " : " + level.ToString() + " : " + msg + Environment.NewLine);
        }


    }
}
