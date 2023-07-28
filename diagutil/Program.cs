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
using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;
using System.IO;
using System.Diagnostics;
using System.Runtime.InteropServices;
using Microsoft.Win32;

namespace DiagUtil
{
    class Program
    {
        /// <summary>
        /// no args=just find sqldiag
        /// 1 == International counters
        /// </summary>
        static void Main(string[] args)
        {
            
            if (args.Length == 0)
            {
                FindSqldiag();
            }
            else
            {
                switch (args[0])
                {
                    case "1":
                        TransfromInternatioinalPerfmonCounters();
                        break;
                    default:
                        //do nothing here
                        break;
                }
            }
            

        }

        static void FindSqldiag()
        {
            try
            {

                bool is64bit = false;

                using (XmlReader xmlReader = XmlReader.Create(@"pssdiag.xml", new XmlReaderSettings() {XmlResolver = null } ))
                {
                    XmlDocument ConfigDoc = new XmlDocument() { XmlResolver = null };
                    ConfigDoc.Load(xmlReader);

                    string sqlver = ConfigDoc["dsConfig"]["Collection"]["Machines"]["Machine"]["Instances"]["Instance"].Attributes["ssver"].Value;

                    // SQL 2008 and 2008 R2 share the same tools so we call the same routine for both versions
                    if (sqlver == "10.50")
                        sqlver = "10";

                    string plat = ConfigDoc["dsConfig"]["DiagMgrInfo"]["IntendedPlatform"].InnerText;


                    String x86Env = Environment.GetEnvironmentVariable("CommonProgramFiles(x86)");

                    if (x86Env != null)
                    {
                        is64bit = true;
                    }

                    string tools = (string)Registry.GetValue(string.Format(@"HKEY_LOCAL_MACHINE\" + @"SOFTWARE\Microsoft\Microsoft SQL Server\{0}0\Tools\ClientSetup", sqlver), "Path", null);
                    string toolswow = (string)Registry.GetValue(string.Format(@"HKEY_LOCAL_MACHINE\" + @"SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\{0}0\Tools\ClientSetup", sqlver), "Path", null);

                    string toolsbin = tools;
                    if (is64bit == true && plat.Trim().ToUpper() == "I386" && System.IO.File.Exists(toolswow)) //last condition: if a pure 2008 R2 is isntalled sqldiag.exe WOW is not shipped
                    {
                        toolsbin = toolswow;
                    }

                    if (!System.IO.File.Exists(toolsbin + "sqldiag.exe"))
                    {
                        System.Windows.Forms.MessageBox.Show("Unable to find SQL Server client tools such as sqldiag.exe from this machine.  Data collection will fail");
                    }

                    Console.WriteLine(sqlver + "~" + toolsbin);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error occured in findSqldiag");
                Console.WriteLine(ex.ToString());
            }

        }
        static void TransfromInternatioinalPerfmonCounters()
        {

            string inputXml = "pssdiag.xml";
            string outputTempXml = "pssdiag_new_temp.xml";
            XmlDocument pssdiagDoc = null;

            CounterDictionary counterDictionary = new CounterDictionary();
            counterDictionary.Init();

            using (XmlReader xmlReader = XmlReader.Create(inputXml, new XmlReaderSettings() { XmlResolver = null }))
            {
                //Read XML and change counters
                pssdiagDoc = new XmlDocument() { XmlResolver = null };
                pssdiagDoc.Load(xmlReader);

                XmlTranslator translator = new XmlTranslator(counterDictionary);
                translator.Translate(pssdiagDoc);
                pssdiagDoc.Save(outputTempXml);
            }

            // To overwrite the destination file if it already exists with the content of the new translated counters
            // then delete the pssdiag_new_temp.xml file
            File.Copy(outputTempXml, inputXml, true);
            File.Delete(outputTempXml);

        }
    }
    
}
