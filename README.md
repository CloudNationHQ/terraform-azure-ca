# Container Apps

This terraform module automates the creation of container app resources on the azure cloud platform, enabling easier deployment and management of container apps within a container app environment.

## Goals

The main objective is to create a more logic data structure, achieved by combining and grouping related resources together in a complex object.

The structure of the module promotes reusability. It's intended to be a repeatable component, simplifying the process of building diverse workloads and platform accelerators consistently.

A primary goal is to utilize keys and values in the object that correspond to the REST API's structure. This enables us to carry out iterations, increasing its practical value as time goes on.

A last key goal is to separate logic from configuration in the module, thereby enhancing its scalability, ease of customization, and manageability.

## Non-Goals

These modules are not intended to be complete, ready-to-use solutions; they are designed as components for creating your own patterns.

They are not tailored for a single use case but are meant to be versatile and applicable to a range of scenarios.

Security standardization is applied at the pattern level, while the modules include default values based on best practices but do not enforce specific security standards.

End-to-end testing is not conducted on these modules, as they are individual components and do not undergo the extensive testing reserved for complete patterns or solutions.

## Features

- provides support for retrieval of container images from the registry using user-assigned identities
- provides support for secrets to retrieve from a key vault backend scope
- offers possibility to integrate the container app environment to your own vnet (vnet integration)
- allows for ingress to be set to external (limited to container app environment), limited to the vnet or wide open
- facilitates the use of custom domain names for your container apps
- provides support for certificates for custom domain names
- allows for multiple container apps to be deployed within a container app environment
- enables multiple container app jobs
- utilization of terratest for robust validation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_container_app.ca](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_container_app_custom_domain.domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_custom_domain) | resource |
| [azurerm_container_app_environment.cae](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) | resource |
| [azurerm_container_app_environment_certificate.certificate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment_certificate) | resource |
| [azurerm_container_app_job.job](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_job) | resource |
| [azurerm_role_assignment.role_acr_pull](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_acr_pull_jobs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_secret_user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_secret_user_jobs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_user_assigned_identity.identity_jobs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | describes container apps configuration | `any` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | default azure region and can be used if location is not specified inside the object. | `string` | `null` | no |
| <a name="input_naming"></a> [naming](#input\_naming) | contains naming convention | `map(string)` | `{}` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | default resource group and can be used if resourcegroup is not specified inside the object. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | default tags and can be used if tags are not specified inside the object. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_certificates"></a> [certificates](#output\_certificates) | contains all container app environment certificate(s) configuration |
| <a name="output_container_app_jobs"></a> [container\_app\_jobs](#output\_container\_app\_jobs) | contains all container app jobs configuration |
| <a name="output_container_apps"></a> [container\_apps](#output\_container\_apps) | contains all container app(s) configuration |
| <a name="output_custom_domains"></a> [custom\_domains](#output\_custom\_domains) | contains all container app custom domain(s) configuration |
| <a name="output_environment"></a> [environment](#output\_environment) | contains all container app environment configuration |
| <a name="output_user_assigned_identities"></a> [user\_assigned\_identities](#output\_user\_assigned\_identities) | contains all user assigned identities configuration |
<!-- END_TF_DOCS -->

## Testing

As a prerequirement, please ensure that both go and terraform are properly installed on your system.

The [Makefile](Makefile) includes two distinct variations of tests. The first one is designed to deploy different usage scenarios of the module. These tests are executed by specifying the TF_PATH environment variable, which determines the different usages located in the example directory.

To execute this test, input the command ```make test TF_PATH=default```, substituting default with the specific usage you wish to test.

The second variation is known as a extended test. This one performs additional checks and can be executed without specifying any parameters, using the command ```make test_extended```.

Both are designed to be executed locally and are also integrated into the github workflow.

Each of these tests contributes to the robustness and resilience of the module. They ensure the module performs consistently and accurately under different scenarios and configurations.

## Notes

**Recommended Identity for Image Retrieval from Azure Container Registry (ACR):**
While it's technically possible to use a system-assigned identity for pulling images from an Azure Container Registry (ACR), we strongly recommend using user-assigned identities. Here's why:

The system-assigned identity requires 'AcrPull' permissions on the registry. However, you cannot assign this role until after the resource (in this case, the container app) has been deployed. This creates a catch-22, because the container app cannot be deployed without first retrieving an image.

By using a user-assigned identity, this issue can be avoided. The deployment order within the module would be as follows:

- deploy ACR
- deploy user-assigned identity
- assign the 'AcrPull' role
- deploy the container app

This way, the module ensures that all the necessary permissions are in place before the container app deployment. It is a smoother, first time right deployment and more reliable process that we strongly recommend for most use cases.
See also [here](https://learn.microsoft.com/en-us/azure/container-apps/managed-identity?tabs=portal%2Cdotnet#common-use-cases)

Full examples detailing all usages, along with integrations with dependency modules, are located in the examples directory

## Authors

Module is maintained by [these awesome contributors](https://github.com/cloudnationhq/terraform-azure-ca/graphs/contributors).

## Contributing

We welcome contributions from the community! Whether it's reporting a bug, suggesting a new feature, or submitting a pull request, your input is highly valued.

For more information, please see our contribution [guidelines](./CONTRIBUTING.md).

## License

MIT Licensed. See [LICENSE](./LICENSE) for full details.

## Reference

- [Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Rest Api](https://learn.microsoft.com/en-us/rest/api/containerapps/)
