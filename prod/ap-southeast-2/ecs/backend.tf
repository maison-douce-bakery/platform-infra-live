terraform {
  backend "s3" {
    key = "platform-infra-live/prod/ap-southeast-2/ecs/terraform.tfstate"
  }
}
