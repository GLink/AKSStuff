$env:resourceGroup="akswin-rg"
$env:clusterName="akswin"
$env:passwordWin=""
$env:location="westeurope"
$env:userName="azureuser"
#$env:winPoolName must be 6 characters or less
$env:winPoolName="winvms"
$env:HELM_HOST=":44134"
$env:customVnetName="akswin-vnet"
$env:vnetCIDR="10.1.0.0/23"
$env:subnetName="cni"
$env:subnetCIDR="10.240.0.0/16"
$env:nodeCniVnet=""    