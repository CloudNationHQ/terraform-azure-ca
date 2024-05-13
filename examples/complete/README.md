This example highlights the complete usage.

## Usage

```hcl
module "ca" {
  source  = "cloudnationhq/ca/azure"
  version = "~> 0.1"

  naming = local.naming

  environment = {
    name                           = module.naming.container_app_environment.name
    location                       = module.rg.groups.demo.location
    resourcegroup                  = module.rg.groups.demo.name
    infrastructure_subnet_id       = module.vnet.subnets.cae.id
    log_analytics_workspace_id     = module.law.workspace.id
    zone_redundancy_enabled        = true
    internal_load_balancer_enabled = true

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
        revision_mode         = "Single"
        workload_profile_name = "Consumption"
        kv_scope              = module.kv.vault.id
        template = {
          min_replicas    = 1
          max_replicas    = 3
          revision_suffix = "test"

          containers = {
            container1 = {
              image = "nginx:latest"
              env = {
                ALLOWED_HOSTS = {
                  value = "*"
                }
                DEBUG = {
                  value = "True"
                }
                SECRET_KEY = {
                  secret_name = "secret-key"
                }
              }
            }
          }
        }

        secrets = {
          secret-key = {
            key_vault_secret_id = module.kv.secrets.secret1.versionless_id
          }
        }

        ingress = {
          external_enabled = true
          target_port      = 80
          transport        = "auto"
          traffic_weight = {
            default = {
              latest_revision = true
              percentage      = 100
            }
          }
        }

        identities = {
          uai1 = {
            type = "UserAssigned"
            name = "uai-demo-dev"
          }
        }

        registry = {
          server = module.acr.acr.login_server
          scope  = module.acr.acr.id
        }
      }
    }
  }
}
```
