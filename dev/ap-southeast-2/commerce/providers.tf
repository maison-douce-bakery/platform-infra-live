provider "aws" {
  region              = "ap-southeast-2"
  allowed_account_ids = ["452258152479"]

  default_tags {
    tags = {
      Project     = "mdb"
      Environment = "dev"
      ManagedBy   = "terraform"
      Repo        = "platform-infra-live"
    }
  }
}
