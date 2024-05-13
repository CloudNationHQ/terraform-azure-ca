locals {
  naming = {
    # lookup outputs to have consistent naming
    for type in local.naming_types : type => lookup(module.naming, type).name
  }

  naming_types = ["container_app", "container_app_job", "container_app_environment", "user_assigned_identity", "key_vault_secret"]
}

locals {
  jobs = {
    job1 = {
      trigger_type = "Event"
      template = {
        containers = {
          container1 = {
            image = "nginx:latest"
            env = {
              ALLOWED_HOSTS = {
                value = "*"
              }
            }
          }
        }
      }
      rules = {
        rule1 = {
          name = "rule1"
          type = "github-runner"
          metadata = {
            githubAPIURL              = "https://api.github.com"
            runnerScope               = "repo"
            targetWorkflowQueueLength = "1"
          }
          auth = {
            auth1 = {
              secret_ref        = "personal-access-token"
              trigger_parameter = "personalAccessToken"
            }
          }
        }
      }

      identities = {
        uai1 = {
          type = "UserAssigned"
          name = "uai1-demo-dev"
        }
      }

      registry = {
        server   = module.acr.acr.login_server
        scope    = module.acr.acr.id
        identity = "uai1-demo-dev"
      }
    }
    job2 = {
      cron_expression = "0 0 * * *"
      trigger_type    = "Schedule"
      kv_scope        = module.kv.vault.id

      template = {
        containers = {
          container1 = {
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

      secrets = {
        secret-key = {
          key_vault_secret_id = module.kv.secrets.secret1.versionless_id
          identity            = "uai2-demo-dev"
        }
      }
      identities = {
        uai2 = {
          type = "UserAssigned"
          name = "uai2-demo-dev"
        }
      }

      registry = {
        server   = module.acr.acr.login_server
        scope    = module.acr.acr.id
        identity = "uai2-demo-dev"
      }
    }
  }
}
