#### Usage
The release number and dependency resource ID needs to be modified.
```hcl
module "private_endpoint" {
  count = length(local.private_endpoint_flat) > 0 ? 1 : 0
  source = "git::https://github.com/goldstrike77/terraform-module-azurerm.git//private-endpoint?ref=v0.1"
  private_endpoint_spec = local.private_endpoint_flat
  resource = { for i, redis_cache in azurerm_redis_cache.redis_cache: i => redis_cache.id }
}
```