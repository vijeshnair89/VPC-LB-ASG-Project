provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "vijesh-bucket123" # change this
    key            = "vijesh-bucket123/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "state"
  }
}