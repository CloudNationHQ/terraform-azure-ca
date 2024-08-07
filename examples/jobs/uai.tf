resource "azurerm_user_assigned_identity" "identity_sec" {
  name                = "uai-job4-sec-byown"
  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location
}

resource "azurerm_user_assigned_identity" "identity_reg" {
  name                = "uai-job4-reg-byown"
  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location
}
