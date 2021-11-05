#### Usage
Only the release number needs to be modified.
```hcl
module "private_dns_zone" {
  source     = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//private-dns-zone?ref=v0.1"
  tags       = var.tags
  res_spec   = var.res_spec
  depends_on = [module.resource_group]
}
```