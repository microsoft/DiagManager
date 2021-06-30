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
using System.IO;
namespace PssdiagConfig
{

    #region EventTemplate
    [Serializable()]
    public class Scenario : DiagItem //: IComparable<EventTemplate>
    {
        //public Boolean IsChecked = false;
        public string FullName
        {
            get { return Name; }
        }
        public string Target;
        public Int32 Version;
        //public bool EventEnabled = false;
        public bool DefaultChecked = false;


        //static object m_lock;
        //static int m_objectcount;

        public string Description { get; set; }
        public override string ToString()
        {
            return FriendlyName;
        }
        public Scenario (string name, string friendlyname, string target, bool defaultchecked, string description)
        {
            this.Name = name;
            this.FriendlyName = friendlyname;
            this.Target = target;
            this.DefaultChecked = defaultchecked;
            this.Description = description;

        }

        public Scenario(string XmlElement)
        {

            //throw new Exception("Scenario contrsuct taking XML shouldn't be used");
            //"<event package=\"sqlserver\" name=\"parallel_scan_range_returned\" version=\"11\" general=\"false\" detail=\"false\" replay=\"false\" />"
            TextReader reader = new StringReader("<root>" + XmlElement + "</root>");
            XPathDocument doc = new XPathDocument(reader);
            XPathNavigator rootnav = doc.CreateNavigator();
            XPathNodeIterator iterEventField = rootnav.Select("//EventTemplate");

            int counter = 0;
            while (iterEventField.MoveNext())
            {
                //<field name="duration" AutoInclude="1" IsNum="true"/>
                XPathNavigator eventNav = iterEventField.Current;

                this.Name = Convert.ToString(eventNav.GetAttribute("name", ""));
                this.FriendlyName = Convert.ToString(eventNav.GetAttribute("friendlyname", ""));
                this.Target = Convert.ToString(eventNav.GetAttribute("target", ""));
                this.Version = Convert.ToInt32(eventNav.GetAttribute("version", ""));

                this.DefaultChecked = Convert.ToBoolean(eventNav.GetAttribute("DefaultChecked", ""));
                counter++;

            }

            if (counter != 1)
            {
                throw new ArgumentException("The XML passed for Event Template is not valid and should only contain one record");
            }



        }

    }


    [Serializable()]
    public class EventTemplateCollection : List<Scenario>
    {

        /*  public EventTemplate Find(string name)
          {
              foreach (EventTemplate obj in this)
              {
                  if (obj.Name == name)
                      return obj;
              }

              return null;
          }*/


        public EventTemplateCollection()
        {
            Init();
        }
        public void Init()
        {
            foreach (Scenario evtTemp in this)
            {
                evtTemp.IsChecked = evtTemp.DefaultChecked;
            }
        }
        public void Reset()
        {
            foreach (Scenario evtTemp in this)
            {
                evtTemp.IsChecked = false;
            }
        }

        public string CheckConflict()
        {
            string msg = string.Empty;
            Scenario evtGeneralPerf = this.FindByNameIgnoreCase<Scenario>("GeneralPerf");
            Scenario evtDetailedPerf = this.FindByNameIgnoreCase<Scenario>("DetailedPerf");
            Scenario evtLightPerf = this.FindByNameIgnoreCase<Scenario>("LightPerf");
            Scenario evtReplay = this.FindByNameIgnoreCase<Scenario>("Replay");

            int checkedCount = 0;
            if (evtGeneralPerf.IsChecked)
                checkedCount++;
            if (evtDetailedPerf.IsChecked)
                checkedCount++;
            if (evtLightPerf.IsChecked)
                checkedCount++;

            if (evtReplay.IsChecked)
                checkedCount++;


            if (checkedCount > 1)
            {
                msg += "Performance templates are selected more than once.  You should only select one of General Performance, Light Performance, Detailed Performance or Replay";
            }


            return msg;
        }


        public string GetNameForXEventFileTarget()
        {
            string name = string.Empty;
            foreach (Scenario evtTemp in this)
            {
                if (evtTemp.IsChecked == true)
                {
                    name += "_" + evtTemp.Name + "_";
                }
            }
            return name;
        }

        public void PrintInfo()
        {
            Logger.LogInfo("EventTemplateCollection");
            foreach (Scenario evtTemp in this)
            {
                Logger.LogInfo(evtTemp.Name + " is checked " + evtTemp.IsChecked);
            }
        }
    }


    #endregion



}
