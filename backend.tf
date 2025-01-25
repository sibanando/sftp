terraform {
  backend "s3" {
    bucket = "testayush"
    key    = "siba/terraform.tfstate"
    region = "us-east-1"
  }
}