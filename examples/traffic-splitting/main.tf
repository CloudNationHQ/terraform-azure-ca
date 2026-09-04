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
        revision_mode          = "Multiple"
        max_inactive_revisions = 5

        template = {
          revision_suffix = "v1"

          containers = {
            frontend = {
              image = "nginx:latest"
            }
          }
        }

        ingress = {
          external_enabled = true
          target_port      = 80

          traffic_weight = {
            v1 = {
              latest_revision = false
              revision_suffix = "v1"
              percentage      = 100
            }
          }
        }
      }

      app2 = {
        revision_mode = "Single"

        template = {
          containers = {
            frontend = {
              image = "nginx:latest"
            }
          }
        }

        ingress = {
          external_enabled = true
          target_port      = 80

          traffic_weight = {
            latest = {
              latest_revision = true
              percentage      = 100
            }
          }
        }
      }
    }
  }
}
