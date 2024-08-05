This example illustrates the default setup, in its simplest form.

## Usage

```hcl
module "ca" {
  source  = "cloudnationhq/ca/azure"
  version = "~> 0.4"

  naming = local.naming

  environment = {
    name          = module.naming.container_app_environment.name
    location      = module.rg.groups.demo.location
    resourcegroup = module.rg.groups.demo.name

    container_apps = {
      app1 = {
        template = {
          containers = {
            container1 = {
              image = "nginx:latest"
            }
          }
        }

        ingress = {
          external_enabled = true
          target_port      = 80
          traffic_weight = {
            default = {
              percentage = 100
            }
          }
        }

        registry = {
          server = "docker.io"
        }
      }
    }
  }
}
```
