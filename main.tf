data "azurerm_container_app_environment" "this" {
  for_each = var.environment.use_existing ? { "this" = var.environment } : {}

  resource_group_name = coalesce(
    each.value.resource_group_name, var.resource_group_name
  )

  name = each.value.name
}

resource "azurerm_container_app_environment" "this" {
  for_each = var.environment.use_existing ? {} : { "this" = var.environment }

  location = coalesce(
    each.value.location, var.location
  )

  resource_group_name = coalesce(
    each.value.resource_group_name, var.resource_group_name
  )

  ## provider v5 dropped the v4 inference of log-analytics from a set workspace id and now rejects the pair
  logs_destination = each.value.log_analytics_workspace_id != null ? coalesce(
    each.value.logs_destination, "log-analytics"
  ) : each.value.logs_destination

  name                                        = each.value.name
  dapr_application_insights_connection_string = each.value.dapr_application_insights_connection_string
  infrastructure_subnet_id                    = each.value.infrastructure_subnet_id
  infrastructure_resource_group_name          = each.value.infrastructure_resource_group_name
  internal_load_balancer_enabled              = each.value.internal_load_balancer_enabled
  zone_redundancy_enabled                     = each.value.zone_redundancy_enabled
  log_analytics_workspace_id                  = each.value.log_analytics_workspace_id
  mutual_tls_enabled                          = each.value.mutual_tls_enabled
  public_network_access                       = each.value.public_network_access

  dynamic "identity" {
    for_each = each.value.identity != null ? { "this" = each.value.identity } : {}

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

  tags = coalesce(
    each.value.tags, var.tags
  )
}

resource "azurerm_container_app" "this" {
  for_each = var.environment.container_apps

  name = coalesce(
    each.value.name, each.key
  )

  resource_group_name = coalesce(
    each.value.resource_group_name, var.environment.resource_group_name, var.resource_group_name
  )

  container_app_environment_id = var.environment.use_existing ? data.azurerm_container_app_environment.this["this"].id : azurerm_container_app_environment.this["this"].id
  revision_mode                = each.value.revision_mode
  workload_profile_name        = each.value.workload_profile_name
  max_inactive_revisions       = each.value.max_inactive_revisions

  template {
    min_replicas                     = each.value.template.min_replicas
    max_replicas                     = each.value.template.max_replicas
    revision_suffix                  = each.value.template.revision_suffix
    termination_grace_period_seconds = each.value.template.termination_grace_period_seconds
    cooldown_period_in_seconds       = each.value.template.cooldown_period_in_seconds
    polling_interval_in_seconds      = each.value.template.polling_interval_in_seconds

    dynamic "init_container" {
      for_each = each.value.template.init_containers

      content {
        name    = init_container.key
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
          for_each = init_container.value.volume_mounts

          content {
            name     = volume_mounts.key
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
          for_each = container.value.volume_mounts

          content {
            name     = volume_mounts.key
            path     = volume_mounts.value.path
            sub_path = volume_mounts.value.sub_path
          }
        }

        dynamic "liveness_probe" {
          for_each = container.value.liveness_probe != null ? { "this" = container.value.liveness_probe } : {}

          content {
            transport               = liveness_probe.value.transport
            port                    = liveness_probe.value.port
            host                    = liveness_probe.value.host
            failure_count_threshold = liveness_probe.value.failure_count_threshold
            initial_delay           = liveness_probe.value.initial_delay
            interval_seconds        = liveness_probe.value.interval_seconds
            path                    = liveness_probe.value.path
            timeout                 = liveness_probe.value.timeout

            dynamic "header" {
              for_each = liveness_probe.value.headers

              content {
                name  = header.key
                value = header.value.value
              }
            }
          }
        }

        dynamic "readiness_probe" {
          for_each = container.value.readiness_probe != null ? { "this" = container.value.readiness_probe } : {}

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
              for_each = readiness_probe.value.headers

              content {
                name  = header.key
                value = header.value.value
              }
            }
          }
        }

        dynamic "startup_probe" {
          for_each = container.value.startup_probe != null ? { "this" = container.value.startup_probe } : {}

          content {
            transport               = startup_probe.value.transport
            port                    = startup_probe.value.port
            host                    = startup_probe.value.host
            failure_count_threshold = startup_probe.value.failure_count_threshold
            initial_delay           = startup_probe.value.initial_delay
            interval_seconds        = startup_probe.value.interval_seconds
            path                    = startup_probe.value.path
            timeout                 = startup_probe.value.timeout

            dynamic "header" {
              for_each = startup_probe.value.headers

              content {
                name  = header.key
                value = header.value.value
              }
            }
          }
        }
      }
    }

    dynamic "azure_queue_scale_rule" {
      for_each = each.value.template.azure_queue_scale_rules

      content {
        name         = azure_queue_scale_rule.key
        queue_name   = azure_queue_scale_rule.value.queue_name
        queue_length = azure_queue_scale_rule.value.queue_length

        dynamic "authentication" {
          for_each = azure_queue_scale_rule.value.authentication

          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "custom_scale_rule" {
      for_each = each.value.template.custom_scale_rules

      content {
        name             = custom_scale_rule.key
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata
        identity_id      = custom_scale_rule.value.identity_id

        dynamic "authentication" {
          for_each = custom_scale_rule.value.authentication

          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "http_scale_rule" {
      for_each = each.value.template.http_scale_rules

      content {
        name                = http_scale_rule.key
        concurrent_requests = http_scale_rule.value.concurrent_requests

        dynamic "authentication" {
          for_each = http_scale_rule.value.authentication

          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "tcp_scale_rule" {
      for_each = each.value.template.tcp_scale_rules

      content {
        name                = tcp_scale_rule.key
        concurrent_requests = tcp_scale_rule.value.concurrent_requests

        dynamic "authentication" {
          for_each = tcp_scale_rule.value.authentication

          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "volume" {
      for_each = each.value.template.volumes

      content {
        name          = volume.key
        storage_name  = volume.value.storage_name
        storage_type  = volume.value.storage_type
        mount_options = volume.value.mount_options
      }
    }
  }

  dynamic "ingress" {
    for_each = each.value.ingress != null ? { "this" = each.value.ingress } : {}

    content {
      allow_insecure_connections = ingress.value.allow_insecure_connections
      external_enabled           = ingress.value.external_enabled
      fqdn                       = ingress.value.fqdn
      target_port                = ingress.value.target_port
      exposed_port               = ingress.value.transport == "tcp" ? ingress.value.exposed_port : null
      transport                  = ingress.value.transport
      client_certificate_mode    = ingress.value.client_certificate_mode


      dynamic "traffic_weight" {
        for_each = ingress.value.traffic_weight

        content {
          label           = traffic_weight.value.label
          latest_revision = traffic_weight.value.latest_revision
          percentage      = traffic_weight.value.percentage
          revision_suffix = traffic_weight.value.latest_revision == false ? traffic_weight.value.revision_suffix : null
        }
      }

      dynamic "ip_security_restriction" {
        for_each = ingress.value.ip_security_restrictions

        content {
          name             = ip_security_restriction.key
          description      = ip_security_restriction.value.description
          action           = ip_security_restriction.value.action
          ip_address_range = ip_security_restriction.value.ip_address_range
        }
      }

      dynamic "cors" {
        for_each = ingress.value.cors != null ? { "this" = ingress.value.cors } : {}

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
    for_each = each.value.dapr != null ? { "this" = each.value.dapr } : {}

    content {
      app_id       = dapr.value.app_id
      app_port     = dapr.value.app_port
      app_protocol = dapr.value.app_protocol
    }
  }

  dynamic "registry" {
    for_each = each.value.registries

    content {
      server               = registry.value.server
      identity             = registry.value.identity
      username             = registry.value.username
      password_secret_name = registry.value.password_secret_name
    }
  }

  dynamic "secret" {
    for_each = each.value.secrets

    content {
      name                = secret.key
      value               = secret.value.value
      identity            = secret.value.identity
      key_vault_secret_id = secret.value.key_vault_secret_id
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? { "this" = each.value.identity } : {}

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  tags = coalesce(each.value.tags, var.tags)
}

resource "azurerm_role_assignment" "this" {
  for_each = local.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition
  principal_id         = each.value.principal_id
}

resource "azurerm_container_app_environment_certificate" "this" {
  for_each = merge([
    for ca_key, ca in var.environment.container_apps : {
      for cert_key, cert in ca.certificates :
      "${ca_key}-${cert_key}" => {
        ca_key                = ca_key
        cert_key              = cert_key
        name                  = cert.name
        certificate_path      = cert.certificate_path
        certificate_key_vault = cert.certificate_key_vault
        password              = cert.password
      }
    }
  ]...)

  name = coalesce(
    each.value.name, each.value.cert_key
  )

  container_app_environment_id = var.environment.use_existing ? data.azurerm_container_app_environment.this["this"].id : azurerm_container_app_environment.this["this"].id
  certificate_blob_base64      = each.value.certificate_path != null ? filebase64(each.value.certificate_path) : null
  certificate_password         = each.value.certificate_path != null ? each.value.password : null

  dynamic "certificate_key_vault" {
    for_each = each.value.certificate_key_vault != null ? { "this" = each.value.certificate_key_vault } : {}

    content {
      identity            = certificate_key_vault.value.identity
      key_vault_secret_id = certificate_key_vault.value.key_vault_secret_id
    }
  }

  tags = coalesce(
    var.environment.tags, var.tags
  )
}

resource "azurerm_container_app_custom_domain" "this" {
  for_each = merge([
    for ca_key, ca in var.environment.container_apps : {
      for cert_key, cert in ca.certificates :
      "${ca_key}-${cert_key}" => {
        ca_key       = ca_key
        fqdn         = cert.fqdn
        binding_type = cert.binding_type
      } if cert.fqdn != null
    }
  ]...)

  name = trimprefix(
    each.value.fqdn, "asuid."
  )

  container_app_id                         = azurerm_container_app.this[each.value.ca_key].id
  container_app_environment_certificate_id = azurerm_container_app_environment_certificate.this[each.key].id
  certificate_binding_type                 = each.value.binding_type
}



resource "azurerm_container_app_job" "this" {
  for_each = var.environment.jobs

  name = coalesce(
    each.value.name, each.key
  )

  location = coalesce(
    each.value.location, var.environment.location, var.location
  )

  resource_group_name = coalesce(
    each.value.resource_group_name, var.environment.resource_group_name, var.resource_group_name
  )

  container_app_environment_id = var.environment.use_existing ? data.azurerm_container_app_environment.this["this"].id : azurerm_container_app_environment.this["this"].id
  replica_timeout_in_seconds   = each.value.replica_timeout_in_seconds
  workload_profile_name        = each.value.workload_profile_name
  replica_retry_limit          = each.value.replica_retry_limit

  template {
    dynamic "init_container" {
      for_each = each.value.template.init_containers

      content {
        name              = init_container.key
        image             = init_container.value.image
        cpu               = init_container.value.cpu
        memory            = init_container.value.memory
        command           = init_container.value.command
        args              = init_container.value.args
        ephemeral_storage = init_container.value.ephemeral_storage

        dynamic "env" {
          for_each = init_container.value.env

          content {
            name        = env.key
            value       = env.value.value
            secret_name = env.value.secret_name
          }
        }

        dynamic "volume_mounts" {
          for_each = init_container.value.volume_mounts

          content {
            name     = volume_mounts.key
            path     = volume_mounts.value.path
            sub_path = volume_mounts.value.sub_path
          }
        }
      }
    }

    dynamic "container" {
      for_each = each.value.template.containers

      content {
        name              = container.key
        image             = container.value.image
        cpu               = container.value.cpu
        memory            = container.value.memory
        command           = container.value.command
        args              = container.value.args
        ephemeral_storage = container.value.ephemeral_storage

        dynamic "env" {
          for_each = container.value.env

          content {
            name        = env.key
            value       = env.value.value
            secret_name = env.value.secret_name
          }
        }

        dynamic "volume_mounts" {
          for_each = container.value.volume_mounts

          content {
            name     = volume_mounts.key
            path     = volume_mounts.value.path
            sub_path = volume_mounts.value.sub_path
          }
        }

        dynamic "liveness_probe" {
          for_each = container.value.liveness_probe != null ? { "this" = container.value.liveness_probe } : {}

          content {
            transport               = liveness_probe.value.transport
            port                    = liveness_probe.value.port
            host                    = liveness_probe.value.host
            failure_count_threshold = liveness_probe.value.failure_count_threshold
            initial_delay           = liveness_probe.value.initial_delay
            interval_seconds        = liveness_probe.value.interval_seconds
            path                    = liveness_probe.value.path
            timeout                 = liveness_probe.value.timeout

            dynamic "header" {
              for_each = liveness_probe.value.headers

              content {
                name  = header.key
                value = header.value.value
              }
            }
          }
        }

        dynamic "readiness_probe" {
          for_each = container.value.readiness_probe != null ? { "this" = container.value.readiness_probe } : {}

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
              for_each = readiness_probe.value.headers

              content {
                name  = header.key
                value = header.value.value
              }
            }
          }
        }

        dynamic "startup_probe" {
          for_each = container.value.startup_probe != null ? { "this" = container.value.startup_probe } : {}

          content {
            transport               = startup_probe.value.transport
            port                    = startup_probe.value.port
            host                    = startup_probe.value.host
            initial_delay           = startup_probe.value.initial_delay
            failure_count_threshold = startup_probe.value.failure_count_threshold
            interval_seconds        = startup_probe.value.interval_seconds
            path                    = startup_probe.value.path
            timeout                 = startup_probe.value.timeout

            dynamic "header" {
              for_each = startup_probe.value.headers

              content {
                name  = header.key
                value = header.value.value
              }
            }
          }
        }
      }
    }

    dynamic "volume" {
      for_each = each.value.template.volumes

      content {
        name          = volume.key
        storage_type  = volume.value.storage_type
        storage_name  = volume.value.storage_name
        mount_options = volume.value.mount_options
      }
    }
  }

  dynamic "registry" {
    for_each = each.value.registries

    content {
      server               = registry.value.server
      identity             = registry.value.identity
      username             = registry.value.username
      password_secret_name = registry.value.password_secret_name
    }
  }

  dynamic "secret" {
    for_each = each.value.secrets

    content {
      name                = secret.key
      value               = secret.value.value
      identity            = secret.value.identity
      key_vault_secret_id = secret.value.key_vault_secret_id
    }
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? { "this" = each.value.identity } : {}

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "manual_trigger_config" {
    for_each = each.value.manual_trigger_config != null ? { "this" = each.value.manual_trigger_config } : {}

    content {
      parallelism              = manual_trigger_config.value.parallelism
      replica_completion_count = manual_trigger_config.value.replica_completion_count
    }
  }

  dynamic "event_trigger_config" {
    for_each = each.value.event_trigger_config != null ? { "this" = each.value.event_trigger_config } : {}

    content {
      parallelism              = event_trigger_config.value.parallelism
      replica_completion_count = event_trigger_config.value.replica_completion_count

      dynamic "scale" {
        for_each = event_trigger_config.value.scale != null ? { "this" = event_trigger_config.value.scale } : {}

        content {
          max_executions              = scale.value.max_executions
          min_executions              = scale.value.min_executions
          polling_interval_in_seconds = scale.value.polling_interval_in_seconds

          dynamic "rules" {
            for_each = scale.value.rules

            content {
              name             = rules.key
              custom_rule_type = rules.value.custom_rule_type
              metadata         = rules.value.metadata
              identity_id      = rules.value.identity_id

              dynamic "authentication" {
                for_each = rules.value.authentication

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
    for_each = each.value.schedule_trigger_config != null ? { "this" = each.value.schedule_trigger_config } : {}

    content {
      parallelism              = schedule_trigger_config.value.parallelism
      replica_completion_count = schedule_trigger_config.value.replica_completion_count
      cron_expression          = schedule_trigger_config.value.cron_expression
    }
  }

  tags = coalesce(
    each.value.tags, var.tags
  )
}

locals {
  workloads = merge(
    {
      for ca_key, ca in var.environment.container_apps : "ca-${ca_key}" => {
        identity                          = ca.identity
        registries                        = ca.registries
        secrets                           = ca.secrets
        key_vault_scope                   = ca.key_vault_scope
        key_vault_role_assignment_enabled = ca.key_vault_role_assignment_enabled
      }
    },
    {
      for job_key, job in var.environment.jobs : "job-${job_key}" => {
        identity                          = job.identity
        registries                        = job.registries
        secrets                           = job.secrets
        key_vault_scope                   = job.key_vault_scope
        key_vault_role_assignment_enabled = job.key_vault_role_assignment_enabled
      }
    }
  )

  role_assignments = merge(
    {
      for pair in flatten([
        for wl_key, wl in local.workloads : [
          for reg_key, reg in wl.registries : {
            key          = "acr-${wl_key}-${reg_key}"
            scope        = reg.scope
            principal_id = wl.identity.principal_id
          } if wl.identity != null && reg.role_assignment_enabled
        ]
        ]) : pair.key => {
        scope           = pair.scope
        role_definition = "AcrPull"
        principal_id    = pair.principal_id
      }
    },
    {
      for wl_key, wl in local.workloads : "kv-${wl_key}" => {
        scope           = wl.key_vault_scope
        role_definition = "Key Vault Secrets User"
        principal_id    = wl.identity.principal_id
      } if wl.identity != null && length(wl.secrets) > 0 && wl.key_vault_role_assignment_enabled
    }
  )
}
