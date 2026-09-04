module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.32"

  suffix = ["demo", "dev"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 3.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = "westeurope"
    }
  }
}

module "ca" {
  source  = "cloudnationhq/ca/azure"
  version = "~> 5.0"

  environment = {
    name                = module.naming.container_app_environment.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    container_apps = {
      app1 = {
        template = {
          containers = {
            frontend = {
              image = "nginx:latest"

              startup_probe = {
                transport               = "HTTP"
                port                    = 80
                path                    = "/"
                initial_delay           = 5
                interval_seconds        = 10
                timeout                 = 5
                failure_count_threshold = 10
              }

              liveness_probe = {
                transport               = "HTTP"
                port                    = 80
                path                    = "/"
                interval_seconds        = 30
                timeout                 = 5
                failure_count_threshold = 3

                headers = {
                  x-probe-source = {
                    value = "liveness"
                  }
                }
              }

              readiness_probe = {
                transport               = "HTTP"
                port                    = 80
                path                    = "/"
                interval_seconds        = 10
                timeout                 = 5
                failure_count_threshold = 3
                success_count_threshold = 1
              }
            }
          }

          init_containers = {
            wait = {
              image   = "busybox:latest"
              command = ["/bin/sh"]
              args    = ["-c", "echo ready"]
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
      }
    }
  }
}
