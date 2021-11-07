#### Usage
Only the release number needs to be modified.
```hcl
module "kubernetes_cluster" {
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//kubernetes-cluster?ref=v0.1"
  tags = var.tags
  res_spec = var.res_spec
  depends_on = [module.resource_group]
}
```