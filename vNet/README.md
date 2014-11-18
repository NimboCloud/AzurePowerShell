Create vNets in Three Regions
===============

**Status: In Progress**

###Description

This script creates three vnet networks and links them together via site-to-site VPN connections. There are parameters to select the location of the network. By default, it will create the vNet's in South Central US, East US and West US.

**Warning**: This script will overwrite the existing network configuration within an Azure subscription, and may fail if assets are a part of an existing vnet. Please be cautious when running this script
