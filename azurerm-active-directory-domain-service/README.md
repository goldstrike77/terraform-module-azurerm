#### Usage
Only the release number needs to be modified.
```hcl
module "azurerm_active_directory_domain_service" {
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//azurerm-active-directory-domain-service?ref=v0.1"
  tags = var.tags
  res_spec = var.res_spec
  depends_on = [module.resource_group]
}
```