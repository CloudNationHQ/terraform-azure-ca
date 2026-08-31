output "container_apps" {
  description = "contains all container app(s) configuration"
  value       = azurerm_container_app.this
}

output "container_app_jobs" {
  description = "contains all container app jobs configuration"
  value       = azurerm_container_app_job.this
}

output "environment" {
  description = "contains all container app environment configuration"
  value       = var.environment.use_existing ? data.azurerm_container_app_environment.this : azurerm_container_app_environment.this
}

output "certificates" {
  description = "contains all container app environment certificate(s) configuration"
  value       = azurerm_container_app_environment_certificate.this
}

output "custom_domains" {
  description = "contains all container app custom domain(s) configuration"
  value       = azurerm_container_app_custom_domain.this
}
