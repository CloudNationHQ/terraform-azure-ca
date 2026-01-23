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
    mutual_tls_enabled                          = optional(bool, false)
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
        init_container = optional(object({
          name    = string
          image   = string
          cpu     = optional(number, 0.25)
          memory  = optional(string, "0.5Gi")
          command = optional(list(string), [])
          args    = optional(list(string), [])
          env = optional(map(object({
            value       = optional(string)
            secret_name = optional(string)
          })), {})
          volume_mounts = optional(object({
            name     = string
            path     = string
            sub_path = optional(string)
          }))
        }))
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
          volume_mounts = optional(object({
            name     = string
            path     = string
            sub_path = optional(string)
          }))
          liveness_probe = optional(object({
            transport                        = optional(string, "HTTPS")
            port                             = number
            host                             = optional(string)
            failure_count_threshold          = optional(number, 3)
            initial_delay                    = optional(number, 30)
            interval_seconds                 = optional(number, 10)
            path                             = optional(string, "/")
            timeout                          = optional(number, 1)
            termination_grace_period_seconds = optional(number)
            header = optional(object({
              name  = string
              value = string
            }))
          }))
          readiness_probe = optional(object({
            transport               = optional(string, "HTTPS")
            port                    = number
            host                    = optional(string)
            initial_delay           = optional(number, 0)
            failure_count_threshold = optional(number, 3)
            success_count_threshold = optional(number, 3)
            interval_seconds        = optional(number, 10)
            path                    = optional(string, "/")
            timeout                 = optional(number, 1)
            header = optional(object({
              name  = string
              value = string
            }))
          }))
          startup_probe = optional(object({
            transport                        = optional(string, "HTTPS")
            port                             = number
            host                             = optional(string)
            failure_count_threshold          = optional(number, 3)
            initial_delay                    = optional(number, 0)
            interval_seconds                 = optional(number, 10)
            path                             = optional(string, "/")
            timeout                          = optional(number, 1)
            termination_grace_period_seconds = optional(number)
            header = optional(object({
              name  = string
              value = string
            }))
          }))
        }))
        azure_queue_scale_rule = optional(object({
          name         = string
          queue_name   = string
          queue_length = number
          authentication = map(object({
            secret_name       = string
            trigger_parameter = string
          }))
        }))
        custom_scale_rule = optional(object({
          name             = string
          custom_rule_type = string
          metadata         = map(string)
          authentication = optional(map(object({
            secret_name       = string
            trigger_parameter = string
          })))
        }))
        http_scale_rule = optional(object({
          name                = string
          concurrent_requests = number
          authentication = optional(map(object({
            secret_name       = string
            trigger_parameter = string
          })))
        }))
        tcp_scale_rule = optional(object({
          name                = string
          concurrent_requests = number
          authentication = optional(map(object({
            secret_name       = string
            trigger_parameter = string
          })))
        }))
      })
      volume = optional(object({
        name          = string
        storage_name  = optional(string)
        storage_type  = optional(string)
        mount_options = optional(string)
      }))
      ingress = optional(object({
        allow_insecure_connections = optional(bool, false)
        external_enabled           = optional(bool, false)
        fqdn                       = optional(string)
        target_port                = number
        exposed_port               = optional(number)
        transport                  = optional(string, "auto")
        client_certificate_mode    = optional(string)
        traffic_weight = optional(map(object({
          label           = optional(string)
          latest_revision = optional(bool, true)
          percentage      = optional(number, 100)
          revision_suffix = optional(string)
        })), {})
        ip_security_restriction = optional(object({
          name             = optional(string)
          description      = optional(string)
          action           = string
          ip_address_range = string
        }))
        cors = optional(object({
          allowed_origins           = set(string)
          allowed_methods           = optional(set(string))
          allowed_headers           = optional(set(string))
          exposed_headers           = optional(set(string))
          max_age_in_seconds        = optional(number)
          allow_credentials_enabled = optional(bool, false)
        }))
      }))
      dapr = optional(object({
        app_id       = string
        app_port     = optional(number)
        app_protocol = optional(string, "http")
      }))
      registry = optional(object({
        server                  = string
        identity_id             = optional(string)
        username                = optional(string)
        password_secret_name    = optional(string)
        scope                   = optional(string)
        role_assignment_enabled = optional(bool, true)
      }))
      key_vault_scope                   = optional(string)
      key_vault_role_assignment_enabled = optional(bool, true)
      secrets = optional(map(object({
        value               = optional(string)
        identity_id         = optional(string)
        key_vault_secret_id = optional(string)
      })))
      identity = optional(object({
        type         = optional(string, "UserAssigned")
        identity_ids = list(string)
        principal_id = optional(string)
      }))
      certificates = optional(map(object({
        fqdn             = optional(string)
        binding_type     = optional(string)
        name             = optional(string)
        path             = optional(string)
        password         = optional(string, "")
        certificate_path = optional(string)
        key_vault_certificate = optional(object({
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
        init_container = optional(object({
          name              = string
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
          volume_mounts = optional(object({
            name     = string
            path     = string
            sub_path = optional(string)
          }))
        }))
        container = optional(object({
          name              = string
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
          volume_mounts = optional(object({
            name     = string
            path     = string
            sub_path = optional(string)
          }))
          liveness_probe = optional(object({
            transport                        = optional(string, "HTTPS")
            port                             = number
            host                             = optional(string)
            failure_count_threshold          = optional(number, 3)
            initial_delay                    = optional(number, 30)
            interval_seconds                 = optional(number, 10)
            path                             = optional(string, "/")
            timeout                          = optional(number, 1)
            termination_grace_period_seconds = optional(number)
            header = optional(object({
              name  = string
              value = string
            }))
          }))
          readiness_probe = optional(object({
            transport               = optional(string, "HTTPS")
            port                    = number
            host                    = optional(string)
            initial_delay           = optional(number, 0)
            failure_count_threshold = optional(number, 3)
            success_count_threshold = optional(number, 3)
            interval_seconds        = optional(number, 10)
            path                    = optional(string, "/")
            timeout                 = optional(number, 1)
            header = optional(object({
              name  = string
              value = string
            }))
          }))
          startup_probe = optional(object({
            transport                        = optional(string, "HTTPS")
            port                             = number
            host                             = optional(string)
            initial_delay                    = optional(number, 0)
            failure_count_threshold          = optional(number, 3)
            interval_seconds                 = optional(number, 10)
            path                             = optional(string, "/")
            timeout                          = optional(number, 1)
            termination_grace_period_seconds = optional(number)
            header = optional(object({
              name  = string
              value = string
            }))
          }))
        }))
        volume = optional(object({
          name          = string
          storage_type  = optional(string)
          storage_name  = optional(string)
          mount_options = optional(string)
        }))
      })
      registry = optional(object({
        server                  = string
        identity_id             = optional(string)
        username                = optional(string)
        password_secret_name    = optional(string)
        scope                   = optional(string)
        role_assignment_enabled = optional(bool, true)
      }))
      key_vault_scope                   = optional(string)
      key_vault_role_assignment_enabled = optional(bool, true)
      secrets = optional(map(object({
        value               = optional(string)
        identity_id         = optional(string)
        key_vault_secret_id = optional(string)
      })))
      identity = optional(object({
        type         = optional(string, "UserAssigned")
        identity_ids = list(string)
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
            name             = optional(string)
            custom_rule_type = optional(string)
            metadata         = optional(map(string), {})
            authentication = optional(map(object({
              trigger_parameter = string
              secret_name       = string
            })))
          })))
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

variable "naming" {
  description = "contains naming convention"
  type        = map(string)
  default     = {}
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
