# Create the service principals needed for AAD integration
$aadServerAppId=az ad app create `
    --display-name "h${env:clusterName}Server" `
    --identifier-uris "https://${env:clusterName}Server" `
    --query appId -o tsv

# Update the application group memebership claims
az ad app update --id $aadServerAppId --set groupMembershipClaims=All

# Create a service principal for the Azure AD application
az ad sp create --id $aadServerAppId

# Get the service principal secret
$aadServerAppSecret=az ad sp credential reset `
    --name $aadServerAppId `
    --credential-description "AKSPassword" `
    --query password -o tsv

# Add permissions for the Azure AD app to read directory data, sign in and read
# user profile, and read directory data
az ad app permission add `
    --id $aadServerAppId `
    --api 00000003-0000-0000-c000-000000000000 `
    --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role

# Grant permissions for the permissions assigned in the previous step
# You must be the Azure AD tenant admin for these steps to successfully complete
az ad app permission grant --id $aadServerAppId --api 00000003-0000-0000-c000-000000000000
az ad app permission admin-consent --id  $aadServerAppId

# Create the Azure AD client application
$aadClientAppId=az ad app create `
--display-name "${env:clusterName}Client" `
--native-app `
--reply-urls "https://${env:clusterName}Client" `
--query appId -o tsv 

# Create a service principal for the client application
az ad sp create --id $aadClientAppId

# Get the oAuth2 ID for the server app to allow authentication flow
$oAuthPermissionId=az ad app show --id $aadServerAppId --query "oauth2Permissions[0].id" -o tsv

# Assign permissions for the client and server applications to communicate with each other
az ad app permission add --id $aadClientAppId --api $aadServerAppId --api-permissions $oAuthPermissionId=Scope
az ad app permission grant --id $aadClientAppId --api $aadServerAppId

# Create a resource group
az group create --name $env:resourceGroup --location $env:location

# Create a virtual network and subnet
az network vnet create `
    --resource-group $env:resourceGroup `
    --name $env:customVnetName `
    --address-prefixes $env:vnetCIDR `
    --subnet-name $env:subnetName `
    --subnet-prefix $env:subnetCIDR

# Create a service principal and read in the application ID
# This is the service principal for the cluster itself, and must be in the same tenant as the cluster
$ClusterApplicationId=az ad app create `
--display-name "${env:clusterName}Cluster" `
--identifier-uris "https://${env:clusterName}Cluster" `
--query appId -o tsv

# Create a service principal for the Azure AD application
az ad sp create --id $ClusterApplicationId

# Get the service principal secret
$ClusterApplicationSecret=az ad sp credential reset `
    --name $ClusterApplicationId `
    --credential-description "AKSClusterPwd" `
    --query password -o tsv

# Get the virtual network resource ID
$VNET_ID=az network vnet show --resource-group $env:resourceGroup --name $env:customVnetName --query id -o tsv

# Assign the service principal Contributor permissions to the virtual network resource
az role assignment create --assignee $ClusterApplicationId --scope $VNET_ID --role Contributor

# Get the virtual network subnet resource ID
$SUBNET_ID=az network vnet subnet show --resource-group $env:resourceGroup --vnet-name $env:customVnetName --name $env:subnetName --query id -o tsv

# Create the AKS cluster and specify the virtual network and service principal information
# Enable network policy by using the `--network-policy` parameter
az aks create `
    --resource-group $env:resourceGroup `
    --name $env:clusterName `
    --node-vm-size Standard_DS2_v2 `
    --node-count 1 `
    --max-pods 32 `
    --kubernetes-version 1.13.5 `
    --generate-ssh-keys `
    --network-plugin azure `
    --service-cidr 10.0.0.0/16 `
    --dns-service-ip 10.0.0.10 `
    --docker-bridge-address 172.17.0.1/16 `
    --admin-username $env:userName `
    --vnet-subnet-id $SUBNET_ID `
    --aad-client-app-id $aadClientAppId `
    --aad-server-app-id $aadServerAppId `
    --aad-server-app-secret $aadServerAppSecret `
    --aad-tenant-id $env:aadTenantId `
    --service-principal $ClusterApplicationId `
    --client-secret $ClusterApplicationSecret `
    --network-policy azure