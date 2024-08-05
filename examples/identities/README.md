## Identities
This example highlights the usage for (user-assigned) Managed Identities.
Although System-Assigned Managed Identity is technically supported, it is not recommended to use, see notes further below. 

## Types

```hcl
environment = object({
    name                           = string
    location                       = string
    resourcegroup                  = string


    container_apps = optional(map(object({
        revision_mode         = string
        workload_profile_name = string
        kv_scope              = optional(string)

        template = object({
          min_replicas    = optional(integer)
          max_replicas    = optional(integer)
          revision_suffix = optional(string)

          containers = object(map({
              image = string
              env = object(map({
                secret_name = optional(string)
                value = optional(string)
              }))
          }))
        })

        ingress = optional(object({
          target_port      = integer
          external_enabled = optional(bool, false)
          transport        = optional(string, "auto")
        
          traffic_weight = object(map({
              latest_revision = optional(bool, true)
              percentage      = integer
          }))
        }))

        secrets = optional(object(map({
          value               = optional(string)
          key_vault_secret_id = optional(string)
          kv_scope            = optional(string)
          identity            = optional(object{
                                  name          = string
                                  id            = optional(string)
                                  principal_id  = optional(string)
                              })
        })))

        registry = object({
          server                = string
          username              = optional(stirng)
          password_secret_name  = optional(string)
          scope                 = optional(string)
          identity              = optional(object{
                                    name          = string
                                    id            = optional(string)
                                    principal_id  = optional(string)
                                })
        })
      })))
    })
```


## Notes
System-Assigned Managed Identities: It is technically possible to enable a system-assigned identity for a container app. 
However, role assignment cannot be set if the resource (container app) is not there yet, 
and the container app needs ACR pull permissions to pull the image from the container registry. 
The resource in turn cannot be created as it needs the RBAC permissions for the image retrieval upon initial deployment.
In order to deploy everything in one single Terraform run withou manual intervention, use User-Assigned Managed Identity instead.

User-Assigned Managed Identities: The module generates a user-assigned identity automatically for the secrets retrieval and the registry image retrieval. 
If not specified, the naming will be derived from the naming module, but can be overrriden if explicitly specified. 
In addition, it is also possible to bring your own user-assigned identity from outside of the modules or through a data lookup. 
For this, the (resource) id, principal_id (for role assignments) and name (for TF keys) of the user-assigned identity are needed. 

No Identity for authentication: For testing purposes it is also possible to use the secret value, and ingest this directly but
for production environments it is better to have this key-vault backend scoped which requires an identity for retrieval. 
For the registry, it is also possible to use an (admin) username and password_secret_name (which refers to a secret name set with the 
value of the admin_password of the container registry). The ACR needs admin_enabled property set to enabled.
Again, not recommended for production environments. 