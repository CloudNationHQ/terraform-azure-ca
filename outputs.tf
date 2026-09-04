output "container_apps" {
  description = "contains all container app(s) configuration"
  value       = azurerm_container_app.this
  sensitive   = true
}

output "container_app_jobs" {
  description = "contains all container app jobs configuration"
  value       = azurerm_container_app_job.this
  sensitive   = true
}

output "environment" {
  description = "contains all container app environment configuration"
  value       = var.environment.use_existing ? data.azurerm_container_app_environment.this : azurerm_container_app_environment.this
  sensitive   = true
}

output "certificates" {
  description = "contains all container app environment certificate(s) configuration"
  value       = azurerm_container_app_environment_certificate.this
  sensitive   = true
}

output "custom_domains" {
  description = "contains all container app custom domain(s) configuration"
  value       = azurerm_container_app_custom_domain.this
}


