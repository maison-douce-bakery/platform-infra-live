terraform {
  backend "s3" {
    key = "platform-infra-live/dev/ap-southeast-2/ecs/terraform.tfstate"
  }
}
