resource "azurerm_container_app_environment" "cae" {
  name                               = var.environment.name
  location                           = try(var.environment.location, var.location)
  resource_group_name                = try(var.environment.resourcegroup, var.resourcegroup)
  infrastructure_subnet_id           = try(var.environment.infrastructure_subnet_id, null)
  infrastructure_resource_group_name = try(var.environment.infrastructure_resource_group_name, null)
  internal_load_balancer_enabled     = try(var.environment.internal_load_balancer_enabled, null)
  zone_redundancy_enabled            = try(var.environment.zone_redundancy_enabled, null)
  log_analytics_workspace_id         = try(var.environment.log_analytics_workspace_id, null)

  dynamic "workload_profile" {
    for_each = try(var.environment.workload_profile, {})
    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
      maximum_count         = workload_profile.value.maximum_count
      minimum_count         = workload_profile.value.minimum_count
    }
  }
  tags = try(var.environment.tags, {})
}

resource "azurerm_container_app" "ca" {
  for_each = {
    for ca_key, ca in lookup(var.environment, "container_apps", {}) : ca_key => ca
  }

  name                         = try(each.value.name, "${var.naming.container_app}-${each.key}")
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = try(each.value.resourcegroup, var.environment.resourcegroup, var.resourcegroup)
  revision_mode                = try(each.value.revision_mode, "Single")
  workload_profile_name        = try(each.value.workload_profile_name, null)

  template {
    min_replicas    = try(each.value.template.min_replicas, 1)
    max_replicas    = try(each.value.template.max_replicas, 1)
    revision_suffix = try(each.value.template.revision_suffix, null)

    dynamic "init_container" {
      for_each = try(each.value.init_container, null) != null ? { default = each.value.init_container } : {}
      content {
        name    = init_container.value.name
        image   = init_container.value.image
        cpu     = try(init_container.value.cpu, 0.25)
        memory  = try(init_container.value.memory, "0.5Gi")
        command = try(init_container.value.command, [])
        args    = try(init_container.value.args, [])

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
      for_each = each.value.template.containers
      content {
        name    = container.key
        image   = container.value.image
        cpu     = try(container.value.cpu, 0.25)
        memory  = try(container.value.memory, "0.5Gi")
        command = try(container.value.command, null)
        args    = try(container.value.args, null)

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

    dynamic "azure_queue_scale_rule" {
      for_each = try(each.value.template.azure_queue_scale_rule, null) != null ? { default = each.value.template.azure_queue_scale_rule } : {}
      content {
        name         = azure_queue_scale_rule.value.name
        queue_name   = azure_queue_scale_rule.value.queue_name
        queue_length = azure_queue_scale_rule.value.queue_length

        dynamic "authentication" {
          for_each = try(azure_queue_scale_rule.value.template.authentication, null) != null ? { default = azure_queue_scale_rule.value.template.authentication } : {}
          content {
            secret_name       = azure_queue_scale_rule.value.authentication.secret_name
            trigger_parameter = azure_queue_scale_rule.value.authentication.trigger_parameter
          }
        }
      }
    }

    dynamic "custom_scale_rule" {
      for_each = try(each.value.template.custom_scale_rule, null) != null ? { default = each.value.template.custom_scale_rule } : {}
      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata

        dynamic "authentication" {
          for_each = try(custom_scale_rule.value.authentication, null) != null ? { default = custom_scale_rule.value.authentication } : {}
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "http_scale_rule" {
      for_each = try(each.value.template.http_scale_rule, null) != null ? { default = each.value.template.http_scale_rule } : {}
      content {
        name                = http_scale_rule.value.name
        concurrent_requests = http_scale_rule.value.concurrent_requests

        dynamic "authentication" {
          for_each = try(http_scale_rule.value.template.authentication, null) != null ? { default = http_scale_rule.value.template.authentication } : {}
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "tcp_scale_rule" {
      for_each = try(each.value.template.tcp_scale_rule, null) != null ? { default = each.value.template.tcp_scale_rule } : {}
      content {
        name                = tcp_scale_rule.value.name
        concurrent_requests = tcp_scale_rule.value.concurrent_requests

        dynamic "authentication" {
          for_each = try(tcp_scale_rule.value.template.authentication, null) != null ? { default = tcp_scale_rule.value.template.authentication } : {}
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "volume" {
      for_each = try(each.value.volume, null) != null ? { default = each.value.volume } : {}
      content {
        name         = volume.value.name
        storage_name = try(volume.value.storage_name, null)
        storage_type = try(volume.value.storage_type, null)
      }
    }
  }

  dynamic "ingress" {
    for_each = try(each.value.ingress, null) != null ? { default = each.value.ingress } : {}

    content {
      allow_insecure_connections = try(ingress.value.allow_insecure_connections, false)
      external_enabled           = try(ingress.value.external_enabled, false)
      fqdn                       = try(ingress.value.fqdn, null)
      target_port                = ingress.value.target_port
      exposed_port               = try(ingress.value.transport, null) == "tcp" ? ingress.value.exposed_port : null
      transport                  = try(ingress.value.transport, "auto")


      dynamic "traffic_weight" {
        ## This block only applies when revision_mode is set to Multiple.
        for_each = { for k, v in try(ingress.value.traffic_weight, null) : k => v }
        content {
          label           = try(traffic_weight.value.label, null)
          latest_revision = try(traffic_weight.value.latest_revision, true)
          percentage      = try(traffic_weight.value.percentage, 100)
          revision_suffix = try(traffic_weight.value.latest_revision, null) == false ? traffic_weight.value.revision_suffix : null
        }
      }

      dynamic "ip_security_restriction" {
        ## The action types in an all ip_security_restriction blocks must be the same for the ingress, mixing Allow and Deny rules is not currently supported by the service.
        for_each = try(ingress.value.ip_security_restriction, null) != null ? { default = ingress.value.ip_security_restriction } : {}
        content {
          name             = try(ip_security_restriction.value.name, null)
          description      = try(ip_security_restriction.value.description, null)
          action           = ip_security_restriction.value.action
          ip_address_range = ip_security_restriction.value.ip_address_range
        }
      }
    }
  }

  dynamic "registry" {
    for_each = { for id in local.user_assigned_identities : id.id_name => id if id.ca_name == each.key && try(id.server, null) != null }
    content {
      server               = registry.value.server
      identity             = coalesce(registry.value.identity, azurerm_user_assigned_identity.identity[registry.value.id_name].id, null)
      username             = try(registry.value.username, null)
      password_secret_name = try(registry.value.password_secret_name, null)
    }
  }

  ## Secrets should be set correctly, otherwise the secret should be removed from the container app from within the portal:
  ## Cannot remove secrets from Container Apps at this time due to a limitation in the Container Apps Service.
  ## Please see `https://github.com/microsoft/azure-container-apps/issues/395` for more details
  dynamic "secret" {
    for_each = { for sec in local.user_assigned_identities_secrets : sec.name => sec if sec.ca_name == each.key }
    content {
      name                = secret.value.name
      value               = try(secret.value.value, null)
      identity            = try(secret.value.key_vault_secret_id, null) == null ? null : coalesce(secret.value.identity, azurerm_user_assigned_identity.identity[secret.value.id_name].id)
      key_vault_secret_id = try(secret.value.key_vault_secret_id, null)
    }
  }

  dynamic "identity" {
    for_each = { default = local.user_assigned_identities }

    content {
      type         = try(identity.value.type, "UserAssigned")
      identity_ids = [for id in local.user_assigned_identities : azurerm_user_assigned_identity.identity[id.id_name].id if id.ca_name == each.key]
    }
  }
  tags = try(each.value.tags, {})

}

resource "azurerm_container_app_environment_certificate" "certificate" {
  for_each = { for caec in local.custom_domain_certificates : caec.key => caec }

  name                         = each.value.name
  container_app_environment_id = azurerm_container_app_environment.cae.id
  certificate_blob_base64      = try(each.value.key_vault_certificate, filebase64(each.value.path))
  certificate_password         = each.value.password
}

resource "azurerm_container_app_custom_domain" "domain" {
  for_each = { for domain in local.custom_domain_certificates : domain.key => domain }

  name                                     = trimprefix(each.value.fqdn, "asuid.")
  container_app_id                         = azurerm_container_app.ca[each.value.ca_name].id
  container_app_environment_certificate_id = azurerm_container_app_environment_certificate.certificate[each.key].id
  certificate_binding_type                 = try(each.value.binding_type, "Disabled")
}

resource "azurerm_user_assigned_identity" "identity" {
  for_each = { for identity in local.user_assigned_identities : identity.id_name => identity }

  name                = each.key
  resource_group_name = try(each.value.resourcegroup, var.resourcegroup)
  location            = try(each.value.location, var.location)
  tags                = try(each.value.tags, var.environment.tags, null)
}

resource "azurerm_user_assigned_identity" "identity_jobs" {
  for_each = { for identity in local.user_assigned_identities_jobs : identity.name => identity if contains(["UserAssigned", "SystemAssigned, UserAssigned"], identity.type) }

  name                = each.value.name
  resource_group_name = try(each.value.resourcegroup, var.resourcegroup)
  location            = try(each.value.location, var.location)
  tags                = try(each.value.tags, var.environment.tags, null)
}

resource "azurerm_role_assignment" "role_secret_user" {
  for_each = { for identity in local.user_assigned_identities_secrets : identity.id_name => identity }

  scope                = each.value.kv_scope
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.identity[each.key].principal_id
}

resource "azurerm_role_assignment" "role_secret_user_jobs" {
  for_each = { for identity in local.secrets_jobs : identity.name => identity }

  scope                = each.value.kv_scope
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.identity_principal_id
}

resource "azurerm_role_assignment" "role_acr_pull_jobs" {
  for_each = { for identity in local.user_assigned_identities_jobs : identity.name => identity }

  scope                = each.value.scope
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.identity_jobs[each.key].principal_id
}

resource "azurerm_role_assignment" "role_acr_pull" {
  for_each = { for identity in local.user_assigned_identity_registry : identity.id_name => identity }

  scope                = each.value.scope
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.identity[each.key].principal_id
}

resource "azapi_resource" "containerjob" {
  for_each  = { for key, job in local.job_containers : key => job }
  type      = "Microsoft.App/jobs@2023-11-02-preview"
  name      = each.value.name
  location  = each.value.location
  parent_id = each.value.resourcegroup_id

  dynamic "identity" {
    for_each = try(each.value.identities, null)
    content {
      type = try(identity.value.type, "SystemAssigned")
      identity_ids = concat(
        try([azurerm_user_assigned_identity.identity_jobs[identity.value.name].id], []),
      try(identity.value.identity_ids, []))
    }
  }

  body = jsonencode({
    properties = {
      configuration = {
        replicaRetryLimit = each.value.retry_limit
        replicaTimeout    = each.value.timeout
        triggerType       = each.value.trigger_type
        eventTriggerConfig = each.value.trigger_type == "Event" ? {
          parallelism            = each.value.parallelism
          replicaCompletionCount = each.value.replica_completion_count
          scale = {
            maxExecutions   = each.value.scale.max_executions
            minExecutions   = each.value.scale.min_executions
            pollingInterval = each.value.scale.polling_interval
            rules           = each.value.scale.rules
          }
        } : null
        scheduleTriggerConfig = each.value.trigger_type == "Schedule" ? {
          cronExpression         = each.value.cron_expression
          parallelism            = each.value.parallelism
          replicaCompletionCount = each.value.replica_completion_count
        } : null
        manualTriggerConfig = each.value.trigger_type == "Manual" ? {
          parallelism            = each.value.parallelism
          replicaCompletionCount = each.value.replica_completion_count
        } : null
        secrets = each.value.secrets
        registries = [
          {
            identity          = try(azurerm_user_assigned_identity.identity_jobs[each.value.registry.identity].id, null)
            passwordSecretRef = try(each.value.registry.password, "")
            username          = try(each.value.registry.username, "")
            server            = try(each.value.registry.server, null)
          }
        ]
      }
      environmentId = azurerm_container_app_environment.cae.id
      template = {
        containers = each.value.containers
      }
    }
  })
}
