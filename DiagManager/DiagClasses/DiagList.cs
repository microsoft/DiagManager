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


    public static class DiagList
    {
        public static void AddToFront<T>(this List<T> list, T item)
        {
            // omits validation, etc.
            list.Insert(0, item);
        }

        public static void PrintList <T> (this List<T> list)
        {

            foreach (T obj in list)
            {

                Logger.LogInfo(obj.ToString());
                
            }

        }
     
        public static void InsertUnique<T>(this List<T> list, T item)
        {
            bool bExists =    list.Exists( x =>  x.GetHashCode() == item.GetHashCode());
           
            if (bExists)
            {
                throw new ArgumentException("There is already an item named: " + item.ToString());
            }

            list.Add(item);
        }

        public static T FindByNameIgnoreCase <T>(this List<T> list, string _Name)
        {
            T item = list.Find(x => x.GetHashCode() == _Name.ToUpper().GetHashCode());
            return item;
        }


        public static List<CompOp>  GetCompOpListByType(this List<CompOp> list, bool ForNumOnly)
        {
            if (false == ForNumOnly) return list;

            List<CompOp>  col = new List<CompOp> ();

            foreach (CompOp op in list)
            {
                if (op.CanApplyNum == true)
                {
                    col.Add(op);
                }
            }
            return col;
        }

        public static List<DiagCategory> GetCheckedCategoryList(this List<DiagCategory> list)
        {

            List<DiagCategory> checedkList = new List<DiagCategory>();

            foreach (DiagCategory cat in list)
            {
                if (cat.IsChecked == true)
                {
                    checedkList.Add(cat);
                }
            }

            return checedkList;

        }

        public static List<DiagItem> GetCheckedDiagItemList(this List<DiagCategory> list)
        {
            List<DiagItem> itemList = new List<DiagItem>();

            foreach (DiagCategory cat in list)
            {
                foreach (DiagItem item in cat.GetCheckedEventList())
                {
                    itemList.Add(item);
                }

            }

            return itemList;
        }
        public static List<DiagItem> GetDiagItemListByFeatureName(this List<DiagItem> list, string FeatureName)
        {
            List<DiagItem> itemList = new List<DiagItem>();

            foreach (DiagItem item in list)
            {
                Feature feat = item.EnabledFeatures.Find(x => x.Name == FeatureName);
                if (null != feat && feat.Enabled)
                {
                    itemList.Add(item);
                }

            }
            return itemList;
        }

        public static string GetCategoryXml(this List<DiagCategory> list)
        {
            StringBuilder sb = new StringBuilder();
            sb.Append("");

            foreach (DiagCategory cat in list)
            {
                sb.Append(cat.GetCheckedEventListXml());

            }
            return sb.ToString();
        }

        public static string GetTraceFilterXML (this List<TraceFilter> list)
        {
            StringBuilder sb = new StringBuilder();
            sb.Append("");

            if (list.Count> 0)
            {
            //    sb.Append ("<Parameters>");
            }

            foreach (TraceFilter filter in list)
            {
                sb.Append (filter.GetXML());
            }

            if (list.Count> 0)
            {
                //sb.Append("</Parameters>");
            }
            return sb.ToString();

        }



        //getting XEvent Script
        /* working example

          CREATE EVENT SESSION [Batch_RPC_Only] ON SERVER 
                ADD EVENT sqlserver.rpc_completed(SET collect_data_stream=(1),collect_statement=(1)
                ACTION(package0.collect_cpu_cycle_time,package0.collect_current_thread_id,package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.query_hash,sqlserver.request_id,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)),
                ADD EVENT sqlserver.sql_batch_completed(
                ACTION(package0.collect_current_thread_id,package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.query_hash,sqlserver.request_id,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)) 
                ADD TARGET package0.event_file(SET filename=N'$(XEFileName)',max_file_size=(500),max_rollover_files=(50))
                WITH (MAX_MEMORY=200800 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=10 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=PER_CPU,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
         */
        public static string GetSQLScript (this List<DiagItem> list)
        {
            StringBuilder sb = new StringBuilder();
            sb.Append("if exists (select * from sys.server_event_sessions where name= 'pssdiag_xevent') drop  EVENT SESSION [pssdiag_xevent] ON SERVER \r\n");
            sb.Append("GO\r\n");
            sb.Append("CREATE EVENT SESSION [pssdiag_xevent] ON SERVER \r\n");

            int ctr = 0;
            foreach (Xevent xevt in list)
            {
                string prefix = "";
                if (ctr == 0)
                {
                    
                    sb.Append(prefix + xevt.AddEventActionText() + "\r\n");
                    sb.Append("WITH (MAX_MEMORY=200800 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=10 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=PER_CPU,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)\n\r");

                }
                else
                {
                    prefix = "GO\r\n";
                    prefix += "alter  EVENT SESSION [pssdiag_xevent] ON SERVER  ";
                    sb.Append(prefix + xevt.AddEventActionText() + "\r\n");
                }
                ctr++;
            }
            return sb.ToString();
        }
    }
}
