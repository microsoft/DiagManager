/**************************************************
beginning of licensing agreement
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
end of licensing agreement
**************************************************/
namespace PssdiagConfig
{
    partial class fmDiagManager
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(fmDiagManager));
            this.contextMenuStripCustomDiag = new System.Windows.Forms.ContextMenuStrip(this.components);
            this.preferencesToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.tlp_Overall_bottom = new System.Windows.Forms.TableLayoutPanel();
            this.tlp_UserChoice = new System.Windows.Forms.TableLayoutPanel();
            this.gb_Feature = new System.Windows.Forms.GroupBox();
            this.gb_Version2 = new System.Windows.Forms.GroupBox();
            this.gb_MachineName = new System.Windows.Forms.GroupBox();
            this.txt_MachineName = new System.Windows.Forms.TextBox();
            this.gb_InstanceName = new System.Windows.Forms.GroupBox();
            this.txt_InstanceName = new System.Windows.Forms.TextBox();
            this.gb_Plat = new System.Windows.Forms.GroupBox();
            this.tabControl_Events = new System.Windows.Forms.TabControl();
            this.tp_Xevent = new System.Windows.Forms.TabPage();
            this.tlp_Xevent = new System.Windows.Forms.TableLayoutPanel();
            this.tv_XEvent = new System.Windows.Forms.TreeView();
            this.tlp_XEvent_top = new System.Windows.Forms.TableLayoutPanel();
            this.gb_CaptureXEvent = new System.Windows.Forms.GroupBox();
            this.cb_CaptureXevent = new System.Windows.Forms.CheckBox();
            this.gb_XEvent_FileSize = new System.Windows.Forms.GroupBox();
            this.txt_XEvent_MaxFileSize = new System.Windows.Forms.TextBox();
            this.gb_XEvnt_RolloverFiles = new System.Windows.Forms.GroupBox();
            this.txt_XEventRolloverFiles = new System.Windows.Forms.TextBox();
            this.tp_ProfilerTrace = new System.Windows.Forms.TabPage();
            this.tlp_Trace = new System.Windows.Forms.TableLayoutPanel();
            this.tv_Trace = new System.Windows.Forms.TreeView();
            this.tlp_ProfilerTrace_Top = new System.Windows.Forms.TableLayoutPanel();
            this.gb_CaptureProfilerTrace = new System.Windows.Forms.GroupBox();
            this.cb_CaptureTrace = new System.Windows.Forms.CheckBox();
            this.gb_MaxTraceFileSize = new System.Windows.Forms.GroupBox();
            this.txt_TraceMaxFileSize = new System.Windows.Forms.TextBox();
            this.gb_TraceRolloverFiles = new System.Windows.Forms.GroupBox();
            this.txt_TraceRolloverFiles = new System.Windows.Forms.TextBox();
            this.tp_Perfmon = new System.Windows.Forms.TabPage();
            this.tlp_Perfmon = new System.Windows.Forms.TableLayoutPanel();
            this.tlp_Perfmon_top = new System.Windows.Forms.TableLayoutPanel();
            this.gb_CapturePerfmon = new System.Windows.Forms.GroupBox();
            this.cb_CapturePerfmon = new System.Windows.Forms.CheckBox();
            this.gb_MaxPerfmonFileSize = new System.Windows.Forms.GroupBox();
            this.txt_MaxPerfmonFileSize = new System.Windows.Forms.TextBox();
            this.gb_PerfmonInterval = new System.Windows.Forms.GroupBox();
            this.txt_PerfmonInterval = new System.Windows.Forms.TextBox();
            this.tv_Perfmon = new System.Windows.Forms.TreeView();
            this.tp_CustomDiag = new System.Windows.Forms.TabPage();
            this.tlp_CustomDiag = new System.Windows.Forms.TableLayoutPanel();
            this.tv_CustomDiag = new System.Windows.Forms.TreeView();
            this.tp_Misc = new System.Windows.Forms.TabPage();
            this.tlp_Misc = new System.Windows.Forms.TableLayoutPanel();
            this.gb_EventLog = new System.Windows.Forms.GroupBox();
            this.cb_EventLogShtudown = new System.Windows.Forms.CheckBox();
            this.cb_EventLogStartup = new System.Windows.Forms.CheckBox();
            this.gb_sqldiag = new System.Windows.Forms.GroupBox();
            this.chkSQLDIAGShutdown = new System.Windows.Forms.CheckBox();
            this.chkSQLDiagStartup = new System.Windows.Forms.CheckBox();
            this.gb_outputFoler = new System.Windows.Forms.GroupBox();
            this.txt_OutputFolder = new System.Windows.Forms.TextBox();
            this.gb_Scenario = new System.Windows.Forms.GroupBox();
            this.cbl_Scenario = new System.Windows.Forms.CheckedListBox();
            this.tlp_SuperOverall = new System.Windows.Forms.TableLayoutPanel();
            this.tlp_top_overall = new System.Windows.Forms.TableLayoutPanel();
            this.btnSettings = new System.Windows.Forms.Button();
            this.btnSaveSelection = new System.Windows.Forms.Button();
            this.btnHelp = new System.Windows.Forms.Button();
            this.toolTipScenario = new System.Windows.Forms.ToolTip(this.components);
            this.tooltipMachineName = new System.Windows.Forms.ToolTip(this.components);
            this.tooltipInstanceName = new System.Windows.Forms.ToolTip(this.components);
            this.contextMenuStripCustomDiag.SuspendLayout();
            this.tlp_Overall_bottom.SuspendLayout();
            this.tlp_UserChoice.SuspendLayout();
            this.gb_MachineName.SuspendLayout();
            this.gb_InstanceName.SuspendLayout();
            this.tabControl_Events.SuspendLayout();
            this.tp_Xevent.SuspendLayout();
            this.tlp_Xevent.SuspendLayout();
            this.tlp_XEvent_top.SuspendLayout();
            this.gb_CaptureXEvent.SuspendLayout();
            this.gb_XEvent_FileSize.SuspendLayout();
            this.gb_XEvnt_RolloverFiles.SuspendLayout();
            this.tp_ProfilerTrace.SuspendLayout();
            this.tlp_Trace.SuspendLayout();
            this.tlp_ProfilerTrace_Top.SuspendLayout();
            this.gb_CaptureProfilerTrace.SuspendLayout();
            this.gb_MaxTraceFileSize.SuspendLayout();
            this.gb_TraceRolloverFiles.SuspendLayout();
            this.tp_Perfmon.SuspendLayout();
            this.tlp_Perfmon.SuspendLayout();
            this.tlp_Perfmon_top.SuspendLayout();
            this.gb_CapturePerfmon.SuspendLayout();
            this.gb_MaxPerfmonFileSize.SuspendLayout();
            this.gb_PerfmonInterval.SuspendLayout();
            this.tp_CustomDiag.SuspendLayout();
            this.tlp_CustomDiag.SuspendLayout();
            this.tp_Misc.SuspendLayout();
            this.tlp_Misc.SuspendLayout();
            this.gb_EventLog.SuspendLayout();
            this.gb_sqldiag.SuspendLayout();
            this.gb_outputFoler.SuspendLayout();
            this.gb_Scenario.SuspendLayout();
            this.tlp_SuperOverall.SuspendLayout();
            this.tlp_top_overall.SuspendLayout();
            this.SuspendLayout();
            // 
            // contextMenuStripCustomDiag
            // 
            this.contextMenuStripCustomDiag.ImageScalingSize = new System.Drawing.Size(20, 20);
            this.contextMenuStripCustomDiag.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.preferencesToolStripMenuItem});
            this.contextMenuStripCustomDiag.Name = "contextMenuStripCustomDiag";
            this.contextMenuStripCustomDiag.Size = new System.Drawing.Size(155, 28);
            this.contextMenuStripCustomDiag.Opening += new System.ComponentModel.CancelEventHandler(this.contextMenuStripCustomDiag_Opening);
            // 
            // preferencesToolStripMenuItem
            // 
            this.preferencesToolStripMenuItem.Name = "preferencesToolStripMenuItem";
            this.preferencesToolStripMenuItem.Size = new System.Drawing.Size(154, 24);
            this.preferencesToolStripMenuItem.Text = "Preferences";
            // 
            // tlp_Overall_bottom
            // 
            this.tlp_Overall_bottom.BackColor = System.Drawing.SystemColors.Control;
            this.tlp_Overall_bottom.ColumnCount = 7;
            this.tlp_Overall_bottom.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 2F));
            this.tlp_Overall_bottom.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 20F));
            this.tlp_Overall_bottom.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 2F));
            this.tlp_Overall_bottom.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.tlp_Overall_bottom.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 2F));
            this.tlp_Overall_bottom.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 47F));
            this.tlp_Overall_bottom.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 2F));
            this.tlp_Overall_bottom.Controls.Add(this.tlp_UserChoice, 1, 0);
            this.tlp_Overall_bottom.Controls.Add(this.tabControl_Events, 5, 0);
            this.tlp_Overall_bottom.Controls.Add(this.gb_Scenario, 3, 0);
            this.tlp_Overall_bottom.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tlp_Overall_bottom.Location = new System.Drawing.Point(4, 93);
            this.tlp_Overall_bottom.Margin = new System.Windows.Forms.Padding(4);
            this.tlp_Overall_bottom.Name = "tlp_Overall_bottom";
            this.tlp_Overall_bottom.RowCount = 1;
            this.tlp_Overall_bottom.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tlp_Overall_bottom.Size = new System.Drawing.Size(1615, 793);
            this.tlp_Overall_bottom.TabIndex = 1;
            // 
            // tlp_UserChoice
            // 
            this.tlp_UserChoice.BackColor = System.Drawing.Color.Transparent;
            this.tlp_UserChoice.ColumnCount = 1;
            this.tlp_UserChoice.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tlp_UserChoice.Controls.Add(this.gb_Feature, 0, 2);
            this.tlp_UserChoice.Controls.Add(this.gb_Version2, 0, 4);
            this.tlp_UserChoice.Controls.Add(this.gb_MachineName, 0, 0);
            this.tlp_UserChoice.Controls.Add(this.gb_InstanceName, 0, 1);
            this.tlp_UserChoice.Controls.Add(this.gb_Plat, 0, 3);
            this.tlp_UserChoice.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tlp_UserChoice.Location = new System.Drawing.Point(36, 4);
            this.tlp_UserChoice.Margin = new System.Windows.Forms.Padding(4);
            this.tlp_UserChoice.Name = "tlp_UserChoice";
            this.tlp_UserChoice.RowCount = 5;
            this.tlp_UserChoice.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 12F));
            this.tlp_UserChoice.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 12F));
            this.tlp_UserChoice.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 15F));
            this.tlp_UserChoice.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 20F));
            this.tlp_UserChoice.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 41F));
            this.tlp_UserChoice.Size = new System.Drawing.Size(315, 785);
            this.tlp_UserChoice.TabIndex = 0;
            // 
            // gb_Feature
            // 
            this.gb_Feature.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_Feature.Location = new System.Drawing.Point(4, 192);
            this.gb_Feature.Margin = new System.Windows.Forms.Padding(4);
            this.gb_Feature.Name = "gb_Feature";
            this.gb_Feature.Padding = new System.Windows.Forms.Padding(4);
            this.gb_Feature.Size = new System.Drawing.Size(307, 109);
            this.gb_Feature.TabIndex = 5;
            this.gb_Feature.TabStop = false;
            this.gb_Feature.Text = " Feature";
            this.gb_Feature.Enter += new System.EventHandler(this.gb_Feature_Enter);
            // 
            // gb_Version2
            // 
            this.gb_Version2.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_Version2.Location = new System.Drawing.Point(4, 466);
            this.gb_Version2.Margin = new System.Windows.Forms.Padding(4);
            this.gb_Version2.Name = "gb_Version2";
            this.gb_Version2.Padding = new System.Windows.Forms.Padding(4);
            this.gb_Version2.Size = new System.Drawing.Size(307, 315);
            this.gb_Version2.TabIndex = 8;
            this.gb_Version2.TabStop = false;
            this.gb_Version2.Text = "Version";
            // 
            // gb_MachineName
            // 
            this.gb_MachineName.Controls.Add(this.txt_MachineName);
            this.gb_MachineName.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_MachineName.Location = new System.Drawing.Point(4, 4);
            this.gb_MachineName.Margin = new System.Windows.Forms.Padding(4);
            this.gb_MachineName.Name = "gb_MachineName";
            this.gb_MachineName.Padding = new System.Windows.Forms.Padding(4);
            this.gb_MachineName.Size = new System.Drawing.Size(307, 86);
            this.gb_MachineName.TabIndex = 10;
            this.gb_MachineName.TabStop = false;
            this.gb_MachineName.Text = "Machine Name";
            this.gb_MachineName.MouseHover += new System.EventHandler(this.gb_MachineName_MouseHover);
            // 
            // txt_MachineName
            // 
            this.txt_MachineName.Location = new System.Drawing.Point(9, 31);
            this.txt_MachineName.Margin = new System.Windows.Forms.Padding(4);
            this.txt_MachineName.Name = "txt_MachineName";
            this.txt_MachineName.Size = new System.Drawing.Size(208, 22);
            this.txt_MachineName.TabIndex = 1;
            this.txt_MachineName.Text = ".";
            this.txt_MachineName.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.txt_MachineName.MouseHover += new System.EventHandler(this.txt_MachineName_MouseHover);
            // 
            // gb_InstanceName
            // 
            this.gb_InstanceName.Controls.Add(this.txt_InstanceName);
            this.gb_InstanceName.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_InstanceName.Location = new System.Drawing.Point(4, 98);
            this.gb_InstanceName.Margin = new System.Windows.Forms.Padding(4);
            this.gb_InstanceName.Name = "gb_InstanceName";
            this.gb_InstanceName.Padding = new System.Windows.Forms.Padding(4);
            this.gb_InstanceName.Size = new System.Drawing.Size(307, 86);
            this.gb_InstanceName.TabIndex = 11;
            this.gb_InstanceName.TabStop = false;
            this.gb_InstanceName.Text = "Instance Name";
            this.gb_InstanceName.MouseHover += new System.EventHandler(this.gb_InstanceName_MouseHover);
            // 
            // txt_InstanceName
            // 
            this.txt_InstanceName.Location = new System.Drawing.Point(9, 30);
            this.txt_InstanceName.Margin = new System.Windows.Forms.Padding(4);
            this.txt_InstanceName.Name = "txt_InstanceName";
            this.txt_InstanceName.Size = new System.Drawing.Size(208, 22);
            this.txt_InstanceName.TabIndex = 3;
            this.txt_InstanceName.Text = "*";
            this.txt_InstanceName.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.txt_InstanceName.MouseHover += new System.EventHandler(this.txt_InstanceName_MouseHover);
            // 
            // gb_Plat
            // 
            this.gb_Plat.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_Plat.Location = new System.Drawing.Point(4, 309);
            this.gb_Plat.Margin = new System.Windows.Forms.Padding(4);
            this.gb_Plat.Name = "gb_Plat";
            this.gb_Plat.Padding = new System.Windows.Forms.Padding(4);
            this.gb_Plat.Size = new System.Drawing.Size(307, 149);
            this.gb_Plat.TabIndex = 12;
            this.gb_Plat.TabStop = false;
            this.gb_Plat.Text = "Platform";
            // 
            // tabControl_Events
            // 
            this.tabControl_Events.Controls.Add(this.tp_Xevent);
            this.tabControl_Events.Controls.Add(this.tp_ProfilerTrace);
            this.tabControl_Events.Controls.Add(this.tp_Perfmon);
            this.tabControl_Events.Controls.Add(this.tp_CustomDiag);
            this.tabControl_Events.Controls.Add(this.tp_Misc);
            this.tabControl_Events.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tabControl_Events.Location = new System.Drawing.Point(826, 4);
            this.tabControl_Events.Margin = new System.Windows.Forms.Padding(4);
            this.tabControl_Events.Name = "tabControl_Events";
            this.tabControl_Events.SelectedIndex = 0;
            this.tabControl_Events.ShowToolTips = true;
            this.tabControl_Events.Size = new System.Drawing.Size(751, 785);
            this.tabControl_Events.TabIndex = 1;
            // 
            // tp_Xevent
            // 
            this.tp_Xevent.Controls.Add(this.tlp_Xevent);
            this.tp_Xevent.Location = new System.Drawing.Point(4, 25);
            this.tp_Xevent.Margin = new System.Windows.Forms.Padding(4);
            this.tp_Xevent.Name = "tp_Xevent";
            this.tp_Xevent.Padding = new System.Windows.Forms.Padding(4);
            this.tp_Xevent.Size = new System.Drawing.Size(743, 756);
            this.tp_Xevent.TabIndex = 2;
            this.tp_Xevent.Text = "XEvent";
            this.tp_Xevent.ToolTipText = "For 2012 and above, XEvent is recommended";
            this.tp_Xevent.UseVisualStyleBackColor = true;
            // 
            // tlp_Xevent
            // 
            this.tlp_Xevent.ColumnCount = 1;
            this.tlp_Xevent.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tlp_Xevent.Controls.Add(this.tv_XEvent, 0, 1);
            this.tlp_Xevent.Controls.Add(this.tlp_XEvent_top, 0, 0);
            this.tlp_Xevent.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tlp_Xevent.Location = new System.Drawing.Point(4, 4);
            this.tlp_Xevent.Margin = new System.Windows.Forms.Padding(4);
            this.tlp_Xevent.Name = "tlp_Xevent";
            this.tlp_Xevent.RowCount = 2;
            this.tlp_Xevent.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 15F));
            this.tlp_Xevent.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 85F));
            this.tlp_Xevent.Size = new System.Drawing.Size(735, 748);
            this.tlp_Xevent.TabIndex = 0;
            // 
            // tv_XEvent
            // 
            this.tv_XEvent.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.tv_XEvent.CheckBoxes = true;
            this.tv_XEvent.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tv_XEvent.Location = new System.Drawing.Point(4, 116);
            this.tv_XEvent.Margin = new System.Windows.Forms.Padding(4);
            this.tv_XEvent.Name = "tv_XEvent";
            this.tv_XEvent.Size = new System.Drawing.Size(727, 628);
            this.tv_XEvent.TabIndex = 0;
            // 
            // tlp_XEvent_top
            // 
            this.tlp_XEvent_top.ColumnCount = 4;
            this.tlp_XEvent_top.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.tlp_XEvent_top.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.tlp_XEvent_top.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.tlp_XEvent_top.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.tlp_XEvent_top.Controls.Add(this.gb_CaptureXEvent, 0, 0);
            this.tlp_XEvent_top.Controls.Add(this.gb_XEvent_FileSize, 1, 0);
            this.tlp_XEvent_top.Controls.Add(this.gb_XEvnt_RolloverFiles, 2, 0);
            this.tlp_XEvent_top.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tlp_XEvent_top.Location = new System.Drawing.Point(4, 4);
            this.tlp_XEvent_top.Margin = new System.Windows.Forms.Padding(4);
            this.tlp_XEvent_top.Name = "tlp_XEvent_top";
            this.tlp_XEvent_top.RowCount = 1;
            this.tlp_XEvent_top.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tlp_XEvent_top.Size = new System.Drawing.Size(727, 104);
            this.tlp_XEvent_top.TabIndex = 1;
            // 
            // gb_CaptureXEvent
            // 
            this.gb_CaptureXEvent.Controls.Add(this.cb_CaptureXevent);
            this.gb_CaptureXEvent.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_CaptureXEvent.Location = new System.Drawing.Point(4, 4);
            this.gb_CaptureXEvent.Margin = new System.Windows.Forms.Padding(4);
            this.gb_CaptureXEvent.Name = "gb_CaptureXEvent";
            this.gb_CaptureXEvent.Padding = new System.Windows.Forms.Padding(4);
            this.gb_CaptureXEvent.Size = new System.Drawing.Size(173, 96);
            this.gb_CaptureXEvent.TabIndex = 0;
            this.gb_CaptureXEvent.TabStop = false;
            this.gb_CaptureXEvent.Text = "Capture ";
            // 
            // cb_CaptureXevent
            // 
            this.cb_CaptureXevent.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.cb_CaptureXevent.AutoSize = true;
            this.cb_CaptureXevent.Location = new System.Drawing.Point(63, 34);
            this.cb_CaptureXevent.Margin = new System.Windows.Forms.Padding(4);
            this.cb_CaptureXevent.Name = "cb_CaptureXevent";
            this.cb_CaptureXevent.Size = new System.Drawing.Size(15, 14);
            this.cb_CaptureXevent.TabIndex = 0;
            this.cb_CaptureXevent.UseVisualStyleBackColor = true;
            this.cb_CaptureXevent.CheckedChanged += new System.EventHandler(this.cb_CaptureXevent_CheckedChanged);
            // 
            // gb_XEvent_FileSize
            // 
            this.gb_XEvent_FileSize.Controls.Add(this.txt_XEvent_MaxFileSize);
            this.gb_XEvent_FileSize.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_XEvent_FileSize.Location = new System.Drawing.Point(185, 4);
            this.gb_XEvent_FileSize.Margin = new System.Windows.Forms.Padding(4);
            this.gb_XEvent_FileSize.Name = "gb_XEvent_FileSize";
            this.gb_XEvent_FileSize.Padding = new System.Windows.Forms.Padding(4);
            this.gb_XEvent_FileSize.Size = new System.Drawing.Size(173, 96);
            this.gb_XEvent_FileSize.TabIndex = 1;
            this.gb_XEvent_FileSize.TabStop = false;
            this.gb_XEvent_FileSize.Text = "Max Size (MB)";
            // 
            // txt_XEvent_MaxFileSize
            // 
            this.txt_XEvent_MaxFileSize.Location = new System.Drawing.Point(8, 34);
            this.txt_XEvent_MaxFileSize.Margin = new System.Windows.Forms.Padding(4);
            this.txt_XEvent_MaxFileSize.Name = "txt_XEvent_MaxFileSize";
            this.txt_XEvent_MaxFileSize.Size = new System.Drawing.Size(155, 22);
            this.txt_XEvent_MaxFileSize.TabIndex = 0;
            this.txt_XEvent_MaxFileSize.Tag = "500";
            this.txt_XEvent_MaxFileSize.Text = "500";
            this.txt_XEvent_MaxFileSize.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.txt_XEvent_MaxFileSize.TextChanged += new System.EventHandler(this.On_TextChanged_ValidateNumeric);
            this.txt_XEvent_MaxFileSize.Enter += new System.EventHandler(this.On_Enter_SaveOldValue);
            // 
            // gb_XEvnt_RolloverFiles
            // 
            this.gb_XEvnt_RolloverFiles.Controls.Add(this.txt_XEventRolloverFiles);
            this.gb_XEvnt_RolloverFiles.Location = new System.Drawing.Point(366, 4);
            this.gb_XEvnt_RolloverFiles.Margin = new System.Windows.Forms.Padding(4);
            this.gb_XEvnt_RolloverFiles.Name = "gb_XEvnt_RolloverFiles";
            this.gb_XEvnt_RolloverFiles.Padding = new System.Windows.Forms.Padding(4);
            this.gb_XEvnt_RolloverFiles.Size = new System.Drawing.Size(171, 96);
            this.gb_XEvnt_RolloverFiles.TabIndex = 2;
            this.gb_XEvnt_RolloverFiles.TabStop = false;
            this.gb_XEvnt_RolloverFiles.Text = "# Files";
            // 
            // txt_XEventRolloverFiles
            // 
            this.txt_XEventRolloverFiles.Location = new System.Drawing.Point(8, 34);
            this.txt_XEventRolloverFiles.Margin = new System.Windows.Forms.Padding(4);
            this.txt_XEventRolloverFiles.Name = "txt_XEventRolloverFiles";
            this.txt_XEventRolloverFiles.Size = new System.Drawing.Size(155, 22);
            this.txt_XEventRolloverFiles.TabIndex = 0;
            this.txt_XEventRolloverFiles.Tag = "50";
            this.txt_XEventRolloverFiles.Text = "50";
            this.txt_XEventRolloverFiles.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.txt_XEventRolloverFiles.TextChanged += new System.EventHandler(this.On_TextChanged_ValidateNumeric);
            // 
            // tp_ProfilerTrace
            // 
            this.tp_ProfilerTrace.Controls.Add(this.tlp_Trace);
            this.tp_ProfilerTrace.Location = new System.Drawing.Point(4, 25);
            this.tp_ProfilerTrace.Margin = new System.Windows.Forms.Padding(4);
            this.tp_ProfilerTrace.Name = "tp_ProfilerTrace";
            this.tp_ProfilerTrace.Padding = new System.Windows.Forms.Padding(4);
            this.tp_ProfilerTrace.Size = new System.Drawing.Size(743, 756);
            this.tp_ProfilerTrace.TabIndex = 3;
            this.tp_ProfilerTrace.Text = "Profiler Trace";
            this.tp_ProfilerTrace.ToolTipText = "Use profile trace for 2008 R2 or below";
            this.tp_ProfilerTrace.UseVisualStyleBackColor = true;
            // 
            // tlp_Trace
            // 
            this.tlp_Trace.BackColor = System.Drawing.Color.Transparent;
            this.tlp_Trace.ColumnCount = 1;
            this.tlp_Trace.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tlp_Trace.Controls.Add(this.tv_Trace, 0, 1);
            this.tlp_Trace.Controls.Add(this.tlp_ProfilerTrace_Top, 0, 0);
            this.tlp_Trace.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tlp_Trace.Location = new System.Drawing.Point(4, 4);
            this.tlp_Trace.Margin = new System.Windows.Forms.Padding(4);
            this.tlp_Trace.Name = "tlp_Trace";
            this.tlp_Trace.RowCount = 2;
            this.tlp_Trace.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 15F));
            this.tlp_Trace.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 85F));
            this.tlp_Trace.Size = new System.Drawing.Size(735, 748);
            this.tlp_Trace.TabIndex = 0;
            // 
            // tv_Trace
            // 
            this.tv_Trace.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.tv_Trace.CheckBoxes = true;
            this.tv_Trace.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tv_Trace.Location = new System.Drawing.Point(4, 116);
            this.tv_Trace.Margin = new System.Windows.Forms.Padding(4);
            this.tv_Trace.Name = "tv_Trace";
            this.tv_Trace.Size = new System.Drawing.Size(727, 628);
            this.tv_Trace.TabIndex = 0;
            // 
            // tlp_ProfilerTrace_Top
            // 
            this.tlp_ProfilerTrace_Top.ColumnCount = 4;
            this.tlp_ProfilerTrace_Top.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.tlp_ProfilerTrace_Top.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.tlp_ProfilerTrace_Top.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.tlp_ProfilerTrace_Top.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 25F));
            this.tlp_ProfilerTrace_Top.Controls.Add(this.gb_CaptureProfilerTrace, 0, 0);
            this.tlp_ProfilerTrace_Top.Controls.Add(this.gb_MaxTraceFileSize, 1, 0);
            this.tlp_ProfilerTrace_Top.Controls.Add(this.gb_TraceRolloverFiles, 2, 0);
            this.tlp_ProfilerTrace_Top.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tlp_ProfilerTrace_Top.Location = new System.Drawing.Point(4, 4);
            this.tlp_ProfilerTrace_Top.Margin = new System.Windows.Forms.Padding(4);
            this.tlp_ProfilerTrace_Top.Name = "tlp_ProfilerTrace_Top";
            this.tlp_ProfilerTrace_Top.RowCount = 1;
            this.tlp_ProfilerTrace_Top.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tlp_ProfilerTrace_Top.Size = new System.Drawing.Size(727, 104);
            this.tlp_ProfilerTrace_Top.TabIndex = 1;
            // 
            // gb_CaptureProfilerTrace
            // 
            this.gb_CaptureProfilerTrace.Controls.Add(this.cb_CaptureTrace);
            this.gb_CaptureProfilerTrace.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_CaptureProfilerTrace.Location = new System.Drawing.Point(4, 4);
            this.gb_CaptureProfilerTrace.Margin = new System.Windows.Forms.Padding(4);
            this.gb_CaptureProfilerTrace.Name = "gb_CaptureProfilerTrace";
            this.gb_CaptureProfilerTrace.Padding = new System.Windows.Forms.Padding(4);
            this.gb_CaptureProfilerTrace.Size = new System.Drawing.Size(173, 96);
            this.gb_CaptureProfilerTrace.TabIndex = 0;
            this.gb_CaptureProfilerTrace.TabStop = false;
            this.gb_CaptureProfilerTrace.Tag = "ProfilerCollector";
            this.gb_CaptureProfilerTrace.Text = "Capture Trace";
            // 
            // cb_CaptureTrace
            // 
            this.cb_CaptureTrace.AutoSize = true;
            this.cb_CaptureTrace.Checked = true;
            this.cb_CaptureTrace.CheckState = System.Windows.Forms.CheckState.Checked;
            this.cb_CaptureTrace.Location = new System.Drawing.Point(57, 34);
            this.cb_CaptureTrace.Margin = new System.Windows.Forms.Padding(4);
            this.cb_CaptureTrace.Name = "cb_CaptureTrace";
            this.cb_CaptureTrace.Size = new System.Drawing.Size(15, 14);
            this.cb_CaptureTrace.TabIndex = 0;
            this.cb_CaptureTrace.UseVisualStyleBackColor = true;
            // 
            // gb_MaxTraceFileSize
            // 
            this.gb_MaxTraceFileSize.Controls.Add(this.txt_TraceMaxFileSize);
            this.gb_MaxTraceFileSize.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_MaxTraceFileSize.Location = new System.Drawing.Point(185, 4);
            this.gb_MaxTraceFileSize.Margin = new System.Windows.Forms.Padding(4);
            this.gb_MaxTraceFileSize.Name = "gb_MaxTraceFileSize";
            this.gb_MaxTraceFileSize.Padding = new System.Windows.Forms.Padding(4);
            this.gb_MaxTraceFileSize.Size = new System.Drawing.Size(173, 96);
            this.gb_MaxTraceFileSize.TabIndex = 1;
            this.gb_MaxTraceFileSize.TabStop = false;
            this.gb_MaxTraceFileSize.Text = "Max Size(MB)";
            // 
            // txt_TraceMaxFileSize
            // 
            this.txt_TraceMaxFileSize.Location = new System.Drawing.Point(8, 34);
            this.txt_TraceMaxFileSize.Margin = new System.Windows.Forms.Padding(4);
            this.txt_TraceMaxFileSize.Name = "txt_TraceMaxFileSize";
            this.txt_TraceMaxFileSize.Size = new System.Drawing.Size(155, 22);
            this.txt_TraceMaxFileSize.TabIndex = 0;
            this.txt_TraceMaxFileSize.Tag = "500";
            this.txt_TraceMaxFileSize.Text = "500";
            this.txt_TraceMaxFileSize.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.txt_TraceMaxFileSize.TextChanged += new System.EventHandler(this.On_TextChanged_ValidateNumeric);
            // 
            // gb_TraceRolloverFiles
            // 
            this.gb_TraceRolloverFiles.Controls.Add(this.txt_TraceRolloverFiles);
            this.gb_TraceRolloverFiles.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_TraceRolloverFiles.Location = new System.Drawing.Point(366, 4);
            this.gb_TraceRolloverFiles.Margin = new System.Windows.Forms.Padding(4);
            this.gb_TraceRolloverFiles.Name = "gb_TraceRolloverFiles";
            this.gb_TraceRolloverFiles.Padding = new System.Windows.Forms.Padding(4);
            this.gb_TraceRolloverFiles.Size = new System.Drawing.Size(173, 96);
            this.gb_TraceRolloverFiles.TabIndex = 2;
            this.gb_TraceRolloverFiles.TabStop = false;
            this.gb_TraceRolloverFiles.Text = "# Files";
            // 
            // txt_TraceRolloverFiles
            // 
            this.txt_TraceRolloverFiles.Location = new System.Drawing.Point(8, 34);
            this.txt_TraceRolloverFiles.Margin = new System.Windows.Forms.Padding(4);
            this.txt_TraceRolloverFiles.Name = "txt_TraceRolloverFiles";
            this.txt_TraceRolloverFiles.Size = new System.Drawing.Size(155, 22);
            this.txt_TraceRolloverFiles.TabIndex = 0;
            this.txt_TraceRolloverFiles.Tag = "50";
            this.txt_TraceRolloverFiles.Text = "50";
            this.txt_TraceRolloverFiles.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.txt_TraceRolloverFiles.TextChanged += new System.EventHandler(this.On_TextChanged_ValidateNumeric);
            // 
            // tp_Perfmon
            // 
            this.tp_Perfmon.Controls.Add(this.tlp_Perfmon);
            this.tp_Perfmon.Location = new System.Drawing.Point(4, 25);
            this.tp_Perfmon.Margin = new System.Windows.Forms.Padding(4);
            this.tp_Perfmon.Name = "tp_Perfmon";
            this.tp_Perfmon.Padding = new System.Windows.Forms.Padding(4);
            this.tp_Perfmon.Size = new System.Drawing.Size(743, 756);
            this.tp_Perfmon.TabIndex = 1;
            this.tp_Perfmon.Text = "Perfmon";
            this.tp_Perfmon.UseVisualStyleBackColor = true;
            // 
            // tlp_Perfmon
            // 
            this.tlp_Perfmon.ColumnCount = 1;
            this.tlp_Perfmon.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tlp_Perfmon.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Absolute, 27F));
            this.tlp_Perfmon.Controls.Add(this.tlp_Perfmon_top, 0, 0);
            this.tlp_Perfmon.Controls.Add(this.tv_Perfmon, 0, 1);
            this.tlp_Perfmon.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tlp_Perfmon.Location = new System.Drawing.Point(4, 4);
            this.tlp_Perfmon.Margin = new System.Windows.Forms.Padding(4);
            this.tlp_Perfmon.Name = "tlp_Perfmon";
            this.tlp_Perfmon.RowCount = 2;
            this.tlp_Perfmon.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 15F));
            this.tlp_Perfmon.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 85F));
            this.tlp_Perfmon.Size = new System.Drawing.Size(735, 748);
            this.tlp_Perfmon.TabIndex = 0;
            // 
            // tlp_Perfmon_top
            // 
            this.tlp_Perfmon_top.ColumnCount = 3;
            this.tlp_Perfmon_top.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 33.33333F));
            this.tlp_Perfmon_top.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 33.33333F));
            this.tlp_Perfmon_top.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 33.33333F));
            this.tlp_Perfmon_top.Controls.Add(this.gb_CapturePerfmon, 0, 0);
            this.tlp_Perfmon_top.Controls.Add(this.gb_MaxPerfmonFileSize, 1, 0);
            this.tlp_Perfmon_top.Controls.Add(this.gb_PerfmonInterval, 2, 0);
            this.tlp_Perfmon_top.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tlp_Perfmon_top.Location = new System.Drawing.Point(4, 4);
            this.tlp_Perfmon_top.Margin = new System.Windows.Forms.Padding(4);
            this.tlp_Perfmon_top.Name = "tlp_Perfmon_top";
            this.tlp_Perfmon_top.RowCount = 1;
            this.tlp_Perfmon_top.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tlp_Perfmon_top.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 104F));
            this.tlp_Perfmon_top.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 104F));
            this.tlp_Perfmon_top.Size = new System.Drawing.Size(727, 104);
            this.tlp_Perfmon_top.TabIndex = 0;
            // 
            // gb_CapturePerfmon
            // 
            this.gb_CapturePerfmon.Controls.Add(this.cb_CapturePerfmon);
            this.gb_CapturePerfmon.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_CapturePerfmon.Location = new System.Drawing.Point(4, 4);
            this.gb_CapturePerfmon.Margin = new System.Windows.Forms.Padding(4);
            this.gb_CapturePerfmon.Name = "gb_CapturePerfmon";
            this.gb_CapturePerfmon.Padding = new System.Windows.Forms.Padding(4);
            this.gb_CapturePerfmon.Size = new System.Drawing.Size(234, 96);
            this.gb_CapturePerfmon.TabIndex = 0;
            this.gb_CapturePerfmon.TabStop = false;
            this.gb_CapturePerfmon.Tag = "20";
            this.gb_CapturePerfmon.Text = "Capture Perfmon";
            // 
            // cb_CapturePerfmon
            // 
            this.cb_CapturePerfmon.AutoSize = true;
            this.cb_CapturePerfmon.Checked = true;
            this.cb_CapturePerfmon.CheckState = System.Windows.Forms.CheckState.Checked;
            this.cb_CapturePerfmon.Location = new System.Drawing.Point(57, 34);
            this.cb_CapturePerfmon.Margin = new System.Windows.Forms.Padding(4);
            this.cb_CapturePerfmon.Name = "cb_CapturePerfmon";
            this.cb_CapturePerfmon.Size = new System.Drawing.Size(15, 14);
            this.cb_CapturePerfmon.TabIndex = 0;
            this.cb_CapturePerfmon.UseVisualStyleBackColor = true;
            this.cb_CapturePerfmon.CheckedChanged += new System.EventHandler(this.cb_CapturePerfmon_CheckedChanged);
            // 
            // gb_MaxPerfmonFileSize
            // 
            this.gb_MaxPerfmonFileSize.Controls.Add(this.txt_MaxPerfmonFileSize);
            this.gb_MaxPerfmonFileSize.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_MaxPerfmonFileSize.Location = new System.Drawing.Point(246, 4);
            this.gb_MaxPerfmonFileSize.Margin = new System.Windows.Forms.Padding(4);
            this.gb_MaxPerfmonFileSize.Name = "gb_MaxPerfmonFileSize";
            this.gb_MaxPerfmonFileSize.Padding = new System.Windows.Forms.Padding(4);
            this.gb_MaxPerfmonFileSize.Size = new System.Drawing.Size(234, 96);
            this.gb_MaxPerfmonFileSize.TabIndex = 1;
            this.gb_MaxPerfmonFileSize.TabStop = false;
            this.gb_MaxPerfmonFileSize.Tag = "20";
            this.gb_MaxPerfmonFileSize.Text = "Max File Size (MB)";
            // 
            // txt_MaxPerfmonFileSize
            // 
            this.txt_MaxPerfmonFileSize.Location = new System.Drawing.Point(8, 34);
            this.txt_MaxPerfmonFileSize.Margin = new System.Windows.Forms.Padding(4);
            this.txt_MaxPerfmonFileSize.Name = "txt_MaxPerfmonFileSize";
            this.txt_MaxPerfmonFileSize.Size = new System.Drawing.Size(155, 22);
            this.txt_MaxPerfmonFileSize.TabIndex = 0;
            this.txt_MaxPerfmonFileSize.Tag = "250";
            this.txt_MaxPerfmonFileSize.Text = "250";
            this.txt_MaxPerfmonFileSize.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.txt_MaxPerfmonFileSize.TextChanged += new System.EventHandler(this.On_TextChanged_ValidateNumeric);
            // 
            // gb_PerfmonInterval
            // 
            this.gb_PerfmonInterval.Controls.Add(this.txt_PerfmonInterval);
            this.gb_PerfmonInterval.Location = new System.Drawing.Point(488, 4);
            this.gb_PerfmonInterval.Margin = new System.Windows.Forms.Padding(4);
            this.gb_PerfmonInterval.Name = "gb_PerfmonInterval";
            this.gb_PerfmonInterval.Padding = new System.Windows.Forms.Padding(4);
            this.gb_PerfmonInterval.Size = new System.Drawing.Size(233, 84);
            this.gb_PerfmonInterval.TabIndex = 2;
            this.gb_PerfmonInterval.TabStop = false;
            this.gb_PerfmonInterval.Tag = "20";
            this.gb_PerfmonInterval.Text = "Polling Interval (secs)";
            // 
            // txt_PerfmonInterval
            // 
            this.txt_PerfmonInterval.Location = new System.Drawing.Point(8, 34);
            this.txt_PerfmonInterval.Margin = new System.Windows.Forms.Padding(4);
            this.txt_PerfmonInterval.Name = "txt_PerfmonInterval";
            this.txt_PerfmonInterval.Size = new System.Drawing.Size(155, 22);
            this.txt_PerfmonInterval.TabIndex = 0;
            this.txt_PerfmonInterval.Tag = "5";
            this.txt_PerfmonInterval.Text = "5";
            this.txt_PerfmonInterval.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            this.txt_PerfmonInterval.TextChanged += new System.EventHandler(this.On_TextChanged_ValidateNumeric);
            // 
            // tv_Perfmon
            // 
            this.tv_Perfmon.CheckBoxes = true;
            this.tv_Perfmon.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tv_Perfmon.Location = new System.Drawing.Point(4, 116);
            this.tv_Perfmon.Margin = new System.Windows.Forms.Padding(4);
            this.tv_Perfmon.Name = "tv_Perfmon";
            this.tv_Perfmon.Size = new System.Drawing.Size(727, 628);
            this.tv_Perfmon.TabIndex = 1;
            this.tv_Perfmon.Tag = "Perfmon";
            this.tv_Perfmon.AfterSelect += new System.Windows.Forms.TreeViewEventHandler(this.tv_Perfmon_AfterSelect);
            // 
            // tp_CustomDiag
            // 
            this.tp_CustomDiag.Controls.Add(this.tlp_CustomDiag);
            this.tp_CustomDiag.Location = new System.Drawing.Point(4, 25);
            this.tp_CustomDiag.Margin = new System.Windows.Forms.Padding(4);
            this.tp_CustomDiag.Name = "tp_CustomDiag";
            this.tp_CustomDiag.Padding = new System.Windows.Forms.Padding(4);
            this.tp_CustomDiag.Size = new System.Drawing.Size(743, 756);
            this.tp_CustomDiag.TabIndex = 4;
            this.tp_CustomDiag.Text = "Custom Diagnostics";
            this.tp_CustomDiag.UseVisualStyleBackColor = true;
            // 
            // tlp_CustomDiag
            // 
            this.tlp_CustomDiag.ColumnCount = 1;
            this.tlp_CustomDiag.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tlp_CustomDiag.Controls.Add(this.tv_CustomDiag, 0, 1);
            this.tlp_CustomDiag.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tlp_CustomDiag.Location = new System.Drawing.Point(4, 4);
            this.tlp_CustomDiag.Margin = new System.Windows.Forms.Padding(4);
            this.tlp_CustomDiag.Name = "tlp_CustomDiag";
            this.tlp_CustomDiag.RowCount = 2;
            this.tlp_CustomDiag.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 10F));
            this.tlp_CustomDiag.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 90F));
            this.tlp_CustomDiag.Size = new System.Drawing.Size(735, 748);
            this.tlp_CustomDiag.TabIndex = 0;
            // 
            // tv_CustomDiag
            // 
            this.tv_CustomDiag.CheckBoxes = true;
            this.tv_CustomDiag.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tv_CustomDiag.Location = new System.Drawing.Point(4, 78);
            this.tv_CustomDiag.Margin = new System.Windows.Forms.Padding(4);
            this.tv_CustomDiag.Name = "tv_CustomDiag";
            this.tv_CustomDiag.Size = new System.Drawing.Size(727, 666);
            this.tv_CustomDiag.TabIndex = 0;
            // 
            // tp_Misc
            // 
            this.tp_Misc.Controls.Add(this.tlp_Misc);
            this.tp_Misc.Location = new System.Drawing.Point(4, 25);
            this.tp_Misc.Margin = new System.Windows.Forms.Padding(4);
            this.tp_Misc.Name = "tp_Misc";
            this.tp_Misc.Size = new System.Drawing.Size(743, 756);
            this.tp_Misc.TabIndex = 5;
            this.tp_Misc.Text = "Misc";
            this.tp_Misc.UseVisualStyleBackColor = true;
            // 
            // tlp_Misc
            // 
            this.tlp_Misc.ColumnCount = 3;
            this.tlp_Misc.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 5F));
            this.tlp_Misc.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 90F));
            this.tlp_Misc.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 5F));
            this.tlp_Misc.Controls.Add(this.gb_EventLog, 1, 0);
            this.tlp_Misc.Controls.Add(this.gb_sqldiag, 1, 1);
            this.tlp_Misc.Controls.Add(this.gb_outputFoler, 1, 2);
            this.tlp_Misc.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tlp_Misc.Location = new System.Drawing.Point(0, 0);
            this.tlp_Misc.Margin = new System.Windows.Forms.Padding(4);
            this.tlp_Misc.Name = "tlp_Misc";
            this.tlp_Misc.RowCount = 7;
            this.tlp_Misc.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 13.1579F));
            this.tlp_Misc.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 13.1579F));
            this.tlp_Misc.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 21.05262F));
            this.tlp_Misc.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 13.1579F));
            this.tlp_Misc.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 13.1579F));
            this.tlp_Misc.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 13.1579F));
            this.tlp_Misc.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 13.1579F));
            this.tlp_Misc.Size = new System.Drawing.Size(743, 756);
            this.tlp_Misc.TabIndex = 0;
            // 
            // gb_EventLog
            // 
            this.gb_EventLog.Controls.Add(this.cb_EventLogShtudown);
            this.gb_EventLog.Controls.Add(this.cb_EventLogStartup);
            this.gb_EventLog.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_EventLog.Location = new System.Drawing.Point(41, 4);
            this.gb_EventLog.Margin = new System.Windows.Forms.Padding(4);
            this.gb_EventLog.Name = "gb_EventLog";
            this.gb_EventLog.Padding = new System.Windows.Forms.Padding(4);
            this.gb_EventLog.Size = new System.Drawing.Size(660, 91);
            this.gb_EventLog.TabIndex = 0;
            this.gb_EventLog.TabStop = false;
            this.gb_EventLog.Tag = "20";
            this.gb_EventLog.Text = "Collect Event Logs";
            // 
            // cb_EventLogShtudown
            // 
            this.cb_EventLogShtudown.AutoSize = true;
            this.cb_EventLogShtudown.Checked = true;
            this.cb_EventLogShtudown.CheckState = System.Windows.Forms.CheckState.Checked;
            this.cb_EventLogShtudown.Location = new System.Drawing.Point(215, 25);
            this.cb_EventLogShtudown.Margin = new System.Windows.Forms.Padding(4);
            this.cb_EventLogShtudown.Name = "cb_EventLogShtudown";
            this.cb_EventLogShtudown.Size = new System.Drawing.Size(89, 21);
            this.cb_EventLogShtudown.TabIndex = 1;
            this.cb_EventLogShtudown.Text = "Shutdown";
            this.cb_EventLogShtudown.UseVisualStyleBackColor = true;
            // 
            // cb_EventLogStartup
            // 
            this.cb_EventLogStartup.AutoSize = true;
            this.cb_EventLogStartup.Location = new System.Drawing.Point(21, 25);
            this.cb_EventLogStartup.Margin = new System.Windows.Forms.Padding(4);
            this.cb_EventLogStartup.Name = "cb_EventLogStartup";
            this.cb_EventLogStartup.Size = new System.Drawing.Size(73, 21);
            this.cb_EventLogStartup.TabIndex = 0;
            this.cb_EventLogStartup.Text = "Startup";
            this.cb_EventLogStartup.UseVisualStyleBackColor = true;
            // 
            // gb_sqldiag
            // 
            this.gb_sqldiag.Controls.Add(this.chkSQLDIAGShutdown);
            this.gb_sqldiag.Controls.Add(this.chkSQLDiagStartup);
            this.gb_sqldiag.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_sqldiag.Location = new System.Drawing.Point(41, 103);
            this.gb_sqldiag.Margin = new System.Windows.Forms.Padding(4);
            this.gb_sqldiag.Name = "gb_sqldiag";
            this.gb_sqldiag.Padding = new System.Windows.Forms.Padding(4);
            this.gb_sqldiag.Size = new System.Drawing.Size(660, 91);
            this.gb_sqldiag.TabIndex = 1;
            this.gb_sqldiag.TabStop = false;
            this.gb_sqldiag.Tag = "20";
            this.gb_sqldiag.Text = "Collect SQLDiag DMVs";
            // 
            // chkSQLDIAGShutdown
            // 
            this.chkSQLDIAGShutdown.AutoSize = true;
            this.chkSQLDIAGShutdown.Checked = true;
            this.chkSQLDIAGShutdown.CheckState = System.Windows.Forms.CheckState.Checked;
            this.chkSQLDIAGShutdown.Location = new System.Drawing.Point(215, 47);
            this.chkSQLDIAGShutdown.Margin = new System.Windows.Forms.Padding(4);
            this.chkSQLDIAGShutdown.Name = "chkSQLDIAGShutdown";
            this.chkSQLDIAGShutdown.Size = new System.Drawing.Size(89, 21);
            this.chkSQLDIAGShutdown.TabIndex = 1;
            this.chkSQLDIAGShutdown.Text = "Shutdown";
            this.chkSQLDIAGShutdown.UseVisualStyleBackColor = true;
            // 
            // chkSQLDiagStartup
            // 
            this.chkSQLDiagStartup.AutoSize = true;
            this.chkSQLDiagStartup.Location = new System.Drawing.Point(21, 47);
            this.chkSQLDiagStartup.Margin = new System.Windows.Forms.Padding(4);
            this.chkSQLDiagStartup.Name = "chkSQLDiagStartup";
            this.chkSQLDiagStartup.Size = new System.Drawing.Size(73, 21);
            this.chkSQLDiagStartup.TabIndex = 0;
            this.chkSQLDiagStartup.Text = "Startup";
            this.chkSQLDiagStartup.UseVisualStyleBackColor = true;
            // 
            // gb_outputFoler
            // 
            this.gb_outputFoler.Controls.Add(this.txt_OutputFolder);
            this.gb_outputFoler.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_outputFoler.Location = new System.Drawing.Point(41, 202);
            this.gb_outputFoler.Margin = new System.Windows.Forms.Padding(4);
            this.gb_outputFoler.Name = "gb_outputFoler";
            this.gb_outputFoler.Padding = new System.Windows.Forms.Padding(4);
            this.gb_outputFoler.Size = new System.Drawing.Size(660, 151);
            this.gb_outputFoler.TabIndex = 2;
            this.gb_outputFoler.TabStop = false;
            this.gb_outputFoler.Tag = "20";
            this.gb_outputFoler.Text = "Pssdiag Package Default Output Folder";
            // 
            // txt_OutputFolder
            // 
            this.txt_OutputFolder.Location = new System.Drawing.Point(9, 48);
            this.txt_OutputFolder.Margin = new System.Windows.Forms.Padding(4);
            this.txt_OutputFolder.MinimumSize = new System.Drawing.Size(639, 20);
            this.txt_OutputFolder.Name = "txt_OutputFolder";
            this.txt_OutputFolder.Size = new System.Drawing.Size(639, 22);
            this.txt_OutputFolder.TabIndex = 0;
            // 
            // gb_Scenario
            // 
            this.gb_Scenario.BackColor = System.Drawing.SystemColors.Control;
            this.gb_Scenario.Controls.Add(this.cbl_Scenario);
            this.gb_Scenario.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gb_Scenario.Location = new System.Drawing.Point(391, 4);
            this.gb_Scenario.Margin = new System.Windows.Forms.Padding(4);
            this.gb_Scenario.Name = "gb_Scenario";
            this.gb_Scenario.Padding = new System.Windows.Forms.Padding(4);
            this.gb_Scenario.Size = new System.Drawing.Size(395, 785);
            this.gb_Scenario.TabIndex = 2;
            this.gb_Scenario.TabStop = false;
            this.gb_Scenario.Text = "Scenario";
            // 
            // cbl_Scenario
            // 
            this.cbl_Scenario.BackColor = System.Drawing.SystemColors.Control;
            this.cbl_Scenario.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.cbl_Scenario.CheckOnClick = true;
            this.cbl_Scenario.Dock = System.Windows.Forms.DockStyle.Fill;
            this.cbl_Scenario.FormattingEnabled = true;
            this.cbl_Scenario.Location = new System.Drawing.Point(4, 19);
            this.cbl_Scenario.Margin = new System.Windows.Forms.Padding(4);
            this.cbl_Scenario.Name = "cbl_Scenario";
            this.cbl_Scenario.Size = new System.Drawing.Size(387, 762);
            this.cbl_Scenario.TabIndex = 0;
            this.cbl_Scenario.SelectedIndexChanged += new System.EventHandler(this.cbl_Scenario_SelectedIndexChanged);
            this.cbl_Scenario.MouseLeave += new System.EventHandler(this.cbl_Scenario_MouseLeave);
            this.cbl_Scenario.MouseMove += new System.Windows.Forms.MouseEventHandler(this.cbl_Scenario_MouseMove);
            // 
            // tlp_SuperOverall
            // 
            this.tlp_SuperOverall.BackColor = System.Drawing.SystemColors.Control;
            this.tlp_SuperOverall.ColumnCount = 1;
            this.tlp_SuperOverall.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tlp_SuperOverall.Controls.Add(this.tlp_Overall_bottom, 0, 1);
            this.tlp_SuperOverall.Controls.Add(this.tlp_top_overall, 0, 0);
            this.tlp_SuperOverall.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tlp_SuperOverall.Location = new System.Drawing.Point(0, 0);
            this.tlp_SuperOverall.Margin = new System.Windows.Forms.Padding(4);
            this.tlp_SuperOverall.Name = "tlp_SuperOverall";
            this.tlp_SuperOverall.RowCount = 2;
            this.tlp_SuperOverall.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 10F));
            this.tlp_SuperOverall.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 90F));
            this.tlp_SuperOverall.Size = new System.Drawing.Size(1623, 890);
            this.tlp_SuperOverall.TabIndex = 2;
            this.tlp_SuperOverall.Paint += new System.Windows.Forms.PaintEventHandler(this.tlp_SuperOverall_Paint);
            // 
            // tlp_top_overall
            // 
            this.tlp_top_overall.BackColor = System.Drawing.SystemColors.Control;
            this.tlp_top_overall.ColumnCount = 5;
            this.tlp_top_overall.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Absolute, 27F));
            this.tlp_top_overall.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tlp_top_overall.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Absolute, 107F));
            this.tlp_top_overall.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Absolute, 107F));
            this.tlp_top_overall.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Absolute, 107F));
            this.tlp_top_overall.Controls.Add(this.btnSettings, 3, 0);
            this.tlp_top_overall.Controls.Add(this.btnSaveSelection, 2, 0);
            this.tlp_top_overall.Controls.Add(this.btnHelp, 4, 0);
            this.tlp_top_overall.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tlp_top_overall.Location = new System.Drawing.Point(4, 4);
            this.tlp_top_overall.Margin = new System.Windows.Forms.Padding(4);
            this.tlp_top_overall.Name = "tlp_top_overall";
            this.tlp_top_overall.RowCount = 1;
            this.tlp_top_overall.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tlp_top_overall.Size = new System.Drawing.Size(1615, 81);
            this.tlp_top_overall.TabIndex = 2;
            this.tlp_top_overall.Paint += new System.Windows.Forms.PaintEventHandler(this.tlp_top_overall_Paint);
            // 
            // btnSettings
            // 
            this.btnSettings.Dock = System.Windows.Forms.DockStyle.Fill;
            this.btnSettings.Image = ((System.Drawing.Image)(resources.GetObject("btnSettings.Image")));
            this.btnSettings.ImageAlign = System.Drawing.ContentAlignment.TopCenter;
            this.btnSettings.Location = new System.Drawing.Point(1405, 4);
            this.btnSettings.Margin = new System.Windows.Forms.Padding(4);
            this.btnSettings.Name = "btnSettings";
            this.btnSettings.Size = new System.Drawing.Size(99, 73);
            this.btnSettings.TabIndex = 3;
            this.btnSettings.Text = "Settings";
            this.btnSettings.TextAlign = System.Drawing.ContentAlignment.BottomCenter;
            this.btnSettings.UseVisualStyleBackColor = true;
            this.btnSettings.Click += new System.EventHandler(this.btnSettings_Click);
            // 
            // btnSaveSelection
            // 
            this.btnSaveSelection.AutoSize = true;
            this.btnSaveSelection.Dock = System.Windows.Forms.DockStyle.Fill;
            this.btnSaveSelection.Image = ((System.Drawing.Image)(resources.GetObject("btnSaveSelection.Image")));
            this.btnSaveSelection.ImageAlign = System.Drawing.ContentAlignment.TopCenter;
            this.btnSaveSelection.Location = new System.Drawing.Point(1298, 4);
            this.btnSaveSelection.Margin = new System.Windows.Forms.Padding(4);
            this.btnSaveSelection.Name = "btnSaveSelection";
            this.btnSaveSelection.Size = new System.Drawing.Size(99, 73);
            this.btnSaveSelection.TabIndex = 2;
            this.btnSaveSelection.Text = "Save";
            this.btnSaveSelection.TextAlign = System.Drawing.ContentAlignment.BottomCenter;
            this.btnSaveSelection.UseVisualStyleBackColor = true;
            this.btnSaveSelection.Click += new System.EventHandler(this.btnSaveSelection_Click);
            // 
            // btnHelp
            // 
            this.btnHelp.Dock = System.Windows.Forms.DockStyle.Fill;
            this.btnHelp.Image = ((System.Drawing.Image)(resources.GetObject("btnHelp.Image")));
            this.btnHelp.ImageAlign = System.Drawing.ContentAlignment.TopCenter;
            this.btnHelp.Location = new System.Drawing.Point(1512, 4);
            this.btnHelp.Margin = new System.Windows.Forms.Padding(4);
            this.btnHelp.Name = "btnHelp";
            this.btnHelp.Size = new System.Drawing.Size(99, 73);
            this.btnHelp.TabIndex = 4;
            this.btnHelp.Text = "Help";
            this.btnHelp.TextAlign = System.Drawing.ContentAlignment.BottomCenter;
            this.btnHelp.UseVisualStyleBackColor = true;
            this.btnHelp.Click += new System.EventHandler(this.btnHelp_Click);
            // 
            // fmDiagManager
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 16F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.SystemColors.Control;
            this.ClientSize = new System.Drawing.Size(1623, 890);
            this.Controls.Add(this.tlp_SuperOverall);
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.IsMdiContainer = true;
            this.Margin = new System.Windows.Forms.Padding(4);
            this.Name = "fmDiagManager";
            this.Text = "Pssdiag & Sqldiag Configuration Manager";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.fmDiagManager_FormClosing);
            this.Load += new System.EventHandler(this.fmDiagManager_Load);
            this.Leave += new System.EventHandler(this.fmDiagManager_Leave);
            this.contextMenuStripCustomDiag.ResumeLayout(false);
            this.tlp_Overall_bottom.ResumeLayout(false);
            this.tlp_UserChoice.ResumeLayout(false);
            this.gb_MachineName.ResumeLayout(false);
            this.gb_MachineName.PerformLayout();
            this.gb_InstanceName.ResumeLayout(false);
            this.gb_InstanceName.PerformLayout();
            this.tabControl_Events.ResumeLayout(false);
            this.tp_Xevent.ResumeLayout(false);
            this.tlp_Xevent.ResumeLayout(false);
            this.tlp_XEvent_top.ResumeLayout(false);
            this.gb_CaptureXEvent.ResumeLayout(false);
            this.gb_CaptureXEvent.PerformLayout();
            this.gb_XEvent_FileSize.ResumeLayout(false);
            this.gb_XEvent_FileSize.PerformLayout();
            this.gb_XEvnt_RolloverFiles.ResumeLayout(false);
            this.gb_XEvnt_RolloverFiles.PerformLayout();
            this.tp_ProfilerTrace.ResumeLayout(false);
            this.tlp_Trace.ResumeLayout(false);
            this.tlp_ProfilerTrace_Top.ResumeLayout(false);
            this.gb_CaptureProfilerTrace.ResumeLayout(false);
            this.gb_CaptureProfilerTrace.PerformLayout();
            this.gb_MaxTraceFileSize.ResumeLayout(false);
            this.gb_MaxTraceFileSize.PerformLayout();
            this.gb_TraceRolloverFiles.ResumeLayout(false);
            this.gb_TraceRolloverFiles.PerformLayout();
            this.tp_Perfmon.ResumeLayout(false);
            this.tlp_Perfmon.ResumeLayout(false);
            this.tlp_Perfmon_top.ResumeLayout(false);
            this.gb_CapturePerfmon.ResumeLayout(false);
            this.gb_CapturePerfmon.PerformLayout();
            this.gb_MaxPerfmonFileSize.ResumeLayout(false);
            this.gb_MaxPerfmonFileSize.PerformLayout();
            this.gb_PerfmonInterval.ResumeLayout(false);
            this.gb_PerfmonInterval.PerformLayout();
            this.tp_CustomDiag.ResumeLayout(false);
            this.tlp_CustomDiag.ResumeLayout(false);
            this.tp_Misc.ResumeLayout(false);
            this.tlp_Misc.ResumeLayout(false);
            this.gb_EventLog.ResumeLayout(false);
            this.gb_EventLog.PerformLayout();
            this.gb_sqldiag.ResumeLayout(false);
            this.gb_sqldiag.PerformLayout();
            this.gb_outputFoler.ResumeLayout(false);
            this.gb_outputFoler.PerformLayout();
            this.gb_Scenario.ResumeLayout(false);
            this.tlp_SuperOverall.ResumeLayout(false);
            this.tlp_top_overall.ResumeLayout(false);
            this.tlp_top_overall.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.ContextMenuStrip contextMenuStripCustomDiag;
        private System.Windows.Forms.TableLayoutPanel tlp_Overall_bottom;
        private System.Windows.Forms.TableLayoutPanel tlp_UserChoice;
        private System.Windows.Forms.TextBox txt_MachineName;
        private System.Windows.Forms.TabControl tabControl_Events;
        private System.Windows.Forms.TabPage tp_Perfmon;
        private System.Windows.Forms.TabPage tp_Xevent;
        private System.Windows.Forms.TabPage tp_ProfilerTrace;
        private System.Windows.Forms.TabPage tp_CustomDiag;
        private System.Windows.Forms.TabPage tp_Misc;
        private System.Windows.Forms.TableLayoutPanel tlp_Xevent;
        private System.Windows.Forms.TreeView tv_XEvent;
        private System.Windows.Forms.TableLayoutPanel tlp_SuperOverall;
        private System.Windows.Forms.TableLayoutPanel tlp_Trace;
        private System.Windows.Forms.TableLayoutPanel tlp_CustomDiag;
        private System.Windows.Forms.TreeView tv_Trace;
        private System.Windows.Forms.TreeView tv_CustomDiag;
        private System.Windows.Forms.TextBox txt_InstanceName;
        private System.Windows.Forms.GroupBox gb_Feature;
        private System.Windows.Forms.GroupBox gb_Version2;
        private System.Windows.Forms.GroupBox gb_MachineName;
        private System.Windows.Forms.GroupBox gb_InstanceName;
        private System.Windows.Forms.GroupBox gb_Plat;
        private System.Windows.Forms.GroupBox gb_Scenario;
        private System.Windows.Forms.CheckedListBox cbl_Scenario;
        private System.Windows.Forms.TableLayoutPanel tlp_Misc;
        private System.Windows.Forms.GroupBox gb_EventLog;
        private System.Windows.Forms.GroupBox gb_sqldiag;
        private System.Windows.Forms.GroupBox gb_outputFoler;
        private System.Windows.Forms.CheckBox cb_EventLogShtudown;
        private System.Windows.Forms.CheckBox cb_EventLogStartup;
        private System.Windows.Forms.CheckBox chkSQLDIAGShutdown;
        private System.Windows.Forms.CheckBox chkSQLDiagStartup;
        private System.Windows.Forms.TextBox txt_OutputFolder;
        private System.Windows.Forms.Button btnSaveSelection;
        private System.Windows.Forms.TableLayoutPanel tlp_XEvent_top;
        private System.Windows.Forms.GroupBox gb_CaptureXEvent;
        private System.Windows.Forms.CheckBox cb_CaptureXevent;
        private System.Windows.Forms.GroupBox gb_XEvent_FileSize;
        private System.Windows.Forms.TextBox txt_XEvent_MaxFileSize;
        private System.Windows.Forms.GroupBox gb_XEvnt_RolloverFiles;
        private System.Windows.Forms.TextBox txt_XEventRolloverFiles;
        private System.Windows.Forms.TableLayoutPanel tlp_ProfilerTrace_Top;
        private System.Windows.Forms.GroupBox gb_CaptureProfilerTrace;
        private System.Windows.Forms.GroupBox gb_MaxTraceFileSize;
        private System.Windows.Forms.GroupBox gb_TraceRolloverFiles;
        private System.Windows.Forms.CheckBox cb_CaptureTrace;
        private System.Windows.Forms.TextBox txt_TraceMaxFileSize;
        private System.Windows.Forms.TextBox txt_TraceRolloverFiles;
        private System.Windows.Forms.TableLayoutPanel tlp_Perfmon;
        private System.Windows.Forms.TableLayoutPanel tlp_Perfmon_top;
        private System.Windows.Forms.GroupBox gb_CapturePerfmon;
        private System.Windows.Forms.CheckBox cb_CapturePerfmon;
        private System.Windows.Forms.GroupBox gb_MaxPerfmonFileSize;
        private System.Windows.Forms.TextBox txt_MaxPerfmonFileSize;
        private System.Windows.Forms.GroupBox gb_PerfmonInterval;
        private System.Windows.Forms.TextBox txt_PerfmonInterval;
        private System.Windows.Forms.TreeView tv_Perfmon;
        private System.Windows.Forms.TableLayoutPanel tlp_top_overall;
        private System.Windows.Forms.ToolStripMenuItem preferencesToolStripMenuItem;
        private System.Windows.Forms.Button btnSettings;
        private System.Windows.Forms.ToolTip toolTipScenario;
        private System.Windows.Forms.ToolTip tooltipMachineName;
        private System.Windows.Forms.ToolTip tooltipInstanceName;
        private System.Windows.Forms.Button btnHelp;
    }
}