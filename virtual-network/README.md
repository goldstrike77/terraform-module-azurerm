#### Usage
Only the release number needs to be modified.
```hcl
module "virtual_network" {
  source   = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//virtual-network?ref=v0.1"
  tags     = var.tags
  res_spec = var.res_spec
}
```

#### Variables
There are some variables that can (Or needs to) be overridden:
```hcl
variable "tags" {
  default = {
    location    = "chinaeast2"
    environment = "dmz"
    customer    = "Learn"
    owner       = "Somebody"
    email       = "somebody@mail.com"
    title       = "Engineer"
    department  = "IS"
  }
}

variable "res_spec" {
  default = {
    rg = [
      {
        name     = "rg-network-dmz-001"
        location = "chinaeast2"
        tags     = {
          project = "network"
        }
        role_ass = []
      }
    ]
    vnet = [
      {
        name     = "vnet-dmz-chinaeast2-001"
        location = "chinaeast2"
        tags     = {}
        cidr     = ["10.10.0.0/16","10.20.0.0/16"]
        dns      = []
        role_ass = []
        peering  = [
          {
            remote_virtual_network_id    = "/subscriptions/f55a9c04-d605-4b56-9e3b-9a4b4d8db8cc/resourceGroups/rg-network-prd-001/providers/Microsoft.Network/virtualNetworks/vnet-prd-chinaeast2-001"
            allow_virtual_network_access = true
            allow_forwarded_traffic      = false
            allow_gateway_transit        = false
            use_remote_gateways          = false
          },
          {
            remote_virtual_network_id    = "/subscriptions/f55a9c04-d605-4b56-9e3b-9a4b4d8db8cc/resourceGroups/rg-network-dev-001/providers/Microsoft.Network/virtualNetworks/vnet-dev-chinaeast2-001"
            allow_virtual_network_access = true
            allow_forwarded_traffic      = false
            allow_gateway_transit        = false
            use_remote_gateways          = false
          }
        ]
      }
    ]
  }
}
```