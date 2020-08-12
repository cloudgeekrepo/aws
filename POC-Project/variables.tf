variable "my-access-key" {
  default = ""
}

variable "my-secret-key" {
  default = ""
}

variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "private_subnet_count" {
  default = "3"
}

variable "public_subnet_count" {
  default = "3"
}

variable "key_name" {
  default = "mydemopoc"
}

variable "iam_profile_name" {
  default = "DemoEC2Full"
}
