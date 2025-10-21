module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.24"

  suffix = ["demo", "prd"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 2.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = "westeurope"
    }
  }
}

module "kv" {
  source  = "cloudnationhq/kv/azure"
  version = "~> 4.0"

  naming = local.naming

  vault = {
    name                = module.naming.key_vault.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    secrets = {
      random_string = {
        secret1 = {
          length  = 32
          special = false
        }
        secret2 = {
          length  = 32
          special = false
        }
      }
    }
  }
}

module "vnet" {
  source  = "cloudnationhq/vnet/azure"
  version = "~> 9.0"

  naming = local.naming

  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.19.0.0/16"]

    subnets = {
      cae = {
        address_prefixes       = ["10.19.1.0/24"]
        service_endpoints      = ["Microsoft.KeyVault", "Microsoft.Storage"]
        default_outbound       = true
        private_link_endpoints = true

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
  version = "~> 3.0"

  workspace = {
    name                = module.naming.log_analytics_workspace.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "acr" {
  source  = "cloudnationhq/acr/azure"
  version = "~> 5.0"

  naming = local.naming

  registry = {
    name                          = module.naming.container_registry.name_unique
    location                      = module.rg.groups.demo.location
    resource_group_name           = module.rg.groups.demo.name
    sku                           = "Premium"
    public_network_access_enabled = true
    admin_enabled                 = true
  }
}

module "tasks" {
  source  = "cloudnationhq/acr/azure//modules/tasks"
  version = "~> 5.0"

  tasks = {
    build = {
      platform = {
        architecture = "amd64"
        os           = "Linux"
      }

      agent_setting = {
        cpu = 2
      }

      schedule_run_now = true

      container_registry_id = module.acr.registry.id

      encoded_step = {
        task_content = base64encode(<<-EOT
    version: v1.1.0
    steps:
      - cmd: docker pull mcr.microsoft.com/hello-world:latest
      - cmd: docker tag mcr.microsoft.com/hello-world:latest ${module.acr.registry.login_server}/hello-world:latest
      - cmd: docker push ${module.acr.registry.login_server}/hello-world:latest
  EOT
        )
      }

      identity = {
        type = "SystemAssigned"
      }
    }
  }
}

module "uai" {
  source  = "cloudnationhq/uai/azure"
  version = "~> 2.0"

  config = {
    name                = "${module.naming.user_assigned_identity.name}-app2"
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "ca" {
  source = "../../"

  naming = local.naming

  environment = {
    name                           = module.naming.container_app_environment.name
    location                       = module.rg.groups.demo.location
    resource_group_name            = module.rg.groups.demo.name
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

      # App pulling from public registry
      app1 = {
        revision_mode         = "Single"
        workload_profile_name = "Consumption"
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
            value = module.acr.registry.admin_password
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
      }

      # App with username/password authentication for registry
      app2 = {
        revision_mode         = "Single"
        workload_profile_name = "Consumption"
        template = {
          min_replicas    = 1
          max_replicas    = 3
          revision_suffix = "test"

          containers = {
            container1 = {
              image = "${module.acr.registry.login_server}/hello-world:latest"
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
            value = module.acr.registry.admin_password
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

        registry = {
          server               = module.acr.registry.login_server
          username             = module.acr.registry.admin_username
          password_secret_name = "secret-key"
        }
      }

      # App with user-assigned identity for Key Vault and ACR access
      app3 = {
        revision_mode         = "Single"
        workload_profile_name = "Dedicated"

        identity = {
          type         = "UserAssigned"
          identity_ids = [module.uai.config.id]
          principal_id = module.uai.config.principal_id
        }

        key_vault_scope = module.kv.vault.id

        template = {
          min_replicas    = 1
          max_replicas    = 3
          revision_suffix = "test"

          containers = {
            container1 = {
              image = "${module.acr.registry.login_server}/hello-world:latest"
              env = {
                ALLOWED_HOSTS = {
                  value = "*"
                }
                DEBUG = {
                  value = "True"
                }
                SECRET_KEY1 = {
                  secret_name = "secret-key1"
                }
                SECRET_KEY2 = {
                  secret_name = "secret-key2"
                }
              }
            }
          }
        }

        secrets = {
          secret-key1 = {
            key_vault_secret_id = module.kv.secrets.secret1.versionless_id
            identity_id         = module.uai.config.id
          }
          secret-key2 = {
            key_vault_secret_id = module.kv.secrets.secret2.versionless_id
            identity_id         = module.uai.config.id
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

        registry = {
          server      = module.acr.registry.login_server
          scope       = module.acr.registry.id
          identity_id = module.uai.config.id
        }
      }
    }
  }

  depends_on = [module.tasks]
}
