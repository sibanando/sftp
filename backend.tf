terraform {
  backend "s3" {
    bucket = "testayush"
    key    = "siba/terraform.tfstate"
    region = "us-west-2"
  }
}