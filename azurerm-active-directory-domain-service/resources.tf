# Manages an Active Directory Domain Service.
resource "azurerm_template_deployment" "template_deployment" {
  for_each = { for s in var.res_spec.aadds : format("%s", s.name) => s }
  name = each.value.name
  resource_group_name = var.res_spec.rg[0].name
  parameters = {
    apiVersion = "2020-01-01"
    name = each.value.name
    domainConfigurationType = lookup(each.value, "type", "FullySynced")
    domainName = lookup(each.value, "domain", "partner.onmschina.cn")
    sku = lookup(each.value, "sku", "Standard")
    filteredSync = lookup(each.value, "filteredsync", "Disabled")
    location = each.value.location
    subnetName = each.value.network.subnet
    vnetName = each.value.network.virtual_network
    vnetResourceGroup = each.value.network.resource_group
  }
  deployment_mode    = "Incremental"
  template_body      = <<DEPLOY
{
  "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "name": {
      "type": "string"
    },
    "apiVersion": {
      "type": "string"
    },
    "sku": {
      "type": "String"
    },
    "domainConfigurationType": {
      "type": "string"
    },
    "domainName": {
      "type": "string"
    },
    "filteredSync": {
      "type": "string"
    },
    "location": {
      "type": "string"
    },
    "subnetName": {
      "type": "string"
    },
    "vnetName": {
      "type": "string"
    },
    "vnetResourceGroup": {
      "type": "string"
    }
  },
  "resources": [
    {
      "apiVersion": "[parameters('apiVersion')]",
      "type": "Microsoft.AAD/DomainServices",
      "name": "[parameters('name')]",
      "location": "[parameters('location')]",
      "properties": {
        "domainName": "[parameters('domainName')]",
        "filteredSync": "[parameters('filteredSync')]",
        "domainConfigurationType": "[parameters('domainConfigurationType')]",
        "notificationSettings": {
          "notifyGlobalAdmins": "Enabled",
          "notifyDcAdmins": "Enabled",
          "additionalRecipients": []
        },
        "domainSecuritySettings": {
          "ntlmV1": "Enabled",
          "tlsV1": "Enabled",
          "syncNtlmPasswords": "Enabled"
        },
        "replicaSets": [
          {
            "subnetId": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', parameters('vnetResourceGroup'), '/providers/Microsoft.Network/virtualNetworks/', parameters('vnetName'), '/subnets/', parameters('subnetName'))]",
            "location": "[parameters('location')]"
          }
        ],
        "sku": "[parameters('sku')]"
      }
    }
  ],
  "outputs": {}
}
DEPLOY
}