namespace PssdiagConfig
{
    partial class fmHelp
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
            this.tableLayoutPanel1 = new System.Windows.Forms.TableLayoutPanel();
            this.lblPssdiagWiki = new System.Windows.Forms.LinkLabel();
            this.lblPssdiagAppDirectory = new System.Windows.Forms.LinkLabel();
            this.lblDiagMangerLogDirectory = new System.Windows.Forms.LinkLabel();
            this.lblUserPreferenceDir = new System.Windows.Forms.LinkLabel();
            this.lblWhatsNew = new System.Windows.Forms.LinkLabel();
            this.tableLayoutPanel1.SuspendLayout();
            this.SuspendLayout();
            // 
            // tableLayoutPanel1
            // 
            this.tableLayoutPanel1.ColumnCount = 2;
            this.tableLayoutPanel1.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 5F));
            this.tableLayoutPanel1.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 95F));
            this.tableLayoutPanel1.Controls.Add(this.lblPssdiagWiki, 1, 2);
            this.tableLayoutPanel1.Controls.Add(this.lblPssdiagAppDirectory, 1, 3);
            this.tableLayoutPanel1.Controls.Add(this.lblDiagMangerLogDirectory, 1, 4);
            this.tableLayoutPanel1.Controls.Add(this.lblUserPreferenceDir, 1, 5);
            this.tableLayoutPanel1.Controls.Add(this.lblWhatsNew, 1, 1);
            this.tableLayoutPanel1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tableLayoutPanel1.Location = new System.Drawing.Point(0, 0);
            this.tableLayoutPanel1.Name = "tableLayoutPanel1";
            this.tableLayoutPanel1.RowCount = 8;
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 35F));
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 35F));
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 35F));
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 35F));
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 35F));
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 33F));
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tableLayoutPanel1.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 20F));
            this.tableLayoutPanel1.Size = new System.Drawing.Size(683, 473);
            this.tableLayoutPanel1.TabIndex = 0;
            this.tableLayoutPanel1.Paint += new System.Windows.Forms.PaintEventHandler(this.tableLayoutPanel1_Paint);
            // 
            // lblPssdiagWiki
            // 
            this.lblPssdiagWiki.AutoSize = true;
            this.lblPssdiagWiki.Dock = System.Windows.Forms.DockStyle.Left;
            this.lblPssdiagWiki.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblPssdiagWiki.Location = new System.Drawing.Point(37, 70);
            this.lblPssdiagWiki.Name = "lblPssdiagWiki";
            this.lblPssdiagWiki.Size = new System.Drawing.Size(66, 35);
            this.lblPssdiagWiki.TabIndex = 0;
            this.lblPssdiagWiki.TabStop = true;
            this.lblPssdiagWiki.Text = "Help Wiki";
            this.lblPssdiagWiki.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.lblPssdiagWiki.LinkClicked += new System.Windows.Forms.LinkLabelLinkClickedEventHandler(this.Link_Clicked);
            // 
            // lblPssdiagAppDirectory
            // 
            this.lblPssdiagAppDirectory.AutoSize = true;
            this.lblPssdiagAppDirectory.Dock = System.Windows.Forms.DockStyle.Left;
            this.lblPssdiagAppDirectory.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblPssdiagAppDirectory.Location = new System.Drawing.Point(37, 105);
            this.lblPssdiagAppDirectory.Name = "lblPssdiagAppDirectory";
            this.lblPssdiagAppDirectory.Size = new System.Drawing.Size(191, 35);
            this.lblPssdiagAppDirectory.TabIndex = 1;
            this.lblPssdiagAppDirectory.TabStop = true;
            this.lblPssdiagAppDirectory.Text = "Diag Manager  Install Directory";
            this.lblPssdiagAppDirectory.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.lblPssdiagAppDirectory.LinkClicked += new System.Windows.Forms.LinkLabelLinkClickedEventHandler(this.Link_Clicked);
            // 
            // lblDiagMangerLogDirectory
            // 
            this.lblDiagMangerLogDirectory.AutoSize = true;
            this.lblDiagMangerLogDirectory.Dock = System.Windows.Forms.DockStyle.Left;
            this.lblDiagMangerLogDirectory.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblDiagMangerLogDirectory.Location = new System.Drawing.Point(37, 140);
            this.lblDiagMangerLogDirectory.Name = "lblDiagMangerLogDirectory";
            this.lblDiagMangerLogDirectory.Size = new System.Drawing.Size(175, 35);
            this.lblDiagMangerLogDirectory.TabIndex = 2;
            this.lblDiagMangerLogDirectory.TabStop = true;
            this.lblDiagMangerLogDirectory.Text = "Diag Manager Log directory";
            this.lblDiagMangerLogDirectory.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.lblDiagMangerLogDirectory.LinkClicked += new System.Windows.Forms.LinkLabelLinkClickedEventHandler(this.Link_Clicked);
            // 
            // lblUserPreferenceDir
            // 
            this.lblUserPreferenceDir.AutoSize = true;
            this.lblUserPreferenceDir.Dock = System.Windows.Forms.DockStyle.Left;
            this.lblUserPreferenceDir.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblUserPreferenceDir.Location = new System.Drawing.Point(37, 175);
            this.lblUserPreferenceDir.Name = "lblUserPreferenceDir";
            this.lblUserPreferenceDir.Size = new System.Drawing.Size(188, 33);
            this.lblUserPreferenceDir.TabIndex = 3;
            this.lblUserPreferenceDir.TabStop = true;
            this.lblUserPreferenceDir.Text = "User Preference File Directory";
            this.lblUserPreferenceDir.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.lblUserPreferenceDir.LinkClicked += new System.Windows.Forms.LinkLabelLinkClickedEventHandler(this.Link_Clicked);
            // 
            // lblWhatsNew
            // 
            this.lblWhatsNew.AutoSize = true;
            this.lblWhatsNew.Dock = System.Windows.Forms.DockStyle.Left;
            this.lblWhatsNew.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblWhatsNew.Location = new System.Drawing.Point(37, 35);
            this.lblWhatsNew.Name = "lblWhatsNew";
            this.lblWhatsNew.Size = new System.Drawing.Size(79, 35);
            this.lblWhatsNew.TabIndex = 4;
            this.lblWhatsNew.TabStop = true;
            this.lblWhatsNew.Text = "What\'s New";
            this.lblWhatsNew.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            this.lblWhatsNew.LinkClicked += new System.Windows.Forms.LinkLabelLinkClickedEventHandler(this.Link_Clicked);
            // 
            // fmHelp
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(683, 473);
            this.Controls.Add(this.tableLayoutPanel1);
            this.Name = "fmHelp";
            this.ShowIcon = false;
            this.Text = "Help";
            this.Load += new System.EventHandler(this.fmHelp_Load);
            this.tableLayoutPanel1.ResumeLayout(false);
            this.tableLayoutPanel1.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.TableLayoutPanel tableLayoutPanel1;
        private System.Windows.Forms.LinkLabel lblPssdiagWiki;
        private System.Windows.Forms.LinkLabel lblPssdiagAppDirectory;
        private System.Windows.Forms.LinkLabel lblDiagMangerLogDirectory;
        private System.Windows.Forms.LinkLabel lblUserPreferenceDir;
        private System.Windows.Forms.LinkLabel lblWhatsNew;
    }
}