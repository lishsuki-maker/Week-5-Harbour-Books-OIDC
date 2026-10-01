variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-2"
}

variable "name_prefix" {
  description = "Prefix used when naming resources"
  type        = string
  default     = "harbour-books-reformation"
}

variable "my_ip" {
  description = "My public IP address"
  type        = string
  default     = "180.150.37.68/32"
}

variable "instances" {
  description = "EC2 instances"
  type = map(object({
    instance_type = string
  }))
}

variable "ami_id" {
  description = "EC2 AMI ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
}

variable "db_user_password" {
  description = "Master password for the database"
  type        = string
}
