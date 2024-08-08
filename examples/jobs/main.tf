module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 0.1"

  groups = {
    demo = {
      name   = module.naming.resource_group.name
      region = "westeurope"
    }
  }
}

module "kv" {
  source  = "cloudnationhq/kv/azure"
  version = "~> 0.2"

  naming = local.naming

  vault = {
    name          = module.naming.key_vault.name_unique
    location      = module.rg.groups.demo.location
    resourcegroup = module.rg.groups.demo.name

    secrets = {
      random_string = {
        secret1 = {
          length  = 32
          special = false
        }
      }
    }
  }
}

module "acr" {
  source  = "cloudnationhq/acr/azure"
  version = "~> 1.0"

  registry = {
    name                          = module.naming.container_registry.name_unique
    location                      = module.rg.groups.demo.location
    resourcegroup                 = module.rg.groups.demo.name
    sku                           = "Premium"
    public_network_access_enabled = true
    admin_enabled                 = true
  }
}

module "ca" {
  source  = "cloudnationhq/ca/azure"
  version = "~> 1.0"

  naming = local.naming

  environment = {
    name           = module.naming.container_app_environment.name
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name

    jobs = local.jobs
  }
}
