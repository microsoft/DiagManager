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
using System.Threading.Tasks;
using System.IO;
using System.Xml;
using System.Xml.XPath;
using PssdiagConfig;

namespace PssdiagConfig
{
    [Serializable()]
    public class XMgr
    {

        private static String OriginalXeventText = string.Empty;

        public List<DiagCategory> CategoryList = new List<DiagCategory>();

        public static List<EventAction> GlobalActionList = new List<EventAction>();
        public static EventTemplateCollection GlobalEventTemplateList = new EventTemplateCollection();

        public static EventFilterCollection GlobalFilterList = new EventFilterCollection();
        public static EventFilterCollection UserFilterList = new EventFilterCollection();
        public static List<CompOp> GlobalCompOpList = new List<CompOp>();

        static XMgr()
        {
            OriginalXeventText = Resource1.AllEvents;

            SetGlobalFilterList();
            SetGlobalActionList();
            SetGlobalTemplateList();
            SetGlobalCompOpList();
            

        }
        private static void SetGlobalCompOpList()
        {

            XPathNodeIterator iter = Util.GetXPathIterator(OriginalXeventText, "DiagMgr/events/CompOps/CompOp");
            while (iter.MoveNext())
            {
                GlobalCompOpList.Add(new CompOp(iter.Current.OuterXml));
            }


        }
        private static void SetGlobalTemplateList()
        {
            XPathNodeIterator iter = Util.GetXPathIterator(OriginalXeventText, "DiagMgr/events/EventTemplates/EventTemplate");
            while (iter.MoveNext())
            {
                GlobalEventTemplateList.Add(new Scenario(iter.Current.OuterXml));
            }

            GlobalEventTemplateList.Init();// Initialize it just once

        }
        private static void SetGlobalActionList()
        {
            TextReader reader = new StringReader(OriginalXeventText);
            XPathDocument doc = new XPathDocument(reader);
            XPathNavigator rootnav = doc.CreateNavigator();
            XPathNodeIterator iter = rootnav.Select("DiagMgr/events/GlobalActions/action");

            while (iter.MoveNext())
            {
                GlobalActionList.Add(new EventAction(iter.Current.OuterXml));
            }


        }
        private static void SetGlobalFilterList()
        {
            XPathNodeIterator iter = Util.GetXPathIterator(OriginalXeventText, "DiagMgr/events/filters/filter");
            while (iter.MoveNext())
            {
                GlobalFilterList.Add(new EventFilter(iter.Current.OuterXml));

            }
        }


        public XMgr(string XEventText)
        {
            OriginalXeventText = XEventText;
            TextReader reader = new StringReader(XEventText);
            XPathDocument doc = new XPathDocument(reader);
            XPathNavigator rootnav = doc.CreateNavigator();
            XPathNodeIterator iterCat = rootnav.Select("DiagMgr/events/category");

            while (iterCat.MoveNext())
            {

                string name = iterCat.Current.GetAttribute("name", "").ToString();
                DiagCategory cat = new DiagCategory("category", name);
                XPathNavigator eventNav = iterCat.Current.CreateNavigator();
                XPathNodeIterator iterEvent = eventNav.Select("event");
                while (iterEvent.MoveNext())
                {

                    /*Xevent evt = new Xevent();
                    evt.Name = iterEvent.Current.GetAttribute("name", "");
                    
                    evt.Package = iterEvent.Current.GetAttribute("package", "");
                    evt.General = Convert.ToBoolean(iterEvent.Current.GetAttribute("general", ""));
                    evt.Detailed = Convert.ToBoolean(iterEvent.Current.GetAttribute("detail", ""));
                    evt.Replay = Convert.ToBoolean(iterEvent.Current.GetAttribute("replay", ""));
                    */
                    cat.XEventList_DONOTUSE.Add(new Xevent(iterEvent.Current.OuterXml));

                    //Xevent xevt2 = ObjectCopier.Clone<Xevent>(new Xevent(iterEvent.Current.OuterXml));
                    //MessageBox.Show(xevt2.Name);

                }
                CategoryList.Add(cat);



            }
            // PrintInfo();
        }

        public void PrintInfo()
        {
            throw new Exception("Not implemnted yet");

        }




        public static String GetConfigXML(List<Xevent> evtList)
        {
            StringBuilder sbXML = new StringBuilder();

            sbXML.Append("<event_session memoryPartitionMode=\"perCpu\" maxEventSize=\"0\" trackCausality=\"true\" eventRetentionMode=\"noEventLoss\" maxMemory=\"4\"  dispatchLatency=\"0\" name=\"PssdiagXeventCapture\"> " + Environment.NewLine);
            String action = "<action name=\"collect_current_thread_id\" package=\"package0\"/><action name=\"cpu_id\" package=\"sqlos\"/><action name=\"scheduler_id\" package=\"sqlos\"/><action name=\"system_thread_id\" package=\"sqlos\"/><action name=\"task_address\" package=\"sqlos\"/><action name=\"worker_address\" package=\"sqlos\"/><action name=\"database_id\" package=\"sqlserver\"/><action name=\"database_name\" package=\"sqlserver\"/><action name=\"event_sequence\" package=\"package0\"/><action name=\"is_system\" package=\"sqlserver\"/><action name=\"plan_handle\" package=\"sqlserver\"/><action name=\"request_id\" package=\"sqlserver\"/><action name=\"session_id\" package=\"sqlserver\"/><action name=\"transaction_id\" package=\"sqlserver\"/>";


            foreach (Xevent evt in evtList)
            {

                sbXML.AppendFormat("<event name=\"{0}\"  package=\"{1}\"> {2}", evt.Name, evt.Package, Environment.NewLine);
                sbXML.AppendFormat("{0}{1}", action, Environment.NewLine);
                sbXML.Append("</event>");

            }

            sbXML.Append("<target name=\"event_file\" package=\"package0\">" + Environment.NewLine);
            sbXML.Append("<parameter name=\"filename\" value=\"c:\\temp\\pssdiagxevent.xel\"/>" + Environment.NewLine);
            sbXML.Append("</target>");
            sbXML.Append("</event_session>");




            return sbXML.ToString();
        }

        public static String GetSQLScript(List<DiagItem> evtList)
        {
            StringBuilder sbSQL = new StringBuilder();
            XEventRuntime runtime = new XEventRuntime();
            sbSQL.AppendFormat(string.Format("-- {0}\n", runtime.DropCommand));

            sbSQL.AppendFormat("{0}\n ", "print 'Creating Xevent Session'");
            sbSQL.AppendFormat("{0}\n", runtime.DropCommand);

            sbSQL.Append("\nGO\n");
            sbSQL.AppendFormat("{0}\n ", runtime.CreateCommandPrefix);

            for (int i = 0; i < evtList.Count; i++)
            {
                //sbSQL.Append("ADD EVENT " + evtList[i].ToString());

                Xevent xevt = evtList[i] as Xevent;
                sbSQL.Append(xevt.AddEventActionText());
                if (i != (evtList.Count - 1))
                {
                    sbSQL.Append(",");

                }
                sbSQL.Append(Environment.NewLine);

            }

            // sbSQL.AppendFormat(@" ADD TARGET package0.event_file(SET filename=N'c:\temp\{0}_XEvent.xel') {1}", XMgr.GlobalEventTemplateList.GetNameForXEventFileTarget(),  Environment.NewLine);
            sbSQL.Append(@"WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=10 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)" + Environment.NewLine);

            sbSQL.AppendFormat("--{0}\n", runtime.AlterCommandAddFileTarget);

            sbSQL.AppendFormat("--{0}\n", runtime.StartCommand);
            sbSQL.AppendFormat("--{0}\n", runtime.StopCommand);

            return sbSQL.ToString();

        }
        public List<Xevent> AllEvents
        {
            get
            {
                List<Xevent> evtList = new List<Xevent>();
                foreach (DiagCategory cat in CategoryList)
                {
                    foreach (Xevent evt in cat.XEventList_DONOTUSE)
                    {
                        evtList.Add(evt);

                    }
                }

                evtList.Sort();

                return evtList;

            }
        }


    }
}
