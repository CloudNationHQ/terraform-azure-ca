moved {
  from = data.azurerm_container_app_environment.existing
  to   = data.azurerm_container_app_environment.this
}

moved {
  from = azurerm_container_app_environment.cae["cae"]
  to   = azurerm_container_app_environment.this["this"]
}

moved {
  from = azurerm_container_app.ca
  to   = azurerm_container_app.this
}

moved {
  from = azurerm_container_app_environment_certificate.certificate
  to   = azurerm_container_app_environment_certificate.this
}

moved {
  from = azurerm_container_app_custom_domain.domain
  to   = azurerm_container_app_custom_domain.this
}

moved {
  from = azurerm_container_app_job.job
  to   = azurerm_container_app_job.this
}
