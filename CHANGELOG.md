# Changelog

## [2.0.0](https://github.com/CloudNationHQ/terraform-azure-ca/compare/v1.1.0...v2.0.0) (2024-09-24)


### ⚠ BREAKING CHANGES

* Version 4 of the azurerm provider includes breaking changes.

### Features

* upgrade azurerm provder to v4 ([#33](https://github.com/CloudNationHQ/terraform-azure-ca/issues/33)) ([bfdbb44](https://github.com/CloudNationHQ/terraform-azure-ca/commit/bfdbb444dae770afee7669facde976a35b02d1bb))

### Upgrade from v1.1.0 to v2.0.0:

- Update module reference to: `version = "~> 2.0"`

## [1.1.0](https://github.com/CloudNationHQ/terraform-azure-ca/compare/v1.0.0...v1.1.0) (2024-08-28)


### Features

* update documentation ([#30](https://github.com/CloudNationHQ/terraform-azure-ca/issues/30)) ([15cffdb](https://github.com/CloudNationHQ/terraform-azure-ca/commit/15cffdb7229e31ac1911019ca323d85e4a5110e7))

## [1.0.0](https://github.com/CloudNationHQ/terraform-azure-ca/compare/v0.4.0...v1.0.0) (2024-08-08)


### ⚠ BREAKING CHANGES

* replaced azapi resources for container app jobs with native azurerm_container_app_job native resource

### Features

* update jobs to native azurerm resources ([#27](https://github.com/CloudNationHQ/terraform-azure-ca/issues/27)) ([03f344b](https://github.com/CloudNationHQ/terraform-azure-ca/commit/03f344b5bd2f0c457ecc0b7db7ac01bfe757c4b3))

### Upgrade from v0.4.0 to v1.0.0

- Update **module reference** to: `version = "~> 1.0"`
- Rename properties in **environment** object:
   * resourcegroup -> resource_group
   * init_container -> template.init_container
- Rename **variable** (optional):
   * resourcegroup -> resource_group

## [0.4.0](https://github.com/CloudNationHQ/terraform-azure-ca/compare/v0.3.0...v0.4.0) (2024-08-05)


### Features

* **deps:** bump github.com/gruntwork-io/terratest in /tests ([#24](https://github.com/CloudNationHQ/terraform-azure-ca/issues/24)) ([d618a99](https://github.com/CloudNationHQ/terraform-azure-ca/commit/d618a9959237d965ab2fe4932a432e7c1e688a35))
* update contribution docs ([#22](https://github.com/CloudNationHQ/terraform-azure-ca/issues/22)) ([93e1d73](https://github.com/CloudNationHQ/terraform-azure-ca/commit/93e1d736a538dcd1f1fa8fddbaec97993fc9cfbd))


### Bug Fixes

* bring your own user assigned identity ([#26](https://github.com/CloudNationHQ/terraform-azure-ca/issues/26)) ([deb475d](https://github.com/CloudNationHQ/terraform-azure-ca/commit/deb475d40e2729b1f2f26214f1080762f6d9f18d))

## [0.3.0](https://github.com/CloudNationHQ/terraform-azure-ca/compare/v0.2.1...v0.3.0) (2024-07-02)


### Features

* add issue template ([#20](https://github.com/CloudNationHQ/terraform-azure-ca/issues/20)) ([6c436b5](https://github.com/CloudNationHQ/terraform-azure-ca/commit/6c436b5af7432fd76b2c57d10517f20412eec83f))
* **deps:** bump github.com/gruntwork-io/terratest in /tests ([#18](https://github.com/CloudNationHQ/terraform-azure-ca/issues/18)) ([dd2f9bc](https://github.com/CloudNationHQ/terraform-azure-ca/commit/dd2f9bcaf34dbb10562bb3f9c37c3b9e89677ef2))
* **deps:** bump github.com/hashicorp/go-getter in /tests ([#15](https://github.com/CloudNationHQ/terraform-azure-ca/issues/15)) ([51623b3](https://github.com/CloudNationHQ/terraform-azure-ca/commit/51623b31412a86f48ef05bdab7d9ee65b89bcd08))

## [0.2.1](https://github.com/CloudNationHQ/terraform-azure-ca/compare/v0.2.0...v0.2.1) (2024-07-01)


### Bug Fixes

* make kv_scope optional for secret retrieval when identity is not required ([#17](https://github.com/CloudNationHQ/terraform-azure-ca/issues/17)) ([29b264f](https://github.com/CloudNationHQ/terraform-azure-ca/commit/29b264f12e6069f34e53757f030664789db18388))

## [0.2.0](https://github.com/CloudNationHQ/terraform-azure-ca/compare/v0.1.0...v0.2.0) (2024-06-26)


### Features

* create pull request template ([#8](https://github.com/CloudNationHQ/terraform-azure-ca/issues/8)) ([a7efb14](https://github.com/CloudNationHQ/terraform-azure-ca/commit/a7efb143f70e573cdd4599a9be63294e9d1d87a4))
* **deps:** bump github.com/gruntwork-io/terratest in /tests ([#7](https://github.com/CloudNationHQ/terraform-azure-ca/issues/7)) ([19c546b](https://github.com/CloudNationHQ/terraform-azure-ca/commit/19c546b95df35192195fd2f27a3e12580162959d))
* interpolation syntax ([#10](https://github.com/CloudNationHQ/terraform-azure-ca/issues/10)) ([0359eab](https://github.com/CloudNationHQ/terraform-azure-ca/commit/0359eab40edbd5af99e4a965199414e17a4c03ed))


### Bug Fixes

* authentication for custom scale rule ([#16](https://github.com/CloudNationHQ/terraform-azure-ca/issues/16)) ([26237ee](https://github.com/CloudNationHQ/terraform-azure-ca/commit/26237ee3a979322e7182f0737649b043f9c7c178))
* refactor secrets and user assigned identities, with complete examples with all secrets variations ([#14](https://github.com/CloudNationHQ/terraform-azure-ca/issues/14)) ([8600690](https://github.com/CloudNationHQ/terraform-azure-ca/commit/86006903e6749c764dbc831e7798000e4eea7b76))

## 0.1.0 (2024-05-13)


### Features

* add initial resources ([18c5230](https://github.com/CloudNationHQ/terraform-azure-ca/commit/18c5230687d4250fb1c65ae88bdbc9a4ba1e72ab))
* **deps:** bump golang.org/x/net from 0.17.0 to 0.23.0 in /tests ([#4](https://github.com/CloudNationHQ/terraform-azure-ca/issues/4)) ([33a4711](https://github.com/CloudNationHQ/terraform-azure-ca/commit/33a471159d2c82a40c67f3d52d3f27f94967262e))
