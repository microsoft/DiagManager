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
    partial class fmSettings
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
            this.txtDefaultPssdPath = new System.Windows.Forms.TextBox();
            this.lblBkColor = new System.Windows.Forms.Label();
            this.btnPickColor = new System.Windows.Forms.Button();
            this.lblCurrentColorText = new System.Windows.Forms.Label();
            this.lblShowColor = new System.Windows.Forms.Label();
            this.lblDefaultPath = new System.Windows.Forms.Label();
            this.label1 = new System.Windows.Forms.Label();
            this.chkBoxCreateEmail = new System.Windows.Forms.CheckBox();
            this.btnReset = new System.Windows.Forms.Button();
            this.btnSave = new System.Windows.Forms.Button();
            this.btnCancel = new System.Windows.Forms.Button();
            this.SuspendLayout();
            // 
            // txtDefaultPssdPath
            // 
            this.txtDefaultPssdPath.Font = new System.Drawing.Font("Microsoft Sans Serif", 11F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.txtDefaultPssdPath.Location = new System.Drawing.Point(160, 4);
            this.txtDefaultPssdPath.Name = "txtDefaultPssdPath";
            this.txtDefaultPssdPath.Size = new System.Drawing.Size(465, 24);
            this.txtDefaultPssdPath.TabIndex = 22;
            // 
            // lblBkColor
            // 
            this.lblBkColor.AutoSize = true;
            this.lblBkColor.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblBkColor.Location = new System.Drawing.Point(12, 54);
            this.lblBkColor.Name = "lblBkColor";
            this.lblBkColor.Size = new System.Drawing.Size(116, 16);
            this.lblBkColor.TabIndex = 27;
            this.lblBkColor.Text = "Background Color";
            this.lblBkColor.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // btnPickColor
            // 
            this.btnPickColor.FlatStyle = System.Windows.Forms.FlatStyle.Popup;
            this.btnPickColor.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnPickColor.Location = new System.Drawing.Point(160, 44);
            this.btnPickColor.Name = "btnPickColor";
            this.btnPickColor.Size = new System.Drawing.Size(74, 35);
            this.btnPickColor.TabIndex = 23;
            this.btnPickColor.Text = "Pick Color";
            this.btnPickColor.UseVisualStyleBackColor = true;
            this.btnPickColor.Click += new System.EventHandler(this.btnPickColor_Click);
            // 
            // lblCurrentColorText
            // 
            this.lblCurrentColorText.AutoSize = true;
            this.lblCurrentColorText.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblCurrentColorText.Location = new System.Drawing.Point(254, 54);
            this.lblCurrentColorText.Name = "lblCurrentColorText";
            this.lblCurrentColorText.Size = new System.Drawing.Size(79, 15);
            this.lblCurrentColorText.TabIndex = 24;
            this.lblCurrentColorText.Text = "Current Color";
            this.lblCurrentColorText.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // lblShowColor
            // 
            this.lblShowColor.AutoSize = true;
            this.lblShowColor.BackColor = System.Drawing.SystemColors.ActiveCaptionText;
            this.lblShowColor.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.lblShowColor.Location = new System.Drawing.Point(339, 56);
            this.lblShowColor.Name = "lblShowColor";
            this.lblShowColor.Size = new System.Drawing.Size(30, 15);
            this.lblShowColor.TabIndex = 25;
            this.lblShowColor.Text = "       ";
            this.lblShowColor.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // lblDefaultPath
            // 
            this.lblDefaultPath.AutoSize = true;
            this.lblDefaultPath.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblDefaultPath.Location = new System.Drawing.Point(12, 9);
            this.lblDefaultPath.Name = "lblDefaultPath";
            this.lblDefaultPath.Size = new System.Drawing.Size(142, 16);
            this.lblDefaultPath.TabIndex = 26;
            this.lblDefaultPath.Text = "Default PSSDIAG Path";
            this.lblDefaultPath.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.Location = new System.Drawing.Point(12, 100);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(138, 16);
            this.label1.TabIndex = 29;
            this.label1.Text = "Create Email on Save";
            // 
            // chkBoxCreateEmail
            // 
            this.chkBoxCreateEmail.AutoSize = true;
            this.chkBoxCreateEmail.Checked = true;
            this.chkBoxCreateEmail.CheckState = System.Windows.Forms.CheckState.Checked;
            this.chkBoxCreateEmail.Location = new System.Drawing.Point(160, 100);
            this.chkBoxCreateEmail.Name = "chkBoxCreateEmail";
            this.chkBoxCreateEmail.Size = new System.Drawing.Size(15, 14);
            this.chkBoxCreateEmail.TabIndex = 30;
            this.chkBoxCreateEmail.UseVisualStyleBackColor = true;
           
            // 
            // btnReset
            // 
            this.btnReset.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnReset.Location = new System.Drawing.Point(512, 284);
            this.btnReset.Name = "btnReset";
            this.btnReset.Size = new System.Drawing.Size(113, 23);
            this.btnReset.TabIndex = 28;
            this.btnReset.Text = "Reset to Defaults";
            this.btnReset.UseVisualStyleBackColor = true;
            this.btnReset.Click += new System.EventHandler(this.btnReset_Click);
            // 
            // btnSave
            // 
            this.btnSave.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnSave.Location = new System.Drawing.Point(12, 284);
            this.btnSave.Name = "btnSave";
            this.btnSave.Size = new System.Drawing.Size(75, 23);
            this.btnSave.TabIndex = 33;
            this.btnSave.Tag = "NotActive";
            this.btnSave.Text = "Save";
            this.btnSave.UseVisualStyleBackColor = true;
            this.btnSave.Click += new System.EventHandler(this.btnSave_Click);
            // 
            // btnCancel
            // 
            this.btnCancel.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnCancel.Location = new System.Drawing.Point(100, 284);
            this.btnCancel.Name = "btnCancel";
            this.btnCancel.Size = new System.Drawing.Size(75, 23);
            this.btnCancel.TabIndex = 32;
            this.btnCancel.Tag = "NotActive";
            this.btnCancel.Text = "Cancel";
            this.btnCancel.UseVisualStyleBackColor = true;
            this.btnCancel.Click += new System.EventHandler(this.btnCancel_Click);
            // 
            // fmSettings
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(635, 317);
            this.Controls.Add(this.txtDefaultPssdPath);
            this.Controls.Add(this.lblBkColor);
            this.Controls.Add(this.btnPickColor);
            this.Controls.Add(this.lblCurrentColorText);
            this.Controls.Add(this.lblShowColor);
            this.Controls.Add(this.lblDefaultPath);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.chkBoxCreateEmail);
            this.Controls.Add(this.btnReset);
            this.Controls.Add(this.btnSave);
            this.Controls.Add(this.btnCancel);
            this.Name = "fmSettings";
            this.ShowIcon = false;
            this.Text = "Settings";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.fmSettings_FormClosing);
            this.Load += new System.EventHandler(this.fmSettings_Load);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox txtDefaultPssdPath;
        private System.Windows.Forms.Label lblBkColor;
        private System.Windows.Forms.Button btnPickColor;
        private System.Windows.Forms.Label lblCurrentColorText;
        private System.Windows.Forms.Label lblShowColor;
        private System.Windows.Forms.Label lblDefaultPath;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.CheckBox chkBoxCreateEmail;
        private System.Windows.Forms.Button btnReset;
        private System.Windows.Forms.Button btnSave;
        private System.Windows.Forms.Button btnCancel;
    }
}