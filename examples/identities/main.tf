module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 2.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name
      location = "westeurope"
    }
  }
}

module "kv" {
  source  = "cloudnationhq/kv/azure"
  version = "~> 2.0"

  naming = local.naming

  vault = {
    name           = module.naming.key_vault.name_unique
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name

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

module "acr" {
  source  = "cloudnationhq/acr/azure"
  version = "~> 3.0"

  naming = local.naming

  registry = {
    name                          = module.naming.container_registry.name_unique
    location                      = module.rg.groups.demo.location
    resource_group                = module.rg.groups.demo.name
    sku                           = "Premium"
    public_network_access_enabled = true
    admin_enabled                 = true
  }
}

module "ca" {
  source  = "cloudnationhq/ca/azure"
  version = "~> 3.0"

  naming = local.naming

  environment = {
    name           = module.naming.container_app_environment.name
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name

    container_apps = {
      ## No identities used, only username/pw combination for registry with secret as value
      app1 = {
        revision_mode = "Single"
        template = {
          min_replicas    = 1
          max_replicas    = 3
          revision_suffix = "latest"

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

      ## Identity (User-Assigned) implicitly generated used for both secrets and registry
      app2 = {
        revision_mode = "Single"
        kv_scope      = module.kv.vault.id
        template = {
          min_replicas    = 1
          max_replicas    = 3
          revision_suffix = "latest"

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
          server = module.acr.registry.login_server
          scope  = module.acr.registry.id
        }
      }

      ## Identity (User-Assigned) explicitly defined with own naming for registry and no identity for secret as value is used instead of retrieving from KV
      app3 = {
        revision_mode = "Single"
        template = {
          min_replicas    = 1
          max_replicas    = 3
          revision_suffix = "latest"

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
          server = module.acr.registry.login_server
          scope  = module.acr.registry.id

          identity = {
            name = "uai-app3-reg-with-override-name"
          }
        }
      }

      ## Identity (User-Assigned) explicitly defined with own naming for secrets and implicitly for registry
      app4 = {
        revision_mode = "Single"
        template = {
          min_replicas    = 1
          max_replicas    = 3
          revision_suffix = "latest"

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
                SECRET_KEY1 = {
                  secret_name = "secret-key1"
                }
              }
            }
          }
        }

        secrets = {
          secret-key1 = {
            key_vault_secret_id = module.kv.secrets.secret1.versionless_id
            kv_scope            = module.kv.vault.id
            identity = {
              name = "uai-app4-sec-with-override-name"
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
          server = module.acr.registry.login_server
          scope  = module.acr.registry.id
        }
      }

      ## Identity (User-Assigned) explicitly defined with own naming for secrets and registry
      app5 = {
        revision_mode = "Single"
        template = {
          min_replicas    = 1
          max_replicas    = 3
          revision_suffix = "latest"

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
                SECRET_KEY1 = {
                  secret_name = "secret-key1"
                }
              }
            }
          }
        }

        secrets = {
          secret-key1 = {
            key_vault_secret_id = module.kv.secrets.secret1.versionless_id
            kv_scope            = module.kv.vault.id
            identity = {
              name = "uai-app5-sec-with-override-name"
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
          server = module.acr.registry.login_server
          scope  = module.acr.registry.id

          identity = {
            name = "uai-app5-reg-with-override-name"
          }
        }
      }

      ## Identity (User-Assigned) implicitly generated used for both a secret and registry, additional secret with own explicit naming for identity
      app6 = {
        revision_mode = "Single"
        template = {
          min_replicas    = 1
          max_replicas    = 3
          revision_suffix = "latest"

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
            kv_scope            = module.kv.vault.id
            identity = {
              name = "uai-app6-sec-with-override-name"
            }
          }
          secret-key2 = {
            key_vault_secret_id = module.kv.secrets.secret2.versionless_id
            kv_scope            = module.kv.vault.id
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
          server = module.acr.registry.login_server
          scope  = module.acr.registry.id
        }
      }

      ## Identity bring your own identity for both secrets and registry
      app7 = {
        revision_mode = "Single"
        template = {
          min_replicas    = 1
          max_replicas    = 3
          revision_suffix = "latest"

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
            kv_scope            = module.kv.vault.id

            identity = {
              name         = azurerm_user_assigned_identity.identity_sec1.name
              id           = azurerm_user_assigned_identity.identity_sec1.id,
              principal_id = azurerm_user_assigned_identity.identity_sec1.principal_id
            }
          }
          secret-key2 = {
            key_vault_secret_id = module.kv.secrets.secret2.versionless_id
            kv_scope            = module.kv.vault.id

            identity = {
              name         = azurerm_user_assigned_identity.identity_sec2.name
              id           = azurerm_user_assigned_identity.identity_sec2.id,
              principal_id = azurerm_user_assigned_identity.identity_sec2.principal_id
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
          server = module.acr.registry.login_server
          scope  = module.acr.registry.id

          identity = {
            name         = azurerm_user_assigned_identity.identity_reg.name
            id           = azurerm_user_assigned_identity.identity_reg.id
            principal_id = azurerm_user_assigned_identity.identity_reg.principal_id
          }
        }
      }

      ## No Secrets used, only identity for registry
      app8 = {
        revision_mode = "Single"
        template = {
          min_replicas    = 1
          max_replicas    = 3
          revision_suffix = "latest"

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
          server = module.acr.registry.login_server
          scope  = module.acr.registry.id
        }
      }
    }
  }
}
