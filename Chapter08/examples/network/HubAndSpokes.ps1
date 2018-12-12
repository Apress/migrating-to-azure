Write-Output "
 _____                               
|   __|___ _____ ___ ___ ___ ___ ___ 
|  |  | .'|     | -_|  _| . |  _| . |
|_____|__,|_|_|_|___|___|___|_| |  _|
                                |_|  
"
Write-Output "###> Hub and Spoke Network Topology"
# Create the resource groups needed, if not already in existence
az group create -n gc-corp-shared -l eastus2
az group create -n gc-sandbox -l centralus
az group create -n gc-uat -l eastus2
az group create -n gc-production -l eastus2
az group create -n gc-production-bcdr -l centralus

# Create the virtual networks
# Illustrative examples - CIDR blocks are set up to not overlap
# but are using default (10.*.*.*) addresses
Write-Output "Creating UAT network..."
$uatVnet = (az network vnet create -n gamecorp-uat-vnet -g gc-uat --address-prefix 10.2.0.0/24)
Write-Output "Creating dev network..."
$devVnet = (az network vnet create -n gamecorp-dev-vnet -g gc-sandbox --address-prefix 10.1.0.0/23)
Write-Output "Creating QA network..."
$qaVnet = (az network vnet create -n gamecorp-qa-vnet -g gc-sandbox --address-prefix 10.5.0.0/24)
Write-Output "Creating prod blue network..."
$blueVnet = (az network vnet create -n gamecorp-prod-blue-vnet -g gc-production --address-prefix 10.3.0.0/24 --subnet-name GatewaySubnet --subnet-prefix 10.3.0.128/28)
Write-Output "Creating prod green network..."
$greenVnet = (az network vnet create -n gamecorp-prod-green-vnet -g gc-production-bcdr --address-prefix 10.3.1.0/24 --subnet-name GatewaySubnet --subnet-prefix 10.3.1.128/28)
Write-Output "Creating Gamecorp core network..."
$coreVnet = (az network vnet create -n gamecorp-core-vnet -g gc-corp-shared --address-prefix 10.4.0.0/16 --subnet-name GatewaySubnet --subnet-prefix 10.4.0.0/24)

# Get the resource ID of the core network
$coreVnetId = (az network vnet show -n gamecorp-core-vnet -g gc-corp-shared --query "id" -o json)

# Create the peerings
Write-Output "Creating UAT network peering..."
az network vnet peering create -g gc-uat -n gc-uat-to-core --vnet-name gamecorp-uat-vnet --remote-vnet-id $coreVnetId --allow-vnet-access
Write-Output "Creating QA network peering..."
az network vnet peering create -g gc-sandbox -n gc-qa-to-core --vnet-name gamecorp-qa-vnet --remote-vnet-id $coreVnetId --allow-vnet-access
Write-Output "Creating dev network..."
az network vnet peering create -g gc-sandbox -n gc-dev-to-core --vnet-name gamecorp-dev-vnet --remote-vnet-id $coreVnetId --allow-vnet-access
Write-Output "Creating prod blue network peering..."
az network vnet peering create -g gc-production -n gc-prod-blue-to-core --vnet-name gamecorp-prod-blue-vnet --remote-vnet-id $coreVnetId --allow-vnet-access
Write-Output "Creating prod green network peering..."
az network vnet peering create -g gc-production-bcdr -n gc-prod-green-to-core --vnet-name gamecorp-prod-green-vnet --remote-vnet-id $coreVnetId --allow-vnet-access

Write-Output "Network setup complete."