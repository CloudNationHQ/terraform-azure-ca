locals {
  # Custom domain certificates processing
  custom_domain_certificates = flatten([
    for ca_key, ca in(var.environment.container_apps != null ? var.environment.container_apps : {}) : [
      for cert_key, cert in(ca.certificates != null ? ca.certificates : {}) : {
        key                   = "${ca_key}-${cert_key}"
        ca_name               = ca_key
        fqdn                  = cert.fqdn
        binding_type          = cert.binding_type
        name                  = cert.name
        path                  = cert.path
        password              = cert.password
        key_vault_certificate = cert.key_vault_certificate
      }
    ]
  ])
}
