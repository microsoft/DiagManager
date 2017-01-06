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
using System.IO;
using System.IO.Compression;
using PssdiagConfig;


namespace PssdiagConfig
{
    public class PackageMgr
    {
        UserSetting m_userchoice;
        string m_DestFullFileName;
        string m_DestPathNameOnly;
        string m_DestFileNameOnly;
        string m_tempDirectory = Globals.BuildDir;
        public PackageMgr(UserSetting userchoice, string destFullFileName)
        {
            m_userchoice = userchoice;
            m_DestFullFileName = destFullFileName;
            m_DestPathNameOnly= Path.GetDirectoryName(destFullFileName);
            m_DestFileNameOnly = Path.GetFileName(destFullFileName);

        }

        private void CopyAllFiles()
        {
            string FinalOutputFolder = m_userchoice[Res.OutputFolder];
            

            ConfigFileMgrEx configMgr = new ConfigFileMgrEx(m_userchoice);

            //clear tempDirectory
            Globals.DeleteDir(m_tempDirectory);



            //generate XEvent script file
            StreamWriter srXEventFile = File.CreateText(m_tempDirectory + @"\pssdiag_xevent.sql");
            srXEventFile.Write(m_userchoice.XEventCategoryList.GetCheckedDiagItemList().GetSQLScript());
            srXEventFile.Flush();
            srXEventFile.Close();

            //pssdiag.xml
            configMgr.SaveConfig(m_tempDirectory + @"\pssdiag.xml");


            // copy custom diagnostics

            List<DiagCategory> selectedcustomDiagList = m_userchoice.CustomDiagCategoryList.GetCheckedCategoryList();


            foreach (DiagCategory cat in selectedcustomDiagList)
            {
                string src = Globals.ExePath + @"\CustomDiagnostics\" + cat.Name;
                Globals.CopyDir(src, m_tempDirectory);

                Globals.CopyDir(src + @"\" + m_userchoice[Res.Platform], m_tempDirectory);

            }


            //Copy Pristine
            Globals.CopyDir(Globals.ExePath + @"\Pristine", m_tempDirectory);
            Globals.CopyDir(Globals.ExePath + @"\Pristine\" + m_userchoice[Res.Platform], m_tempDirectory);

            string customdiagxml = m_tempDirectory + @"\CustomDiag.XML";

            //these are copied over from custom diag folder. we don't need it
            if (File.Exists(customdiagxml))
            {
                File.Delete(customdiagxml);
            }

        }

        public void MakeZip()
        {
            CopyAllFiles();

            if (File.Exists(m_DestFullFileName))
            {
                File.Delete(m_DestFullFileName);
            }
            ZipFile.CreateFromDirectory(m_tempDirectory, m_DestFullFileName);
        }

    }
}
