locals {
  jobs = {
    job1 = {
      replica_timeout_in_seconds = 300
      key_vault_scope            = module.kv.vault.id

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
            rule1 = {
              name             = "rule1"
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
          identity_id         = module.uai["job1"].config.id
        }
      }

      registry = {
        server      = module.acr.registry.login_server
        identity_id = module.uai["job1"].config.id
        scope       = module.acr.registry.id
      }

      identity = {
        type         = "UserAssigned"
        identity_ids = [module.uai["job1"].config.id]
        principal_id = module.uai["job1"].config.principal_id
      }
    }
    job2 = {
      replica_timeout_in_seconds = 300
      key_vault_scope            = module.kv.vault.id

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
          identity_id         = module.uai["job2"].config.id
        }
      }

      registry = {
        server      = module.acr.registry.login_server
        identity_id = module.uai["job2"].config.id
        scope       = module.acr.registry.id
      }

      identity = {
        type         = "UserAssigned"
        identity_ids = [module.uai["job2"].config.id]
        principal_id = module.uai["job2"].config.principal_id
      }
    }
  }
}
