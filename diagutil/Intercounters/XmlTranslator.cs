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
using System.Xml.XPath;

namespace DiagUtil
{
    internal class XmlTranslator
    {
        #region private
        Dictionary<string, string> m_dictionary;
        #endregion

        #region public
        public XmlTranslator(Dictionary<string, string> dictionary)
        {
            m_dictionary = dictionary;
        }

        public void Translate(XmlDocument pssdiagDoc)
        {
            XPathNavigator nav = pssdiagDoc.CreateNavigator();
            XPathExpression perfmonObject = nav.Compile("/dsConfig/Collection/Machines/Machine/MachineCollectors/PerfmonCollector/PerfmonCounters/PerfmonObject");
            XPathNodeIterator iteratorPerfObject = nav.Select(perfmonObject);

            //iterate over PerfmonObjects
            while (iteratorPerfObject.MoveNext())
            {

                string attribute = iteratorPerfObject.Current.GetAttribute("name", "").Substring(1);
                string sufix = string.Empty;
                int startofsufix = attribute.IndexOf('(');
                if (startofsufix >= 0)
                {
                    sufix = attribute.Substring(startofsufix);
                    attribute = attribute.Substring(0, startofsufix);
                }
                string substitute = string.Empty;
                if (m_dictionary.ContainsKey(attribute))
                {
                    substitute = string.Format("\\{0}{1}", m_dictionary[attribute], sufix);
                }

                if (string.IsNullOrEmpty(substitute))
                {
                    substitute = string.Format("\\{0}{1}", attribute, sufix);
                }

                //delete english PerfmonObjects name and add local PerfmonObjects name
                XPathNavigator currentNode = iteratorPerfObject.Current;
                currentNode.MoveToAttribute("name", "");
                currentNode.DeleteSelf();
                iteratorPerfObject.Current.CreateAttribute("", "name", "", substitute);

                //iterate throught PerfmonCounter searching for matches
                XPathExpression perfmonCounter = iteratorPerfObject.Current.Compile("PerfmonCounter");
                XPathNodeIterator iteratorPerfCounter = iteratorPerfObject.Current.Select(perfmonCounter);
                while (iteratorPerfCounter.MoveNext())
                {
                    string attributePerfCounter = iteratorPerfCounter.Current.GetAttribute("name", "").Substring(1);
                    string substitutePerfCounter = string.Empty;
                    string sufixPerfCounter = string.Empty;
                    int startofsufixPerfCounter = attributePerfCounter.IndexOf('(');
                    if (startofsufixPerfCounter >= 0)
                    {
                        sufixPerfCounter = attributePerfCounter.Substring(startofsufixPerfCounter);
                        attributePerfCounter = attributePerfCounter.Substring(0, startofsufixPerfCounter);
                    }
                    if (m_dictionary.ContainsKey(attributePerfCounter))
                    {
                        substitutePerfCounter = string.Format("\\{0}{1}", m_dictionary[attributePerfCounter], sufixPerfCounter);
                    }

                    if (string.IsNullOrEmpty(substitutePerfCounter))
                    {
                        substitutePerfCounter = string.Format("\\{0}{1}", attributePerfCounter, sufixPerfCounter);
                    }

                    //delete english PerfmonCounter name and add local PerfmonCounter name
                    XPathNavigator currentNodePerfCounter = iteratorPerfCounter.Current;
                    currentNodePerfCounter.MoveToAttribute("name", "");
                    currentNodePerfCounter.DeleteSelf();
                    iteratorPerfCounter.Current.CreateAttribute("", "name", "", substitutePerfCounter);
                }
            }
        }
        #endregion
    }
}
