<#
.SYNOPSIS
    The following script will dynamically create a network config xml, upload it to an azure account and create and connect all of the necessary gateways to get the environment working.

.DESCRIPTION
   This script creates three vnet networks and links them together via site-to-site VPN connections. There are parameters to select the location of the network. By default, it will create the vNet's in South Central US, East US and West US.

The script processes through 5 user provided parameters in order to dynamically create a vnet-to-vnet connection in a specified azure account. The script will overwrite any existing vnet information, and will fail if a vnet exists with vm's already contained within. There are several #TODO tags in the document with content and features that should be added. This script should represent a desired state of an azure network when complete, and have the ability to dynamically skip and check sections if the setup is already configured correctly
#>
Param(
    #The subscription where you'll be adding the vnet config
    [parameter(Mandatory,Position=1)]
    [ValidateLength(2,20)]
    [String]$AzureSub,

    #The name used to prefix the assets being created
    [parameter(Mandatory,Position=2)]
    [ValidateLength(2,12)]
    [String]$ServicePrefix,
	
    #The location of the primary vnet
    [parameter(Position=3)]
    [ValidateSet("East Asia",`
                "Southeast Asia",`
                "North Europe",`
                "West Europe",`
                "Central US",`
                "East US 2",`
                "East US",`
                "West US",`
                "South Central US")]
    [String]$Location1 = "South Central US",

    #The location of the second vnet
    [parameter(Position=4)]
    [ValidateSet("East Asia",`
                "Southeast Asia",`
                "North Europe",`
                "West Europe",`
                "Central US",`
                "East US 2",`
                "East US",`
                "West US",`
                "South Central US")]
    [String]$Location2 = "East US",

    #The location of the third vnet
    [parameter(Position=5)]
    [ValidateSet("East Asia",`
                "Southeast Asia",`
                "North Europe",`
                "West Europe",`
                "Central US",`
                "East US 2",`
                "East US",`
                "West US",`
                "South Central US")]
    [String]$Location3 = "West US"

    #TODO: Add ability to specify CIDR
    #TODO: Load location parameters into an array and loop below rather than running multiple commands.
      	
)
       
Select-AzureSubscription -SubscriptionName $AzureSub
		
#Set strict mode to identify typographical errors
Set-StrictMode -Version Latest
		
##########################################################################################################
		
#######################################
## FUNCTION 1 - Create-AzureNetCfgFile
#######################################
		
#Creates a NetCfg XML file to be consumed by Set-AzureVNetConfig
		
Function Create-AzureNetCfgFile {
		
	Param(
      	#The name used to prefix all build items, e.g. IANCLOUD
      	[parameter(Mandatory,Position=1)]
      	[ValidateNotNullOrEmpty()]
      	[String]$ServicePrefix,
		
      	#The data center location of the build items
      	[parameter(Mandatory,Position=2)]
      	[ValidateNotNullOrEmpty()]
      	[String]$Location1,

        #The data center location of the build items
      	[parameter(Mandatory,Position=3)]
      	[ValidateNotNullOrEmpty()]
      	[String]$Location2,

        #The data center location of the build items
      	[parameter(Mandatory,Position=4)]
      	[ValidateNotNullOrEmpty()]
      	[String]$Location3,
		
      	#The netcfg file path
      	[parameter(Mandatory,Position=5)]
      	[ValidateNotNullOrEmpty()]
      	[String]$NetCfgFile,
        
        #The gateway IP for the first vnet
      	[parameter(Mandatory,Position=6)]
      	[ValidateNotNullOrEmpty()]
      	[String]$GatewayIP1,

        #The gateway IP for the second vnet
      	[parameter(Mandatory,Position=7)]
      	[ValidateNotNullOrEmpty()]
      	[String]$GatewayIP2,

        #The the gateway IP for the third vnet
      	[parameter(Mandatory,Position=8)]
      	[ValidateNotNullOrEmpty()]
      	[String]$GatewayIP3
      	)
		
	#Define a here-string for our NetCfg xml structure
	$NetCfg = @"
<?xml version="1.0" encoding="utf-8"?>
<NetworkConfiguration xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration">
  <VirtualNetworkConfiguration>
    <Dns>
      <DnsServers>
        <DnsServer name="$($ServicePrefix)DC01" IPAddress="10.0.0.4" />
      </DnsServers>
    </Dns>
    <LocalNetworkSites>
      <LocalNetworkSite name="vNet1-to-vNet2">
        <AddressSpace>
          <AddressPrefix>10.1.0.0/16</AddressPrefix>
        </AddressSpace>
        <VPNGatewayAddress>$($GatewayIP2)</VPNGatewayAddress>
      </LocalNetworkSite>
      <LocalNetworkSite name="vNet1-to-vNet3">
        <AddressSpace>
          <AddressPrefix>10.2.0.0/16</AddressPrefix>
        </AddressSpace>
        <VPNGatewayAddress>$($GatewayIP3)</VPNGatewayAddress>
      </LocalNetworkSite>
      <LocalNetworkSite name="vNet2-to-vNet1">
        <AddressSpace>
          <AddressPrefix>10.0.0.0/16</AddressPrefix>
        </AddressSpace>
        <VPNGatewayAddress>$($GatewayIP1)</VPNGatewayAddress>
      </LocalNetworkSite>
      <LocalNetworkSite name="vNet2-to-vNet3">
        <AddressSpace>
          <AddressPrefix>10.2.0.0/16</AddressPrefix>
        </AddressSpace>
        <VPNGatewayAddress>$($GatewayIP3)</VPNGatewayAddress>
      </LocalNetworkSite>
      <LocalNetworkSite name="vNet3-to-vNet1">
        <AddressSpace>
          <AddressPrefix>10.0.0.0/16</AddressPrefix>
        </AddressSpace>
        <VPNGatewayAddress>$($GatewayIP1)</VPNGatewayAddress>
      </LocalNetworkSite>
      <LocalNetworkSite name="vNet3-to-vNet2">
        <AddressSpace>
          <AddressPrefix>10.1.0.0/16</AddressPrefix>
        </AddressSpace>
        <VPNGatewayAddress>$($GatewayIP2)</VPNGatewayAddress>
      </LocalNetworkSite>
    </LocalNetworkSites>
    <VirtualNetworkSites>
      <VirtualNetworkSite name="$($ServicePrefix)vNet1" Location="$($Location1)">
        <AddressSpace>
          <AddressPrefix>10.0.0.0/16</AddressPrefix>
        </AddressSpace>
        <Subnets>
          <Subnet name="Public">
            <AddressPrefix>10.0.0.0/24</AddressPrefix>
          </Subnet>
          <Subnet name="Private">
            <AddressPrefix>10.0.1.0/24</AddressPrefix>
          </Subnet>
          <Subnet name="GatewaySubnet">
            <AddressPrefix>10.0.15.0/29</AddressPrefix>
          </Subnet>
        </Subnets>
        <DnsServersRef>
          <DnsServerRef name="$($ServicePrefix)DC01" />
        </DnsServersRef>
        <Gateway>
          <ConnectionsToLocalNetwork>
            <LocalNetworkSiteRef name="vNet1-to-vNet2">
              <Connection type="IPsec" />
            </LocalNetworkSiteRef>
            <LocalNetworkSiteRef name="vNet1-to-vNet3">
              <Connection type="IPsec" />
            </LocalNetworkSiteRef>
          </ConnectionsToLocalNetwork>
        </Gateway>
      </VirtualNetworkSite>
      <VirtualNetworkSite name="$($ServicePrefix)vNet2" Location="$($Location2)">
        <AddressSpace>
          <AddressPrefix>10.1.0.0/16</AddressPrefix>
        </AddressSpace>
        <Subnets>
          <Subnet name="Public">
            <AddressPrefix>10.1.0.0/24</AddressPrefix>
          </Subnet>
          <Subnet name="Private">
            <AddressPrefix>10.1.1.0/24</AddressPrefix>
          </Subnet>
          <Subnet name="GatewaySubnet">
            <AddressPrefix>10.1.15.0/29</AddressPrefix>
          </Subnet>
        </Subnets>
        <DnsServersRef>
          <DnsServerRef name="$($ServicePrefix)DC01" />
        </DnsServersRef>
        <Gateway>
          <ConnectionsToLocalNetwork>
            <LocalNetworkSiteRef name="vNet2-to-vNet1">
              <Connection type="IPsec" />
            </LocalNetworkSiteRef>
            <LocalNetworkSiteRef name="vNet2-to-vNet3">
              <Connection type="IPsec" />
            </LocalNetworkSiteRef>
          </ConnectionsToLocalNetwork>
        </Gateway>
      </VirtualNetworkSite>
      <VirtualNetworkSite name="$($ServicePrefix)vNet3" Location="$($Location3)">
        <AddressSpace>
          <AddressPrefix>10.2.0.0/16</AddressPrefix>
        </AddressSpace>
        <Subnets>
          <Subnet name="Public">
            <AddressPrefix>10.2.0.0/24</AddressPrefix>
          </Subnet>
          <Subnet name="Private">
            <AddressPrefix>10.2.1.0/24</AddressPrefix>
          </Subnet>
          <Subnet name="GatewaySubnet">
            <AddressPrefix>10.2.15.0/29</AddressPrefix>
          </Subnet>
        </Subnets>
        <DnsServersRef>
          <DnsServerRef name="$($ServicePrefix)DC01" />
        </DnsServersRef>
        <Gateway>
          <ConnectionsToLocalNetwork>
            <LocalNetworkSiteRef name="vNet3-to-vNet1">
              <Connection type="IPsec" />
            </LocalNetworkSiteRef>
            <LocalNetworkSiteRef name="vNet3-to-vNet2">
              <Connection type="IPsec" />
            </LocalNetworkSiteRef>
          </ConnectionsToLocalNetwork>
        </Gateway>
      </VirtualNetworkSite>
    </VirtualNetworkSites>
  </VirtualNetworkConfiguration>
</NetworkConfiguration>

"@
		
    	#Update the NetCfg file with parameter values
    	Set-Content -Value $NetCfg -Path $NetCfgFile
		
    	#Error handling
    	If (!$?) {
		
        	#Write Error and exit
        	Write-Error "Unable to create $NetCfgFile with custom vNet settings" -ErrorAction Stop
		
    	}   #End of If (!$?)
    	Else {
		
        	#Troubleshooting message
        	Write-Verbose "$(Get-Date -f T) - $($NetCfgFile) successfully created"
		
    	}   #End of Else (!$?)
		
		
	}   #End of Function Create-AzureNetCfgFile
		
####################
## MAIN SCRIPT BODY
####################
    	
##############################
#Stage 1 - Check Connectivity
##############################
		
#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Checking Azure connectivity"
Write-Debug "About to check Azure connectivity"
    	
#Check we have Azure connectivity
$Subscription = Get-AzureSubscription -Current 
		
#Error handling
If ($Subscription) {
		
    #Write details of current subscription to screen
    Write-Verbose "$(Get-Date -f T) - Current subscription found - $($Subscription.SubscriptionName)"
		
}   #End of If ($Subscription)
Else {
		
    #Write Error and exit
    Write-Error "Unable to obtain current Azure subscription details" -ErrorAction Stop
		
}   #End of Else ($Subscription)
			
		
#####################################
#Stage 2 - Create Initial NetCfg File
#####################################
		
#Variable for NetCfg file
$SourceParent = (Get-Location).Path
$NetCfgFile = "$SourceParent\$($ServicePrefix)_vNet.netcfg"
		
#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Creating vNet config file"
Write-Debug "About to create the vNet config file"
		
#Use the Create-AzureNetCfgFile function to create the NetCfg XML file used to seed the new Azure virtual network
Create-AzureNetCfgFile -ServicePrefix $ServicePrefix -Location1 $Location1 -Location2 $Location2 -Location3 $Location3 -NetCfgFile $NetCfgFile -GatewayIP1 1.1.1.1 -GatewayIP2 1.1.1.1 -GatewayIP3 1.1.1.1
		
		
##################################
#Stage 3 - Create Virtual Network
##################################
		
#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Creating Azure DNS object"
Write-Debug "About to create Azure DNS object"
		
#First, we need to create an object representing the DNS server created later
$AzureDns = New-AzureDns -IPAddress 10.0.0.4 -Name "$($ServicePrefix)DC01" -ErrorAction SilentlyContinue 
		
#Error handling
If ($AzureDns) {
		
    #Troubleshooting message
    Write-Verbose "$(Get-Date -f T) - DNS object successfully created"
		
}   #End of If ($AzureDns) 
Else {
		
    #Write Error and exit
    Write-Error "Unable to create DNS object" -ErrorAction Stop
		
}   #End of Else ($AzureDns)
		
		
#Set virtual network name
$vNetName1 = "$($ServicePrefix)vNet1"
$vNetName2 = "$($ServicePrefix)vNet2"
$vNetName3 = "$($ServicePrefix)vNet3"
		
#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Creating $vNetName1 virtual network"
Write-Debug "About to create $vNetName1 virtual network"
		
#Next, we need to create the virtual network itself
Set-AzureVNetConfig -ConfigurationPath $NetCfgFile -ErrorAction SilentlyContinue | Out-Null
		
#Error handling
If (!$?) {
		
    #Write Error and exit
    Write-Error "Unable to create $vNetName1 virtual network" -ErrorAction Stop
		
}   #End of If (!$?) 
Else {
		
    #Troubleshooting message
    Write-Verbose "$(Get-Date -f T) - $vNetName1 virtual network successfully created"
		
}   #End of Else (!$?)


#########################################
#Stage 4 - Create Virtual Network Gateway
#########################################

#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Creating Azure Gateways"
Write-Debug "Creating azure gateways"

#Create jobs that will run in parallel
$CreatevNetGateway = {
    param($vNetName)

    #TODO: Check to see if the gateway is already created

    #Create the gateway: this takes 30 minutes to process
    New-AzureVNetGateway -VNetName $vNetName -GatewayType DynamicRouting
}

#Create the gateways in parallel
Start-Job $CreatevNetGateway -ArgumentList $vNetName1
Start-Job $CreatevNetGateway -ArgumentList $vNetName2
Start-Job $CreatevNetGateway -ArgumentList $vNetName3

#Wait for all of the gateway creation jobs to complete prior to proceeding
Wait-Job *


#Error handling
If (!$?) {
		
    #Write Error and exit
    Write-Error "Unable to create $vNetName1 or $vNetName2 Dynamic Gateway" -ErrorAction Stop
		
}   #End of If (!$?) 
Else {
		
    #Troubleshooting message
    Write-Verbose "$(Get-Date -f T) - $vNetName1 and $vNetName2 Dynamic Gateway successfully created"
		
}   #End of Else (!$?)

       
##############################
#Stage 5 - Update NetCfg File
##############################
		
#Variable for NetCfg file
$SourceParent = (Get-Location).Path
$NetCfgFile = "$SourceParent\$($ServicePrefix)_vNet.netcfg"

$vNet1GatewayIP = (Get-AzureVNetGateway -VNetName $vNetName1).VIPAddress
$vNet2GatewayIP = (Get-AzureVNetGateway -VNetName $vNetName2).VIPAddress
$vNet3GatewayIP = (Get-AzureVNetGateway -VNetName $vNetName3).VIPAddress
		
#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Creating vNet config file"
Write-Debug "About to create the vNet config file"
		
#Use the Create-AzureNetCfgFile function to create the NetCfg XML file used to seed the new Azure virtual network
Create-AzureNetCfgFile -ServicePrefix $ServicePrefix -Location1 $Location1 -Location2 $Location2 -Location3 $Location3 -NetCfgFile $NetCfgFile -GatewayIP1 $vNet1GatewayIP -GatewayIP2 $vNet2GatewayIP -GatewayIP3 $vNet3GatewayIP

#Apply the new network config
Set-AzureVNetConfig -ConfigurationPath $NetCfgFile -ErrorAction SilentlyContinue | Out-Null
	
##############################
#Stage 6 - Match Shared Keys
##############################
    
Write-Verbose "$(Get-Date -f T) - Matching Gateway Shared Keys"
Write-Debug "About to match the gateway shared keys"
    
#Recover private key each vNet connection
$vNet12SharedKey = (Get-AzureVNetGatewayKey -VNetName $vNetName1 -LocalNetworkSiteName "vNet1-to-vNet2").Value
$vNet13SharedKey = (Get-AzureVNetGatewayKey -VNetName $vNetName1 -LocalNetworkSiteName "vNet1-to-vNet3").Value
$vNet23SharedKey = (Get-AzureVNetGatewayKey -VNetName $vNetName2 -LocalNetworkSiteName "vNet2-to-vNet3").Value

#TODO: Check to see if the connection has already successfully been established prior to changing the network keys. This shouldn't hurt either way though.

#Set the corresponding private key to match its partner vnet 
Set-AzureVNetGatewayKey -VNetName $vNetName2 -LocalNetworkSiteName "vNet2-to-vNet1" -SharedKey $vNet12SharedKey
Set-AzureVNetGatewayKey -VNetName $vNetName3 -LocalNetworkSiteName "vNet3-to-vNet1" -SharedKey $vNet13SharedKey
Set-AzureVNetGatewayKey -VNetName $vNetName3 -LocalNetworkSiteName "vNet3-to-vNet2" -SharedKey $vNet23SharedKey

##################################
#Stage 6 - Finalize the Connection
##################################

#Write out the connection status
Get-AzureVNetConnection -VNetName $vNetName1
Get-AzureVNetConnection -VNetName $vNetName2
Get-AzureVNetConnection -VNetName $vNetName3

Write-Output "The operation has completed."