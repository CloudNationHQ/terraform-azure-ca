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

module "ca" {
  source  = "cloudnationhq/ca/azure"
  version = "~> 1.0"

  naming = local.naming

  environment = {
    name           = module.naming.container_app_environment.name
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name

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
          external_enabled = true
          target_port      = 80
          traffic_weight = {
            default = {
              percentage = 100
            }
          }
        }

        registry = {
          server = "docker.io"
        }
      }
    }
  }
}
