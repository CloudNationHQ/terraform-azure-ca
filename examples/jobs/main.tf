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

module "kv" {
  source  = "cloudnationhq/kv/azure"
  version = "~> 6.0"


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
      }
    }
  }
}

module "acr" {
  source  = "cloudnationhq/acr/azure"
  version = "~> 6.0"

  registry = {
    name                          = module.naming.container_registry.name_unique
    location                      = module.rg.groups.demo.location
    resource_group_name           = module.rg.groups.demo.name
    sku                           = "Premium"
    public_network_access_enabled = true
    admin_enabled                 = true
  }
}

module "uai" {
  source  = "cloudnationhq/uai/azure"
  version = "~> 3.0"

  identity = {
    name                = module.naming.user_assigned_identity.name
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

    jobs = {
      job1 = {
        replica_timeout_in_seconds = 300
        key_vault_scope            = module.kv.vault.id

        template = {
          containers = {
            container1 = {
              image = "nginx:latest"
              env = {
                ALLOWED_HOSTS = {
                  value = "*"
                }
                SECRET_KEY = {
                  secret_name = "personal-access-token"
                }
              }
            }
          }
        }

        event_trigger_config = {
          scale = {
            rules = {
              rule1 = {
                custom_rule_type = "github-runner"
                metadata = {
                  githubAPIURL              = "https://api.github.com"
                  runnerScope               = "repo"
                  targetWorkflowQueueLength = "1"
                }
                authentication = {
                  auth1 = {
                    secret_name       = "personal-access-token"
                    trigger_parameter = "personalAccessToken"
                  }
                }
              }
            }
          }
        }

        secrets = {
          personal-access-token = {
            key_vault_secret_id = module.kv.secrets.secret1.versionless_id
            identity            = module.uai.identity.id
          }
        }

        registries = {
          acr = {
            server   = module.acr.registry.login_server
            identity = module.uai.identity.id
            scope    = module.acr.registry.id
          }
        }

        identity = {
          type         = "UserAssigned"
          identity_ids = [module.uai.identity.id]
          principal_id = module.uai.identity.principal_id
        }
      }

      job2 = {
        replica_timeout_in_seconds = 300
        key_vault_scope            = module.kv.vault.id

        template = {
          containers = {
            container2 = {
              image = "nginx:latest"
              env = {
                ALLOWED_HOSTS = {
                  value = "*"
                }
                SECRET_KEY = {
                  secret_name = "secret-key"
                }
              }
            }
          }
        }

        schedule_trigger_config = {
          cron_expression          = "0 0 * * *"
          parallelism              = 4
          replica_completion_count = 2
        }

        key_vault_role_assignment_enabled = false

        secrets = {
          secret-key = {
            key_vault_secret_id = module.kv.secrets.secret1.versionless_id
            identity            = module.uai.identity.id
          }
        }

        registries = {
          acr = {
            server                  = module.acr.registry.login_server
            identity                = module.uai.identity.id
            role_assignment_enabled = false
          }
        }

        identity = {
          type         = "UserAssigned"
          identity_ids = [module.uai.identity.id]
          principal_id = module.uai.identity.principal_id
        }
      }
    }
  }
}
