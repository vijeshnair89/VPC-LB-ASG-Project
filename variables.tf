#### Variables 

variable "cidr_vpc" {
  default = "10.0.0.0/16"
  description = "cidr block to be used by the VPC in Mumbai"
}


variable "az1" {
  default = "us-east-1a"
  description = "cidr block to be used by the VPC in Mumbai"
}


variable "az2" {
  default = "us-east-1b"
  description = "cidr block to be used by the VPC in Mumbai"
}

variable "cidr_pubsub1" {
  default = "10.0.0.0/24"
  description = "cidr block to be used by the public subnet in US-EAST-1A"
}

variable "cidr_pubsub2" {
  default = "10.0.1.0/24"
  description = "cidr block to be used by the public subnet in us-east-ab"
}

variable "cidr_prvsub1" {
  default = "10.0.2.0/24"
  description = "cidr block to be used by the private subnet in US-EAST-1A"
}

variable "cidr_prvsub2" {
  default = "10.0.3.0/24"
  description = "cidr block to be used by the private subnet in US-EAST-1B"
}

variable "ami" {
  default = "ami-080e1f13689e07408"
  description = "AMI of the instance to be used in Virginia"
}


variable "type" {
  default ="t2.micro"
  description = "Instance Type of Virginia"
}