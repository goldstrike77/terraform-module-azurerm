#### Usage
Only the release number needs to be modified.
```hcl
module "resource_group" {
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//resource-group?ref=v0.1"
  tags = var.tags
  res_spec = var.res_spec
}
```