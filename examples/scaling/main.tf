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

module "sa" {
  source  = "cloudnationhq/sa/azure"
  version = "~> 5.0"

  storage = {
    name                = module.naming.storage_account.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    queue_properties = {
      # the provider needs at least one of cors_rule, logging, hour_metrics or minute_metrics
      logging = {
        read                  = true
        write                 = true
        delete                = true
        retention_policy_days = 7
      }

      queues = {
        orders = {}
      }
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
      http = {
        template = {
          min_replicas                = 1
          max_replicas                = 10
          cooldown_period_in_seconds  = 60
          polling_interval_in_seconds = 15

          containers = {
            frontend = {
              image = "nginx:latest"
            }
          }

          http_scale_rules = {
            concurrency = {
              concurrent_requests = 50
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
      }

      cpu = {
        template = {
          min_replicas = 1
          max_replicas = 5

          containers = {
            worker = {
              image  = "nginx:latest"
              cpu    = 0.5
              memory = "1Gi"
            }
          }

          custom_scale_rules = {
            utilization = {
              custom_rule_type = "cpu"
              metadata = {
                type  = "Utilization"
                value = "70"
              }
            }
          }
        }
      }

      queue = {
        template = {
          min_replicas = 0
          max_replicas = 8

          containers = {
            consumer = {
              image = "nginx:latest"
            }
          }

          azure_queue_scale_rules = {
            orders = {
              queue_name   = module.sa.queues.orders.name
              queue_length = 5

              authentication = {
                connection = {
                  secret_name       = "queue-connection"
                  trigger_parameter = "connection"
                }
              }
            }
          }
        }

        secrets = {
          queue-connection = {
            value = module.sa.account.primary_connection_string
          }
        }
      }
    }
  }
}
