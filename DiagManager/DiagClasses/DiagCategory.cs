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

namespace PssdiagConfig
{

    #region XCategory
    [Serializable()]
    public class DiagCategory : DiagItem //, IComparable<DiagCategory>
    {

        public List<DiagItem> DiagEventList = new List<DiagItem>();

        //todo:need to remove
        public List<Xevent> XEventList_DONOTUSE = new List<Xevent>();

        //used to handle one off things like xevent custome collector or AS Trace
        public void CheckEvents (bool ischecked)
        {
            foreach (DiagItem item in DiagEventList)
            {
                item.IsChecked = ischecked;
            }

        }
    
        public string GetCheckedEventListXml()
        {

            StringBuilder sb = new StringBuilder();
            sb.Append("");

            

            string Inner = "";
            foreach (DiagItem item in DiagEventList)
            {
                if (item.IsChecked)
                {
                    Inner += item.GetElement(true);
                }
            }

            if (!string.IsNullOrEmpty(Inner))
            {
                sb.Append(GetOpenTag(true));
                sb.Append(Inner);
                sb.Append(GetCloseTag());
            }
            
            return sb.ToString();
        }

        public List<DiagItem> GetCheckedEventList()
        {
            List<DiagItem> list = new List<DiagItem>();


            foreach (DiagItem item in DiagEventList)
            {
                if (item.IsChecked)
                {
                    list.Add(item);
                }
            }

            return list;
        }

            
        
        public override string ToString()
        {
            return Name;
        }
        public string FullName
        {
            get { return Name; }
        }

        /*
        public int  CompareTo(DiagCategory other)
        {
            if (null == other) return 1;
            return this.Name.CompareTo(other.Name);
        }*/
        public override string TreeNodeName
        {
            get
            {
                return base.Name;
            }
            set
            {
                base.TreeNodeName = value;
            }
        }
        public override string TreeNodeText
        {
            get
            {
                return base.Name;
            }
            set
            {
                base.TreeNodeText = value;
            }
        }

        public DiagCategory(string xmltag, string name)
        {
            base.XmlTagName = xmltag;
            base.Name = name;

        }


    }



    #endregion
}
