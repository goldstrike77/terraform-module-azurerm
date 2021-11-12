#### Usage
Only the release number needs to be modified.
```hcl
module "servicebus" {
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//servicebus?ref=v0.1"
  tags = var.tags
  res_spec = var.res_spec
  depends_on = [module.resource_group]
}
```