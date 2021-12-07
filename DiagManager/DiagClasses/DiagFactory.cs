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
    public class DiagFactory
    {
       // private static string DiagMgrXML;
        public static List<Version> GlobalVersionList = new List<Version>();
        public static List<Scenario> GlobalScenarioList = new List<Scenario>();
        public static List<Feature> GlobalFeatureList = new List<Feature>();
        public static List<Platform> GlobalPlatformList = new List<Platform>();
        
        public static List<DiagCategory> SQLTraceEventCategoryList;//= new List<DiagCategory>();

       // public static List<DiagCategory> ASTraceEventCategoryList;//= new List<DiagCategory>();
        
        public static List<DiagCategory> SQLPerfmonCounterCategoryList = new List<DiagCategory>();
        //public static List<DiagCategory> ASPerfmonCounterCategoryList = new List<DiagCategory>();

        public static List<DiagCategory> CustomDiagnosticsCategoryList = new List<DiagCategory>();

        public static List<DiagCategory> XEventCategoryList;

        /// <summary>
        /// Get a List of XEvent from Category
        /// </summary>
        /// <returns>List of XEvent from Category</returns>
        public static List<Xevent>  GetXEventList()
        {
            List<Xevent> list = new List<Xevent>();
              foreach  (DiagCategory cat in XEventCategoryList)
              {
                  foreach (Xevent xevt in cat.DiagEventList)
                  {
                      list.Add(xevt as Xevent);
                  }
              }
        
            return list;

        }

        public static List<Scenario> GetGlobalScenarioListByFeatureVersion (string featureName, string version)
        {
            List<Scenario> scenarioList = new List<Scenario>();
            foreach (Scenario scen in GlobalScenarioList)
            {
                Feature feat = scen.EnabledFeatures.Find(x => x.Name == featureName && x.Enabled == true);
                Version ver = scen.EnabledVersions.Find(x => x.Name == version && x.Enabled == true);
                if (feat != null && ver != null)
                {
                    scenarioList.Add(scen);
                }
                

            }

            return scenarioList;
        }
     
        static DiagFactory()
        {
            Init();
            //GlobalVersionList.PrintList();
            //GlobalFeatureList.PrintList();
            //GlobalScenarioList.PrintList();
            //TraceEventCategoryList.PrintList();
        }
  
        static List<Version>  GetGlobalVersionList(XPathNodeIterator iter) 
        {

            List<Version> verList = new List<Version>();
            while (iter.MoveNext())
            {
                string name = iter.Current.GetAttribute("name", "");
                string friendlyname = iter.Current.GetAttribute("friendlyname", "");
                bool enabled = Convert.ToBoolean(iter.Current.GetAttribute("enabled", ""));

                verList.Add(new Version(name, friendlyname, enabled));
            }
            return verList;

        }

        static List<Feature> GetGlobalFeatureList(XPathNodeIterator iter) 
        {

            List<Feature> featList = new List<Feature>();
            while (iter.MoveNext())
            {
                string name = iter.Current.GetAttribute("name", "");
                string friendlyname = iter.Current.GetAttribute("friendlyname", "");
                bool enabled = Convert.ToBoolean(iter.Current.GetAttribute("enabled", ""));

                featList.Add(new Feature(name, friendlyname, enabled));
            }

            return featList;
        }

        static List<Feature>  GetLocalFeatureList(XPathNodeIterator iter) 
        {

            List<Feature> featList = new List<Feature>();
            while (iter.MoveNext())
            {
                string featurename = iter.Current.GetAttribute("name", "");
                bool featureenabled = Convert.ToBoolean(iter.Current.GetAttribute("enabled", ""));
                if (featureenabled)
                {
                    Feature feat = GlobalFeatureList.Find(x => x.Name == featurename);
                    //if global feature is populated, then check
                    if (feat == null && GlobalFeatureList.Count > 0)
                    {
                        throw new ArgumentException(string.Format("feature {0} doesn't exist in global list", featurename));
                    }
                    else
                    {
                        featList.Add(feat);
                    }
                }

            }
            return featList;


        }
        static List<Version>  GetLocalVersionList(XPathNodeIterator iter) 
        {

            List<Version> verList = new List<Version>();
            while (iter.MoveNext())
            {
                string versionename = iter.Current.GetAttribute("name", "");
                bool versionenabled = Convert.ToBoolean(iter.Current.GetAttribute("enabled", ""));

                //enable this for all Versions
                if (versionename == "All" && versionenabled == true)
                {
                    return GlobalVersionList;
                }
                if (versionenabled)
                {
                    Version ver = GlobalVersionList.Find(x => x.Name == versionename);
                    //if global version is populated, then check
                    if (ver == null && GlobalVersionList.Count > 0 )
                    {
                        throw new ArgumentException(string.Format("versioin {0} doesn't exist in global list", versionename));
                    }
                    else
                    {
                        verList.Add(ver);
                    }
                }

            }
            return verList;
        }


        
        static List<Scenario> GetLocalScenarioList(XPathNodeIterator iter)
        {

            List<Scenario> tempList = new List<Scenario>();

            while (iter.MoveNext())
            {
                string tempname = iter.Current.GetAttribute("name", "");
                bool tempenabled = Convert.ToBoolean(iter.Current.GetAttribute("enabled", ""));

                //enable this for all Scenarios
                if (tempname == "All" && tempenabled == true)
                {
                    return GlobalScenarioList;
                }
                if (tempenabled)
                {
                    Scenario temp = GlobalScenarioList.Find(x => x.Name == tempname);
                    //if global templatelist populated
                    if (temp == null && GlobalScenarioList.Count > 0)
                    {
                        throw new ArgumentException(string.Format("template {0} doesn't exist in global list", tempname));
                    }
                    else
                    {
                        tempList.Add(temp);
                    }
                }

            }
            return tempList;
        }

        static void PopulateTemplateFeatureVersion(XPathNodeIterator iter, DiagItem evt)
        {
            XPathNodeIterator iterLocalFeatures = iter.Current.Select("Features/Feature");
            evt.EnabledFeatures = GetLocalFeatureList(iterLocalFeatures);
            XPathNodeIterator iterLocalVersions = iter.Current.Select("Versions/Version");
            evt.EnabledVersions = GetLocalVersionList(iterLocalVersions);
            XPathNodeIterator iterLocalTemplates = iter.Current.Select("Scenarios/Scenario");
            evt.EnabledTemplate = GetLocalScenarioList(iterLocalTemplates);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="XmlFile"> XML template file</param>
        /// <param name="CatClause">select clause for Category of the Event such as PerfmonObject, EventType for trace, Category for XEvent</param>
        /// <param name="EventClause">select clause for the event.  eg. PerfmonCounter, Event etc</param>
        /// <param name="evtType">Enum</param>
        /// <returns>List of Categories</returns>
        static List<DiagCategory>  GetEventCategoryList (string XmlFile, string CatClause, string EventClause, EventType evtType)
        {
            List<DiagCategory> catList = new List<DiagCategory>();

            XPathDocument traceDoc = new XPathDocument(XmlFile); //new XPathDocument("TraceEvents.xml");
            XPathNavigator rootnav = traceDoc.CreateNavigator();

            
            XPathNodeIterator iter = rootnav.Select(CatClause); //rootnav.Select("TraceEvents/EventType");
            while (iter.MoveNext())
            {
                string catname = iter.Current.GetAttribute("name", "");
                DiagCategory cat = new DiagCategory(iter.Current.Name, catname);
                catList.Add(cat);
                PopulateTemplateFeatureVersion(iter, cat);

           

                XPathNodeIterator iterEvents = iter.Current.Select(EventClause);  // iter.Current.Select("Event");
                while (iterEvents.MoveNext())
                {
                    string evtname = iterEvents.Current.GetAttribute("name", "");

                    DiagItem evt = null; //set to NULL because it will create child event for each type

                    if (evtType == EventType.TraceEvent)
                    {
                        string trcid = iterEvents.Current.GetAttribute("id", "");
                        TraceEvent trcevt = new TraceEvent(cat, iterEvents.Current.Name, evtname, trcid);
                        evt = trcevt;
                    }
                    else if (evtType == EventType.Perfmon)
                    {
                        evt = new DiagItem(cat, iterEvents.Current.Name, evtname);
                    }
                    else if (evtType == EventType.XEvent)
                    {
                        string evtpackage = iterEvents.Current.GetAttribute("package", "");
                        evt = new Xevent(cat, iterEvents.Current.Name, evtname, evtpackage);
                        //read field elements from eventfields section
                        XPathNodeIterator iterEventFields = iterEvents.Current.Select("eventfields/field");
                        while (iterEventFields.MoveNext())
                        {
                            string name = iterEventFields.Current.GetAttribute("name", "");
                            bool autoinclude = Convert.ToBoolean(iterEventFields.Current.GetAttribute("AutoInclude", ""));
                            bool isnum = Convert.ToBoolean(iterEventFields.Current.GetAttribute("IsNum", ""));
                            EventField evtField = new EventField(name, autoinclude, isnum);
                            (evt as Xevent).EventFieldList.Add(evtField);
                        }
                        //read action elements from eventactions section
                        XPathNodeIterator iterEventActions = iterEvents.Current.Select("eventactions/action");
                        while (iterEventActions.MoveNext())
                        {
                            string package = iterEventActions.Current.GetAttribute("package", "");
                            string name = iterEventActions.Current.GetAttribute("name", "");
                            EventAction evtAction = new EventAction(package, name);
                            (evt as Xevent).EventActionList.Add(evtAction);
                        }
                    }
                    else
                    {
                        throw new ArgumentException("GetEventCategoryList doesn't know how to handle this type of event yet");
                    }

                    PopulateTemplateFeatureVersion(iterEvents, evt);
                    cat.DiagEventList.Add(evt);
                }
            }

            return catList;

        }

        

        public static DiagCategory GetCustomGroup (string CustomGroupName, string filename)
        {

            //AS currently doesn't support public release
            if (!string.IsNullOrEmpty(CustomGroupName)  &&  (DiagRuntime.IsPublicVersion  == true  && CustomGroupName.ToUpper().Contains("ANALYSIS")))
            {
                return null;

            }
            DiagCategory cat;
            if (CustomGroupName != null)

            { 
                cat = new DiagCategory("CustomGroup", CustomGroupName);
            }
            else
            {
                cat = new DiagCategory("CustomGroup", "PlaceHolder"); //will change later
            }

            //we need to fake a custom xml file for TSQL Scripts to make it easier to develop



            XPathDocument doc;

            string CustomGroupDir = Path.GetDirectoryName(filename);
            string[] sqlfiles = Directory.GetFiles(CustomGroupDir, "*.sql");


            if (File.Exists (filename))
            { 
                
              doc = new XPathDocument(filename);
            }
            else if (sqlfiles.Length > 0)
            {
                StringBuilder sb = new StringBuilder();
                sb.Append("<?xml version=\"1.0\" standalone=\"yes\"?>\n\r");
                sb.Append("<CustomTasks>\n\r");

                foreach (string file in sqlfiles)
                {
                    string fileNameOnly = Path.GetFileName(file);
                    string format = "<CustomTask enabled = \"true\" groupname = \"{0}\" taskname = \"{1}\" type = \"TSQL_Script\" point = \"Startup\" wait = \"No\" cmd = \"{2}\" pollinginterval = \"0\" />";
                    sb.AppendFormat(format, cat.Name, fileNameOnly, fileNameOnly);


                }
                sb.Append("</CustomTasks>");

                StringReader stream = new StringReader(sb.ToString());

                doc = new XPathDocument(stream);
            }
            else
            {
                throw new ArgumentException("Invalide custom group");
            }



            XPathNavigator rootnav = doc.CreateNavigator();

            XPathNodeIterator iter = rootnav.Select("CustomTasks/CustomTask ");


            while (iter.MoveNext())
            {
                string groupname = iter.Current.GetAttribute("groupname", "");
                
                //reading it from the file
                if (CustomGroupName == null)
                {
                    cat.Name = groupname;
                }

                string taskname = iter.Current.GetAttribute("taskname", "");
                string type = iter.Current.GetAttribute("type", "");
                string point = iter.Current.GetAttribute("point", "");
                string wait = iter.Current.GetAttribute("wait", "");
                string cmd = iter.Current.GetAttribute("cmd", "");
                string strpollinginterval = iter.Current.GetAttribute("pollinginterval", "");

                Int32 pollinginterval = 0;
                if (!string.IsNullOrEmpty(strpollinginterval))
                {
                    pollinginterval = Convert.ToInt32(iter.Current.GetAttribute("pollinginterval", ""));
                }

                /*
                if (groupname != cat.Name)
                {
                    throw new ArgumentException(string.Format("The custom diagnotics group name supplied from file directory doesn't match the xml definition.  file directory is {0} and the xml group name is {1}", cat.Name, groupname));
                }*/


                CustomTask task = new CustomTask(cat, "CustomTask", taskname, type, point, wait, cmd, pollinginterval);
                cat.DiagEventList.Add(task);


                //merge file system and config xml files
                XPathDocument doc2 = new XPathDocument(@"Templates\CustomDiagnostics_Template.xml");
                XPathNavigator rootnav2 = doc2.CreateNavigator();
                XPathNodeIterator iter2 = rootnav2.Select(string.Format("CustomDiagnostics/CustomGroup[@name=\"{0}\"]/Scenarios/Scenario", cat.Name));

                task.EnabledTemplate = GetLocalScenarioList(iter2);

                XPathNodeIterator iterVersion = rootnav2.Select(string.Format("CustomDiagnostics/CustomGroup[@name=\"{0}\"]/Versions/Version", cat.Name));

                task.EnabledVersions = GetLocalVersionList(iterVersion);  // GlobalVersionList;

                XPathNodeIterator iterFeature = rootnav2.Select(string.Format("CustomDiagnostics/CustomGroup[@name=\"{0}\"]/Features/Feature", cat.Name));
                task.EnabledFeatures = GetLocalFeatureList (iterFeature);// GlobalFeatureList;


            }
            return cat;


        }

        static List<DiagCategory>  GetCustomDiagnostics()
        {
            List<DiagCategory> customList = new List<DiagCategory>();

            //string CustomDiag = Directory.GetParent(System.Reflection.Assembly.GetExecutingAssembly().FullName) + @"\CustomDiagnostics";
            string CustomDiag = Globals.ExePath + @"\CustomDiagnostics";
            DirectoryInfo dInfo = new DirectoryInfo(CustomDiag);
            DirectoryInfo[] subdirs = dInfo.GetDirectories();
            foreach (DirectoryInfo dirinfo in subdirs)
            {
              //  Logger.LogInfo(dirinfo.Name);

                //DiagCategory cat = new DiagCategory("CustomGroup", dirinfo.Name);


                DiagCategory cat = GetCustomGroup (dirinfo.Name, dirinfo.FullName + @"\CustomDiag.xml");
                //donit' want ot deal with empty folder

                if (null != cat && cat.DiagEventList.Count > 0)
                {
                    customList.Add(cat);
                }

            }
            return customList;

        }
        static void Init()
        {
            GlobalPlatformList.Add(new Platform("i386", "x86"));
            //GlobalPlatformList.Add(new Platform("ia64", "ia64"));
            GlobalPlatformList.Add(new Platform("x64", "x64"));


            XPathDocument doc = new XPathDocument(@"Templates\General_Template.xml");
            XPathNavigator rootnav = doc.CreateNavigator();

            //global version
            XPathNodeIterator iter = rootnav.Select("DiagMgr/Versions/Version");
            GlobalVersionList = GetGlobalVersionList(iter);


            //global features
            iter = rootnav.Select("DiagMgr/Features/Feature");
             GlobalFeatureList = GetGlobalFeatureList(iter);

            
            //global templates
            iter = rootnav.Select("DiagMgr/Scenarios/Scenario");
            while (iter.MoveNext())
            {
                string name = iter.Current.GetAttribute("name", "");
                string friendlname = iter.Current.GetAttribute("friendlyname", "");
                string target = iter.Current.GetAttribute("target", "");
                string description =                    iter.Current.GetAttribute("description", "");
                

                bool defaultchecked = Convert.ToBoolean(iter.Current.GetAttribute("DefaultChecked", ""));

                Scenario temp = new Scenario(name, friendlname, target, defaultchecked, description);

                XPathNodeIterator iterChildren = iter.Current.Select("Features/Feature");
                temp.EnabledFeatures = GetLocalFeatureList(iterChildren);
                iterChildren = iter.Current.Select("Versions/Version");
                temp.EnabledVersions =                GetLocalVersionList(iterChildren);
                GlobalScenarioList.Add(temp);
            }

            SQLTraceEventCategoryList = GetEventCategoryList(@"Templates\SQLTraceEvent_Template.xml", "TraceEvents/EventType", "Event", EventType.TraceEvent);

            //ASTraceEventCategoryList = GetEventCategoryList(@"Templates\ASTraceEvent_Template.xml", "TraceEvents/EventType", "Event", EventType.TraceEvent);
            SQLPerfmonCounterCategoryList = GetEventCategoryList(@"Templates\SQLPerfmon_Template.xml", "PerfmonCounters/PerfmonObject", "PerfmonCounter", EventType.Perfmon);

            //ASPerfmonCounterCategoryList = GetEventCategoryList(@"Templates\ASPerfmon_Template.xml", "PerfmonCounters/PerfmonObject", "PerfmonCounter", EventType.Perfmon);


            XEventCategoryList = GetEventCategoryList(@"Templates\SQLXevent_Template.xml", "XEvents/category", "event", EventType.XEvent);


            CustomDiagnosticsCategoryList = GetCustomDiagnostics();

            //CustomDiagnosticsCategoryList = GetEventCategoryList(@"Templates\CustomDiagnostics_Template.xml", "CustomDiagnostics/CustomGroup", "CustomTask", EventType.CustomDiagnostics);

        }
        



    }
}
