terraform {
  backend "s3" {
    bucket = "nzsl-infrastructure-terraform-state"
    region = "ap-southeast-2"
    key    = "signbank/env-uat.tfstate"
  }
}

variable "default_tags" {
  type        = map(any)
  description = "Common tags applied to all AWS resources"
  default = {
    Environment      = "uat"
    Client           = "DSRU"
    Project          = "NZSL Signbank"
    ProvisioningTool = "Terraform"
  }
}

################################################################################
# Module Local Variables
################################################################################

locals {
  # Application names should be kept relatively short as they're used to prefix
  # resources which regularly have low limits on name length.
  #
  # Generally we try and go with snappy pseudonyms or acronyms where possible
  app_name_kebab_case  = "signbank"
  app_name_pascal_case = "Signbank"

  env_name_kebab_case  = "uat"
  env_name_pascal_case = "UAT"

  client_name_kebab_case  = "nzsl"
  client_name_pascal_case = "NZSL"

  name_prefix_pascal_case = "${local.app_name_pascal_case}${local.env_name_pascal_case}"
  name_prefix_kebab_case  = "${local.app_name_kebab_case}-${local.env_name_kebab_case}"
}
