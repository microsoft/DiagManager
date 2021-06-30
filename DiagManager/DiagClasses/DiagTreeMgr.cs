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
using System.Windows.Forms;
using System.Xml;
using System.Xml.XPath;

namespace PssdiagConfig
{
    public class DiagTreeMgr
    {

        private static void OnCheck(object sender, TreeViewEventArgs e)
        {
           

            e.Node.TreeView.AfterCheck -= OnCheck;
            TreeNode node = e.Node;
            TreeNode parentNode = e.Node.Parent;
           

            if (parentNode != null)
            {
                bool AllChildNodesChecked = true;
                bool AllChildNodesUnchecked = true;
                bool IsAnyChildNodechecked = false;

                foreach (TreeNode childNode in parentNode.Nodes)
                {
                    if (childNode.Checked == false && AllChildNodesChecked == true)
                    {
                        AllChildNodesChecked = false;
                    }
                    if (childNode.Checked == true && IsAnyChildNodechecked == false)
                    {
                        IsAnyChildNodechecked = true;
                    }
                    if (childNode.Checked == true && AllChildNodesUnchecked == true)
                    {
                        AllChildNodesUnchecked = false;
                    }
                }

                if (AllChildNodesChecked || IsAnyChildNodechecked)
                {
                    parentNode.Checked = true;
                }
                if (AllChildNodesUnchecked)
                {
                    parentNode.Checked = false;

                }

                SetCategoryColor(parentNode);
            }
            else
            {
                foreach (TreeNode childNode in node.Nodes)
                {
                    childNode.Checked = node.Checked;
                    (childNode.Tag as DiagItem).IsChecked = childNode.Checked;

                }
                SetCategoryColor(node);
            }


            (e.Node.Tag as DiagItem).IsChecked = e.Node.Checked;
            

            e.Node.TreeView.AfterCheck += OnCheck;            


        }
        public static void SetCategoryColor (TreeNode node)
        {
            bool AllChecked = true;
            bool AnyChecked = false;

            foreach (TreeNode childNode in node.Nodes)
            {
                if (!childNode.Checked && AllChecked == true)
                {
                    AllChecked = false;
                }
                if (childNode.Checked && AnyChecked == false)
                {
                    AnyChecked = true;
                }
            }


            if (AnyChecked && !AllChecked)
            {
                node.ForeColor = System.Drawing.Color.Blue;
             

            }
            else if (AllChecked)
            {
                node.ForeColor = System.Drawing.Color.Green;
            }
            else //no selected
            {
                node.ForeColor = System.Drawing.Color.Black;
            }
            
        }
        public static void PopulateTree<T>  (TreeView tree, List<T> treelist, UserSetting setting)
        {


            TreeNodeCollection tc = tree.Nodes;
            tree.AfterCheck -= OnCheck;
            tree.AfterCheck += OnCheck;
            if (tc.Count > 0)
            {
                tree.Nodes.Clear();

            }

            //sort the list for tree display
            treelist.Sort();

            foreach (T obj in treelist)
            {
                DiagCategory cat = obj as DiagCategory;
                TreeNode catNode = new TreeNode();
                catNode.Name = cat.TreeNodeName;
                catNode.Text = cat.TreeNodeText;
                catNode.Tag = cat;

                if (cat.DiagEventList.Count <=0)
                {
                    continue;
                }

                cat.DiagEventList.Sort();

                bool anyChildChecked = false;
                foreach (DiagItem evt in cat.DiagEventList)
                {
                    TreeNode evtNode = new TreeNode();
                    evtNode.Name = evt.TreeNodeText;
                    evtNode.Text = evt.TreeNodeText;
                    bool IsVersionEnabled = false;
                    bool IsFeatureEanbled = false;
                    bool IsAnyTemplateEnabled = false;

                 

                    if (null != evt.EnabledVersions.Find(x => x.Name == setting["Version"] && x.Enabled == true))
                   {
                       IsVersionEnabled = true;
                   }

                    if (null != evt.EnabledFeatures.Find(x => x.Name == setting["Feature"] && x.Enabled == true))
                   {
                       IsFeatureEanbled = true;
                   }
                    //foreach (string temp in setting.GetDefaultChoiceByFeatureVersion (setting.Feature, setting.Version).ScenarioList)
                    foreach (string temp in setting.UserChosenScenarioList)
                   {

                       if (null != evt.EnabledTemplate.Find(x => x.Name == temp))
                       {
                           IsAnyTemplateEnabled = true;
                           break;
                       }

                   }

                   if (IsVersionEnabled == true && IsFeatureEanbled == true && IsAnyTemplateEnabled == true)
                    {
                        anyChildChecked = true;
                        evtNode.Checked = true;

                    }

                    evtNode.Tag = evt;
                    
                    if (IsVersionEnabled && IsFeatureEanbled)
                    { 
                        catNode.Nodes.Add(evtNode);
                        (evtNode.Tag as DiagItem).IsChecked = evtNode.Checked;
                    }


                }

                //don't add if the feature or version doesn't event support any of the events in this event category
                if (anyChildChecked == true)
                {
                    catNode.Checked = anyChildChecked;

                    
                }

                //only add the node if it's for this feature and version
                //regardless of template

                SetCategoryColor(catNode);
                if (catNode.Nodes.Count > 0)
                {
                    (catNode.Tag as DiagItem).IsChecked = catNode.Checked;
                    tree.Nodes.Add(catNode);
                }

            }
            tree.Refresh();
        }
        public static List<DiagCategory> CategoryListFromTree(TreeView tree)
        {
            List<DiagCategory> catList = new List<DiagCategory>();

            
            foreach (TreeNode catNode in tree.Nodes)
            {
                catList.Add(catNode.Tag as DiagCategory);
            }

            return catList;
        }

        
    }
}
