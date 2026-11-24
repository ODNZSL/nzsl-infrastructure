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
