Create vNets in Three Regions
===============

**Status: In Progress**

###Description

This script creates three vnet networks and links them together via site-to-site VPN connections. There are parameters to select the location of the network. By default, it will create the vNet's in South Central US, East US and West US.

The script processes through 5 user provided parameters in order to dynamically create a vnet-to-vnet connection in a specified azure account. The script will overwrite any existing vnet information, and will fail if a vnet exists with vm's already contained within. There are several #TODO tags in the document with content and features that should be added. This script should represent a desired state of an azure network when complete, and have the ability to dynamically skip and check sections if the setup is already configured correctly

**Warning**: This script will overwrite the existing network configuration within an Azure subscription, and may fail if assets are a part of an existing vnet. Please be cautious when running this script
