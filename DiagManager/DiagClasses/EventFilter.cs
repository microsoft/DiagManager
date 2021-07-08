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
using System.Windows.Forms;
using System.Xml;
using System.Xml.XPath;

namespace PssdiagConfig
{
    [Serializable()]
    public class EventFilter : DiagItem, IComparable<EventFilter>
    {
        public FilterChoiceCollection ChoiceList = new FilterChoiceCollection();
        public Dictionary<string, string> CompareOperatorList;
        public string package;


        //public string CompareOpeator;
        public CompOp CompareOpeator;
        private string _value;
        public string Value
        {
            get
            {
                return _value;
            }
            set
            {
                if (IsNum == true)
                {
                    Int32 result;
                    bool success = Int32.TryParse(value, out result);
                    if (!success)
                    {
                        MessageBox.Show("Filter " + Name + " should be a number. try again");
                    }
                    else
                    {
                        _value = value;
                    }
                }
                else
                {
                    //double quote single quote for sql
                    _value = value.Replace("'", "''");
                }

            }
        }
        public string LogicalOperator;
        public bool IsNum;
        public string FullName
        {
            get
            {
                if (string.IsNullOrEmpty(package))
                    return Name;
                else
                    return string.Format("{0}.{1}", package, Name);
            }
        }


        public int CompareTo(EventFilter other)
        {
            if (null == other) return 1;
            return this.FullName.CompareTo(other.FullName);
        }

        public static EventFilter CreateEventFilter(string filtName, CompOp op, string filtValue, string LogOp)
        {

            EventFilter evtFilter = ObjectCopier.Clone<EventFilter>(XMgr.GlobalFilterList.FindByNameIgnoreCase(filtName));
            evtFilter.CompareOpeator = op;
            evtFilter.Value = filtValue;
            evtFilter.LogicalOperator = LogOp;
            return evtFilter;



        }
        //[sqlserver].[like_i_sql_unicode_string]([sqlserver].[nt_domain],N'') 
        //[sqlserver].[database_id]=(12)  AND [logical_reads]>(99)
        public string WhereClause
        {
            get
            {
                if (CompareOpeator == null)
                    return string.Empty;
                //if (string.IsNullOrEmpty(Value)) throw new ArgumentException("There is no value defined for this filter");
                string clause = string.Empty;

                if (CompareOpeator.IsSpecial == true)
                {

                    clause = string.Format("{0} ( {1} , N'{2}') {3}  ", CompareOpeator.Name, FullName, Value, LogicalOperator);
                }
                else
                {
                    string quote = string.Empty;
                    if (IsNum == false)
                    {
                        quote = "'";
                    }
                    clause = FullName + " " + CompareOpeator.Name + " (" + quote + Value + quote + ") " + LogicalOperator;

                }

                return clause;

            }
        }
        public EventFilter(string XmlElement)
        {
            XPathNodeIterator iter = Util.GetXPathIterator("<root>" + XmlElement + "</root>", "/root/filter");


            int counter = 0;
            while (iter.MoveNext())
            {

                XPathNavigator Nav = iter.Current;
                this.package = Nav.GetAttribute("package", "");
                this.Name = Nav.GetAttribute("name", "");
                this.FriendlyName = Nav.GetAttribute("friendlyname", "");

                this.IsNum = Convert.ToBoolean(Nav.GetAttribute("IsNum", ""));

                //this.EnabledSQLVersion = Convert.ToInt32(eventNav.GetAttribute("version", ""));
                XPathNodeIterator iterChoice = Util.GetXPathIterator("<root>" + Nav.OuterXml + "</root>", "//choice");
                while (iterChoice.MoveNext())
                {
                    ChoiceList.Add(new FilterChoice(iterChoice.Current.OuterXml));
                }

                counter++;

            }

            if (counter != 1)
            {
                throw new ArgumentException("The XML passed for EventFilter is not valid and should only contain one record");
            }



        }

    }
}
