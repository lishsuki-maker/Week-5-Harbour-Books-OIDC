variable "sg_name" {
  description = "Name of the security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the security group belongs to"
  type        = string
}

variable "ingress_port" {
  description = "TCP port to allow inbound"
  type        = number
}

variable "allowed_sg" {
  description = "Security group ID allowed to reach this port"
  type        = string
  default     = null
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach this port"
  type        = list(string)
  default     = []
}
