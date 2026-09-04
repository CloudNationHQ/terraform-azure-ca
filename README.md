# Container Apps

This terraform module automates the creation of container app resources on the azure cloud platform, enabling easier deployment and management of container apps within a container app environment.

## Features

Provides support for retrieval of container images from the registry using user-assigned identities

Provides support for secrets to retrieve from a key vault backend scope

Offers possibility to integrate the container app environment to your own vnet (vnet integration)

Allows for ingress to be set to external (limited to container app environment), limited to the vnet or wide open

Facilitates the use of custom domain names for your container apps

Provides support for certificates for custom domain names

Allows for multiple container apps to be deployed within a container app environment

Enables multiple container app jobs

Utilization of terratest for robust validation

<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 5.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 5.0)

## Resources

The following resources are used by this module:

- [azurerm_container_app.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) (resource)
- [azurerm_container_app_custom_domain.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_custom_domain) (resource)
- [azurerm_container_app_environment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) (resource)
- [azurerm_container_app_environment_certificate.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment_certificate) (resource)
- [azurerm_container_app_job.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_job) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_container_app_environment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/container_app_environment) (data source)

## Required Inputs

The following input variables are required:

### <a name="input_environment"></a> [environment](#input\_environment)

Description: contains container apps environment configuration

Type:

```hcl
object({
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
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_location"></a> [location](#input\_location)

Description: default azure region to be used.

Type: `string`

Default: `null`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: default resource group to be used.

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: tags to be added to the resources

Type: `map(string)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_certificates"></a> [certificates](#output\_certificates)

Description: contains all container app environment certificate(s) configuration

### <a name="output_container_app_jobs"></a> [container\_app\_jobs](#output\_container\_app\_jobs)

Description: contains all container app jobs configuration

### <a name="output_container_apps"></a> [container\_apps](#output\_container\_apps)

Description: contains all container app(s) configuration

### <a name="output_custom_domains"></a> [custom\_domains](#output\_custom\_domains)

Description: contains all container app custom domain(s) configuration

### <a name="output_environment"></a> [environment](#output\_environment)

Description: contains all container app environment configuration
<!-- END_TF_DOCS -->

## Goals

For more information, please see our [goals and non-goals](./GOALS.md).

## Testing

For more information, please see our testing [guidelines](./TESTING.md)

## Notes

Using a dedicated module, we've developed a naming convention for resources that's based on specific regular expressions for each type, ensuring correct abbreviations and offering flexibility with multiple prefixes and suffixes.

Full examples detailing all usages, along with integrations with dependency modules, are located in the examples directory.

To update the module's documentation run `make doc`

## Contributors

We welcome contributions from the community! Whether it's reporting a bug, suggesting a new feature, or submitting a pull request, your input is highly valued.

For more information, please see our contribution [guidelines](./CONTRIBUTING.md).

## License

MIT Licensed. See [LICENSE](./LICENSE) for full details.

## References

- [Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Rest Api](https://learn.microsoft.com/en-us/rest/api/containerapps/)
