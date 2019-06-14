az group create -n $env:resourceGroup -l $env:location

#default
az aks create -g $env:resourceGroup -n $env:clusterName  --windows-admin-password $env:passwordWin --windows-admin-username $env:userName --location $env:location --generate-ssh-keys -c 1 --enable-vmss

az network vnet create -g $env:resourceGroup -n $env:customVnetName --subnet-name $env:subnetName --address-prefixes $env:vnetCIDR --subnet-name $env:subnetName --subnet-prefix $env:subnetCIDR

$subnetId = az network vnet subnet show -g $env:resourceGroup --vnet-name $env:customVnetName -n  $env:subnetName --query "id" -o tsv

#with advanced networking
az aks create `
    --resource-group $env:resourceGroup `
    --name $env:clusterName `
    --windows-admin-password $env:passwordWin `
    --windows-admin-username $env:userName `
    --nodepool-name $env:linuxPoolName `
    --network-plugin azure `
    --vnet-subnet-id $env:nodeCniVnet `
    --docker-bridge-address 172.17.0.1/16 `
    --dns-service-ip 10.240.0.10 `
    --service-cidr 10.240.0.0/24 `
    --generate-ssh-keys `
    -c 1 `
    --enable-vmss 

    az aks get-credentials -g $env:resourceGroup -n $env:clusterName

    # Use Helm to deploy an NGINX ingress controller
    helm install stable/nginx-ingress --name nginx --namespace kube-system --set controller.replicaCount=1

    helm install azure-samples/aks-helloworld --namespace default
    helm install azure-samples/aks-helloworld --namespace default --set title="AKS Ingress Demo" --set serviceName="ingress-demo"

    az aks nodepool add `
        -g $env:resourceGroup `
        --cluster-name $env:clusterName `
        --os-type Windows `
        -n $env:winPoolName `
        --vnet-subnet-id $env:nodeCniVnet `
        -c 1 `
        --node-vm-size "Standard_D2_v2"

# PS Azure:\> az aks create -g $env:resourceGroup -n $env:clusterName  --windows-admin-password $env:passwordWin --windows-admin-username $env:userName --location $env:location --generate-ssh-keys -c 1 --enable-vm
# ss
# The behavior of this command has been altered by the following extension: aks-preview
# SSH key files '/home/gaute/.ssh/id_rsa' and '/home/gaute/.ssh/id_rsa.pub' have been generated under ~/.ssh to allow SSH access to the VM. If using machines without permanent storage like Azure Cloud Shell without an attached file share, back up your keys to a safe location
# {
#     "aadProfile": null,
#     "addonProfiles": null,
#     "agentPoolProfiles": [
#       {
#         "availabilityZones": null,
#         "count": 1,
#         "enableAutoScaling": null,
#         "maxCount": null,
#         "maxPods": 30,
#         "minCount": null,
#         "name": "linvms",
#         "orchestratorVersion": "1.13.5",
#         "osDiskSizeGb": 100,
#         "osType": "Linux",
#         "provisioningState": "Succeeded",
#         "type": "VirtualMachineScaleSets",
#         "vmSize": "Standard_DS2_v2",
#         "vnetSubnetId": "/subscriptions/033a07d7-2fa1-4e06-8159-75f94caf4115/resourceGroups/akswin-rg/providers/Microsoft.Network/virtualNetworks/akswin-vnet/subnets/nodes"
#       }
#     ],
#     "apiServerAuthorizedIpRanges": null,
#     "dnsPrefix": "akswin-akswin-rg-033a07",
#     "enablePodSecurityPolicy": false,
#     "enableRbac": true,
#     "fqdn": "akswin-akswin-rg-033a07-c7c9e101.hcp.westeurope.azmk8s.io",
#     "id": "/subscriptions/033a07d7-2fa1-4e06-8159-75f94caf4115/resourcegroups/akswin-rg/providers/Microsoft.ContainerService/managedClusters/akswin",
#     "kubernetesVersion": "1.13.5",
#     "linuxProfile": {
#       "adminUsername": "azureuser",
#       "ssh": {
#         "publicKeys": [
#           {
#             "keyData": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbq8gTo2Dz+v1AwulbVYHT3kbs58qMnRlmkRl+wJI+Ush/n9SxLVLWQ5bSvCC6IfPK2bUinhn233csqyuvuLjVyahsTWvyjQ+fS2zVLpLRYxGAPmYFl8/kSpJMQ2+GQhO5SrvMobQet43J4CosWQhK55+zm1MdA/kQMHHQRok3DjoYxP1dTqvaXBXcLARSfj1oVZ7HplGiR33MSW+apIRTtL1l1Nl45b+E6nHvYlk2X9ZfFzyevq604nZLmDFxPb8gZNv+3iZHKpiv5vgvkSwsCxTL4kn9gXUdIggETvQ9pTIWmymZdtXq+xZ0XoT2qOaYm5paisjd6jPK9pPbjnuV"
#           }
#         ]
#       }
#     },
#     "location": "westeurope",
#     "maxAgentPools": 8,
#     "name": "akswin",
#     "networkProfile": {
#       "dnsServiceIp": "10.240.0.10",
#       "dockerBridgeCidr": "172.17.0.1/16",
#       "loadBalancerSku": "Basic",
#       "networkPlugin": "azure",
#       "networkPolicy": null,
#       "podCidr": null,
#       "serviceCidr": "10.240.0.0/24"
#     },
#     "nodeResourceGroup": "MC_akswin-rg_akswin_westeurope",
#     "provisioningState": "Succeeded",
#     "resourceGroup": "akswin-rg",
#     "servicePrincipalProfile": {
#       "clientId": "b51b1264-aaab-4334-9b4c-a4951e711e26",
#       "secret": null
#     },
#     "tags": null,
#     "type": "Microsoft.ContainerService/ManagedClusters",
#     "windowsProfile": {
#       "adminPassword": null,
#       "adminUsername": "azureuser"
#     }
#   }