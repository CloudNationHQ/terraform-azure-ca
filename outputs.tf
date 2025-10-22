output "container_apps" {
  description = "contains all container app(s) configuration"
  value       = azurerm_container_app.ca
}

output "container_app_jobs" {
  description = "contains all container app jobs configuration"
  value       = azurerm_container_app_job.job
}

output "environment" {
  description = "contains all container app environment configuration"
  value       = var.environment.use_existing ? data.azurerm_container_app_environment.existing : azurerm_container_app_environment.cae
}

output "certificates" {
  description = "contains all container app environment certificate(s) configuration"
  value       = azurerm_container_app_environment_certificate.certificate
}

output "custom_domains" {
  description = "contains all container app custom domain(s) configuration"
  value       = azurerm_container_app_custom_domain.domain
}


