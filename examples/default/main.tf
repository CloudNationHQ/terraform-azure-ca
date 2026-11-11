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

module "ca" {
  source  = "cloudnationhq/ca/azure"
  version = "~> 5.0"

  environment = {
    name                = module.naming.container_app_environment.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    container_apps = {
      app1 = {
        template = {
          containers = {
            container1 = {
              image = "nginx:latest"
            }
          }
        }

        ingress = {
          external_enabled         = true
          target_port              = 80
          session_affinity_enabled = true
          traffic_weight = {
            default = {
              percentage = 100
            }
          }
        }
      }
    }
  }
}
