variable "environment" {
  description = "describes container apps configuration"
  type        = any
}

variable "naming" {
  description = "contains naming convention"
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "default azure region and can be used if location is not specified inside the object."
  type        = string
  default     = null
}

variable "resource_group" {
  description = "default resource group and can be used if resourcegroup is not specified inside the object."
  type        = string
  default     = null
}

variable "tags" {
  description = "default tags and can be used if tags are not specified inside the object."
  type        = map(string)
  default     = {}
}
