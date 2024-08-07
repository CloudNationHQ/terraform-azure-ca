locals {
  ##########################
  ##### Container Apps #####
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
        resource_group      = try(sec.identity.resource_group, var.environment.resource_group, null)
        location            = try(sec.identity.location, var.environment.location, null)
        tags                = try(sec.identity.tags, {})
        type                = try(sec.identity.type, "UserAssigned")
      }
  if contains(keys(sec), "value") == false]])

  user_assigned_identity_registry = flatten([for ca_key, ca in lookup(var.environment, "container_apps", {}) :
    {
      ca_name        = ca_key
      scope          = try(ca.registry.scope, null)
      server         = ca.registry.server
      principal_id   = try(ca.registry.identity.principal_id, null)
      identity_id    = lookup(lookup(ca.registry, "identity", {}), "id", {})
      id_name        = try(ca.registry.identity.name, "${var.naming.user_assigned_identity}-${ca_key}")
      resource_group = try(ca.registry.identity.resource_group, var.environment.resource_group, null)
      location       = try(ca.registry.identity.location, var.environment.location, null)
      tags           = try(ca.registry.identity.tags, {})
      type           = try(ca.registry.identity.type, "UserAssigned")
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

  ##############################
  ##### Container App Jobs #####

  user_assigned_identities_jobs_secrets = flatten(
    [for job_key, job in lookup(var.environment, "jobs", {}) :
      [for sec_key, sec in lookup(job, "secrets", {}) :
        {
          job_name            = job_key
          name                = try(sec.name, sec_key)
          key_vault_secret_id = try(sec.key_vault_secret_id, null)
          kv_scope            = try(sec.kv_scope, job.kv_scope)
          principal_id        = try(sec.identity.principal_id, null)
          identity_id         = lookup(lookup(sec, "identity", {}), "id", {})
          id_name             = try(sec.identity.name, "${var.naming.user_assigned_identity}-${job_key}")
          resource_group      = try(sec.identity.resource_group, var.environment.resource_group, null)
          location            = try(sec.identity.location, var.environment.location, null)
          tags                = try(sec.identity.tags, {})
          type                = try(sec.identity.type, "UserAssigned")
        }
  if contains(keys(sec), "value") == false]])

  user_assigned_identity_jobs_registry = flatten(
    [for job_key, job in lookup(var.environment, "jobs", {}) :
      {
        job_name       = job_key
        scope          = try(job.registry.scope, null)
        server         = job.registry.server
        principal_id   = try(job.registry.identity.principal_id, null)
        identity_id    = lookup(lookup(job.registry, "identity", {}), "id", {})
        id_name        = try(job.registry.identity.name, "${var.naming.user_assigned_identity}-${job_key}")
        resource_group = try(job.registry.identity.resource_group, var.environment.resource_group, null)
        location       = try(job.registry.identity.location, var.environment.location, null)
        tags           = try(job.registry.identity.tags, {})
        type           = try(job.registry.identity.type, "UserAssigned")
      }
  if contains(keys(job.registry), "username") == false])

  ## Multiple user assigned identities with the same name are implicitly generated when multiple secrets are defined
  ## To avoid this, we create a list of unique identity names and then create a map of identity objects
  unique_uai_jobs_secrets     = distinct([for identity in local.user_assigned_identities_jobs_secrets : identity.id_name])
  unique_uai_jobs_secrets_map = { for name in local.unique_uai_jobs_secrets : name => [for identity in local.user_assigned_identities_jobs_secrets : identity if identity.id_name == name][0] }

  ## Merge all identities, including those with identity_id (Bring Your Own UAI) - needed to set identity_ids in identity block
  merged_jobs_identities_all = merge(
    { for identity in local.unique_uai_jobs_secrets_map : identity.id_name => identity },
    { for identity in local.user_assigned_identity_jobs_registry : identity.id_name => identity }
  )

  ## Merge all identities, except those with identity_id (Bring Your Own UAI) - needed to generate User Assigned Identities
  merged_jobs_identities_filtered = merge(
    { for identity in local.unique_uai_jobs_secrets_map : identity.id_name => identity if identity.identity_id == {} },
    { for identity in local.user_assigned_identity_jobs_registry : identity.id_name => identity if identity.identity_id == {} }
  )

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
