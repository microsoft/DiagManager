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

namespace PssdiagConfig
{

    public class Xevent : DiagItem, IComparable<Xevent>
    {

        //public bool IsChecked { get; set; }
        public string Package { get; set; }
        
        //Objects in this list points to global object (event template
        public EventTemplateCollection EventOnlyTemplateList = new EventTemplateCollection();

        public Int32 EnabledSQLVersion = 11;

        public List<EventField> EventFieldList = new List<EventField>();

        public List<EventAction> EventActionList = new List<EventAction>();
        public Xevent(DiagCategory cat, string xmltag, string name, string package) : base(cat, xmltag, name)
        {
            this.Package = package;
        }
        public Xevent(string EventElement)
        {
            //"<event package=\"sqlserver\" name=\"parallel_scan_range_returned\" version=\"11\" general=\"false\" detail=\"false\" replay=\"false\" />"
            TextReader reader = new StringReader("<root>" + EventElement + "</root>");
            XPathDocument doc = new XPathDocument(reader);
            XPathNavigator rootnav = doc.CreateNavigator();
            XPathNodeIterator iterEvent = rootnav.Select("/root/event");

            int counter = 0;
            while (iterEvent.MoveNext())
            {

                XPathNavigator eventNav = iterEvent.Current;
                this.EnabledSQLVersion = Convert.ToInt32(eventNav.GetAttribute("version", ""));
                this.Name = iterEvent.Current.GetAttribute("name", "");

                foreach (Scenario evtTemp in XMgr.GlobalEventTemplateList)
                {
                    string templateName = evtTemp.Name;
                    bool tempEnabled = Convert.ToBoolean(iterEvent.Current.GetAttribute(evtTemp.Name, ""));
                    if (tempEnabled)
                    {
                        EventOnlyTemplateList.Add(evtTemp);
                    }
                }

                this.Package = iterEvent.Current.GetAttribute("package", "");
                // read and populate the field elements from eventfields section
                TextReader readerFields = new StringReader("<root>" + EventElement + "</root>");
                XPathDocument docFields = new XPathDocument(readerFields);
                XPathNavigator navFields = docFields.CreateNavigator();
                XPathNodeIterator iterFields = navFields.Select("//eventfields/field");
                while (iterFields.MoveNext())
                {
                    XPathNavigator navField = iterFields.Current;
                    EventFieldList.Add(new EventField(navField.OuterXml));
                }
                //read and poulate the action elements from eventactions section
                TextReader readerActions = new StringReader("<root>" + EventElement + "</root>");
                XPathDocument docActions = new XPathDocument(readerActions);
                XPathNavigator navActions = docActions.CreateNavigator();
                XPathNodeIterator iterActions = navActions.Select("//eventactions/action");
                while (iterActions.MoveNext())
                {
                    XPathNavigator navAction = iterActions.Current;
                    EventActionList.Add(new EventAction(navAction.OuterXml));
                }

                counter++;

            }

            if (counter != 1)
            {
                throw new ArgumentException("The XML passed for XEvent is not valid and should only contain one record");
            }
        }

        //0 is event name 1 is the set for event files 2 = action 3 = where
        private string AddEventTextTemplate = "ADD EVENT {0} ( {1}   {2}   {3} )";
        //ADD EVENT sqlserver.sql_batch_completed(SET collect_batch_text=(1)     ACTION(package0.collect_current_thread_id,package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.query_hash,sqlserver.request_id,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)     WHERE ([cpu_time]>(99)))
        public string AddEventActionText()
        {
            string setPrivateFields = string.Empty;
            string setGlobalActions = string.Empty;
            string setLocalActions = string.Empty;
            string setWhereClause = string.Empty;
            //if it's auto included, don't set
            if (EventFieldList != null && EventFieldList.Count() > 0)
            {

                int counter = 0;
                string prefix = "";
                setPrivateFields = "SET ";
                foreach (EventField evtfield in EventFieldList)
                {
                    if (evtfield.AutoInclude == false)
                    {
                        if (counter > 0)
                        {
                            prefix = " , ";
                        }

                        setPrivateFields += prefix + string.Format("{0}=(1)  ", evtfield.Name);
                        counter++;
                    }
                }

            }
            //if event requests specific actions capture them (we will not append to global actions since you can get into situations where you get too many actions error)
            if(this.EventActionList.Count() > 0)
            {
                setLocalActions = " ACTION (";
                for (int a = 0; a < this.EventActionList.Count(); a++)
                {
                    setLocalActions += this.EventActionList[a].FullName;
                    if (a != this.EventActionList.Count() - 1)
                    {
                        setLocalActions += ", ";
                    }
                    else
                    {
                        setLocalActions += ") ";
                    }
                }
                setGlobalActions = String.Copy(setLocalActions);
            }
            //otherwise go with global sction list (we will not append to event specific actions since you can get into situations where you get too many actions error)
            else if (XMgr.GlobalActionList != null && XMgr.GlobalActionList.Count() > 0)
            {
                setGlobalActions = " ACTION (";
                for (int i = 0; i < XMgr.GlobalActionList.Count(); i++)
                {
                    setGlobalActions += XMgr.GlobalActionList[i].FullName;
                    if (i != XMgr.GlobalActionList.Count() - 1)
                    {
                        setGlobalActions += ", ";
                    }
                    else
                    {
                        setGlobalActions += ") ";
                    }
                }
            }

            EventFilterCollection MyUserFilters = new EventFilterCollection();
            foreach (EventFilter evtFilter in XMgr.UserFilterList)
            {
                EventAction act = XMgr.GlobalActionList.FindByNameIgnoreCase(evtFilter.Name);
                EventField field = this.EventFieldList.Find(x => x.Name == evtFilter.Name);
                if (act != null || field != null)
                {
                    MyUserFilters.Add(evtFilter);
                }
            }
            //remove logical operator from last one
            if (MyUserFilters.Count > 0)
            {
                EventFilter evtFilter = MyUserFilters.Last<EventFilter>();
                evtFilter.LogicalOperator = string.Empty;
            }

            if (MyUserFilters != null && MyUserFilters.Count() > 0)
            {
                setWhereClause += " WHERE ( ";
                for (int i = 0; i < MyUserFilters.Count(); i++)
                {
                    EventFilter filt = MyUserFilters[i];
                    setWhereClause += filt.WhereClause + " ";
                }
                setWhereClause += ") ";
            }
            return string.Format(AddEventTextTemplate, this.FullName, setPrivateFields, setGlobalActions, setWhereClause);
        }
        public string FullName
        {
            get
            {
                return string.Format("{0}.{1}", Package, Name);
            }
        }
        public override string ToString()
        {
            return string.Format("{0}.{1}", Package, Name);
        }
        public int CompareTo(Xevent other)
        {

            if (null == other) return 1;
            return this.FullName.CompareTo(other.FullName);
        }
        public bool IsEnabled(EventTemplateCollection tempColl)
        {
            bool ret = false;
            foreach (Scenario temp in this.EventOnlyTemplateList)
            {
                //if (temp.EventEnabled == true)
                //{
                Scenario temp2 = tempColl.FindByNameIgnoreCase<Scenario>(temp.Name);
                if (temp2.IsChecked == true)
                {
                    ret = true;
                }
                //}
            }
            return ret;
        }
    }
}
