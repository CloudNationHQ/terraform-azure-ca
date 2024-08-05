locals {
  user_assigned_identities_secrets = flatten([for ca_key, ca in lookup(var.environment, "container_apps", {}) :
    [for sec_key, sec in lookup(ca, "secrets", {}) :
      {
        ca_name             = ca_key
        name                = try(sec.name, sec_key)
        key_vault_secret_id = try(sec.key_vault_secret_id, null)
        kv_scope            = try(sec.kv_scope, ca.kv_scope)
        principal_id        = try(sec.identity.principal_id, null)
        identity_id         = lookup(lookup(sec, "identity", {}), "id", {})
        id_name             = try(sec.identity.name, "${var.naming.user_assigned_identity}-${ca_key}")
        resourcegroup       = try(sec.identity.resourcegroup, var.environment.resourcegroup, null)
        location            = try(sec.identity.location, var.environment.location, null)
        tags                = try(sec.identity.tags, {})
        type                = try(sec.identity.type, "UserAssigned")
      }
  if contains(keys(sec), "value") == false]])

  user_assigned_identity_registry = flatten([for ca_key, ca in lookup(var.environment, "container_apps", {}) :
    {
      ca_name       = ca_key
      scope         = try(ca.registry.scope, null)
      server        = ca.registry.server
      principal_id  = try(ca.registry.identity.principal_id, null)
      identity_id   = lookup(lookup(ca.registry, "identity", {}), "id", {})
      id_name       = try(ca.registry.identity.name, "${var.naming.user_assigned_identity}-${ca_key}")
      resourcegroup = try(ca.registry.identity.resourcegroup, var.environment.resourcegroup, null)
      location      = try(ca.registry.identity.location, var.environment.location, null)
      tags          = try(ca.registry.identity.tags, {})
      type          = try(ca.registry.identity.type, "UserAssigned")
      # SystemAssigned MI not recommended due to chicken-egg problem:
      # CA can't be deployed without image, image can't be pulled without identity, identity can't be created without CA
    }
  if contains(keys(ca.registry), "username") == false])

  ## Multiple user assigned identities with the same name are implicitly generated when multiple secrets are defined
  ## To avoid this, we create a list of unique identity names and then create a map of identity objects
  unique_uai_secrets     = distinct([for identity in local.user_assigned_identities_secrets : identity.id_name])
  unique_uai_secrets_map = { for name in local.unique_uai_secrets : name => [for identity in local.user_assigned_identities_secrets : identity if identity.id_name == name][0] }


  ## Merge all identities, including those with identity_id (Bring Your Own UAI) - needed to set identity_ids in identity block
  merged_identities_all = merge(
    { for identity in local.unique_uai_secrets_map : identity.id_name => identity },
    { for identity in local.user_assigned_identity_registry : identity.id_name => identity }
  )

  ## Merge all identities, except those with identity_id (Bring Your Own UAI) - needed to generate User Assigned Identities
  merged_identities_filtered = merge(
    { for identity in local.unique_uai_secrets_map : identity.id_name => identity if identity.identity_id == {} },
    { for identity in local.user_assigned_identity_registry : identity.id_name => identity if identity.identity_id == {} }
  )

  user_assigned_identities_jobs = flatten(
    [for job_key, job in lookup(var.environment, "jobs", {}) :
      [for uai_key, uai in lookup(job, "identities", {}) :
        {
          key           = "${job_key}-${uai_key}"
          name          = try(uai.name, "${var.naming.user_assigned_identity}-${job_key}")
          type          = uai.type
          identity_ids  = try(uai.identity_ids, [])
          resourcegroup = try(uai.resourcegroup, var.environment.resourcegroup, null)
          location      = try(uai.location, var.environment.location, null)
          scope         = try(job.registry.scope, null)
          tags          = try(uai.tags, {})
        }
    ]]
  )

  secrets_jobs = flatten(
    [for job_key, job in lookup(var.environment, "jobs", {}) :
      [for sec_key, sec in lookup(job, "secrets", {}) :
        [for uai_key, uai in lookup(job, "identities", {}) : {
          key                   = "${job_key}-${sec_key}"
          uai_name              = try(uai.name, "${var.naming.user_assigned_identity}-${job_key}")
          name                  = sec_key
          value                 = try(sec.value, null)
          identity_principal_id = try(sec.value, null) == null ? azurerm_user_assigned_identity.identity_jobs[try(uai.name, "${var.naming.user_assigned_identity}-${job_key}")].principal_id : null
          identity              = try(sec.value, null) == null ? try(sec.identity, azurerm_user_assigned_identity.identity_jobs[try(uai.name, "${var.naming.user_assigned_identity}-${job_key}")].id) : null
          keyVaultUrl           = try(sec.key_vault_secret_id, null)
          kv_scope              = try(sec.kv_scope, job.kv_scope, null)
          }
        ]
      ]
    ]
  )

  job_containers = {
    for job_key, job in lookup(var.environment, "jobs", {}) : job_key => {
      name                     = try(job.name, "${var.naming.container_app_job}-${job_key}")
      location                 = try(job.location, var.environment.location, var.location)
      resourcegroup_id         = try(job.resourcegroup_id, var.environment.resourcegroup_id)
      cron_expression          = try(job.cron_expression, null)
      trigger_type             = job.trigger_type
      registry                 = job.registry
      retry_limit              = try(job.retry_limit, 10)
      timeout                  = try(job.timeout, 300)
      parallelism              = try(job.parallelism, 1)
      replica_completion_count = try(job.replica_completion_count, 1)
      scale = try(job.scale, {
        max_executions   = try(job.scale.max_executions, 1)
        min_executions   = try(job.scale.min_executions, 1)
        polling_interval = try(job.scale.polling_interval, 60)
        rules = [
          for sr_key, sr in lookup(job, "rules", {}) : {
            name     = sr.name
            type     = sr.type
            metadata = sr.metadata
            auth = [
              for auth_key, auth in lookup(sr, "auth", {}) : {
                secretRef        = auth.secret_ref
                triggerParameter = auth.trigger_parameter
              }
            ]
          }
        ]
      })
      containers = [
        for co_key, co in lookup(job.template, "containers", {}) : {
          name    = co_key
          image   = co.image
          command = try(co.command, null)
          resources = {
            cpu    = try(co.cpu, 0.25)
            memory = try(co.memory, "0.5Gi")
          }
          env = [
            for env_key, env in try(co.env, {}) : {
              name      = env_key
              value     = try(env.value, null)
              secretRef = try(env.secret_name, null)
            }
          ]
        }
      ]
      identities = [
        for uai_key, uai in lookup(job, "identities", {}) : {
          key           = "${job_key}-${uai_key}"
          name          = try(uai.name, "${var.naming.user_assigned_identity}-${job_key}")
          type          = uai.type
          identity_ids  = try(uai.identity_ids, [])
          resourcegroup = try(uai.resourcegroup, var.environment.resourcegroup, null)
          location      = try(uai.location, var.environment.location, null)
          scopes        = try(uai.scopes, null)
          tags          = try(uai.tags, {})
        }
      ]
      secrets = [for sec_key, sec in lookup(job, "secrets", {}) : {
        name        = sec_key
        value       = try(sec.value, null)
        identity    = try(sec.value, null) == null ? azurerm_user_assigned_identity.identity_jobs[try(sec.identity, "${var.naming.user_assigned_identity}-${job_key}")].id : null
        keyVaultUrl = try(sec.key_vault_secret_id, null)
        }
      ]
    }
  }

  custom_domain_certificates = flatten(
    [for ca_key, ca in lookup(var.environment, "container_apps", {}) :
      [for cert_key, cert in lookup(ca, "certificates", {}) :
        [for uai_key, uai in lookup(ca, "identities", {}) : {
          key                   = "${ca_key}-${cert_key}"
          ca_name               = ca_key
          fqdn                  = try(cert.fqdn, null)
          binding_type          = try(cert.binding_type, null)
          name                  = try(cert.name, null)
          path                  = try(cert.path, null)
          password              = try(cert.password, "")
          key_vault_certificate = try(cert.key_vault_certificate, null)
          }
    ]]]
  )
}
