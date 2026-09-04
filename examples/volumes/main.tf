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
          volumes = {
            content = {
              storage_type = "EmptyDir"
            }
          }

          init_containers = {
            seed = {
              image   = "busybox:latest"
              command = ["/bin/sh"]
              args    = ["-c", "echo hello from the init container > /seed/index.html"]

              env = {
                TARGET = {
                  value = "/seed/index.html"
                }
              }

              volume_mounts = {
                content = {
                  path = "/seed"
                }
              }
            }
          }

          containers = {
            frontend = {
              image = "nginx:latest"

              volume_mounts = {
                content = {
                  path = "/usr/share/nginx/html"
                }
              }
            }

            sidecar = {
              image = "busybox:latest"
              args  = ["-c", "while true; do sleep 30; done"]

              command = ["/bin/sh"]

              volume_mounts = {
                content = {
                  path     = "/data"
                  sub_path = "shared"
                }
              }
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
