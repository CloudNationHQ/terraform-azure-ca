data "azurerm_container_app_environment" "existing" {
  for_each = var.environment.use_existing ? { "cae" = var.environment } : {}

  name                = each.value.name
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_group_name)
}

resource "azurerm_container_app_environment" "cae" {
  for_each = var.environment.use_existing ? {} : { "cae" = var.environment }

  name                                        = each.value.name
  location                                    = coalesce(each.value.location, var.location)
  resource_group_name                         = coalesce(each.value.resource_group_name, var.resource_group_name)
  dapr_application_insights_connection_string = each.value.dapr_application_insights_connection_string
  infrastructure_subnet_id                    = each.value.infrastructure_subnet_id
  infrastructure_resource_group_name          = each.value.infrastructure_resource_group_name
  internal_load_balancer_enabled              = each.value.internal_load_balancer_enabled
  zone_redundancy_enabled                     = each.value.zone_redundancy_enabled
  log_analytics_workspace_id                  = each.value.log_analytics_workspace_id
  logs_destination                            = each.value.logs_destination
  mutual_tls_enabled                          = each.value.mutual_tls_enabled

  dynamic "identity" {
    for_each = each.value.identity != null ? { default = each.value.identity } : {}
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "workload_profile" {
    for_each = each.value.workload_profile
    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
      maximum_count         = workload_profile.value.maximum_count
      minimum_count         = workload_profile.value.minimum_count
    }
  }

  tags = coalesce(each.value.tags, var.tags)
}

locals {
  environment_id = var.environment.use_existing ? data.azurerm_container_app_environment.existing["cae"].id : azurerm_container_app_environment.cae["cae"].id
}

resource "azurerm_container_app" "ca" {
  for_each = {
    for ca_key, ca in lookup(var.environment, "container_apps", {}) : ca_key => ca
  }

  name                         = coalesce(each.value.name, try("${var.naming.container_app}-${each.key}", each.key))
  container_app_environment_id = local.environment_id
  resource_group_name          = coalesce(each.value.resource_group_name, var.environment.resource_group_name, var.resource_group_name)
  revision_mode                = each.value.revision_mode
  workload_profile_name        = each.value.workload_profile_name
  max_inactive_revisions       = each.value.max_inactive_revisions

  template {
    min_replicas                     = each.value.template.min_replicas
    max_replicas                     = each.value.template.max_replicas
    revision_suffix                  = each.value.template.revision_suffix
    termination_grace_period_seconds = each.value.template.termination_grace_period_seconds

    dynamic "init_container" {
      for_each = each.value.template.init_container != null ? { default = each.value.template.init_container } : {}
      content {
        name    = init_container.value.name
        image   = init_container.value.image
        cpu     = init_container.value.cpu
        memory  = init_container.value.memory
        command = init_container.value.command
        args    = init_container.value.args

        dynamic "env" {
          for_each = init_container.value.env
          content {
            name        = env.key
            value       = env.value.value
            secret_name = env.value.secret_name
          }
        }

        dynamic "volume_mounts" {
          for_each = init_container.value.volume_mounts != null ? { default = init_container.value.volume_mounts } : {}
          content {
            name     = volume_mounts.value.name
            path     = volume_mounts.value.path
            sub_path = volume_mounts.value.sub_path
          }
        }
      }
    }

    dynamic "container" {
      for_each = each.value.template.containers
      content {
        name    = container.key
        image   = container.value.image
        cpu     = container.value.cpu
        memory  = container.value.memory
        command = container.value.command
        args    = container.value.args

        dynamic "env" {
          for_each = container.value.env
          content {
            name        = env.key
            value       = env.value.value
            secret_name = env.value.secret_name
          }
        }

        dynamic "volume_mounts" {
          for_each = container.value.volume_mounts != null ? { default = container.value.volume_mounts } : {}
          content {
            name     = volume_mounts.value.name
            path     = volume_mounts.value.path
            sub_path = volume_mounts.value.sub_path
          }
        }

        dynamic "liveness_probe" {
          for_each = container.value.liveness_probe != null ? { default = container.value.liveness_probe } : {}
          content {
            transport                        = liveness_probe.value.transport
            port                             = liveness_probe.value.port
            host                             = liveness_probe.value.host
            failure_count_threshold          = liveness_probe.value.failure_count_threshold
            initial_delay                    = liveness_probe.value.initial_delay
            interval_seconds                 = liveness_probe.value.interval_seconds
            path                             = liveness_probe.value.path
            timeout                          = liveness_probe.value.timeout
            termination_grace_period_seconds = liveness_probe.value.termination_grace_period_seconds

            dynamic "header" {
              for_each = liveness_probe.value.header != null ? [1] : []
              content {
                name  = liveness_probe.value.header.name
                value = liveness_probe.value.header.value
              }
            }
          }
        }

        dynamic "readiness_probe" {
          for_each = container.value.readiness_probe != null ? { default = container.value.readiness_probe } : {}
          content {
            transport               = readiness_probe.value.transport
            port                    = readiness_probe.value.port
            host                    = readiness_probe.value.host
            initial_delay           = readiness_probe.value.initial_delay
            failure_count_threshold = readiness_probe.value.failure_count_threshold
            success_count_threshold = readiness_probe.value.success_count_threshold
            interval_seconds        = readiness_probe.value.interval_seconds
            path                    = readiness_probe.value.path
            timeout                 = readiness_probe.value.timeout

            dynamic "header" {
              for_each = readiness_probe.value.header != null ? [1] : []
              content {
                name  = readiness_probe.value.header.name
                value = readiness_probe.value.header.value
              }
            }
          }
        }

        dynamic "startup_probe" {
          for_each = container.value.startup_probe != null ? { default = container.value.startup_probe } : {}
          content {
            transport                        = startup_probe.value.transport
            port                             = startup_probe.value.port
            host                             = startup_probe.value.host
            failure_count_threshold          = startup_probe.value.failure_count_threshold
            initial_delay                    = startup_probe.value.initial_delay
            interval_seconds                 = startup_probe.value.interval_seconds
            path                             = startup_probe.value.path
            timeout                          = startup_probe.value.timeout
            termination_grace_period_seconds = startup_probe.value.termination_grace_period_seconds

            dynamic "header" {
              for_each = startup_probe.value.header != null ? [1] : []
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
      for_each = each.value.template.azure_queue_scale_rule != null ? { default = each.value.template.azure_queue_scale_rule } : {}
      content {
        name         = azure_queue_scale_rule.value.name
        queue_name   = azure_queue_scale_rule.value.queue_name
        queue_length = azure_queue_scale_rule.value.queue_length

        dynamic "authentication" {
          for_each = azure_queue_scale_rule.value.authentication != null ? { default = azure_queue_scale_rule.value.authentication } : {}
          content {
            secret_name       = azure_queue_scale_rule.value.authentication.secret_name
            trigger_parameter = azure_queue_scale_rule.value.authentication.trigger_parameter
          }
        }
      }
    }

    dynamic "custom_scale_rule" {
      for_each = each.value.template.custom_scale_rule != null ? { default = each.value.template.custom_scale_rule } : {}
      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata

        dynamic "authentication" {
          for_each = custom_scale_rule.value.authentication != null ? { default = custom_scale_rule.value.authentication } : {}
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "http_scale_rule" {
      for_each = each.value.template.http_scale_rule != null ? { default = each.value.template.http_scale_rule } : {}
      content {
        name                = http_scale_rule.value.name
        concurrent_requests = http_scale_rule.value.concurrent_requests

        dynamic "authentication" {
          for_each = http_scale_rule.value.authentication != null ? { default = http_scale_rule.value.authentication } : {}
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "tcp_scale_rule" {
      for_each = each.value.template.tcp_scale_rule != null ? { default = each.value.template.tcp_scale_rule } : {}
      content {
        name                = tcp_scale_rule.value.name
        concurrent_requests = tcp_scale_rule.value.concurrent_requests

        dynamic "authentication" {
          for_each = tcp_scale_rule.value.authentication != null ? { default = tcp_scale_rule.value.authentication } : {}
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "volume" {
      for_each = each.value.volume != null ? { default = each.value.volume } : {}
      content {
        name          = volume.value.name
        storage_name  = volume.value.storage_name
        storage_type  = volume.value.storage_type
        mount_options = volume.value.mount_options
      }
    }
  }

  dynamic "ingress" {
    for_each = each.value.ingress != null ? { default = each.value.ingress } : {}

    content {
      allow_insecure_connections = ingress.value.allow_insecure_connections
      external_enabled           = ingress.value.external_enabled
      fqdn                       = ingress.value.fqdn
      target_port                = ingress.value.target_port
      exposed_port               = ingress.value.transport == "tcp" ? ingress.value.exposed_port : null
      transport                  = ingress.value.transport
      client_certificate_mode    = ingress.value.client_certificate_mode


      dynamic "traffic_weight" {
        ## This block only applies when revision_mode is set to Multiple.
        for_each = ingress.value.traffic_weight
        content {
          label           = traffic_weight.value.label
          latest_revision = traffic_weight.value.latest_revision
          percentage      = traffic_weight.value.percentage
          revision_suffix = traffic_weight.value.latest_revision == false ? traffic_weight.value.revision_suffix : null
        }
      }

      dynamic "ip_security_restriction" {
        ## The action types in an all ip_security_restriction blocks must be the same for the ingress, mixing Allow and Deny rules is not currently supported by the service.
        for_each = ingress.value.ip_security_restriction != null ? { default = ingress.value.ip_security_restriction } : {}
        content {
          name             = ip_security_restriction.value.name
          description      = ip_security_restriction.value.description
          action           = ip_security_restriction.value.action
          ip_address_range = ip_security_restriction.value.ip_address_range
        }
      }

      dynamic "cors" {
        for_each = ingress.value.cors != null ? { default = ingress.value.cors } : {}
        content {
          allowed_origins           = cors.value.allowed_origins
          allowed_methods           = cors.value.allowed_methods
          allowed_headers           = cors.value.allowed_headers
          exposed_headers           = cors.value.exposed_headers
          max_age_in_seconds        = cors.value.max_age_in_seconds
          allow_credentials_enabled = cors.value.allow_credentials_enabled
        }
      }
    }
  }

  dynamic "dapr" {
    for_each = each.value.dapr != null ? { default = each.value.dapr } : {}
    content {
      app_id       = dapr.value.app_id
      app_port     = dapr.value.app_port
      app_protocol = dapr.value.app_protocol
    }
  }

  dynamic "registry" {
    for_each = each.value.registry != null ? { default = each.value.registry } : {}
    content {
      server               = registry.value.server
      identity             = registry.value.identity_id
      username             = registry.value.username
      password_secret_name = registry.value.password_secret_name
    }
  }

  dynamic "secret" {
    for_each = each.value.secrets != null ? each.value.secrets : {}
    content {
      name                = secret.key
      value               = secret.value.value
      identity            = secret.value.identity_id
      key_vault_secret_id = secret.value.key_vault_secret_id
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? { default = each.value.identity } : {}
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  tags = coalesce(each.value.tags, var.tags)
}

# Role assignments for ACR pull access when using managed identity
resource "azurerm_role_assignment" "role_acr_pull" {
  for_each = merge(
    {
      for ca_key, ca in lookup(var.environment, "container_apps", {}) : "ca-${ca_key}" => ca
      if ca.identity != null && ca.registry != null && lookup(ca.registry, "role_assignment_enabled", true) == true
    },
    {
      for job_key, job in lookup(var.environment, "jobs", {}) : "job-${job_key}" => job
      if job.identity != null && job.registry != null && lookup(job.registry, "role_assignment_enabled", true) == true
    }
  )

  scope                = each.value.registry.scope
  role_definition_name = "AcrPull"
  principal_id         = each.value.identity.principal_id
}

# Role assignments for Key Vault secret access when using managed identity
resource "azurerm_role_assignment" "role_kv_secrets_user" {
  for_each = merge(
    {
      for ca_key, ca in lookup(var.environment, "container_apps", {}) : "ca-${ca_key}" => ca
      if ca.identity != null && contains(keys(ca), "secrets") && lookup(ca, "key_vault_role_assignment_enabled", true) == true
    },
    {
      for job_key, job in lookup(var.environment, "jobs", {}) : "job-${job_key}" => job
      if job.identity != null && contains(keys(job), "secrets") && lookup(job, "key_vault_role_assignment_enabled", true) == true
    }
  )

  scope                = each.value.key_vault_scope
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.identity.principal_id
}

resource "azurerm_container_app_environment_certificate" "certificate" {
  for_each = merge([
    for ca_key, ca in lookup(var.environment, "container_apps", {}) : {
      for cert_key, cert in(ca.certificates != null ? ca.certificates : {}) : "${ca_key}-${cert_key}" => {
        ca_key                = ca_key
        name                  = cert.name
        key_vault_certificate = cert.key_vault_certificate
        path                  = cert.path
        password              = cert.password
      }
    }
  ]...)

  name                         = each.value.name
  container_app_environment_id = local.environment_id
  certificate_blob_base64      = coalesce(each.value.key_vault_certificate, filebase64(each.value.path))
  certificate_password         = each.value.password

  tags = coalesce(var.environment.tags, var.tags)
}

resource "azurerm_container_app_custom_domain" "domain" {
  for_each = merge([
    for ca_key, ca in lookup(var.environment, "container_apps", {}) : {
      for cert_key, cert in(ca.certificates != null ? ca.certificates : {}) : "${ca_key}-${cert_key}" => {
        ca_key       = ca_key
        fqdn         = cert.fqdn
        binding_type = cert.binding_type
      }
    }
  ]...)

  name                                     = trimprefix(each.value.fqdn, "asuid.")
  container_app_id                         = azurerm_container_app.ca[each.value.ca_key].id
  container_app_environment_certificate_id = azurerm_container_app_environment_certificate.certificate[each.key].id
  certificate_binding_type                 = each.value.binding_type
}



resource "azurerm_container_app_job" "job" {
  for_each = var.environment.jobs != null ? var.environment.jobs : {}

  name                         = coalesce(each.value.name, try("${var.naming.container_app_job}-${each.key}", each.key))
  location                     = coalesce(each.value.location, var.environment.location, var.location)
  resource_group_name          = coalesce(each.value.resource_group_name, var.environment.resource_group_name, var.resource_group_name)
  container_app_environment_id = local.environment_id
  replica_timeout_in_seconds   = each.value.replica_timeout_in_seconds

  workload_profile_name = each.value.workload_profile_name
  replica_retry_limit   = each.value.replica_retry_limit

  template {
    dynamic "init_container" {
      for_each = each.value.template.init_container != null ? { default = each.value.template.init_container } : {}
      content {
        name              = init_container.value.name
        image             = init_container.value.image
        cpu               = init_container.value.cpu
        memory            = init_container.value.memory
        command           = init_container.value.command
        args              = init_container.value.args
        ephemeral_storage = init_container.value.ephemeral_storage
        ## ephemeral_storage is currently in preview and not configurable at this time.

        dynamic "env" {
          for_each = init_container.value.env
          content {
            name        = env.key
            value       = env.value.value
            secret_name = env.value.secret_name
          }
        }

        dynamic "volume_mounts" {
          for_each = init_container.value.volume_mounts != null ? { default = init_container.value.volume_mounts } : {}
          content {
            name     = volume_mounts.value.name
            path     = volume_mounts.value.path
            sub_path = volume_mounts.value.sub_path
          }
        }
      }
    }

    dynamic "container" {
      for_each = each.value.template.container != null ? { default = each.value.template.container } : {}
      content {
        name              = container.value.name
        image             = container.value.image
        cpu               = container.value.cpu
        memory            = container.value.memory
        command           = container.value.command
        args              = container.value.args
        ephemeral_storage = container.value.ephemeral_storage
        ## ephemeral_storage is currently in preview and not configurable at this time.

        dynamic "env" {
          for_each = container.value.env
          content {
            name        = env.key
            value       = env.value.value
            secret_name = env.value.secret_name
          }
        }

        dynamic "volume_mounts" {
          for_each = container.value.volume_mounts != null ? { default = container.value.volume_mounts } : {}
          content {
            name     = volume_mounts.value.name
            path     = volume_mounts.value.path
            sub_path = volume_mounts.value.sub_path
          }
        }

        dynamic "liveness_probe" {
          for_each = container.value.liveness_probe != null ? { default = container.value.liveness_probe } : {}
          content {
            transport                        = liveness_probe.value.transport
            port                             = liveness_probe.value.port
            host                             = liveness_probe.value.host
            failure_count_threshold          = liveness_probe.value.failure_count_threshold
            initial_delay                    = liveness_probe.value.initial_delay
            interval_seconds                 = liveness_probe.value.interval_seconds
            path                             = liveness_probe.value.path
            timeout                          = liveness_probe.value.timeout
            termination_grace_period_seconds = liveness_probe.value.termination_grace_period_seconds

            dynamic "header" {
              for_each = liveness_probe.value.header != null ? [1] : []
              content {
                name  = liveness_probe.value.header.name
                value = liveness_probe.value.header.value
              }
            }
          }
        }

        dynamic "readiness_probe" {
          for_each = container.value.readiness_probe != null ? { default = container.value.readiness_probe } : {}
          content {
            transport               = readiness_probe.value.transport
            port                    = readiness_probe.value.port
            host                    = readiness_probe.value.host
            initial_delay           = readiness_probe.value.initial_delay
            failure_count_threshold = readiness_probe.value.failure_count_threshold
            success_count_threshold = readiness_probe.value.success_count_threshold
            interval_seconds        = readiness_probe.value.interval_seconds
            path                    = readiness_probe.value.path
            timeout                 = readiness_probe.value.timeout

            dynamic "header" {
              for_each = readiness_probe.value.header != null ? [1] : []
              content {
                name  = readiness_probe.value.header.name
                value = readiness_probe.value.header.value
              }
            }
          }
        }

        dynamic "startup_probe" {
          for_each = container.value.startup_probe != null ? { default = container.value.startup_probe } : {}
          content {
            transport                        = startup_probe.value.transport
            port                             = startup_probe.value.port
            host                             = startup_probe.value.host
            initial_delay                    = startup_probe.value.initial_delay
            failure_count_threshold          = startup_probe.value.failure_count_threshold
            interval_seconds                 = startup_probe.value.interval_seconds
            path                             = startup_probe.value.path
            timeout                          = startup_probe.value.timeout
            termination_grace_period_seconds = startup_probe.value.termination_grace_period_seconds

            dynamic "header" {
              for_each = startup_probe.value.header != null ? [1] : []
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
      for_each = each.value.template.volume != null ? { default = each.value.template.volume } : {}
      content {
        name          = volume.value.name
        storage_type  = volume.value.storage_type
        storage_name  = volume.value.storage_name
        mount_options = volume.value.mount_options
      }
    }
  }

  dynamic "registry" {
    for_each = each.value.registry != null ? { default = each.value.registry } : {}
    content {
      server               = registry.value.server
      identity             = registry.value.identity_id
      username             = registry.value.username
      password_secret_name = registry.value.password_secret_name
    }
  }

  dynamic "secret" {
    for_each = each.value.secrets != null ? each.value.secrets : {}
    content {
      name                = secret.key
      value               = secret.value.value
      identity            = secret.value.identity_id
      key_vault_secret_id = secret.value.key_vault_secret_id
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? { default = each.value.identity } : {}
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "manual_trigger_config" {
    for_each = each.value.manual_trigger_config != null ? { default = each.value.manual_trigger_config } : {}
    content {
      parallelism              = manual_trigger_config.value.parallelism
      replica_completion_count = manual_trigger_config.value.replica_completion_count
    }
  }

  dynamic "event_trigger_config" {
    for_each = each.value.event_trigger_config != null ? { default = each.value.event_trigger_config } : {}
    content {
      parallelism              = event_trigger_config.value.parallelism
      replica_completion_count = event_trigger_config.value.replica_completion_count

      dynamic "scale" {
        for_each = event_trigger_config.value.scale != null ? { default = event_trigger_config.value.scale } : {}
        content {
          max_executions              = scale.value.max_executions
          min_executions              = scale.value.min_executions
          polling_interval_in_seconds = scale.value.polling_interval_in_seconds

          dynamic "rules" {
            for_each = scale.value.rules != null ? scale.value.rules : {}
            content {
              name             = rules.value.name
              custom_rule_type = rules.value.custom_rule_type
              metadata         = rules.value.metadata

              dynamic "authentication" {
                for_each = rules.value.authentication != null ? rules.value.authentication : {}
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
    for_each = each.value.schedule_trigger_config != null ? { default = each.value.schedule_trigger_config } : {}
    content {
      parallelism              = schedule_trigger_config.value.parallelism
      replica_completion_count = schedule_trigger_config.value.replica_completion_count
      cron_expression          = schedule_trigger_config.value.cron_expression
    }
  }

  tags = coalesce(each.value.tags, var.tags)
}

