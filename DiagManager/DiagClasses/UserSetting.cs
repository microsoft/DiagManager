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
using System.Xml.Serialization;
using System.IO;
using System.Xml.XPath;
using PssdiagConfig;

namespace PssdiagConfig
{
    [Serializable()]
    public class DefaultChoice
    {
        public string Feature { get; set; }
        public string Version { get; set; }
        public bool Profiler { get; set; }
        public bool Perfmon { get; set; }
        public bool Xevent { get; set; }
        public bool EventLog { get; set; }
        public bool Sqldiag { get; set; }
        public List<string> ScenarioList;

        public DefaultChoice (string feat, string ver, bool profiler, bool perfmon, bool xevent, bool eventlog, bool sqldiag, List<string> scenList)
        {
            Feature = feat;
            Version = ver;
            Profiler = profiler;
            Perfmon = perfmon;
            Xevent = xevent;
            EventLog = eventlog;
            Sqldiag = sqldiag;
            ScenarioList = scenList;
        }

    }
    [Serializable()]
    public class UserSetting
    {


        public List<DiagCategory> ProfilerCategoryList;
        public List<DiagCategory> PerfmonCategoryList;
        public List<DiagCategory> CustomDiagCategoryList;
        public List<DiagCategory> XEventCategoryList;
        public List<TraceFilter> TraceFilterList;

        /*
        public bool XEventCapture;
        public int XEventMaxSize;
        public int XEventNumOfFiles;
        public bool ProfilerCapture;
        public int ProfilerMaxSize;
        public int ProfilerNumOfFiles;
        public bool PerfmonCapture;
        public int PerfmonMaxSize;
        public int PerfmonPollingInterval;
        public bool EventLogStartup;
        public bool EventLogShutdown;
        public bool SqlDiagStartup;
        public bool SqlDiagShutdown;
        public string PackageDefaultPath;
         */


        private static string _settingFile = Globals.ExePath + @"\user.settings2";

        public  List<DefaultChoice> DefaultChoiceList = new List<DefaultChoice>();

        Dictionary<string, string> _indexer = new Dictionary<string, string>();
        public string this [string key]
        {
            get
            {
                return _indexer[key];
            }

            set
            {
                _indexer[key] = value;

            }

        }

        public DefaultChoice GetDefaultChoiceByFeatureVersion(string feat, string ver)
        {
            DefaultChoice choice = DefaultChoiceList.Find(x => x.Feature == feat && x.Version == ver);
            if (null == choice)
            {
                throw new ArgumentException("Unable to find this feature and version");
            }
            return choice;
        }

        public List<string> DefaultScenarioList
        {
            get
            {
                return GetDefaultChoiceByFeatureVersion(this["Feature"], this["Version"]).ScenarioList;
            }

        }
        private List<string> m_UserChosenScenarioList = new List<string>();
        public List<string> UserChosenScenarioList
        {
            get
            {
                return m_UserChosenScenarioList;

            }

        }
        
        public void SetUserChosenScenarioList (List<string> list)
        {
            m_UserChosenScenarioList = list;
        }
        private void SetDefault()
        {
            XPathDocument doc = new XPathDocument(@"Templates\General_Template.xml");
            XPathNavigator rootnav = doc.CreateNavigator();
            XPathNodeIterator iter = rootnav.Select("DiagMgr/DefaultSetting/DefaultChoice");

            while (iter.MoveNext())
            {
                string feat = iter.Current.GetAttribute("Feature", "");
                string ver = iter.Current.GetAttribute("Version", "");
                bool Profiler = Convert.ToBoolean(iter.Current.GetAttribute("Profiler", ""));
                bool Perfmon = Convert.ToBoolean(iter.Current.GetAttribute("Perfmon", ""));
                bool xevent = Convert.ToBoolean(iter.Current.GetAttribute("XEvent", ""));
                bool EvengLog = Convert.ToBoolean(iter.Current.GetAttribute("EvengLog", ""));
                bool Sqldiag = Convert.ToBoolean(iter.Current.GetAttribute("Sqldiag", ""));
                List<string> scenList = new List<string>();
                XPathNodeIterator iterScenario = iter.Current.Select("Scenario");
                while (iterScenario.MoveNext())
                {
                    string scenname = iterScenario.Current.GetAttribute("name", "").ToString();
                    scenList.Add(scenname);

                }
                DefaultChoice choice = new DefaultChoice(feat, ver, Profiler, Perfmon, xevent, EvengLog, Sqldiag, scenList);
                DefaultChoiceList.Add(choice);
            }

        }
        //just for serialization/deserialization
        public UserSetting()
        {
            SetDefault();
        }
        public UserSetting(bool AppDefault)
        {
            if (AppDefault == true)
            {
                SetDefault();
                this[Res.Feature] = "SQL";
                this[Res.Version] = "13";
                this[Res.Platform] = "x64";
                m_UserChosenScenarioList = DefaultScenarioList;
            }
            
            //ScenarioList.Add("DetailedPerf");
            this["OutputFolder"] = @"C:\temp";
        }


        public void SaveSetting()
        {
            SaveSetting(_settingFile);
        }
        private void SaveSetting (string FileName)
        {
            if (File.Exists (FileName))
            {
                File.Delete(FileName);
            }

            StreamWriter writer = new StreamWriter(FileName);
            XmlSerializer serializer = new XmlSerializer(this.GetType());
            serializer.Serialize(writer, this);
            writer.Flush();
            writer.Close();
        }

        public static UserSetting LoadSetting()
        {
            return Load(_settingFile);
        }
        private  static UserSetting Load(string FileName)
        {
            UserSetting setting = null;

            if (File.Exists (FileName))
            {
                FileStream stream = File.OpenRead(FileName); 
                XmlSerializer serializer = new XmlSerializer(typeof(UserSetting));
                setting = serializer.Deserialize(stream) as UserSetting;

                stream.Close();

            }
          
            return setting;
        }
        
    }
}
