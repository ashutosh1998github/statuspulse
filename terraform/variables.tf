variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "Ubuntu 22.04 AMI ID"
  type        = string
  default     = "ami-0f58b397bc5c1f2e8"
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
  default     = "statuspulse-key"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "statuspulse"
}

variable "domain" {
  description = "Domain name"
  type        = string
  default     = "statuspulse.duckdns.org"
}