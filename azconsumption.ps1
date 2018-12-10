#Login-AzAccount
$Subscription = Read-Host -Prompt 'Subscription Name :'
$BillingPeriodName = Read-Host -Prompt 'Billing Period (Example: 20181101):'
Set-AzContext -Subscription $Subscription
$ResourceGroupNames = Get-AzResourceGroup | select-object -Property ResourceGroupName
foreach ($ResourceGroup in $ResourceGroupNames) {
    #resourceusage= Get-AzConsumptionUsageDetail -Expand MeterDetails -BillingPeriodName 20181101 -ResourceGroup databricks-rg-dbricks-octopus-nersvuunzb2c6-dl4jrvkmc67ie | select-object InstanceName, PretaxCost, Product 
    $resourceusage = (Get-AzConsumptionUsageDetail -Expand MeterDetails -BillingPeriodName $BillingPeriodName -ResourceGroup $ResourceGroup.ResourceGroupName  | select-object InstanceName, PretaxCost,Product,UsageStart | Sort-Object -Property InstanceName, Product) 
    $usagedata = $resourceusage | group-object {$_.InstanceName}
    $totalresourcegroupcost = 0 
    $resourcesum = 0
    write-output "-------------------------"
    write-output $Subscription $ResourceGroup
    #$usagedata.Group.Length
    for($i=0; $i -lt $usagedata.Name.Count; $i++) {
    $productcost= 0
    for($j=0; $j -lt [int]($usagedata[$i].Group.Count); $j++) {
    
        #$usagedata[$i].Group[$j].InstanceName

        $resourcesum = $resourcesum + $usagedata[$i].Group[$j].PretaxCost

        if(-not ([string]::IsNullOrEmpty($usagedata[$i].Group[$j].Product))) {
        
            if(($usagedata[$i].Group[$j].Product -eq $usagedata[$i].Group[$j-1].Product) -and ($usagedata[$i].Group[$j].Product -eq $usagedata[$i].Group[$j+1].Product) ){
                $productcost = $usagedata[$i].Group[$j].PretaxCost + $productcost
                $productsum = $productcost
                #$productcost = 0
            }elseif(($usagedata[$i].Group[$j].Product -eq $usagedata[$i].Group[$j-1].Product)) {
                $productcost = $usagedata[$i].Group[$j].PretaxCost + $productcost
                $productsum = $productcost
                $productcost = 0
                
            }else {
                $productcost = $usagedata[$i].Group[$j].PretaxCost + $productcost
                $productsum = $productcost
                $productcost = 0
                
            }
        }

        if($productcost -eq 0) {
            #$usagedata[$i].Group[$j].InstanceName
            #Write-Output SubscriptionName:"Subscription" ":" ResourceGroup:"ResourceGroup.ResourceGroupName" ":" ResourceName: $usagedata[$i].Group[$j].InstanceName ":" Product: $usagedata[$i].Group[$j].Product ":"  $productsum USD
            $results = [PSCustomObject]@{SubscriptionName=$Subscription; ResourceGroup=$ResourceGroup.ResourceGroupName; ResourceName=$usagedata[$i].Group[$j].InstanceName; Product=$usagedata[$i].Group[$j].Product;  USD=$productsum}
            $results | export-csv -path $Subscription".csv" -NoTypeInformation -Append -Force
            $productsum = 0
        }
        
        
    }
    
}
$totalresourcegroupcost = $totaltotalresourcegroupcost + $resourcesum
$totalresourcegroupcostresults = [PSCustomObject]@{SubscriptionName=$Subscription; ResourceGroup=$ResourceGroup.ResourceGroupName; ResourceName="Total USD"; Product="All Resources";  USD=$totalresourcegroupcost; }
Write-Output "Total Cost:" $totalresourcegroupcost
$totalresourcegroupcostresults | export-csv -path $Subscription".csv" -NoTypeInformation -Append -Force
}
