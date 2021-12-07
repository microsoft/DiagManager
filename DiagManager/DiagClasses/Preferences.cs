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
using System.Windows.Forms;
using System.IO;
using System.Xml;
using System.Xml.XPath;
using System.Xml.Serialization;

namespace PssdiagConfig
{
    [Serializable()]
    public class Preferences
    {
        
        public string DefaultPssdPath = @"c:\temp";
        static string userPreferenceFile = Globals.PssdiagAppData + @"\Diagmanager.user.preferences";
        public int Argb;

        
        public Preferences()
        {
            /*
            -1908000 gray
            -1118227 light gray
            -2629132 light blue
            */
            SetBackgroundColor(System.Drawing.Color.FromArgb(-1118227));
            
        }

        public void SetBackgroundColor(System.Drawing.Color bkcolor)
        {
            Argb = bkcolor.ToArgb();
        }
        public System.Drawing.Color GetBackgroundColor ()
        {
            return System.Drawing.Color.FromArgb(Argb);
        }
        public void Save()
        {

            if (File.Exists(userPreferenceFile))
            {
                File.Delete(userPreferenceFile);
            }

            //background doesn't support transparent color
            if (Argb == 0)
            {
                Argb = -1118227;
            }

            FileStream outFile = File.Create(userPreferenceFile);

            XmlSerializer formatter = new XmlSerializer(this.GetType());
            formatter.Serialize(outFile, this);
            outFile.Flush();
            outFile.Close();
            Logger.LogInfo("saving " + userPreferenceFile);
        }
        public static void Rest()
        {
            if (File.Exists(userPreferenceFile))
            {
                File.Delete(userPreferenceFile);
            }


        }
        public static Preferences Load()
        {

            if (File.Exists(userPreferenceFile))
            {
                try
                { 
                XmlSerializer SerializerObj = new XmlSerializer(typeof(Preferences));
                FileStream ReadFileStream = new FileStream(userPreferenceFile, FileMode.Open, FileAccess.Read, FileShare.Read);
                Preferences LoadedObj = (Preferences)SerializerObj.Deserialize(ReadFileStream);
                ReadFileStream.Close();
                return LoadedObj;
                }
                catch (Exception ex)
                {
                    return new Preferences();
                }

            }
            else
            {
                return new Preferences();
            }


        }

    }
}
