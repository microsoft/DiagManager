#Check if the language is not English
if(((Get-WinUserLanguageList).LanguageTag | Select -First 1) -notlike "en*"){

    Write-Host "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff") Executing:Perfmon Counters localization. Please wait..."
    #Get all Local existing counters paths in array for future check
    $counterexistingpaths = @(Get-Counter -ListSet *).Paths
    $countertranslatedcounters = 1
    #Get performance counters names and ID's in english and local languages to hash table
    $pc_en_names = [Microsoft.Win32.Registry]::PerformanceData.GetValue("Counter 009")
    $pc_en_hash = @{}
    $duplicated_en_names_pc_hash = @{} 
    foreach ($item in $pc_en_names) {
        $pc_id_indexnumber = $pc_en_names.IndexOf($item)
        $pc_name_indexnumber = $pc_id_indexnumber+1
        $pv_name_to_add = $pc_en_names[$pc_name_indexnumber]
        if($pc_id_indexnumber% 2 -eq 0 ) {
            #check IF Hash Key already exist
            if(-not ([string]::IsNullOrEmpty($pv_name_to_add)) -and $pc_en_hash.ContainsKey($pv_name_to_add)) {
                $existing_name = $pc_en_hash.$pv_name_to_add
                $duplicated_en_names_pc_hash["$existing_name"] = $pv_name_to_add
                $duplicated_en_names_pc_hash["$item"] = $pv_name_to_add
            }
            $pc_en_hash["$pv_name_to_add"] = $item
        }

    }



    $pc_local_names = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Perflib\CurrentLanguage' -Name 'counter').Counter
    $pc_local_hash = @{}
    foreach ($item in $pc_local_names) {
        $pc_id_indexnumber = $pc_local_names.IndexOf($item)
        $pc_name_indexnumber = $pc_id_indexnumber+1
        if($pc_id_indexnumber% 2 -eq 0 ) {
            #Write-Host "$($pc_id_indexnumber) is even and the name is $($pc_en_names[$pc_name_indexnumber])"
            $pc_local_hash["$item"] = $pc_local_names[$pc_name_indexnumber]
        }

    }


    #get pssdiag xml with performance counters info
    $pathxml = "pssdiag.xml"
    $xml = [xml](Get-Content $pathxml)



    #Get all Perfmon Objects
    $obnodes = $xml.dsConfig.Collection.Machines.Machine.MachineCollectors.PerfmonCollector.PerfmonCounters.SelectNodes("//PerfmonObject[@name]")



    #Translate each Object
    foreach ($obnode in $obnodes) {
        #find performance object in XML
        $xmlPerfObejct = $xml.dsConfig.Collection.Machines.Machine.MachineCollectors.PerfmonCollector.PerfmonCounters.SelectSingleNode("//PerfmonObject[@name='" + $obnode.name + "']")

        #split the string before and after the (), add the first parenteses after split
        IF($xmlPerfObejct.name.Contains("(")) {
            $afixo = $xmlPerfObejct.name.Split('(')
            $afixo[1] = '(' + $afixo[1]
        }ELSE{
            $afixo[0] = $xmlPerfObejct.name
            $afixo[1] = ""
        }


        #Remove the \ at the beginning of the performance object name and make sure exact match name search
        $searchOBname= $afixo[0].substring(1)
        #Get the Object ID based on the line before of the name match
        $LocalPerfObID = $pc_en_hash.$searchOBname
    
        IF (-not ([string]::IsNullOrEmpty($LocalPerfObID))){
            $pob_local_name = $pc_local_hash."$LocalPerfObID"


            IF (-not ([string]::IsNullOrEmpty($pob_local_name))){
            $pob_translated_name = "\" + $pob_local_name + $afixo[1]

            #change the xml of the counter
            $xmlPerfObejct.name = $pob_translated_name
            }
        }



        #Get Perfmon Counters per perfmonobject
        $pcnodes = $xml.dsConfig.Collection.Machines.Machine.MachineCollectors.PerfmonCollector.PerfmonCounters.SelectNodes("//PerfmonObject[@name='" + $obnode.name + "']/PerfmonCounter[@name]")

        foreach ($pcnode in $pcnodes) {
            #find performance object in XML
            $xmlPerfCounter = $xml.dsConfig.Collection.Machines.Machine.MachineCollectors.PerfmonCollector.PerfmonCounters.SelectSingleNode("//PerfmonObject[@name='" + $obnode.name + "']/PerfmonCounter[@name='" + $pcnode.name + "']")

            IF ($xmlPerfCounter.name -ne "\(*)"){

                #Remove the \ at the beginning of the performance object name and make sure exact match name search
                $searchpcname= $xmlPerfCounter.name.substring(1)
                #Get the Object ID based on the line before of the name match
                $LocalPerfCounterID = $pc_en_hash.$searchpcname
    
                IF (-not ([string]::IsNullOrEmpty($LocalPerfCounterID))){
                

                    $pc_local_name = $pc_local_hash."$LocalPerfCounterID"

                    IF (-not ([string]::IsNullOrEmpty($pc_local_name))){

                        #Confirm correct name translation per object+countername
                        IF ($duplicated_en_names_pc_hash.ContainsKey($LocalPerfCounterID)){

                            $pc_duplicated_id = $duplicated_en_names_pc_hash.Keys.Where({$duplicated_en_names_pc_hash[$_] -eq $searchpcname})

                            foreach ($dup_node in $pc_duplicated_id){
                                $dup_node_name = $pc_local_hash."$dup_node"
                                $confirm_counter = $pob_translated_name + "\" + $dup_node_name

                                IF ($counterexistingpaths.Contains($confirm_counter)){
                                    $pc_local_name = $dup_node_name
                                }
                            }
                        }

                        $pc_translated_name = "\" + $pc_local_name


                        #change the xml of the counter

                        $xmlPerfCounter.name = $pc_translated_name
                        $countertranslatedcounters = $countertranslatedcounters +1                
                    }
                }
            }
        }


    }




    #save the XML file with the changes
    $xmlsavelocation = (Get-Location).Path + "\" + $pathxml
    $xml.Save($xmlsavelocation)
    Write-Host "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff") $countertranslatedcounters Perfmon counters in local Language saved in pssdiag.xml"}