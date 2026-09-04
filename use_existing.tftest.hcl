mock_provider "azurerm" {
  mock_data "azurerm_container_app_environment" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-cae/providers/Microsoft.App/managedEnvironments/cae-existing"
      name     = "cae-existing"
      location = "westeurope"
    }
  }

  mock_resource "azurerm_container_app_environment" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-fallback/providers/Microsoft.App/managedEnvironments/cae-managed"
    }
  }
}

variables {
  location            = "westeurope"
  resource_group_name = "rg-fallback"
}

run "existing_environment_is_looked_up" {
  command = plan

  variables {
    environment = {
      name                = "cae-existing"
      resource_group_name = "rg-cae"
      use_existing        = true

      container_apps = {
        app1 = {
          template = {
            containers = {
              frontend = { image = "nginx:latest" }
            }
          }
        }
      }
    }
  }

  assert {
    condition = length(data.azurerm_container_app_environment.this) == 1 && length(azurerm_container_app_environment.this) == 0
    error_message = format(
      "use_existing must select the data source, got %d data source instance(s) and %d managed environment(s)",
      length(data.azurerm_container_app_environment.this),
      length(azurerm_container_app_environment.this),
    )
  }

  assert {
    condition = data.azurerm_container_app_environment.this["this"].resource_group_name == "rg-cae"
    error_message = format(
      "existing environment must be looked up in environment.resource_group_name (\"rg-cae\"), got %q - %s",
      data.azurerm_container_app_environment.this["this"].resource_group_name,
      data.azurerm_container_app_environment.this["this"].resource_group_name == "rg-fallback" ? "the coalesce fell through to var.resource_group_name" : "unexpected resource group",
    )
  }

  assert {
    condition = azurerm_container_app.this["app1"].container_app_environment_id == data.azurerm_container_app_environment.this["this"].id
    error_message = format(
      "container apps must attach to the existing environment id, got %q",
      azurerm_container_app.this["app1"].container_app_environment_id,
    )
  }
}

run "existing_environment_is_exposed_as_output" {
  command = plan

  variables {
    environment = {
      name                = "cae-existing"
      resource_group_name = "rg-cae"
      use_existing        = true
    }
  }

  assert {
    condition     = output.environment["this"].id == data.azurerm_container_app_environment.this["this"].id
    error_message = "the environment output must expose the data source when use_existing is set"
  }
}

run "managed_environment_when_use_existing_is_unset" {
  command = apply

  variables {
    environment = {
      name = "cae-managed"

      jobs = {
        job1 = {
          replica_timeout_in_seconds = 300
          template = {
            containers = {
              worker = { image = "nginx:latest" }
            }
          }
          manual_trigger_config = {
            parallelism              = 1
            replica_completion_count = 1
          }
        }
      }
    }
  }

  assert {
    condition = length(azurerm_container_app_environment.this) == 1 && length(data.azurerm_container_app_environment.this) == 0
    error_message = format(
      "the default must manage the environment, got %d managed environment(s) and %d data source instance(s)",
      length(azurerm_container_app_environment.this),
      length(data.azurerm_container_app_environment.this),
    )
  }

  assert {
    condition = azurerm_container_app_environment.this["this"].resource_group_name == "rg-fallback"
    error_message = format(
      "the managed environment must fall back to var.resource_group_name, got %q",
      azurerm_container_app_environment.this["this"].resource_group_name,
    )
  }

  assert {
    condition = azurerm_container_app_job.this["job1"].container_app_environment_id == azurerm_container_app_environment.this["this"].id
    error_message = format(
      "jobs must attach to the managed environment id, got %q",
      azurerm_container_app_job.this["job1"].container_app_environment_id,
    )
  }
}
