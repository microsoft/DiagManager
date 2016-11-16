
Set objWMIService = GetObject("WinMgmts:\\.\root\cimv2\power")

Set PowerPlans = objWMIService.InstancesOf("Win32_PowerPlan")
wscript.echo "--- Power Plan ---"
wscript.echo "ActivePlanName"
wscript.echo "-------------------------------------------------------------------------------------------------------------------"
For Each PowerPlan in PowerPlans
  If PowerPlan.IsActive Then
    wscript.echo PowerPlan.ElementName
   
  End If
Next
wscript.echo ""
wscript.echo "(1 row(s) affected)"

wscript.echo ""
wscript.echo ""
wscript.echo "WARNING:  You must manually check BIOS setting.  This tool can not check BIOS setting.  "

