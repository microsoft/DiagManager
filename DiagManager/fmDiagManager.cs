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
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Xml;
using System.Xml.XPath;
using System.IO;
using System.Diagnostics;
using PssdiagConfig;
namespace PssdiagConfig
{
    public partial class fmDiagManager : Form
    {

        
        public fmDiagManager()
        {
            InitializeComponent();
            this.StartPosition = FormStartPosition.CenterScreen;

        }

        private void fmDiagManager_Load(object sender, EventArgs e)
        {


            try
            {
                // Populate the ContextMenuStrip control with its default items.
                this.contextMenuStripCustomDiag.Items.Add("Edit");
                this.contextMenuStripCustomDiag.ItemClicked += ToolStrip_ItemClicked;
                contextMenuStripCustomDiag.Opening += new System.ComponentModel.CancelEventHandler(cms_Opening);


                //load user preferences
                Globals.UserPreferences = Preferences.Load();
                DiagRuntime.MainForm = this;


                string build = "";

                //Removing dependency on sqldiag_internal
                //Need to remove after testing
                /*
                if (DiagRuntime.IsPublicVersion == true)
                {
                    build = "Public";
                }
                */
                this.Text = this.Text + " (" + Application.ProductVersion + "" + build +  ")";


                //setting up defaults when form is being loaded
                SetupRadioButtons<Feature>(gb_Feature, DiagFactory.GlobalFeatureList);
                SetupRadioButtons<Platform>(gb_Plat, DiagFactory.GlobalPlatformList);
                SetupRadioButtons<Version>(gb_Version2, DiagFactory.GlobalVersionList);
                SetChecked(gb_Feature, DiagRuntime.UserDefaultSetting[Res.Feature]);
                SetChecked(gb_Version2, DiagRuntime.UserDefaultSetting[Res.Version]);
                SetChecked(gb_Plat, DiagRuntime.UserDefaultSetting[Res.Platform]);
                txt_OutputFolder.Text = DiagRuntime.UserDefaultSetting[Res.OutputFolder];

                //at this time, we need to use default settings

                SetDefaultXeventOrProfiler();
                SetDefaultScenarioList();
                RefreshTreeViews(DiagRuntime.UserDefaultSetting);

                SetEventHandlers(gb_Feature);
                SetEventHandlers(gb_Plat);
                SetEventHandlers(gb_Version2);
                SetFont(this);
                DiagRuntime.MainForm = this;


                SetPreferences();
                Util.ResetAllControlsBackColor(this, Globals.UserPreferences.GetBackgroundColor());
            }
            catch (Exception ex)
            {
                MessageBox.Show("Exception has occurred: " + ex.ToString());

            }
            

            
            
        }

        public void SetPreferences()
        {
            Util.ResetAllControlsBackColor(this, Globals.UserPreferences.GetBackgroundColor());
            this.txt_OutputFolder.Text = Globals.UserPreferences.DefaultPssdPath;
        }
     
        #region Properties
        private string SelectedFeature
        {
            get
            {
                return GetCheckedRadioButtion(gb_Feature).Tag.ToString();
            }
        }

        private string SelectedVersion
        {
            get
            {
                return GetCheckedRadioButtion(gb_Version2).Tag.ToString();
            }
        }

        private string SelectedPlatform
        {
            get
            {
                return GetCheckedRadioButtion(gb_Plat).Tag.ToString();
            }
        }
        



        const Int32 X = 20;
        const Int32 Y_Interval = 30;
        const Int32 Initial_Y = 20;

        //set up radio buttons for features, versions etc
        private void SetupRadioButtons<T> (GroupBox gb,  List<T> mylist)
        {
            Int32 Current_Y = Initial_Y;
            foreach (T item in mylist)
            {
                RadioButton button = new RadioButton();
                DiagItem evt = item as DiagItem;

                Feature ft = item as Feature;

                //we currently don't support public verioin of AS
                if (ft !=null && ft.Name=="AS" && DiagRuntime.IsPublicVersion == true)
                {
                    continue;
                }

                //if this version is not enabled, don't display, for example 2005 is no longer supported
                Version ver = evt as Version;
                if (ver != null && ver.Enabled == false)
                {
                    continue;

                }
                button.Text = evt.FriendlyName;
                button.Width = 120;
                button.Tag = item;
                button.Location = new System.Drawing.Point(X, Current_Y);
                gb.Controls.Add(button);
                Current_Y += Y_Interval;

            }

        }


        //this is used when user makes changes on feature and version
        private void SetDefaultScenarioList()
        {
            cbl_Scenario.Items.Clear();
            List<Scenario> scenarioList = DiagFactory.GetGlobalScenarioListByFeatureVersion(this.SelectedFeature, this.SelectedVersion);
            UserSetting setting = ObjectCopier.Clone<UserSetting>(DiagRuntime.AppSetting);
            setting["Feature"] = GetCheckedRadioButtion(gb_Feature).Tag.ToString();
            setting["Version"] = GetCheckedRadioButtion(gb_Version2).Tag.ToString();
            //populate initial Scenario
            foreach (Scenario evtScenario in scenarioList)
            {
                bool shoulldcheck = false;
                if (!string.IsNullOrEmpty(setting.DefaultScenarioList.Find(x => x.ToString() == evtScenario.Name)))
                {
                    shoulldcheck = true;

                }
                cbl_Scenario.Items.Add(evtScenario, shoulldcheck);
            }
        }

        private UserSetting m_setting = ObjectCopier.Clone<UserSetting>(DiagRuntime.UserDefaultSetting);
        public UserSetting UserChoice
        {
            get
            {
                //we don't want to change default settings
                UserSetting setting = m_setting;
                
                setting[Res.Feature] = GetCheckedRadioButtion(gb_Feature).Tag.ToString();
                setting[Res.Platform] = GetCheckedRadioButtion(gb_Plat).Tag.ToString();
                setting[Res.Version] = GetCheckedRadioButtion(gb_Version2).Tag.ToString();
                setting[Res.MachineName] = this.txt_MachineName.Text;
                setting[Res.InstanceName] = this.txt_InstanceName.Text;

             
                //Profiler
                setting[Res.CollectProfiler] = cb_CaptureTrace.Checked.ToString().ToLower();
                setting[Res.ProfilerMaxFileSize] = txt_TraceMaxFileSize.Text;
                setting[Res.ProfilerFileCount] = txt_TraceRolloverFiles.Text;
                

                //XEvent

                setting[Res.CollectXEvent] = cb_CaptureXevent.Checked.ToString().ToLower();
                setting[Res.XEventMaxFileSize] = txt_XEvent_MaxFileSize.Text;
                setting[Res.XEventFileCount] = txt_XEventRolloverFiles.Text;

                //Eventlogs
                setting[Res.CollectEventLogs] = "true";
                setting[Res.CollectEventLogsStartup] = cb_EventLogStartup.Checked.ToString().ToLower();
                setting[Res.CollectEventLogShutdown] = cb_EventLogShtudown.Checked.ToString().ToLower();
                //sqldiag
                setting[Res.CollectSqldiag] = "true";
                setting[Res.CollectSqldiagStartup] = chkSQLDiagStartup.Checked.ToString().ToLower();
                setting[Res.CollectSqldaigShutdown] = chkSQLDIAGShutdown.Checked.ToString().ToLower();

                //Blocking -- dont' need it for later versions
                setting[Res.CollectBlocking] = "false";
                setting[Res.CollectBlockingStartup] = "false";
                setting[Res.CollectBlockingShutdown] = "false";
                setting[Res.CollectBlockingMaxFileSize] = "350";


                //Perfmon

                setting[Res.CollectPerfmon] = cb_CapturePerfmon.Checked.ToString().ToLower();
                setting[Res.CollectPerfmonShutdown] = "true";
                setting[Res.PerfmonInterval] = txt_PerfmonInterval.Text;
                setting[Res.PerfmonMaxFileSize] = txt_MaxPerfmonFileSize.Text;


                //Profiler
                setting[Res.CollectProfiler] = this.cb_CaptureTrace.Checked.ToString().ToLower();
                setting[Res.ProfilerMaxFileSize] = this.txt_TraceMaxFileSize.Text;
                setting[Res.ProfilerFileCount] = this.txt_TraceRolloverFiles.Text;


                setting[Res.OutputFolder] = txt_OutputFolder.Text;


                List<string> UserChosenScenarioList =  new List<string>();
                foreach (Object item in cbl_Scenario.CheckedItems)
                {
                    UserChosenScenarioList.Add((item as Scenario).Name);
                }
                setting.SetUserChosenScenarioList(UserChosenScenarioList);

                setting.ProfilerCategoryList = DiagTreeMgr.CategoryListFromTree(tv_Trace);
                setting.PerfmonCategoryList = DiagTreeMgr.CategoryListFromTree(tv_Perfmon);
                setting.CustomDiagCategoryList = DiagTreeMgr.CategoryListFromTree(tv_CustomDiag);
                setting.XEventCategoryList = DiagTreeMgr.CategoryListFromTree(tv_XEvent);
                return setting;
            }
        }

    #endregion 


        private void ToolStrip_ItemClicked(Object sender, ToolStripItemClickedEventArgs e)
        {
            //DiagCategory cat = tv_CustomDiag.SelectedNode.Tag as DiagCategory;
            //MessageBox.Show(cat.ToString());
            //fmCustomerDiagEditor frm = new fmCustomerDiagEditor(cat);
            //frm.Show();
        }

        void cms_Opening(object sender, System.ComponentModel.CancelEventArgs e)
        {
            //TreeView tv = tv_CustomDiag;

            //if this is a child node, don't bother to do edit
            /*
            if (tv.SelectedNode.Parent != null)
            {
                e.Cancel = true;
            }
            */
            
            
        }
        private RadioButton GetCheckedRadioButtion (GroupBox gBox)
        {
            RadioButton rButton = (RadioButton)gBox.Controls.OfType<RadioButton>().FirstOrDefault<RadioButton>(x => x.Checked == true);
            return rButton;
        }
        
        private void SetChecked (GroupBox gBox, string tag)
        {

            RadioButton rButton = (RadioButton)gBox.Controls.OfType<RadioButton>().First<RadioButton>(x => x.Tag.ToString() == tag);
            if (rButton == null)
            {
                throw new ArgumentException("Unable to find the button with tag " + tag);
            }
            rButton.Checked = true;
        }
        private void RefreshTreeViews(UserSetting setting)
        {
            List<DiagCategory> TraceList;
            List<DiagCategory> PerfmonList;

            if (this.UserChoice["Feature"] == "SQL")
            {
                TraceList = DiagFactory.SQLTraceEventCategoryList;
                PerfmonList = DiagFactory.SQLPerfmonCounterCategoryList;
                DiagTreeMgr.PopulateTree(tv_Perfmon, PerfmonList, setting);
                DiagTreeMgr.PopulateTree(tv_Trace, TraceList, setting);
            }
            else
            {
                //TraceList = DiagFactory.ASTraceEventCategoryList;
                //PerfmonList = DiagFactory.ASPerfmonCounterCategoryList;
                //No-op after removing SSAS
            }
            
            DiagTreeMgr.PopulateTree(tv_XEvent, DiagFactory.XEventCategoryList, setting);
            DiagTreeMgr.PopulateTree(tv_CustomDiag, DiagFactory.CustomDiagnosticsCategoryList, setting);
        }
    

        //this is hooked up after initial change
        private void radioButtons_CheckedChanged (object sender, EventArgs e)
        {
            RadioButton btn = sender as RadioButton;
            //only chnage default templates if user chose version of feature
            if (btn.Tag.GetType() == typeof(Feature) || btn.Tag.GetType() == typeof(Version))
            {
                SetDefaultXeventOrProfiler();
                SetDefaultScenarioList();
            }
            RefreshTreeViews(this.UserChoice);
        }

        /*
         * 
         * Times New Roman
         * Arial
         */
        private void SetFont(Control parent)
        {

            foreach (Control ctrl in parent.Controls)
            {
                Type type = ctrl.GetType();
                Font EffectiveFont = new Font("Arial", 10, FontStyle.Regular);
                Font Font1 = new Font("Arial", 12, FontStyle.Regular);

                Font Font2 = new Font("Times New Roman", 10, FontStyle.Regular);
                
                if (type == typeof(GroupBox) || type == typeof(TabControl) )
                {
                    object tag = ctrl.Tag;
                    if (tag !=null && tag.ToString() == "20")
                    {
                        //do nothing for now;
                    }
                    else
                    {
                        EffectiveFont = Font1;
                    }
                    
                }
                else if (type == typeof(RadioButton) || type == typeof (CheckedListBox))
                {
                    EffectiveFont = Font2;
                }
                else if (type == typeof (TextBox))
                {
                    ctrl.Width = 120;
                    ctrl.Height = 75;
                }
                else if (type == typeof(CheckBox))
                {
                   
                }
              

                ctrl.Font = EffectiveFont;
                if (ctrl.Controls.Count > 0)
                {
                    SetFont(ctrl);
                }
            }
        }

        private void SetDefaultXeventOrProfiler()
        {
            string Feature = UserChoice[Res.Feature];
            string Version = UserChoice[Res.Version];

            DefaultChoice defaults = UserChoice.GetDefaultChoiceByFeatureVersion(Feature, Version);
            cb_CaptureXevent.Checked = defaults.Xevent;
            cb_CaptureTrace.Checked = defaults.Profiler;



        }
        private void SetEventHandlers(GroupBox gBox)
        {
            foreach (Control ctrl in gBox.Controls)
            {
                Type type = ctrl.GetType();
                if (type == typeof(RadioButton))
                {
                    RadioButton btn = ctrl as RadioButton;
                    btn.CheckedChanged += radioButtons_CheckedChanged;
                }
            }

        }


        private void btnSaveSelection_Click(object sender, EventArgs e)
        {
            

            if ((txt_MachineName.Text=="." || txt_InstanceName.Text=="*") && UserChoice[Res.Feature] == "AS")
            {
                MessageBox.Show("For Analysis Service, you must specify server and instance name!");
                return;
            }

            SaveFileDialog saveFileDialog1 = new SaveFileDialog();
            saveFileDialog1.Filter = "zip files (*.zip)|*.zip|All files (*.*)|*.*";
            saveFileDialog1.FilterIndex = 1 ;
            saveFileDialog1.RestoreDirectory = true;
            string DestFullFileName = txt_OutputFolder.Text + @"\pssd.zip";
            
            saveFileDialog1.FileName = DestFullFileName;

            if (saveFileDialog1.ShowDialog(this) == DialogResult.OK)
            {
                DestFullFileName = saveFileDialog1.FileName;
                PackageMgr pckMgr = new PackageMgr(this.UserChoice, DestFullFileName);
                pckMgr.MakeZip();
            }

            

        }
        private void cbl_Scenario_SelectedIndexChanged(object sender, EventArgs e)
        {
           
            RefreshTreeViews(this.UserChoice);
        }

        private void tlp_SuperOverall_Paint(object sender, PaintEventArgs e)
        {

        }

        private void gb_Feature_Enter(object sender, EventArgs e)
        {

        }

        private void On_TextChanged_ValidateNumeric (object sender, EventArgs e)
        {
            TextBox txt = sender as TextBox;
            Int32 result;
            string ValueEntered = txt.Text;
            if (false == Int32.TryParse(ValueEntered, out result))
            {
                //reverting
                //txt.Text = txt.Tag.ToString();
                txt.Text = txt.Tag.ToString();
                MessageBox.Show(string.Format("The Value \"{0}\" you entered is not a number. Reverting to default value. Please retry", ValueEntered));
            }
        }
        private void On_Enter_SaveOldValue (object sender, EventArgs e)
        {
            //no need to save old value
            //TextBox txt = sender as TextBox;
            //txt.Tag = txt.Text;
        }

        private void btnTraceFilter_Click(object sender, EventArgs e)
        {
            //fmTraceFilters filters = new fmTraceFilters();
            
            //filters.ShowDialog();
        }

        private void tlp_top_overall_Paint(object sender, PaintEventArgs e)
        {

        }

        private void contextMenuStripCustomDiag_Opening(object sender, CancelEventArgs e)
        {

        }

        private void fmDiagManager_Leave(object sender, EventArgs e)
        {
           
        }

        private void fmDiagManager_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (Globals.UserPreferences != null)
            {
                Globals.UserPreferences.Save();

            }
        }

        private void btnSettings_Click(object sender, EventArgs e)
        {
            fmSettings formSettings = new fmSettings();
            formSettings.StartPosition= FormStartPosition.CenterScreen;
            formSettings.ShowDialog();
            
        }


        
        private int toolTipIndex=-1;



        private void showCheckBoxToolTip(object sender, MouseEventArgs e)
        {
            if (toolTipIndex != this.cbl_Scenario.IndexFromPoint(e.Location))
            {
                toolTipIndex = cbl_Scenario.IndexFromPoint(cbl_Scenario.PointToClient(MousePosition));
                if (toolTipIndex > -1)
                {
                    // toolTipScenario.SetToolTip(cbl_Scenario, cbl_Scenario.Items[toolTipIndex].ToString());
                    Scenario scen = cbl_Scenario.Items[toolTipIndex] as Scenario;
                    toolTipScenario.SetToolTip(cbl_Scenario, scen.Description);
                    
                }
            }
        }

        private void cbl_Scenario_MouseHover(object sender, EventArgs e)
        {

        }

        private void cbl_Scenario_MouseMove(object sender, MouseEventArgs e)
        {
            showCheckBoxToolTip(sender, e);
        }

        private void cbl_Scenario_MouseLeave(object sender, EventArgs e)
        {
            toolTipScenario.Hide(cbl_Scenario);
        }

        

        private void gb_MachineName_MouseHover(object sender, EventArgs e)
        {
            tooltipMachineName.SetToolTip(gb_MachineName, "Enter Machine name.  For cluster, enter SQL Server vitual server name!");
        }

        private void txt_MachineName_MouseHover(object sender, EventArgs e)
        {
            //tooltipMachineName.SetToolTip(txt_MachineName, "Enter Machine name.  For cluster, enter SQL Server vitual server name!");
        }

        private void txt_InstanceName_MouseHover(object sender, EventArgs e)
        {
            //tooltipInstanceName.SetToolTip(txt_InstanceName, "Enter instance name. for Default instance, enter MSSQLSERVER");
        }

        private void gb_InstanceName_MouseHover(object sender, EventArgs e)
        {
            tooltipInstanceName.SetToolTip(gb_InstanceName, "Enter instance name. for Default instance, enter MSSQLSERVER");
        }

        private void btnHelp_Click(object sender, EventArgs e)
        {
            fmHelp help = new fmHelp();
            help.StartPosition = FormStartPosition.CenterScreen;
            help.ShowDialog();
        }

        private void cb_CapturePerfmon_CheckedChanged(object sender, EventArgs e)
        {
           
        }

        private void cb_CaptureXevent_CheckedChanged(object sender, EventArgs e)
        {

        }

        private void tv_Perfmon_AfterSelect(object sender, TreeViewEventArgs e)
        {

        }
    }
}
