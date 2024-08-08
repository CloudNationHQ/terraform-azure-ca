resource "azurerm_container_app_job" "job" {
  for_each = {
    for job_key, job in lookup(var.environment, "jobs", {}) : job_key => job
  }

  name                         = try(each.value.name, "${var.naming.container_app_job}-${each.key}")
  location                     = coalesce(lookup(each.value, "location", null), var.environment.location)
  resource_group_name          = coalesce(lookup(each.value, "resource_group", null), var.environment.resource_group)
  container_app_environment_id = azurerm_container_app_environment.cae.id
  replica_timeout_in_seconds   = each.value.replica_timeout_in_seconds

  workload_profile_name = try(each.value.workload_profile_name, null)
  replica_retry_limit   = try(each.value.replica_retry_limit, null)

  template {
    dynamic "init_container" {
      for_each = try(each.value.template.init_container, null) != null ? { default = each.value.template.init_container } : {}
      content {
        name              = init_container.value.name
        image             = init_container.value.image
        cpu               = try(init_container.value.cpu, 0.25)
        memory            = try(init_container.value.memory, "0.5Gi")
        command           = try(init_container.value.command, [])
        args              = try(init_container.value.args, [])
        ephemeral_storage = try(init_container.value.ephemeral_storage, null)
        ## ephemeral_storage is currently in preview and not configurable at this time.

        dynamic "env" {
          for_each = { for key, env in try(init_container.value.env, {}) : key => env }
          content {
            name        = env.key
            value       = try(env.value.value, null)
            secret_name = try(env.value.secret_name, null)
          }
        }

        dynamic "volume_mounts" {
          for_each = try(init_container.value.volume_mounts, null) != null ? { default = init_container.value.volume_mounts } : {}
          content {
            name = volume_mounts.value.name
            path = volume_mounts.value.path
          }
        }
      }
    }

    dynamic "container" {
      for_each = try(each.value.template.container, null) != null ? { default = each.value.template.container } : {}
      content {
        name              = container.value.name
        image             = container.value.image
        cpu               = try(container.value.cpu, 0.25)
        memory            = try(container.value.memory, "0.5Gi")
        command           = try(container.value.command, null)
        args              = try(container.value.args, null)
        ephemeral_storage = try(container.value.ephemeral_storage, null)
        ## ephemeral_storage is currently in preview and not configurable at this time.

        dynamic "env" {
          for_each = { for key, env in try(container.value.env, {}) : key => env }
          content {
            name        = env.key
            value       = try(env.value.value, null)
            secret_name = try(env.value.secret_name, null)
          }
        }

        dynamic "volume_mounts" {
          for_each = try(container.value.volume_mounts, null) != null ? { default = container.value.volume_mounts } : {}
          content {
            name = volume_mounts.value.name
            path = volume_mounts.value.path
          }
        }

        dynamic "liveness_probe" {
          for_each = try(container.value.liveness_probe, null) != null ? { default = container.value.liveness_probe } : {}
          content {
            transport                        = try(liveness_probe.value.transport, "HTTPS")
            port                             = liveness_probe.value.port
            host                             = try(liveness_probe.value.host, null)
            failure_count_threshold          = try(liveness_probe.value.failure_count_threshold, 3)
            initial_delay                    = try(liveness_probe.value.initial_delay, 30)
            interval_seconds                 = try(liveness_probe.value.interval_seconds, 10)
            path                             = try(liveness_probe.value.path, "/")
            timeout                          = try(liveness_probe.value.timeout, 1)
            termination_grace_period_seconds = try(liveness_probe.value.termination_grace_period_seconds, null)

            dynamic "header" {
              for_each = try(liveness_probe.value.header, null) != null ? [1] : []
              content {
                name  = liveness_probe.value.header.name
                value = liveness_probe.value.header.value
              }
            }
          }
        }

        dynamic "readiness_probe" {
          for_each = try(container.value.readiness_probe, null) != null ? { default = container.value.readiness_probe } : {}
          content {
            transport               = try(readiness_probe.value.transport, "HTTPS")
            port                    = readiness_probe.value.port
            host                    = try(readiness_probe.value.host, null)
            failure_count_threshold = try(readiness_probe.value.failure_count_threshold, 3)
            success_count_threshold = try(readiness_probe.value.termination_grace_period_seconds, 3)
            interval_seconds        = try(readiness_probe.value.interval_seconds, 10)
            path                    = try(readiness_probe.value.path, "/")
            timeout                 = try(readiness_probe.value.timeout, 1)

            dynamic "header" {
              for_each = try(readiness_probe.value.header, null) != null ? [1] : []
              content {
                name  = readiness_probe.value.header.name
                value = readiness_probe.value.header.value
              }
            }
          }
        }

        dynamic "startup_probe" {
          for_each = try(container.value.startup_probe, null) != null ? { default = container.value.startup_probe } : {}
          content {
            transport                        = try(startup_probe.value.transport, "HTTPS")
            port                             = startup_probe.value.port
            host                             = try(startup_probe.value.host, null)
            failure_count_threshold          = try(startup_probe.value.failure_count_threshold, 3)
            interval_seconds                 = try(startup_probe.value.interval_seconds, 10)
            path                             = try(startup_probe.value.path, "/")
            timeout                          = try(startup_probe.value.timeout, 1)
            termination_grace_period_seconds = try(startup_probe.value.termination_grace_period_seconds, null)

            dynamic "header" {
              for_each = try(startup_probe.value.header, null) != null ? [1] : []
              content {
                name  = startup_probe.value.header.name
                value = startup_probe.value.header.value
              }
            }
          }
        }
      }
    }

    dynamic "volume" {
      for_each = try(each.value.template.volume, null) != null ? { default = each.value.template.volume } : {}
      content {
        name         = volume.value.name
        storage_type = try(volume.value.storage_type, null)
        storage_name = try(volume.value.storage_name, null)
      }
    }
  }

  dynamic "registry" {
    for_each = try(each.value.registry, null) != null ? { default = each.value.registry } : {}
    content {
      server = registry.value.server
      identity = try(registry.value.scope, null) != null ? try(registry.value.identity.id,
      azurerm_user_assigned_identity.identity_jobs[try(registry.value.identity.name, "${var.naming.user_assigned_identity}-${each.key}")].id, ) : null
      username             = try(registry.value.username, null)
      password_secret_name = try(registry.value.password_secret_name, null)
    }
  }

  dynamic "secret" {
    for_each = { for key, sec in lookup(each.value, "secrets", {}) : key => sec }
    content {
      name  = secret.key
      value = try(secret.value.value, null)
      identity = try(
        secret.value.key_vault_secret_id, null) == null ? null : try(secret.value.identity.id, null) != null ? secret.value.identity.id : azurerm_user_assigned_identity.identity_jobs[try(
      secret.value.identity.name, "${var.naming.user_assigned_identity}-${each.key}")].id
      key_vault_secret_id = try(secret.value.key_vault_secret_id, null)
    }
  }

  dynamic "identity" {
    for_each = length([for id in local.merged_jobs_identities_all : id if id.job_name == each.key
    ]) > 0 ? { default = local.merged_jobs_identities_all } : {}

    content {
      type = try(identity.value.type, "UserAssigned")
      identity_ids = concat([for id in identity.value : azurerm_user_assigned_identity.identity_jobs[id.id_name].id if id.identity_id == {} && id.job_name == each.key],
      [for id in identity.value : id.identity_id if id.identity_id != {} && id.job_name == each.key])
    }
  }

  dynamic "manual_trigger_config" {
    for_each = try(each.value.manual_trigger_config, null) != null ? { default = each.value.manual_trigger_config } : {}
    content {
      parallelism              = try(manual_trigger_config.value.parallelism, null)
      replica_completion_count = try(manual_trigger_config.value.replica_completion_count, null)
    }
  }

  dynamic "event_trigger_config" {
    for_each = try(each.value.event_trigger_config, null) != null ? { default = each.value.event_trigger_config } : {}
    content {
      parallelism              = try(event_trigger_config.value.parallelism, null)
      replica_completion_count = try(event_trigger_config.value.replica_completion_count, null)

      dynamic "scale" {
        for_each = try(event_trigger_config.value.scale, null) != null ? { default = event_trigger_config.value.scale } : {}
        content {
          max_executions              = try(scale.value.max_executions, null)
          min_executions              = try(scale.value.min_executions, null)
          polling_interval_in_seconds = try(scale.value.polling_interval_in_seconds, null)

          dynamic "rules" {
            for_each = try(scale.value.rules, null) != null ? { default = scale.value.rules } : {}
            content {
              name             = try(rules.value.name, null)
              custom_rule_type = try(rules.value.custom_rule_type, null)
              metadata         = try(rules.value.metadata, {})

              dynamic "authentication" {
                for_each = try(rules.value.authentication, null) != null ? { default = rules.value.authentication } : {}
                content {
                  trigger_parameter = authentication.value.trigger_parameter
                  secret_name       = authentication.value.secret_name
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "schedule_trigger_config" {
    for_each = try(each.value.schedule_trigger_config, null) != null ? { default = each.value.schedule_trigger_config } : {}
    content {
      parallelism              = try(schedule_trigger_config.value.parallelism, null)
      replica_completion_count = try(schedule_trigger_config.value.replica_completion_count, null)
      cron_expression          = schedule_trigger_config.value.cron_expression
    }
  }

  tags = try(each.value.tags, {})
}

resource "azurerm_user_assigned_identity" "identity_jobs" {
  for_each = { for id in local.merged_jobs_identities_filtered : id.id_name => id }

  name                = each.key
  resource_group_name = try(each.value.resource_group, var.resource_group)
  location            = try(each.value.location, var.location)
  tags                = try(each.value.tags, var.environment.tags, null)
}

resource "azurerm_role_assignment" "role_secret_user_jobs" {
  for_each = { for id in local.unique_uai_jobs_secrets_map : id.id_name => id }

  scope                = each.value.kv_scope
  role_definition_name = "Key Vault Secrets User"
  principal_id         = try(each.value.principal_id, null) != null ? each.value.principal_id : azurerm_user_assigned_identity.identity_jobs[each.key].principal_id
}

resource "azurerm_role_assignment" "role_acr_pull_jobs" {
  for_each = { for id in local.user_assigned_identity_jobs_registry : id.id_name => id }

  scope                = each.value.scope
  role_definition_name = "AcrPull"
  principal_id         = try(each.value.principal_id, null) != null ? each.value.principal_id : azurerm_user_assigned_identity.identity_jobs[each.key].principal_id
}
