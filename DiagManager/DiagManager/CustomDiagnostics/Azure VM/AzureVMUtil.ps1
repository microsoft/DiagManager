
# powershell.exe -ExecutionPolicy Bypass .\AzureVMUtil.ps1

$source = @" 
using System; 
using System.Collections.Generic; 
using System.Text; 
using System.Runtime.InteropServices; 
using System.ComponentModel; 
using System.Net.NetworkInformation; 
 
namespace Microsoft.WindowsAzure.Internal 
{ 
    /// <summary> 
    /// A simple DHCP client. 
    /// </summary> 
    public class DhcpClient : IDisposable 
    { 
        public DhcpClient() 
        { 
            uint version; 
            int err = NativeMethods.DhcpCApiInitialize(out version); 
            if (err != 0) 
                throw new Win32Exception(err); 
        } 
 
        public void Dispose() 
        { 
            NativeMethods.DhcpCApiCleanup(); 
        } 
 
        /// <summary> 
        /// Gets the available interfaces that are enabled for DHCP. 
        /// </summary> 
        /// <remarks> 
        /// The operational status of the interface is not assessed. 
        /// </remarks> 
        /// <returns></returns> 
        public static IEnumerable<NetworkInterface> GetDhcpInterfaces() 
        { 
            foreach (NetworkInterface nic in NetworkInterface.GetAllNetworkInterfaces()) 
            { 
                if (nic.NetworkInterfaceType != NetworkInterfaceType.Ethernet) continue; 
                if (!nic.Supports(NetworkInterfaceComponent.IPv4)) continue; 
                IPInterfaceProperties props = nic.GetIPProperties(); 
                if (props == null) continue; 
                IPv4InterfaceProperties v4props = props.GetIPv4Properties(); 
                if (v4props == null) continue; 
                if (!v4props.IsDhcpEnabled) continue; 
 
                yield return nic; 
            } 
        } 
 
        /// <summary> 
        /// Requests DHCP parameter data. 
        /// </summary> 
        /// <remarks> 
        /// Windows serves the data from a cache when possible.   
        /// With persistent requests, the option is obtained during boot-time DHCP negotiation. 
        /// </remarks> 
        /// <param name="optionId">the option to obtain.</param> 
        /// <param name="isVendorSpecific">indicates whether the option is vendor-specific.</param> 
        /// <param name="persistent">indicates whether the request should be persistent.</param> 
        /// <returns></returns> 
        public byte[] DhcpRequestParams(string adapterName, uint optionId) 
        { 
            uint bufferSize = 1024; 
        Retry: 
            IntPtr buffer = Marshal.AllocHGlobal((int)bufferSize); 
            try 
            { 
                NativeMethods.DHCPCAPI_PARAMS_ARRAY sendParams = new NativeMethods.DHCPCAPI_PARAMS_ARRAY(); 
                sendParams.nParams = 0; 
                sendParams.Params = IntPtr.Zero; 
 
                NativeMethods.DHCPCAPI_PARAMS recv = new NativeMethods.DHCPCAPI_PARAMS(); 
                recv.Flags = 0x0; 
                recv.OptionId = optionId; 
                recv.IsVendor = false; 
                recv.Data = IntPtr.Zero; 
                recv.nBytesData = 0; 
 
                IntPtr recdParamsPtr = Marshal.AllocHGlobal(Marshal.SizeOf(recv)); 
                try 
                { 
                    Marshal.StructureToPtr(recv, recdParamsPtr, false); 
 
                    NativeMethods.DHCPCAPI_PARAMS_ARRAY recdParams = new NativeMethods.DHCPCAPI_PARAMS_ARRAY(); 
                    recdParams.nParams = 1; 
                    recdParams.Params = recdParamsPtr; 
 
                    NativeMethods.DhcpRequestFlags flags = NativeMethods.DhcpRequestFlags.DHCPCAPI_REQUEST_SYNCHRONOUS; 
 
                    int err = NativeMethods.DhcpRequestParams( 
                        flags, 
                        IntPtr.Zero, 
                        adapterName, 
                        IntPtr.Zero, 
                        sendParams, 
                        recdParams, 
                        buffer, 
                        ref bufferSize, 
                        null); 
 
                    if (err == NativeMethods.ERROR_MORE_DATA) 
                    { 
                        bufferSize *= 2; 
                        goto Retry; 
                    } 
 
                    if (err != 0) 
                        throw new Win32Exception(err); 
 
                    recv = (NativeMethods.DHCPCAPI_PARAMS)  
                        Marshal.PtrToStructure(recdParamsPtr, typeof(NativeMethods.DHCPCAPI_PARAMS)); 
 
                    if (recv.Data == IntPtr.Zero) 
                        return null; 
 
                    byte[] data = new byte[recv.nBytesData]; 
                    Marshal.Copy(recv.Data, data, 0, (int)recv.nBytesData); 
                    return data; 
                } 
                finally 
                { 
                    Marshal.FreeHGlobal(recdParamsPtr); 
                } 
            } 
            finally 
            { 
                Marshal.FreeHGlobal(buffer); 
            } 
        } 
 
        ///// <summary> 
        ///// Unregisters a persistent request. 
        ///// </summary> 
        //public void DhcpUndoRequestParams() 
        //{ 
        //    int err = NativeMethods.DhcpUndoRequestParams(0, IntPtr.Zero, null, this.ApplicationID); 
        //    if (err != 0) 
        //        throw new Win32Exception(err); 
        //} 
 
        #region Native Methods 
    } 
 
    internal static partial class NativeMethods 
    { 
        public const uint ERROR_MORE_DATA = 124; 
 
        [DllImport("dhcpcsvc.dll", EntryPoint = "DhcpRequestParams", CharSet = CharSet.Unicode, SetLastError = false)] 
        public static extern int DhcpRequestParams( 
            DhcpRequestFlags Flags, 
            IntPtr Reserved, 
            string AdapterName, 
            IntPtr ClassId, 
            DHCPCAPI_PARAMS_ARRAY SendParams, 
            DHCPCAPI_PARAMS_ARRAY RecdParams, 
            IntPtr Buffer, 
            ref UInt32 pSize, 
            string RequestIdStr 
            ); 
 
        [DllImport("dhcpcsvc.dll", EntryPoint = "DhcpUndoRequestParams", CharSet = CharSet.Unicode, SetLastError = false)] 
        public static extern int DhcpUndoRequestParams( 
            uint Flags, 
            IntPtr Reserved, 
            string AdapterName, 
            string RequestIdStr); 
 
        [DllImport("dhcpcsvc.dll", EntryPoint = "DhcpCApiInitialize", CharSet = CharSet.Unicode, SetLastError = false)] 
        public static extern int DhcpCApiInitialize(out uint Version); 
 
        [DllImport("dhcpcsvc.dll", EntryPoint = "DhcpCApiCleanup", CharSet = CharSet.Unicode, SetLastError = false)] 
        public static extern int DhcpCApiCleanup(); 
 
        [Flags] 
        public enum DhcpRequestFlags : uint 
        { 
            DHCPCAPI_REQUEST_PERSISTENT = 0x01, 
            DHCPCAPI_REQUEST_SYNCHRONOUS = 0x02, 
            DHCPCAPI_REQUEST_ASYNCHRONOUS = 0x04, 
            DHCPCAPI_REQUEST_CANCEL = 0x08, 
            DHCPCAPI_REQUEST_MASK = 0x0F 
        } 
 
        [StructLayout(LayoutKind.Sequential)] 
        public struct DHCPCAPI_PARAMS_ARRAY 
        { 
            public UInt32 nParams; 
            public IntPtr Params; 
        } 
 
        [StructLayout(LayoutKind.Sequential)] 
        public struct DHCPCAPI_PARAMS 
        { 
            public UInt32 Flags; 
            public UInt32 OptionId; 
            [MarshalAs(UnmanagedType.Bool)]  
            public bool IsVendor; 
            public IntPtr Data; 
            public UInt32 nBytesData; 
        } 
        #endregion 
    } 
} 
"@ 
 
Add-Type -TypeDefinition $source  
 
Function Confirm-AzureVM { 
     
    $detected = $False 
 
    [void][System.Reflection.Assembly]::LoadWithPartialName('System.Serviceprocess') 
 
    $vmbus = [System.ServiceProcess.ServiceController]::GetDevices() | where {$_.Name -eq 'vmbus'} 
 
    If($vmbus.Status -eq 'Running') 
    { 
        $client = New-Object Microsoft.WindowsAzure.Internal.DhcpClient 
        try { 
            [Microsoft.WindowsAzure.Internal.DhcpClient]::GetDhcpInterfaces() | % {  
                $val = $client.DhcpRequestParams($_.Id, 245) 
                if($val -And $val.Length -eq 4) { 
                    $detected = $True 
                } 
            } 
        } finally { 
            $client.Dispose() 
        }     
    } 

$result = "Is AzureVM                                         "  +  $detected ;
Write-Output ""
Write-Output ""
Write-Output "--ServerProperty--"
Write-Output "PropertyName                                       PropertyValue                                                                                                                                                                                                                                                   "
Write-Output "-------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Output $result
Write-Output ""
Write-Output ""


} 
 
Function Get-SectorInfo {
   
  Write-Output "--Disk Sector Info--"
    $wql = "SELECT DriveLetter, Label, Blocksize, Name FROM Win32_Volume WHERE FileSystem='NTFS'"  
    Get-WmiObject -Query $wql -ComputerName '.' | Select-Object DriveLetter, Label, Blocksize, Name 
    Write-Output " "

    Write-Output "--Virtual Disk Info--"
    Get-VirtualDisk  |select FriendlyName,HealthStatus, NumberofColumns,Interleave , size |ft



}

function Get-ClusterInfo
{
    Write-Output "--Get Cluster threasholds--"
    get-cluster | fl *subnet*


    Write-Output "--Get Cluster parameters--"
    get-clusterresource | Get-ClusterParameter
}




Confirm-AzureVM
Get-SectorInfo

 Get-ClusterInfo


