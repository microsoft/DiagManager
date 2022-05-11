#revert xml file to original En language
Copy-Item -Path C:\perfmon_test\org\pssdiag.xml -Destination C:\perfmon_test\pssdiag.xml

#Get performance counters names and ID's in english and local languages
$pc_en_names = [Microsoft.Win32.Registry]::PerformanceData.GetValue("Counter 009")
$pc_local_names = Get-ItemProperty –Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\CurrentLanguage' –Name 'counter' | Select-Object –ExpandProperty Counter



#get pssdiag xml with performance counters info
$pathxml = "C:\perfmon_test\pssdiag.xml"
$xml = [xml](Get-Content $pathxml)



#Get all Perfmon Objects
$objs = @()
$nodes = $xml.dsConfig.Collection.Machines.Machine.MachineCollectors.PerfmonCollector.PerfmonCounters.SelectNodes("//PerfmonObject[@name]")



#Translate each Object
foreach ($node in $nodes) {
    #find performance object in XML
    $xmlPerfObejct = $xml.dsConfig.Collection.Machines.Machine.MachineCollectors.PerfmonCollector.PerfmonCounters.SelectSingleNode("//PerfmonObject[@name='" + $node.name + "']")

    #split the string before and after the (), add the first parenteses after split
    IF($xmlPerfObejct.name.Contains("(")) {
        $afixo = $xmlPerfObejct.name.Split('(')
        $afixo[1] = '(' + $afixo[1]
    }ELSE{
        $afixo[0] = $xmlPerfObejct.name
        $afixo[1] = ""
    }


    #Remove the \ at the beginning of the performance object name and make sure exact match name search
    $searchOBname= "^" + $afixo[0].substring(1) + "$"
    #Get the Object ID based on the line before of the name match
    $LocalPerfObID = ($pc_en_names | Select-String -Pattern $searchOBname -Context 1,0).Context.DisplayPreContext
    
    IF (-not ([string]::IsNullOrEmpty($LocalPerfObID))){
        #make sure exact match ID search
        $searchLocalPerfObID = "^" + $LocalPerfObID + "$"

        $pob_local_name = ($pc_local_names | Select-String -Pattern $searchLocalPerfObID -Context 0,1).Context.DisplayPostContext


        IF (-not ([string]::IsNullOrEmpty($pob_local_name))){
        $pob_translated_name = "\" + $pob_local_name + $afixo[1]

        #change the xml of the counter
        $xmlPerfObejct.name = $pob_translated_name
        }
    }

}








#Get all Perfmon Counters
$objs = @()
$nodes = $xml.dsConfig.Collection.Machines.Machine.MachineCollectors.PerfmonCollector.PerfmonCounters.SelectNodes("//PerfmonCounter[@name]")



foreach ($node in $nodes) {
    #find performance object in XML
    $xmlPerfCounter = $xml.dsConfig.Collection.Machines.Machine.MachineCollectors.PerfmonCollector.PerfmonCounters.SelectSingleNode("//PerfmonCounter[@name='" + $node.name + "']")

    IF ($xmlPerfCounter.name -ne "\(*)"){

        #Remove the \ at the beginning of the performance object name and make sure exact match name search
        $searchpcname= "^" + $xmlPerfCounter.name.substring(1) + "$"
        #Get the Object ID based on the line before of the name match
        $LocalPerfCounterID = ($pc_en_names | Select-String -Pattern $searchpcname -Context 1,0).Context.DisplayPreContext
    
        IF (-not ([string]::IsNullOrEmpty($LocalPerfCounterID))){
            #make sure exact match ID search
            $searchLocalPerfCounterID = "^" + $LocalPerfCounterID + "$"

            $pc_local_name = ($pc_local_names | Select-String -Pattern $searchLocalPerfCounterID -Context 0,1).Context.DisplayPostContext

            IF (-not ([string]::IsNullOrEmpty($pc_local_name))){
                $pc_translated_name = "\" + $pc_local_name


                #change the xml of the counter

                $xmlPerfCounter.name = $pc_translated_name
                
            }
        }
    }
}






#save the XML file with the changes
$xml.Save("C:\perfmon_test\pssdiag.xml")