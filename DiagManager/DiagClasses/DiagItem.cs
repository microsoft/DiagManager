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
using System.Xml;
using System.Xml.XPath;

namespace PssdiagConfig
{

    [Serializable()]
    public class DiagItem : IComparable <DiagItem>
    {

        public DiagCategory Category { get; set; }

        public bool IsChecked { get; set; }

        public virtual string XmlTagName { get; set; }
        public virtual string Name { get; set; }
        public string FriendlyName { get; set; }
        public virtual string TreeNodeName {
            get { return this.Name; }
             set
             {
                 Name = value;
             }}
        
        public virtual string TreeNodeText {
            get
            {
                return Name;
            }
            set
            {
                Name = value;
            }
        }

        //do nothing
        //todo: need to delete
        public DiagItem()
        {

        }
        
        public DiagItem (DiagCategory cat, string xmltag, string name)
        {
            this.Category = cat;
            this.XmlTagName = xmltag;
            this.Name = name;
        }

        public virtual string GetOpenTag(bool isChecked) 
        {
            string template = "<{0} name =\"{1}\" enabled=\"{2}\">";
            return string.Format(template, XmlTagName, Name, isChecked.ToString().ToLower());
          
        }

        public virtual string GetCloseTag() 
        {
            return string.Format("</{0}>", XmlTagName);
        }
        public virtual string GetElement(bool isChecked)
        {
            string template = "<{0} name=\"{1}\" enabled=\"{2}\" />";
            return string.Format(template, this.XmlTagName, Util.ReplaceToken(this.Name), isChecked.ToString().ToLower());
        }

        public List<Feature> EnabledFeatures = new List<Feature>();
        public List<Version> EnabledVersions = new List<Version>();
        public List<Scenario> EnabledTemplate = new List<Scenario>();



        public int CompareTo(DiagItem other)
        {
            if (null == other) return 1;
            return this.Name.CompareTo(other.Name);
        }
        
        public override string ToString()
        {
            return this.Name;
        }
        public override int GetHashCode()
        {
            return Name.ToUpper().GetHashCode();
        }
    }

    
    
    
}
