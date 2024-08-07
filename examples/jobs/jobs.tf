locals {
  jobs = {
    job1 = {
      kv_scope                   = module.kv.vault.id
      replica_timeout_in_seconds = 300
      template = {
        container = {
          name  = "container1"
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
      event_trigger_config = {
        scale = {
          rules = {
            name             = "rule1"
            custom_rule_type = "github-runner"
            metadata = {
              githubAPIURL              = "https://api.github.com"
              runnerScope               = "repo"
              targetWorkflowQueueLength = "1"
            }
            authentication = {
              secret_name       = "personal-access-token"
              trigger_parameter = "personalAccessToken"
            }
          }
        }
      }

      secrets = {
        personal-access-token = {
          key_vault_secret_id = module.kv.secrets.secret1.versionless_id
        }
      }

      registry = {
        server = module.acr.acr.login_server
        scope  = module.acr.acr.id
      }

    }
    job2 = {
      kv_scope                   = module.kv.vault.id
      replica_timeout_in_seconds = 300
      template = {
        container = {
          name  = "container2"
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

      schedule_trigger_config = {
        cron_expression          = "0 0 * * *"
        parallelism              = 4
        replica_completion_count = 2
      }

      secrets = {
        secret-key = {
          key_vault_secret_id = module.kv.secrets.secret1.versionless_id
          identity = {
            name = "uai-job2-secret"
          }
        }
      }

      registry = {
        server = module.acr.acr.login_server
        scope  = module.acr.acr.id
        identity = {
          name = "uai-job2-registry"
        }
      }
    }
    job3 = {
      replica_timeout_in_seconds = 300
      template = {
        container = {
          name  = "container1"
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
      event_trigger_config = {
        scale = {
          rules = {
            name             = "rule1"
            custom_rule_type = "github-runner"
            metadata = {
              githubAPIURL              = "https://api.github.com"
              runnerScope               = "repo"
              targetWorkflowQueueLength = "1"
            }
            authentication = {
              secret_name       = "personal-access-token"
              trigger_parameter = "personalAccessToken"
            }
          }
        }
      }

      secrets = {
        personal-access-token = {
          value = "secret-string"
        }
        secret-key = {
          value = module.acr.acr.admin_password
        }
      }

      registry = {
        server               = module.acr.acr.login_server
        username             = module.acr.acr.admin_username
        password_secret_name = "secret-key"
      }

    }
    job4 = {
      kv_scope                   = module.kv.vault.id
      replica_timeout_in_seconds = 300
      template = {
        container = {
          name  = "container4"
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

      manual_trigger_config = {
        parallelism              = 4
        replica_completion_count = 2
      }

      secrets = {
        secret-key = {
          key_vault_secret_id = module.kv.secrets.secret1.versionless_id
          identity = {
            name         = azurerm_user_assigned_identity.identity_sec.name
            id           = azurerm_user_assigned_identity.identity_sec.id
            principal_id = azurerm_user_assigned_identity.identity_sec.principal_id
          }
        }
      }

      registry = {
        server = module.acr.acr.login_server
        scope  = module.acr.acr.id
        identity = {
          name         = azurerm_user_assigned_identity.identity_reg.name
          id           = azurerm_user_assigned_identity.identity_reg.id
          principal_id = azurerm_user_assigned_identity.identity_reg.principal_id
        }
      }
    }
  }
}
