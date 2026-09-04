variable "environment" {
  description = "contains container apps environment configuration"
  type = object({
    name                                        = string
    location                                    = optional(string)
    resource_group_name                         = optional(string)
    use_existing                                = optional(bool, false)
    dapr_application_insights_connection_string = optional(string)
    infrastructure_subnet_id                    = optional(string)
    infrastructure_resource_group_name          = optional(string)
    internal_load_balancer_enabled              = optional(bool)
    zone_redundancy_enabled                     = optional(bool)
    public_network_access                       = optional(string)
    log_analytics_workspace_id                  = optional(string)
    logs_destination                            = optional(string)
    mutual_tls_enabled                          = optional(bool)
    tags                                        = optional(map(string))
    identity = optional(object({
      type         = string
      identity_ids = optional(set(string))
    }))
    workload_profile = optional(map(object({
      name                  = string
      workload_profile_type = string
      maximum_count         = number
      minimum_count         = number
    })), {})
    role_assignments = optional(map(object({
      scope                                  = string
      principal_id                           = string
      name                                   = optional(string)
      role_definition_name                   = optional(string)
      role_definition_id                     = optional(string)
      description                            = optional(string)
      principal_type                         = optional(string)
      condition                              = optional(string)
      condition_version                      = optional(string)
      delegated_managed_identity_resource_id = optional(string)
      skip_service_principal_aad_check       = optional(bool)
    })), {})
    container_apps = optional(map(object({
      name                   = optional(string)
      resource_group_name    = optional(string)
      revision_mode          = optional(string, "Single")
      workload_profile_name  = optional(string)
      max_inactive_revisions = optional(number)
      tags                   = optional(map(string))
      template = object({
        min_replicas                     = optional(number, 1)
        max_replicas                     = optional(number, 1)
        revision_suffix                  = optional(string)
        termination_grace_period_seconds = optional(number)
        cooldown_period_in_seconds       = optional(number)
        polling_interval_in_seconds      = optional(number)
        init_containers = optional(map(object({
          image   = string
          cpu     = optional(number, 0.25)
          memory  = optional(string, "0.5Gi")
          command = optional(list(string), [])
          args    = optional(list(string), [])
          env = optional(map(object({
            value       = optional(string)
            secret_name = optional(string)
          })), {})
          volume_mounts = optional(map(object({
            path     = string
            sub_path = optional(string)
          })), {})
        })), {})
        containers = map(object({
          image   = string
          cpu     = optional(number, 0.25)
          memory  = optional(string, "0.5Gi")
          command = optional(list(string))
          args    = optional(list(string))
          env = optional(map(object({
            value       = optional(string)
            secret_name = optional(string)
          })), {})
          volume_mounts = optional(map(object({
            path     = string
            sub_path = optional(string)
          })), {})
          liveness_probe = optional(object({
            transport               = optional(string)
            port                    = number
            host                    = optional(string)
            failure_count_threshold = optional(number)
            initial_delay           = optional(number)
            interval_seconds        = optional(number)
            path                    = optional(string)
            timeout                 = optional(number)
            headers = optional(map(object({
              value = string
            })), {})
          }))
          readiness_probe = optional(object({
            transport               = optional(string)
            port                    = number
            host                    = optional(string)
            initial_delay           = optional(number)
            failure_count_threshold = optional(number)
            success_count_threshold = optional(number)
            interval_seconds        = optional(number)
            path                    = optional(string)
            timeout                 = optional(number)
            headers = optional(map(object({
              value = string
            })), {})
          }))
          startup_probe = optional(object({
            transport               = optional(string)
            port                    = number
            host                    = optional(string)
            failure_count_threshold = optional(number)
            initial_delay           = optional(number)
            interval_seconds        = optional(number)
            path                    = optional(string)
            timeout                 = optional(number)
            headers = optional(map(object({
              value = string
            })), {})
          }))
        }))
        azure_queue_scale_rules = optional(map(object({
          queue_name   = string
          queue_length = number
          authentication = map(object({
            secret_name       = string
            trigger_parameter = string
          }))
        })), {})
        custom_scale_rules = optional(map(object({
          custom_rule_type = string
          metadata         = map(string)
          identity_id      = optional(string)
          authentication = optional(map(object({
            secret_name       = string
            trigger_parameter = string
          })), {})
        })), {})
        http_scale_rules = optional(map(object({
          concurrent_requests = number
          authentication = optional(map(object({
            secret_name       = string
            trigger_parameter = string
          })), {})
        })), {})
        tcp_scale_rules = optional(map(object({
          concurrent_requests = number
          authentication = optional(map(object({
            secret_name       = string
            trigger_parameter = string
          })), {})
        })), {})
        volumes = optional(map(object({
          storage_name  = optional(string)
          storage_type  = optional(string)
          mount_options = optional(string)
        })), {})
      })
      ingress = optional(object({
        allow_insecure_connections = optional(bool, false)
        external_enabled           = optional(bool)
        fqdn                       = optional(string)
        target_port                = number
        exposed_port               = optional(number)
        transport                  = optional(string)
        client_certificate_mode    = optional(string)
        traffic_weight = optional(map(object({
          label           = optional(string)
          latest_revision = optional(bool, true)
          percentage      = optional(number, 100)
          revision_suffix = optional(string)
        })), {})
        ip_security_restrictions = optional(map(object({
          description      = optional(string)
          action           = string
          ip_address_range = string
        })), {})
        cors = optional(object({
          allowed_origins           = set(string)
          allowed_methods           = optional(set(string))
          allowed_headers           = optional(set(string))
          exposed_headers           = optional(set(string))
          max_age_in_seconds        = optional(number)
          allow_credentials_enabled = optional(bool)
        }))
      }))
      dapr = optional(object({
        app_id       = string
        app_port     = optional(number)
        app_protocol = optional(string)
      }))
      registries = optional(map(object({
        server               = string
        identity             = optional(string)
        username             = optional(string)
        password_secret_name = optional(string)
      })), {})
      secrets = optional(map(object({
        value               = optional(string)
        identity            = optional(string)
        key_vault_secret_id = optional(string)
      })), {})
      identity = optional(object({
        type         = optional(string, "UserAssigned")
        identity_ids = optional(list(string))
        principal_id = optional(string)
      }))
      certificates = optional(map(object({
        fqdn             = optional(string)
        binding_type     = optional(string)
        name             = optional(string)
        password         = optional(string, "")
        certificate_path = optional(string)
        certificate_key_vault = optional(object({
          identity            = optional(string)
          key_vault_secret_id = string
        }))
      })), {})
    })), {})
    jobs = optional(map(object({
      name                       = optional(string)
      location                   = optional(string)
      resource_group_name        = optional(string)
      replica_timeout_in_seconds = number
      workload_profile_name      = optional(string)
      replica_retry_limit        = optional(number)
      tags                       = optional(map(string))
      template = object({
        init_containers = optional(map(object({
          image             = string
          cpu               = optional(number, 0.25)
          memory            = optional(string, "0.5Gi")
          command           = optional(list(string), [])
          args              = optional(list(string), [])
          ephemeral_storage = optional(string)
          env = optional(map(object({
            value       = optional(string)
            secret_name = optional(string)
          })), {})
          volume_mounts = optional(map(object({
            path     = string
            sub_path = optional(string)
          })), {})
        })), {})
        containers = map(object({
          image             = string
          cpu               = optional(number, 0.25)
          memory            = optional(string, "0.5Gi")
          command           = optional(list(string))
          args              = optional(list(string))
          ephemeral_storage = optional(string)
          env = optional(map(object({
            value       = optional(string)
            secret_name = optional(string)
          })), {})
          volume_mounts = optional(map(object({
            path     = string
            sub_path = optional(string)
          })), {})
          liveness_probe = optional(object({
            transport               = optional(string)
            port                    = number
            host                    = optional(string)
            failure_count_threshold = optional(number)
            initial_delay           = optional(number)
            interval_seconds        = optional(number)
            path                    = optional(string)
            timeout                 = optional(number)
            headers = optional(map(object({
              value = string
            })), {})
          }))
          readiness_probe = optional(object({
            transport               = optional(string)
            port                    = number
            host                    = optional(string)
            initial_delay           = optional(number)
            failure_count_threshold = optional(number)
            success_count_threshold = optional(number)
            interval_seconds        = optional(number)
            path                    = optional(string)
            timeout                 = optional(number)
            headers = optional(map(object({
              value = string
            })), {})
          }))
          startup_probe = optional(object({
            transport               = optional(string)
            port                    = number
            host                    = optional(string)
            initial_delay           = optional(number)
            failure_count_threshold = optional(number)
            interval_seconds        = optional(number)
            path                    = optional(string)
            timeout                 = optional(number)
            headers = optional(map(object({
              value = string
            })), {})
          }))
        }))
        volumes = optional(map(object({
          storage_type  = optional(string)
          storage_name  = optional(string)
          mount_options = optional(string)
        })), {})
      })
      registries = optional(map(object({
        server               = string
        identity             = optional(string)
        username             = optional(string)
        password_secret_name = optional(string)
      })), {})
      secrets = optional(map(object({
        value               = optional(string)
        identity            = optional(string)
        key_vault_secret_id = optional(string)
      })), {})
      identity = optional(object({
        type         = optional(string, "UserAssigned")
        identity_ids = optional(list(string))
        principal_id = optional(string)
      }))
      manual_trigger_config = optional(object({
        parallelism              = optional(number)
        replica_completion_count = optional(number)
      }))
      event_trigger_config = optional(object({
        parallelism              = optional(number)
        replica_completion_count = optional(number)
        scale = optional(object({
          max_executions              = optional(number)
          min_executions              = optional(number)
          polling_interval_in_seconds = optional(number)
          rules = optional(map(object({
            custom_rule_type = optional(string)
            metadata         = optional(map(string), {})
            identity_id      = optional(string)
            authentication = optional(map(object({
              trigger_parameter = string
              secret_name       = string
            })), {})
          })), {})
        }))
      }))
      schedule_trigger_config = optional(object({
        parallelism              = optional(number)
        replica_completion_count = optional(number)
        cron_expression          = string
      }))
    })), {})
  })

  validation {
    condition     = var.environment.location != null || var.location != null
    error_message = "location must be provided either in the environment object or as a separate variable."
  }

  validation {
    condition     = var.environment.resource_group_name != null || var.resource_group_name != null
    error_message = "resource group name must be provided either in the environment object or as a separate variable."
  }
}

variable "location" {
  description = "default azure region to be used."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "default resource group to be used."
  type        = string
  default     = null
}

variable "tags" {
  description = "tags to be added to the resources"
  type        = map(string)
  default     = {}
}
