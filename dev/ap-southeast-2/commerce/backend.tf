terraform {
  backend "s3" {
    key = "platform-infra-live/dev/ap-southeast-2/commerce/terraform.tfstate"
  }
}
