# Dual-region / dual-account: Auckland PRIMARY, Sydney SECONDARY.
# Pass providers = { aws = aws.primary|secondary } into each regional module.
# Route53 VIP records use aws.secondary (zone lives in the Sydney account).

provider "aws" {
  alias   = "primary"
  region  = var.primary_region
  profile = var.primary_aws_profile

  default_tags {
    tags = {
      ManagedBy     = "terraform"
      Service       = "ntripcaster"
      IngestPattern = "relay_iport"
      Example       = "relay_iport_ha_mr"
      HaRole        = "primary"
    }
  }
}

provider "aws" {
  alias   = "secondary"
  region  = var.secondary_region
  profile = var.secondary_aws_profile

  default_tags {
    tags = {
      ManagedBy     = "terraform"
      Service       = "ntripcaster"
      IngestPattern = "relay_iport"
      Example       = "relay_iport_ha_mr"
      HaRole        = "secondary"
    }
  }
}
