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
using System.IO;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Formatters.Binary;
using System.Xml;
using System.Xml.XPath;
using System.Diagnostics;
using System.Windows.Forms;


namespace PssdiagConfig
{

    public static class Globals
    {

        public static bool ExceptionEncountered = false;
        

        // public static PlatVersionTracker PVTracker;

        public static Preferences UserPreferences;
        //public static fmDiagManager MainForm;
        public static bool UseCabarc()
        {
            if (File.Exists("cabarc.exe") && File.Exists("extract.exe"))
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        public static Process LaunchApp(string Cmd, string Params, string WorkingDir, bool bWait, bool HideWindow)
        {
            ProcessStartInfo pi = new ProcessStartInfo(Cmd, Params);
            Debug.WriteLine("[" + WorkingDir + "] " + Cmd + " " + Params);
            Logger.LogInfo("Starting App " + "[" + WorkingDir + "] " + Cmd + " " + Params);
            pi.WorkingDirectory = WorkingDir;
            if (HideWindow)
            {
                pi.WindowStyle = ProcessWindowStyle.Hidden;
                pi.CreateNoWindow = true;
            }
            else
            {
                pi.WindowStyle = ProcessWindowStyle.Normal;
                pi.CreateNoWindow = false;
            }
            Process p = Process.Start(pi);
            if (bWait)
                p.WaitForExit();
            return p;
        }

        public static void DeleteDir (string dirPath)
        {
            DirectoryInfo dirinfo = new DirectoryInfo(dirPath);
            foreach (FileInfo file in dirinfo.GetFiles())
            {
                if (file.Name.ToLower() != "create.dir")
                { 
                    file.Delete();
                }
            }
        }
        public static void CopyDir (string sourcedir, string destdir)
        {
            if (!Directory.Exists(sourcedir))
                return;

            foreach (var srcFile in Directory.GetFiles(sourcedir))
            {
                Logger.LogMessage(string.Format("Copying {0}", srcFile), LogLevel.INFO);
                File.Copy(srcFile, srcFile.Replace(sourcedir, destdir), true);
            }

        }
        //public static XMgr XeventManager;

        public static string ident(int num)
        {
            string temp = "";
            for (int i = 0; i < num; i++)
            {
                temp += "\t";
            }
            return temp;
        }

        public static string PssdiagAppData
        { 
            get
            {
                //string temp = Application.UserAppDataPath;
                string temp = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
                string AppData = temp + @"\Pssdiag";
                if (!System.IO.Directory.Exists (AppData))
                {
                    System.IO.Directory.CreateDirectory (AppData);
                }

                return AppData;

            }
        }

        public static string ExePath
        {
            get
            {
                return Directory.GetParent(System.Reflection.Assembly.GetExecutingAssembly().FullName).ToString();
            }
        }

        public static string DiagMgrVersion
        {
            get
            {
                FileVersionInfo myFileVersionInfo = FileVersionInfo.GetVersionInfo(ExePath+@"\DiagManager.exe");
                FileSystemInfo fsi = new FileInfo(ExePath);

                return myFileVersionInfo.FileVersion + " Build Date:  " +  fsi.LastWriteTime.ToShortDateString();
            }

        }

        public static string LogDir
        {
            get
            {
                string DiagMgrLogPath = Environment.ExpandEnvironmentVariables("%TEMP%") + @"\DiagManager";
                if (!Directory.Exists(DiagMgrLogPath))
                {
                    Directory.CreateDirectory(DiagMgrLogPath);
                }
                return DiagMgrLogPath;

            }

        }
        
        public static string BuildDir
        {
            get
            {
                string temp = Path.GetTempPath() + @"\PssdiagBuild";
                if (!System.IO.Directory.Exists(temp))
                {
                    System.IO.Directory.CreateDirectory(temp);
                }

                return temp;

            }
        }
        
        public static string LB = "\r\n";


    }

    public static class Util
    {
        public static XPathNodeIterator GetXPathIterator (string XmlText, string SelectText)
        { 
        //"<event package=\"sqlserver\" name=\"parallel_scan_range_returned\" version=\"11\" general=\"false\" detail=\"false\" replay=\"false\" />"
            TextReader reader = new StringReader(XmlText);
            XPathDocument doc = new XPathDocument(reader);
            XPathNavigator rootnav = doc.CreateNavigator();
            return rootnav.Select(SelectText);
        }

        public static void PrintInfo(List<object> list)
        {
            foreach (object obj in list)
            {
                Logger.LogInfo(obj.ToString());
            }

        }

        public static string ReplaceToken(string orig)
        {
            return orig.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("'", "&apos;").Replace("\"", "&quot;");
        }

        public static void ResetAllControlsBackColor(Control control, System.Drawing.Color bkColor)
        {
            //control.BackColor = SystemColors.Control;
            control.BackColor = bkColor;
            if (control.GetType() == typeof(TextBox))
            {
                control.BackColor = System.Drawing.Color.White;
            }
            //control.ForeColor = SystemColors.ControlText;
            if (control.HasChildren)
            {
                // Recursively call this method for each child control.
                foreach (Control childControl in control.Controls)
                {
                    ResetAllControlsBackColor(childControl, bkColor);
                }
            }
        }


    }
    public static class ObjectCopier
    {
        /// <summary>
        /// Perform a deep Copy of the object.
        /// </summary>
        /// <typeparam name="T">The type of object being copied.</typeparam>
        /// <param name="source">The object instance to copy.</param>
        /// <returns>The copied object.</returns>
        public static T Clone<T>(T source)
        {
            if (!typeof(T).IsSerializable)
            {
                throw new ArgumentException("The type must be serializable.", "source");
            }

            // Don't serialize a null object, simply return the default for that object
            if (Object.ReferenceEquals(source, null))
            {
                return default(T);
            }

            IFormatter formatter = new BinaryFormatter();
            Stream stream = new MemoryStream();
            using (stream)
            {
                formatter.Serialize(stream, source);
                stream.Seek(0, SeekOrigin.Begin);
                return (T)formatter.Deserialize(stream);
            }
        }
    }


}