#### Usage
Only the release number needs to be modified.
```hcl
module "lb" {
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//lb?ref=v0.1"
  tags = var.tags
  res_spec = var.res_spec
}
```