resource "azurerm_user_assigned_identity" "identity_sec1" {
  name                = "uai-app7-sec1-byown"
  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location
}

resource "azurerm_user_assigned_identity" "identity_sec2" {
  name                = "uai-app7-sec2-byown"
  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location
}

resource "azurerm_user_assigned_identity" "identity_reg" {
  name                = "uai-app7-reg-byown"
  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location
}
