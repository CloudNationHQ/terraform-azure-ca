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

module "vnet" {
  source  = "cloudnationhq/vnet/azure"
  version = "~> 2.0"

  naming = local.naming

  vnet = {
    name          = module.naming.virtual_network.name
    location      = module.rg.groups.demo.location
    resourcegroup = module.rg.groups.demo.name
    cidr          = ["10.0.0.0/16"]

    subnets = {
      cae = {
        cidr = ["10.0.0.0/23"]
        nsg  = {}
        delegations = {
          cae-delegation = {
            name    = "Microsoft.App/environments"
            actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
          }
        }
      }
    }
  }
}

module "law" {
  source  = "cloudnationhq/law/azure"
  version = "~> 0.1"

  law = {
    name          = module.naming.log_analytics_workspace.name
    location      = module.rg.groups.demo.location
    resourcegroup = module.rg.groups.demo.name
  }
}

module "acr" {
  source  = "cloudnationhq/acr/azure"
  version = "~> 0.3"

  naming = local.naming

  registry = {
    name                          = module.naming.container_registry.name_unique
    location                      = module.rg.groups.demo.location
    resourcegroup                 = module.rg.groups.demo.name
    sku                           = "Premium"
    public_network_access_enabled = true
  }
}

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
              }
            }
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
          server = module.acr.acr.login_server
          scope  = module.acr.acr.id
        }
      }

      app2 = {
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

        registry = {
          server = module.acr.acr.login_server
          scope  = module.acr.acr.id
        }
      }

      app3 = {
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
            value = module.kv.secrets.secret1.value
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
          server = module.acr.acr.login_server
          scope  = module.acr.acr.id

          identity = {
            name = "uai-own-name"
          }
        }
      }

      app4 = {
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
            key_vault_secret_id = module.kv.secrets.secret1.versionless_id
            kv_scope            = module.kv.vault.id
            identity = {
              name = "uai-secret-with-override-name"
            }
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
          server = module.acr.acr.login_server
          scope  = module.acr.acr.id

          identity = {
            name = "uai-reg-with-override-name"
          }
        }
      }
    }
  }
}
