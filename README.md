# Container Apps

This terraform module automates the creation of container app resources on the azure cloud platform, enabling easier deployment and management of container apps within a container app environment.

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

## Goals

For more information, please see our [goals and non-goals](./GOALS.md).

## Testing

For more information, please see our testing [guidelines](./TESTING.md)

## Notes

Using a dedicated module, we've developed a naming convention for resources that's based on specific regular expressions for each type, ensuring correct abbreviations and offering flexibility with multiple prefixes and suffixes.

Full examples detailing all usages, along with integrations with dependency modules, are located in the examples directory.

To update the module's documentation run `make doc`

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

## Contributors

We welcome contributions from the community! Whether it's reporting a bug, suggesting a new feature, or submitting a pull request, your input is highly valued.

For more information, please see our contribution [guidelines](./CONTRIBUTING.md). <br><br>

<a href="https://github.com/cloudnationhq/terraform-azure-ca/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=cloudnationhq/terraform-azure-ca" />
</a>


## License

MIT Licensed. See [LICENSE](./LICENSE) for full details.

## References

- [Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Rest Api](https://learn.microsoft.com/en-us/rest/api/containerapps/)
