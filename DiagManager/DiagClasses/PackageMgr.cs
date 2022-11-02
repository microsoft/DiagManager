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
using System.Linq;
using System.Text;
using System.IO;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Diagnostics;
using PssdiagConfig;
using System.Net;

//using ICSharpCode.SharpZipLib.GZip;
//using ICSharpCode.SharpZipLib.Tar;


namespace PssdiagConfig
{
    public class PackageMgr
    {
        UserSetting m_userchoice;
        string m_DestFullFileName;
        string m_DestPathNameOnly;
        string m_DestFileNameOnly;
        string m_tempDirectory = Globals.BuildDir;
        string m_Server_Instance;
        string m_ServerName;
        string m_Instance; 
        string m_output_prefix;
        string m_output_instance_prefix;
        string m_internal_output_instance_prefix;
        string m_AppName;

        //static string KillSQL = "set nocount on select 'kill ' + cast(session_id as varchar(20)) from sys.dm_exec_sessions where host_name='pssdiag'";
        static string SqlCmdTemplate = "SQLCMD.exe -S{0} -E -Hpssdiag -w4000 -o\"{1}\" {2}";
        static string StartTraceTemplate = @"EXEC tempdb.dbo.sp_trace13 'ON', @Events='{0}',@AppName='{1}',@FileName='{2}', @MaxFileSize={3}, @FileCount={4}";
        static string StopTraceTemplate = @"EXEC tempdb.dbo.sp_trace13 'OFF',@AppName='{0}',@TraceName='tsqltrace'";
        string m_input_prefix = @"%launchdir%\";
        string LogManName = "pssdiagperfmon";
        //start  collecterrorlog.cmd server\sql16a 1 ^> "c:\temp\pssd\out5.txt" 2>&1 ^&^&exit
        


        public PackageMgr(UserSetting userchoice, string destFullFileName)
        {
            m_userchoice = userchoice;
            m_DestFullFileName = destFullFileName;
            m_DestPathNameOnly= Path.GetDirectoryName(destFullFileName);
            m_DestFileNameOnly = Path.GetFileName(destFullFileName);
            m_ServerName = m_userchoice[Res.MachineName];
            m_Instance = m_userchoice[Res.InstanceName];

            //when user chose "." for server name, replace this with %servername% variable that will be assigned in the batch file
            if (m_ServerName == ".")
            {
                m_ServerName = "%servername%";
            }

            //build the default or named instances string
            if (m_Instance.ToUpper() != "MSSQLSERVER")
            {
                m_Server_Instance = m_ServerName + @"\" + m_Instance;
            }
            else
            {
                m_Server_Instance = m_Instance;
            }


            m_output_prefix = @"%launchdir%output\" + m_ServerName;
            m_output_instance_prefix = @"%launchdir%output\" + m_ServerName + "_" + m_Instance;
            m_internal_output_instance_prefix = @"%launchdir%output\internal\" + m_ServerName + "_" + m_Instance;
            m_AppName = "SQLDIAG_" + m_ServerName + "_" +  m_Instance;

        }

        private string ReplaceToken (string taskName, string taskCmd)
        {
            
            bool IsInstanceSpecific = false;
            if (taskCmd.ToLower().Contains("%server_instance%"))
            {
                IsInstanceSpecific = true;
            }

            string OutputName = m_output_prefix  + "_" + taskName;
            string OutputInternalName = m_output_instance_prefix  + "_" + taskName;
            if (IsInstanceSpecific==true)
            {
               OutputName = m_userchoice[Res.MachineName] + "_" + m_userchoice[Res.InstanceName] + "_" + taskName;
               OutputInternalName = m_output_instance_prefix +  "_" + taskName;
            }

            return taskCmd.Replace(" %server_instance%", m_Server_Instance).Replace("%output_name%", OutputName).Replace("%output_internal_name%", OutputInternalName);
        }


        private void MakeManualBatchFiles()
        {


            if (m_Instance == "*")
            {
                return;
            }

            StreamWriter ManualStart = File.CreateText(m_tempDirectory + @"\ManualStart.txt");
            StreamWriter ManualStop = File.CreateText(m_tempDirectory + @"\ManualStop.txt");

            ManualStart.WriteLine("REM PURPOSE: This file is for cases where execution of PSSDIAG does not work for some reason. It allows you to manually collect some base information.");
            ManualStart.WriteLine("REM This includes Perfmon, Perfstat scripts and some other configuration information for the instance (sp_configure, sys.databses, etc)");
            ManualStart.WriteLine("REM INSTRUCTIONS:");
            ManualStart.WriteLine("REM 1. Rename the file to ManualStart.cmd (change the extension)");
            ManualStart.WriteLine("REM 2. Rename the ManualStop.txt to ManualStop.cmd (change the extension)");
            ManualStart.WriteLine("REM 3. Execute from a Command Prompt by running ManualStart.cmd");
            ManualStart.WriteLine("REM 4. When ready to stop, execute ManualStop.cmd from another Command Prompt window");
            ManualStart.WriteLine("REM 5. Find the collected data in the \\Output folder");
            ManualStart.WriteLine("");

            ManualStop.WriteLine("REM PURPOSE: This file is for cases where execution of PSSDIAG does not work for some reason. This file stops manual collection of base information.");
            ManualStop.WriteLine("REM INSTRUCTIONS:");
            ManualStop.WriteLine("REM 1. Rename the file to ManualStop.cmd (change the extension)");
            ManualStop.WriteLine("REM 2. When ready to stop collection, execute ManualStop.cmd from a new Command Prompt window");
            ManualStop.WriteLine("REM 3. Find the collected data in the \\Output folder");
            ManualStop.WriteLine("");



            ManualStart.WriteLine("setlocal ENABLEEXTENSIONS");
            ManualStart.WriteLine("set LaunchDir=%~dp0");
            ManualStart.WriteLine("set servername=%computername%");


            ManualStop.WriteLine("setlocal ENABLEEXTENSIONS");
            ManualStop.WriteLine("set LaunchDir=%~dp0");
            ManualStop.WriteLine("set servername=%computername%");

            ManualStart.WriteLine("md \"%LaunchDir%\\output\\internal\"");

            //need to test on a cluster and see if . does anything for VNN
            //TODO: NEED TO EXCLUDE FROM HASH CALCULATION



            ManualStart.WriteLine(string.Format(SqlCmdTemplate, m_Server_Instance, m_output_instance_prefix + "_msdiagprocs.out", "-i\"" + m_input_prefix + "msdiagprocs.sql" + "\""));

            //make manual profile collector
            if (m_userchoice[Res.CollectProfiler] == "true")
            { 
                string strTraceEvents = "";
                foreach (DiagItem diagItem in m_userchoice.ProfilerCategoryList.GetCheckedDiagItemList())
                {
                    TraceEvent evt = diagItem as TraceEvent;
                    if (!string.IsNullOrEmpty(strTraceEvents))
                    {
                        strTraceEvents += ",";
                    }
                    strTraceEvents += evt.Id.ToString();
                }
                string MaxFileSize = m_userchoice[Res.ProfilerMaxFileSize];
                string FileCount = m_userchoice[Res.ProfilerFileCount];
                
                string strTraceStartQuery = string.Format(StartTraceTemplate, strTraceEvents, m_AppName, m_output_instance_prefix + "_sp_trace", MaxFileSize, FileCount);
                string strTraceStopQuery = string.Format(StopTraceTemplate, m_AppName);
                ManualStart.WriteLine("rem starting profiler trace");
                string cmd = string.Format(SqlCmdTemplate, m_Server_Instance, m_internal_output_instance_prefix + "_sp_trace_start.out", "-Q\"" + strTraceStartQuery + "\"");
                ManualStart.WriteLine(cmd);
                ManualStop.WriteLine("rem stoping profile trace");
                cmd = string.Format(SqlCmdTemplate, m_Server_Instance, m_internal_output_instance_prefix + "_sp_trace_stop.out", "-Q\"" + strTraceStopQuery + "\"");
                ManualStop.WriteLine(cmd);
            }

            //make a copy
            List<DiagCategory> checkedCategories = new List<DiagCategory>();
            foreach (DiagCategory cat in m_userchoice.CustomDiagCategoryList.GetCheckedCategoryList())
            {
                checkedCategories.Add(cat);
            }


            // if SQL Xevent needs to be captured
            if (m_userchoice[Res.CollectXEvent] == "true")
            {
                DiagCategory XEventGroup = DiagFactory.GetCustomGroup(null, @"Templates\CustomDiagnostics_Xevent.xml");
                //need to manuall handle taskname "Add File Target" for file size and file count
                DiagItem taskItem = XEventGroup.DiagEventList.Find(x => x.Name == "Add File Target"); // for CustomTask Name is the same as TaskName
                CustomTask task = taskItem as CustomTask;
                task.Cmd = task.Cmd.Replace("1024x", m_userchoice[Res.XEventMaxFileSize]).Replace("5x", m_userchoice[Res.XEventFileCount]);

                XEventGroup.Name = "XEvent";
                //manually check events for special handling
                XEventGroup.CheckEvents(true);
                checkedCategories.Add(XEventGroup);
            }



            foreach (DiagCategory cat in checkedCategories)
            {
                ManualStart.WriteLine("rem group: " + cat.Name);
                foreach (DiagItem item in cat.GetCheckedEventList())
                {
                    CustomTask task = item as CustomTask;
                    //currently do not handle anything other than TSQL script
                    if (null == task )
                    {
                        continue;
                    }
                    if (task.Type.ToUpper() == "TSQL_SCRIPT")
                    {
                        string cmd = "Start ";
                        if (task.GroupName == "XEvent")
                        {
                            cmd = ""; //make sure xevent is last group
                        }
                            
                        cmd = cmd + string.Format(SqlCmdTemplate, m_Server_Instance, m_output_instance_prefix + "_" + task.Cmd + ".out", "-i\"" + m_input_prefix + task.Cmd +"\"" );
                        if (task.Point.ToUpper()=="STARTUP")
                        {
                            ManualStart.WriteLine(cmd);

                        }
                        else
                        {
                            ManualStop.WriteLine(cmd);

                        }
                    
                    }
                  /*
                  //various issues exists for batch files. 
                    else if (task.Type.ToUpper() =="UTILITY")
                    {
                        // working example
                        //start  collecterrorlog.cmd jackli2014\sql16a 1 ^> "c:\temp\pssd\out5.txt" 2>&1 ^&^&exit
                        //
                        string cmd = "start " +  ReplaceToken(task.Name, task.Cmd);
                        cmd = cmd.Replace(">", "^>").Replace("2^>&1", "2>&1");
                        cmd = cmd + " &exit";
                        if (task.Point.ToUpper() == "STARTUP")
                        {
                            ManualStart.WriteLine(cmd);
                        }
                        else
                        {
                            ManualStop.WriteLine(cmd);
                        }

                        
                    }*/
                    else if (task.Type.ToUpper() == "TSQL_COMMAND")
                    {
                        string cmd = "Start ";


                        if (task.GroupName == "XEvent")
                        {
                            cmd = ""; // can do this because it's the last event


                        }
                        
                        cmd =cmd + string.Format(SqlCmdTemplate, m_Server_Instance, m_output_instance_prefix + "_" + task.TaskName + ".out", "-Q\"" + task.Cmd + "\"");
                        cmd = cmd.Replace(@"%output_path%%server%_%instance%", m_output_instance_prefix);

                        if (task.Point.ToUpper() == "STARTUP")
                        {
                            ManualStart.WriteLine(cmd);

                        }
                        else
                        {
                            ManualStop.WriteLine(cmd);

                        }

                    }
                    else
                    {
                        Logger.LogInfo("Manual run hasnot been implemented for task type " + task.Type);
                    }



                    //task.Cmd


                }
            }

            ManualStart.WriteLine("rem starting Perfmon");

            ManualStart.WriteLine(string.Format("logman stop {0}", LogManName));
            ManualStart.WriteLine(string.Format("logman delete {0}", LogManName));
            
            ManualStart.WriteLine(string.Format("logman CREATE COUNTER -n {0} -s {1} -cf {2} -f bin -si 00:00:15 -o {3} -ow ", LogManName, m_userchoice[Res.MachineName], "LogmanConfig.txt", @"output\pssdiag.blg" ));

            ManualStart.WriteLine(string.Format("logman start {0} ", LogManName)); 


            ManualStop.WriteLine(string.Format("logman stop {0}", LogManName));

             ManualStop.WriteLine(string.Format(SqlCmdTemplate, m_Server_Instance, m_output_instance_prefix + "_kill.out", "-Q tempdb.dbo.sp_killpssdiagSessions"));
            
            //logman CREATE COUNTER -n SQLServer -s AlwaysOnN1  -cf C:\dsefiles\dse_counters.txt -f bin -si 00:00:15 -o C:\dsefiles\SQL.blg


            ManualStart.Flush();
            ManualStart.Close();
            ManualStop.Flush();
            ManualStop.Close();

        }

        private void MakeLogmanConfigFile()
        {
            StreamWriter logmanWriter = File.CreateText(m_tempDirectory + @"\LogmanConfig.txt");
            string MachineName = m_userchoice [Res.MachineName];
            string InstanceName = m_userchoice[Res.InstanceName];

            string prefix = @"\SQLServer";
            //no point of doing this
            if (InstanceName.ToUpper() != "MSSQLSERVER")
            {
                prefix = "MSSQL$" + InstanceName;

            }



            foreach (DiagCategory cat in m_userchoice.PerfmonCategoryList)
            {
                string temp = cat.Name.Replace("MSSQL$%s", prefix);
                logmanWriter.WriteLine(temp+@"\*");
                
                
            }

            logmanWriter.Flush();
            logmanWriter.Close();

            
        }
        private void CopyAllFiles()
        {
            string FinalOutputFolder = m_userchoice[Res.OutputFolder];
            

            ConfigFileMgrEx configMgr = new ConfigFileMgrEx(m_userchoice);

            //clear tempDirectory
            Globals.DeleteDir(m_tempDirectory);

            MakeLogmanConfigFile();
            MakeManualBatchFiles();

            //generate XEvent script file
            StreamWriter srXEventFile = File.CreateText(m_tempDirectory + @"\pssdiag_xevent.sql");
            srXEventFile.Write(m_userchoice.XEventCategoryList.GetCheckedDiagItemList().GetSQLScript());
            srXEventFile.Flush();
            srXEventFile.Close();

            //pssdiag.xml
            configMgr.SaveConfig(m_tempDirectory + @"\pssdiag.xml");


            // copy custom diagnostics files 

            string srcGroup;
            string srcFileToCopy;

            //get the full list of custom diagnostics
            List<DiagCategory> fullCustomDiagList = m_userchoice.CustomDiagCategoryList.GetFullCustomDiagsList();

            //go through the list to determine which ones are fully selected and which partially
            foreach (DiagCategory custGroup in fullCustomDiagList)
            {
                //if the entire custom group is selected (all task boxes checked) get all files from there
                if (custGroup.IsChecked == true)
                {
                    srcGroup = Globals.ExePath + @"\CustomDiagnostics\" + custGroup.Name;
                    Globals.CopyDir(srcGroup, m_tempDirectory);
                    Globals.CopyDir(srcGroup + @"\" + m_userchoice[Res.Platform], m_tempDirectory);

                }

                //If entire custom collector is not checked, it is possible that individual tasks within it are selected.
                //Check for individual tasks and copy the files for the entire customer collect so this task can be executed.
                //Since we don't maintain a list of file names associated with each task, it is not possible to copy
                //just the file name for that task. But the pssdiag.xml is configured for the execution of 
                //only the selected task. Once the loop finds one selected task, we can leave the loop and move on to next group

                else
                {
                    foreach(DiagItem customTask in custGroup.DiagEventList)
                    {
                        if (customTask.IsChecked)
                        {
                            srcGroup = Globals.ExePath + @"\CustomDiagnostics\" + custGroup.Name;
                            Globals.CopyDir(srcGroup, m_tempDirectory);
                            Globals.CopyDir(srcGroup + @"\" + m_userchoice[Res.Platform], m_tempDirectory);
                            break;
                        }
                        
                    }
                }


            }

            //Copy Pristine folder into destination

            Globals.CopyDir(Globals.ExePath + @"\Pristine", m_tempDirectory);
            Globals.CopyDir(Globals.ExePath + @"\Pristine\" + m_userchoice[Res.Platform], m_tempDirectory);
            Globals.CopyDir(Globals.ExePath + @"\Pristine\" + m_userchoice[Res.Version] + @"\"+ m_userchoice[Res.Platform], m_tempDirectory);
            string customdiagxml = m_tempDirectory + @"\CustomDiag.XML";

            //these are copied over from custom diag folder. we don't need it
            if (File.Exists(customdiagxml))
            {
                File.Delete(customdiagxml);
            }

        }

        public void MakeZip()
        {
            CopyAllFiles();

            if (File.Exists(m_DestFullFileName))
            {
                File.Delete(m_DestFullFileName);
            }

            ZipFile.CreateFromDirectory(m_tempDirectory, m_DestFullFileName);
            //MakeTar(m_tempDirectory, m_DestFullFileName+".tar");
            
        }

        //this was intended for possible TAR file use, but we don't need it or was ever used. This was intended to use a Nuget package ICSharpCode.SharpZipLib;
        //private void MakeTar(string SourceDirectoryName, string TarFileName)
        //{
        //    Stream oStream = File.Create(TarFileName);
        //    string[] files = Directory.GetFiles(SourceDirectoryName);
        //    TarOutputStream OutputStream = new TarOutputStream(oStream);

        //    foreach (string file in files)
        //    {
        //        using (Stream inputStream = File.OpenRead(file))
        //        {
        //            string tarName = Path.GetFileName(file);
        //            long fileSize = inputStream.Length;
        //            TarEntry entry = TarEntry.CreateTarEntry(tarName);
        //            entry.Size = inputStream.Length;
        //            OutputStream.PutNextEntry(entry);

        //            byte[] Buffer = new byte[1024 * 1024];
        //            while (true)
        //            {
        //                int bytesRead = inputStream.Read(Buffer, 0, Buffer.Length);
        //                if (bytesRead <= 0)
        //                {
        //                    break;
        //                }
        //                OutputStream.Write(Buffer, 0, bytesRead);
        //            }
        //        }
        //        OutputStream.CloseEntry();
        //    }

        //    OutputStream.Close();

        //}

        public bool ComputeFileHash (string filepath, out string hashString)
        {
            hashString = "";

            if (File.Exists(filepath))
            {
                // Initialize a SHA256 hash object.
                using (SHA512 mySHA512 = SHA512.Create())
                {
                    // Compute and print the hash values for each file in directory.
                    try
                    {
                        // Create a fileStream for the file.
                        FileStream fileStream = File.OpenRead(filepath);
                        // Be sure it's positioned to the beginning of the stream.
                        fileStream.Position = 0;
                        // Compute the hash of the fileStream.
                        byte[] hashValue = mySHA512.ComputeHash(fileStream);

                        //convert the byte value to a string and remove "-" inside of the string
                        hashString += BitConverter.ToString(hashValue).Replace("-", ""); ;

                        Logger.LogInfo($"The file hash value for '{filepath}' is: {hashString}");

                        // Close the file.
                        fileStream.Close();
                    }
                    catch (IOException e)
                    {
                        Logger.LogInfo($"I/O Exception: {e.Message}");
                        hashString = "I/O Exception: " + e.Message;
                        return false;
                    }
                    catch (UnauthorizedAccessException e)
                    {
                        Logger.LogInfo($"Access Exception: {e.Message}");
                        hashString = "Access Exception: " + e.Message;
                        return false;
                    }
                }
            }

            else  //file does not exist
            {
                Logger.LogInfo("The file specified could not be found.");
                hashString = "Failed to create hash because .zip file was not found. Examine the log for details";
            }

            return true;
        } //end ComputeFileHash


        public void PrepareEmail(string hashString, string filename)
        {
            try
            {
                using (Process myProcess = new Process())
                {




                    //construct the email body
                    string emailBodyHello = "Hello, " + Environment.NewLine + Environment.NewLine + "Please follow these steps to run a PSSDIAG package:" + Environment.NewLine + Environment.NewLine +
                                            "1. Download the " + filename + Environment.NewLine + Environment.NewLine;

                    string emailBodyInstr = "2. You can optionally verify the downloaded file by computing a SHA512 hash. " + Environment.NewLine + Environment.NewLine +
                                            "   a. Run this command in a Windows Command Prompt to compute a SHA512 hash on it " + Environment.NewLine + Environment.NewLine;

                    string emailBodyCertU = "       certutil -hashfile " + filename + " SHA512 " + Environment.NewLine + Environment.NewLine;
                    string emailBodyHash =  "   b. Compare result to this: " + ((hashString == null) ? "NULL" : hashString) + Environment.NewLine + Environment.NewLine + 
                                            "3. Follow these instructions to run: https://aka.ms/run-pssdiag" + Environment.NewLine;


                    string entireEmail = emailBodyHello + emailBodyInstr + emailBodyCertU + emailBodyHash;


                    //append mailto:?body string to the email body so it automatically triggers a new email
                    string encodedEmail = @"mailto:?body=" + WebUtility.UrlEncode(entireEmail);

                    //since UrlEncode replaces spaces with + sings, but Outlook/email clients use %20 as a space, we need to replace one with the other
                    encodedEmail = encodedEmail.Replace("+", "%20");


                    myProcess.StartInfo.FileName = encodedEmail;
                    //myProcess.StartInfo.FileName = @"mailto:?body=Hello%2C%0A%0APlease%20find%20PSSDIAG%20instructions%20below%3A%0A%0A1.%20Download%20the%20" + filename + @"%20%0A2.%20You%20can%20verify%20the%20downloaded%20file%20by%20computing%20a%20SHA512%20hash.%20See%20the%20instructions%20below%20%0A3.%20Follow%20these%20instructions%20to%20run%3A%20https%3A%2F%2Faka.ms%2Frun-pssdiag%20%0A%0A%0ATo%20verify%20the%20downloaded%20file%3A%0A1.%20Run%20this%20command%20in%20a%20Windows%20Command%20Prompt%20to%20compute%20a%20SHA512%20hash%20on%20it%0A%0A%20%20certutil%20-hashfile%20" + filename + " %20SHA512%20%0A%0A2.%20%20Compare%20result%20to%20this%3A%20%20" + hashString;

                    myProcess.Start();
                }
            }
            catch (Exception e)
            {
                Logger.LogInfo($"Preparing email failed with: {e.Message}");
            }

        }
        
    }//class end
} //namespace
