locals {
  naming = {
    # lookup outputs to have consistent naming
    for type in local.naming_types : type => lookup(module.naming, type).name
  }

  naming_types = ["container_app", "container_app_environment", "user_assigned_identity", "key_vault_secret", "network_security_group", "subnet", "key_vault_certificate"]
}
