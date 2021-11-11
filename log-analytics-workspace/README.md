#### Usage
Only the release number needs to be modified.
```hcl
module "log_analytics_workspace" {
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//log-analytics-workspace?ref=v0.1"
  tags = var.tags
  res_spec = var.res_spec
  depends_on = [module.resource_group]
}
```