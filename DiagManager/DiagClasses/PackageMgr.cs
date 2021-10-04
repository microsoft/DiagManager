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
        //start  collecterrorlog.cmd jackli2014\sql16a 1 ^> "c:\temp\pssd\out5.txt" 2>&1 ^&^&exit
        public PackageMgr(UserSetting userchoice, string destFullFileName)
        {
            m_userchoice = userchoice;
            m_DestFullFileName = destFullFileName;
            m_DestPathNameOnly= Path.GetDirectoryName(destFullFileName);
            m_DestFileNameOnly = Path.GetFileName(destFullFileName);
            m_Server_Instance = m_userchoice[Res.MachineName];
            if (m_userchoice[Res.InstanceName].ToUpper() != "MSSQLSERVER")
            {
                m_Server_Instance = m_Server_Instance + @"\" + m_userchoice[Res.InstanceName];
            }

            m_output_prefix = @"%launchdir%output\" + m_userchoice[Res.MachineName];
            m_output_instance_prefix = @"%launchdir%output\" + m_userchoice[Res.MachineName] + "_" + m_userchoice[Res.InstanceName];
            m_internal_output_instance_prefix = @"%launchdir%output\internal\" + m_userchoice[Res.MachineName] + "_" + m_userchoice[Res.InstanceName];
            m_AppName = "SQLDIAG_" + m_userchoice[Res.MachineName] + "_" +  m_userchoice[Res.InstanceName];


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


            StreamWriter ManualStart = File.CreateText(m_tempDirectory + @"\ManualStart.cmd");
            StreamWriter ManualStop = File.CreateText(m_tempDirectory + @"\ManualStop.cmd");
            ManualStart.WriteLine("setlocal ENABLEEXTENSIONS");
            ManualStart.WriteLine("set LaunchDir=%~dp0");

            ManualStop.WriteLine("setlocal ENABLEEXTENSIONS");
            ManualStop.WriteLine("set LaunchDir=%~dp0");

            ManualStart.WriteLine("md \"%LaunchDir%\\output\\internal\"");

            ManualStart.WriteLine(string.Format (SqlCmdTemplate, m_Server_Instance, m_output_instance_prefix + "_msdiagprocs.out", "-i\"" + m_input_prefix + "msdiagprocs.sql" + "\"" ));

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


            // copy custom diagnostics

            List<DiagCategory> selectedcustomDiagList = m_userchoice.CustomDiagCategoryList.GetCheckedCategoryList();


            foreach (DiagCategory cat in selectedcustomDiagList)
            {
                string src = Globals.ExePath + @"\CustomDiagnostics\" + cat.Name;
                Globals.CopyDir(src, m_tempDirectory);

                Globals.CopyDir(src + @"\" + m_userchoice[Res.Platform], m_tempDirectory);

            }


            //Copy Pristine
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


        public void PrepareEmail(string hashString)
        {
            try
            {
                using (Process myProcess = new Process())
                {
                    //myProcess.StartInfo.FileName = @"mailto:?body=Hello%0AThis is your hash%0A%3Cb%3E" + hashString + @"%3C%2Fb%3E%0A";
                    myProcess.StartInfo.FileName = @"mailto:?body=Hello%0AThis is your hash%0A%3Cb%3E" + hashString + @"%3C%2Fb%3E%20%0A%0A%0A%0A%22If%20you%20would%20like%20to%20check%20the%20hash....%0A%0Acertutil%0A%0A%0Acertutil%20-hashfile%20PATHFILE%20SHA512%0A%0A1.%0A%0A%0A%0A%0A2.%09Copy%20the%20.zip%20to%20the%20machine%20where%20SQL%20Server%20is%20running%20or%20active%20node%20if%20it%27s%20a%20cluster.%0A3.%09Extract%20the%20contents%20of%20the%20.zip%20file%20to%20a%20folder%20%28for%20example%20in%20D%3A%5Cpssd%29%0AThe%20folder%20must%20meet%20the%20following%20requirements%3A%0ASQL%20Server%20startup%20account%20has%20Full%20Control%20permission%20of%20this%20folder.%0AThe%20drive%20should%20be%20fast%20performing%20and%20NOT%20a%20network-mapped%20drive.%20Preferably%20a%20dedicated%20drive%2C%20different%20from%20the%20where%20databases%20reside%0A%20%09The%20drive%20has%20sufficient%20disk%20space%20for%20the%20PSSDIAG%20data%20%28run%20PSSDIAG%20for%201%20minute%20to%20estimate%20how%20much%20output%20data%20is%20generated%29.%0A4.%09Open%20an%20admin%20Command%20Prompt%20and%20go%20to%20the%20folder.%0Ad%3A%5C%3Ecd%20pssd%0A5.%09Run%20pssdiag.cmd%20from%20Command%20Prompt%0Ad%3A%5Cpssd%3Epssdiag.cmd%0A6.%09Wait%20for%20PSSDIAG%20to%20completely%20initialize.%20You%20will%20see%20a%20message%3A%20SQLDIAG%20Collection%20started.%20Press%20Ctrl%2BC%20to%20stop.%0A7.%09Re-create%20the%20problem%20that%20you%20want%20to%20trace%0A8.%09To%20stop%20PSSDIAG%2C%20press%20Ctrl%2BC%20once%20and%20wait%20for%20it%20to%20completely%20shutdown.%0A9.%09You%20will%20see%20messages%20like%20this%3A%0ASQLDIAG%20Ctrl%2BC%20pressed.%20Shutting%20down%20the%20collector%0A%09%09...%0ASQLDIAG%20Ending%20data%20collection.%20Please%20wait%20while%20the%20process%20shuts%20down%20and%20files%20are%20compressed%20%28this%20may%20take%20several%20minutes%29%0A%0ANote%3A%20You%20may%20be%20prompted%20to%20press%20%27Y%27%20to%20complete%20the%20batch%20shutdown.%0ATerminate%20batch%20job%20%28Y%2FN%29%3F%20y%0A10.%09Files%20are%20captured%20in%20%5Coutput%20directory.%20Zip%20and%20copy%20to%20a%20different%20machine%20for%20analysis.%20SQL%20Nexus%20can%20be%20used%20for%20performance%20analysis.%0A";


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
