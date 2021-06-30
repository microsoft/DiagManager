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
using System.Xml;
using System.Xml.XPath;
using PssdiagConfig;
namespace PssdiagConfig
{
    public class ConfigFileMgrEx
    {

        UserSetting m_Setting;
        XmlDocument m_doc;
        XmlDocument doc;


        /* ds_Config/DiagMgrInfo
         * ds_Config/Collection/Machines/Machine/MachineCollectors
         * ds_Config/Collections/Machines/Machine/Instances/Instance
         * 
         */
        public ConfigFileMgrEx (UserSetting setting)
        {
            m_doc = new XmlDocument();
            doc = m_doc;
            m_Setting = setting;

            XmlNode dsConfigNode = m_doc.CreateNode(XmlNodeType.Element, "dsConfig", "");
            m_doc.AppendChild(dsConfigNode);
            XmlNode DiagMgrInfoNode = m_doc.CreateNode(XmlNodeType.Element, "DiagMgrInfo", "");
            dsConfigNode.AppendChild(DiagMgrInfoNode);
            SetDiagMgrInfo(DiagMgrInfoNode);

            XmlNode CollectionNode = m_doc.CreateNode(XmlNodeType.Element, "Collection", "");
            dsConfigNode.AppendChild(CollectionNode);
            SetCollection(CollectionNode);
            
        }

        
        void SetCollection (XmlNode node)
        {
            XmlAttribute attribCollectionCaseNumber = m_doc.CreateAttribute("casenumber");
            attribCollectionCaseNumber.Value = "SRX000000000000";
            XmlAttribute attribCollectionSetupVer = m_doc.CreateAttribute("setupver");
            attribCollectionSetupVer.Value = "12.0.0.1001";
            node.Attributes.Append(attribCollectionCaseNumber);
            node.Attributes.Append(attribCollectionSetupVer);
            XmlNode MachinesNode = m_doc.CreateNode(XmlNodeType.Element, "Machines", "");
            node.AppendChild(MachinesNode);
            SetMachines(MachinesNode);

            //Logger.LogMessage(m_Setting.XEventCategoryList.GetCheckedDiagItemList().GetSQLScript(), LogLevel.INFO);
            

        }

        void SetMachines (XmlNode node)
        {

            XmlNode MachineNode = m_doc.CreateNode(XmlNodeType.Element, "Machine", "");
            node.AppendChild(MachineNode);
            SetMachine(MachineNode);

        }
        void SetMachine (XmlNode node)
        {
            XmlAttribute attribMachineName = m_doc.CreateAttribute("name");
            attribMachineName.Value = m_Setting[Res.MachineName];
            node.Attributes.Append(attribMachineName);
            XmlNode MachineCollectorsNode = m_doc.CreateNode(XmlNodeType.Element, "MachineCollectors", "");

            node.AppendChild(MachineCollectorsNode);

            SetMachineCollectors(MachineCollectorsNode);

            XmlNode InstancesNode = m_doc.CreateNode(XmlNodeType.Element, "Instances", "");
            node.AppendChild(InstancesNode);
            SetInstances(InstancesNode);

        }


        void SetEventLogCollector(XmlNode node)
        {

            XmlAttribute attribEventLogCollectorEnabled = doc.CreateAttribute("enabled");
            attribEventLogCollectorEnabled.Value = m_Setting[Res.CollectEventLogs];
            XmlAttribute attribEventLogCollectorStartup = doc.CreateAttribute("startup");
            attribEventLogCollectorStartup.Value = m_Setting[Res.CollectEventLogsStartup];

            XmlAttribute attribEventLogCollectorShutdown = doc.CreateAttribute("shutdown");
            attribEventLogCollectorShutdown.Value = m_Setting[Res.CollectEventLogShutdown];

            node.Attributes.Append(attribEventLogCollectorEnabled);
            node.Attributes.Append(attribEventLogCollectorStartup);
            node.Attributes.Append(attribEventLogCollectorShutdown);


        }

        void SetPerfmonCounters (XmlNode node)
        {

            string perfmonxml = m_Setting.PerfmonCategoryList.GetCategoryXml();

            if (m_Setting[Res.Feature] == "AS")
            {
                perfmonxml = perfmonxml.Replace("%s", m_Setting[Res.InstanceName]);
            }

            node.InnerXml = perfmonxml;
            //node.InnerXml = DiagTreeMgr.GetXmlText(tv_Perfmon);
        }

        //ds_Config/Collection/Machines/Machine/MachineCollectors/PerfmonCollector/PerfmonCounters
        void SetPerfmonCollector (XmlNode node)
        {
            XmlAttribute attribPerfmonCollectorEnabled = doc.CreateAttribute("enabled");
            attribPerfmonCollectorEnabled.Value = m_Setting[Res.CollectPerfmon];
            XmlAttribute attribPerfmonCollectorMaxFileSize = doc.CreateAttribute("maxfilesize");
            attribPerfmonCollectorMaxFileSize.Value = m_Setting[Res.PerfmonMaxFileSize];
            XmlAttribute attribPerfmonCollectorPollingInterval = doc.CreateAttribute("pollinginterval");
            attribPerfmonCollectorPollingInterval.Value = m_Setting[Res.PerfmonInterval];


            node.Attributes.Append(attribPerfmonCollectorEnabled);
            node.Attributes.Append(attribPerfmonCollectorMaxFileSize);
            node.Attributes.Append(attribPerfmonCollectorPollingInterval);

            XmlNode PerfmonCountersNode = doc.CreateNode(XmlNodeType.Element, "PerfmonCounters", "");
            node.AppendChild(PerfmonCountersNode);

            SetPerfmonCounters(PerfmonCountersNode);



        }

        //ds_Config/Collection/Machines/Machine/MachineCollectors/EventLogCollector
        //ds_Config/Collection/Machines/Machine/MachineCollectors/PerfmonCollector
        void SetMachineCollectors (XmlNode node)
        {
            XmlNode EventLogCollectorNode = m_doc.CreateNode(XmlNodeType.Element, "EventlogCollector", "");
            XmlNode PerfmonCollectorNode = m_doc.CreateNode(XmlNodeType.Element, "PerfmonCollector", "");
            node.AppendChild(EventLogCollectorNode);
            node.AppendChild(PerfmonCollectorNode);

            SetEventLogCollector(EventLogCollectorNode);
            SetPerfmonCollector(PerfmonCollectorNode);


        }


        //ds_Config/Collections/Machines/Machine/Instances/Instance/Collectors/SqldiagCollector
        void SetSqlDiag (XmlNode node)
        {


            //SqlDiag Collector Node
            XmlNode SqlDiagCollectorNode = doc.CreateNode(XmlNodeType.Element, "SqldiagCollector", "");
            XmlAttribute attribSqlDiagEnabled = doc.CreateAttribute("enabled");
            attribSqlDiagEnabled.Value = m_Setting[Res.CollectSqldiag];
            XmlAttribute attribSqlDiagStartup = doc.CreateAttribute("startup");
            attribSqlDiagStartup.Value = m_Setting[Res.CollectSqldiagStartup];
            XmlAttribute attribSqlDiagShutdown = doc.CreateAttribute("shutdown");
            attribSqlDiagShutdown.Value = m_Setting[Res.CollectSqldaigShutdown];
            node.Attributes.Append(attribSqlDiagEnabled);
            node.Attributes.Append(attribSqlDiagStartup);
            node.Attributes.Append(attribSqlDiagShutdown);

        }

        //ds_Config/Collections/Machines/Machine/Instances/Instance/Collectors/BlockingCollector
        void SetBlocking(XmlNode node)
        {
            
            XmlAttribute attribBlockingCollectorshutdown = doc.CreateAttribute("shutdown");
            attribBlockingCollectorshutdown.Value = m_Setting[Res.CollectBlockingShutdown];
            XmlAttribute attribBlockingCollectorstartup = doc.CreateAttribute("startup");
            attribBlockingCollectorstartup.Value = m_Setting[Res.CollectBlockingStartup];

            XmlAttribute attribBlockingCollectorsmaxfilesize = doc.CreateAttribute("maxfilesize");
            attribBlockingCollectorsmaxfilesize.Value = m_Setting[Res.CollectBlockingMaxFileSize];
            
            
            node.Attributes.Append(attribBlockingCollectorshutdown);
            node.Attributes.Append(attribBlockingCollectorstartup);
            node.Attributes.Append(attribBlockingCollectorsmaxfilesize);


        }


        void SetProfilerEvents(XmlNode node)
        {
            node.InnerXml = m_Setting.ProfilerCategoryList.GetCategoryXml();

                  //node.InnerXml =  DiagTreeMgr.GetXmlText(tv_Trace);

        }
        //ds_Config/Collections/Machines/Machine/Instances/Instance/Collectors/ProfilerCollector
        void SetProfiler(XmlNode node)
        {
               XmlAttribute attribProfilerEnabled = doc.CreateAttribute("enabled");
              attribProfilerEnabled.Value = m_Setting[Res.CollectProfiler];

            
            XmlAttribute attribMaxFileSize = doc.CreateAttribute("maxfilesize");
            attribMaxFileSize.Value = m_Setting[Res.ProfilerMaxFileSize];
            
            XmlAttribute attribFileCount = doc.CreateAttribute("filecount");
            attribFileCount.Value = m_Setting[Res.ProfilerFileCount];

            XmlAttribute attribProfilerPollingInterval = doc.CreateAttribute("pollinginterval");
            attribProfilerPollingInterval.Value = "5";

            node.Attributes.Append(attribProfilerEnabled);
            node.Attributes.Append(attribMaxFileSize);
            node.Attributes.Append(attribFileCount);
            node.Attributes.Append(attribProfilerPollingInterval);

            XmlNode ProfilerEventsNode = m_doc.CreateNode(XmlNodeType.Element, "Events", "");
            node.AppendChild (ProfilerEventsNode);

            SetProfilerEvents(ProfilerEventsNode);
            //adding trace filter here
            if (m_Setting.TraceFilterList != null && m_Setting.TraceFilterList.Count > 0)
            {
                XmlNode ParameterNode = m_doc.CreateNode(XmlNodeType.Element, "Parameters", "");
                ParameterNode.InnerXml = m_Setting.TraceFilterList.GetTraceFilterXML();
                node.AppendChild(ParameterNode);
            }




        }

        void SetCustomDiag(XmlNode node)
        {

   

            // if SQL Xevent needs to be captured
            if (m_Setting[Res.CollectXEvent] == "true")
            {
                DiagCategory XEventGroup = DiagFactory.GetCustomGroup(null, @"Templates\CustomDiagnostics_Xevent.xml");
                //need to manuall handle taskname "Add File Target" for file size and file count
                DiagItem taskItem = XEventGroup.DiagEventList.Find(x => x.Name == "Add File Target"); // for CustomTask Name is the same as TaskName
                CustomTask task = taskItem as CustomTask;
                task.Cmd = task.Cmd.Replace("1024x", m_Setting[Res.XEventMaxFileSize]).Replace("5x", m_Setting[Res.XEventFileCount]);
                //manually check events for special handling
                XEventGroup.CheckEvents(true);
                m_Setting.CustomDiagCategoryList.Add(XEventGroup);
            }


            //speical handling Analysis Service (A_S)
            string customDiagxml = m_Setting.CustomDiagCategoryList.GetCategoryXml();
            if (m_Setting[Res.Feature] == "AS")
            {
                string ServerInstance = string.Empty;
                string instance = string.Empty;
                string InstanceName = m_Setting[Res.InstanceName];
                string MachineName =  m_Setting[Res.MachineName];
                string ASTraceFileName = string.Empty;


                if (!(InstanceName.ToUpper() == "MSSQLSERVER"))
                {
                    ServerInstance = MachineName + @"\" + InstanceName;
                    ASTraceFileName = MachineName + "_" + InstanceName;

                }
                else
                {
                    ServerInstance = MachineName;
                    ASTraceFileName = MachineName;
                }


                customDiagxml=customDiagxml.Replace("ASSERVERINSTANCE", ServerInstance);
                customDiagxml = customDiagxml.Replace("ASTraceFileName", ASTraceFileName);
                

            }

            node.InnerXml = customDiagxml;

            //CustomDiagnosticsNode.InnerXml = DiagTreeMgr.GetXmlText(tv_CustomDiag); 
        }

        //parent:  ds_Config/Collections/Machines/Machine/Instances/Instance/Collectors
        void SetCollectors(XmlNode node)
        {

            XmlNode SqldiagCollectorNode = m_doc.CreateNode(XmlNodeType.Element, "SqldiagCollector", "");
            XmlNode BlockingCollectorNode = m_doc.CreateNode(XmlNodeType.Element, "BlockingCollector", "");

            string ProfilerNodeName = "ProfilerCollector";
            if (m_Setting[Res.Feature] == "AS")
            {
                ProfilerNodeName = "ASProfilerCollector";

            }
            XmlNode ProfilerCollectorNode = m_doc.CreateNode(XmlNodeType.Element, ProfilerNodeName, "");

            XmlNode CustomDiagNode = m_doc.CreateNode(XmlNodeType.Element, "CustomDiagnostics", "");
            node.AppendChild(SqldiagCollectorNode);
            node.AppendChild(BlockingCollectorNode);
            node.AppendChild(ProfilerCollectorNode);
            node.AppendChild(CustomDiagNode);
            SetSqlDiag(SqldiagCollectorNode);
            SetBlocking (BlockingCollectorNode);
            SetProfiler (ProfilerCollectorNode);
            SetCustomDiag(CustomDiagNode);

        }

        //Parent=ds_Config/Collections/Machines/Machine/Instances/Instance
        void SetInstance (XmlNode node)
        {

            
            XmlAttribute attribInstanceName = doc.CreateAttribute("name");
            attribInstanceName.Value = m_Setting[Res.InstanceName];

            XmlAttribute attribInstanceSSVER = doc.CreateAttribute("ssver");

            string ssver = m_Setting[Res.Version];
            if (m_Setting[Res.Feature] == "AS")
            {
                ssver = "9";
            }
            attribInstanceSSVER.Value = ssver;

            XmlAttribute attribInstancewindowsauth = doc.CreateAttribute("windowsauth");
            attribInstancewindowsauth.Value = "true";

            XmlAttribute attribInstanceuser = doc.CreateAttribute("user");
            attribInstanceuser.Value = "";


            node.Attributes.Append(attribInstanceName);
            node.Attributes.Append(attribInstanceuser);
            node.Attributes.Append(attribInstancewindowsauth);
            node.Attributes.Append(attribInstanceSSVER);

            XmlNode CollectorsNode = m_doc.CreateNode(XmlNodeType.Element, "Collectors", "");
            node.AppendChild(CollectorsNode);

            SetCollectors (CollectorsNode);
            

        }
        void SetInstances(XmlNode node)
        {


            XmlNode InstanceNode = m_doc.CreateNode(XmlNodeType.Element, "Instance", "");
            node.AppendChild(InstanceNode);
            SetInstance(InstanceNode);




        }
        void SetDiagMgrInfo(XmlNode node)
        {
            XmlNode DiagManagerVersion = m_doc.CreateNode(XmlNodeType.Element, "DiagManagerVersion", "");
            DiagManagerVersion.InnerText = Globals.DiagMgrVersion;

            node.AppendChild(DiagManagerVersion);

            XmlNode IntendedPlatformNode = m_doc.CreateNode(XmlNodeType.Element, "IntendedPlatform", "");
            IntendedPlatformNode.InnerText = m_Setting[Res.Platform];
            node.AppendChild(IntendedPlatformNode);

            XmlNode IntendedVersion = m_doc.CreateNode(XmlNodeType.Element, "IntendedVersion", "");
            IntendedVersion.InnerText = m_Setting[Res.Version];
            node.AppendChild(IntendedVersion);

            XmlNode PssdiagConfigDate = m_doc.CreateNode(XmlNodeType.Element, "PssdiagConfigDate", "");
            PssdiagConfigDate.InnerText = DateTime.Now.ToString();

            

            node.AppendChild(PssdiagConfigDate);


        }

        public void SaveConfig (string fileName)
        {
            using (XmlTextWriter writer = new XmlTextWriter(fileName, null))
            {
                writer.Formatting = Formatting.Indented;
                doc.Save(writer);

            }

        }



    }
}
