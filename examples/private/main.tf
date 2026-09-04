module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.32"

  suffix = ["demo", "dev"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 3.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = "westeurope"
    }
  }
}

module "vnet" {
  source  = "cloudnationhq/vnet/azure"
  version = "~> 10.0"

  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.19.0.0/16"]

    subnets = {
      cae = {
        address_prefixes = ["10.19.0.0/23"]
        default_outbound = true

        delegations = {
          cae = {
            name = "Microsoft.App/environments"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action",
            ]
          }
        }
      }
    }
  }
}

module "law" {
  source  = "cloudnationhq/law/azure"
  version = "~> 4.0"

  workspace = {
    name                = module.naming.log_analytics_workspace.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "ca" {
  source  = "cloudnationhq/ca/azure"
  version = "~> 5.0"

  environment = {
    name                = module.naming.container_app_environment.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    infrastructure_subnet_id       = module.vnet.subnets.cae.id
    internal_load_balancer_enabled = true
    public_network_access          = "Disabled"
    zone_redundancy_enabled        = true

    log_analytics_workspace_id = module.law.workspace.id

    workload_profile = {
      consumption = {
        name                  = "Consumption"
        workload_profile_type = "Consumption"
        minimum_count         = 0
        maximum_count         = 0
      }
      dedicated = {
        name                  = "Dedicated"
        workload_profile_type = "D4"
        minimum_count         = 1
        maximum_count         = 3
      }
    }

    container_apps = {
      app1 = {
        workload_profile_name = "Dedicated"

        template = {
          containers = {
            frontend = {
              image = "nginx:latest"
            }
          }
        }

        ingress = {
          external_enabled = false
          target_port      = 80

          traffic_weight = {
            default = {
              percentage = 100
            }
          }

          ip_security_restrictions = {
            allow-vnet = {
              action           = "Allow"
              ip_address_range = "10.19.0.0/16"
              description      = "only allow traffic originating from the vnet"
            }
          }
        }
      }
    }
  }
}
