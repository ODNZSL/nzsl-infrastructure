terraform {
  backend "s3" {
    region = "ap-southeast-2"
    bucket = "nzsl-infrastructure-terraform-state"
    key    = "share/env-uat.tfstate"

    use_lockfile = true
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
  app_name_kebab_case  = "share"
  app_name_pascal_case = "Share"

  env_name_kebab_case  = "uat"
  env_name_pascal_case = "UAT"

  client_name_kebab_case  = "nzsl"
  client_name_pascal_case = "NZSL"

  default_tags = {
    Application      = local.app_name_pascal_case
    Client           = local.client_name_pascal_case
    Environment      = local.env_name_pascal_case
    ProvisioningTool = "Terraform"
  }

  name_prefix_pascal_case = "${local.app_name_pascal_case}${local.env_name_pascal_case}"
  name_prefix_kebab_case  = "${local.app_name_kebab_case}-${local.env_name_kebab_case}"
}
